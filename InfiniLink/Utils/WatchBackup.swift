//
//  WatchBackup.swift
//  InfiniLink
//
//  Created by Liam Willey on 11/22/26.
//

import Foundation
import Zip

struct WatchBackup {
    struct Manifest: Codable {
        let firmware: String
        let date: Date
        let paths: [String]
    }

    struct Contents {
        let manifest: Manifest
        let directory: URL
    }

    struct RestoreResult {
        var failed = 0
        var skippedResources = false
        var skippedSettings = false
        var restoredSettings = false
    }

    static let resourceDirectories = ["/fonts/", "/images/"]

    private let bleFs = BLEFSHandler.shared

    typealias Progress = (_ completed: Int, _ total: Int, _ size: Int) -> Void

    func create(progress: @escaping Progress, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var url: URL?
            do {
                url = try makeBackup(progress: progress)
            } catch {
                log("Error creating backup: \(error.localizedDescription)", caller: "WatchBackup", target: .ble)
            }

            DispatchQueue.main.async { completion(url) }
        }
    }

    func open(_ url: URL) -> Contents? {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }

        guard let directory = try? Zip.quickUnzipFile(url),
              let data = try? Data(contentsOf: directory.appendingPathComponent("manifest.json")),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else {
            log("Couldn't open backup \(url.lastPathComponent)", caller: "WatchBackup", target: .ble)
            return nil
        }

        return Contents(manifest: manifest, directory: directory)
    }

    func restore(_ contents: Contents, progress: @escaping Progress, completion: @escaping (RestoreResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let firmware = DeviceManager.shared.firmware
            var result = RestoreResult()

            for (index, path) in contents.manifest.paths.enumerated() {
                guard var data = try? Data(contentsOf: contents.directory.appendingPathComponent(String(index))) else {
                    result.failed += 1
                    continue
                }

                var settings: WatchSettingsFile?
                if path == "/settings.dat" {
                    settings = settingsFile(from: data, firmware: contents.manifest.firmware, to: firmware)
                    guard let settings else {
                        result.skippedSettings = true
                        continue
                    }
                    data = settings.data
                } else if path == WatchAlarmFile.path {
                    guard WatchAlarmFile.supported(onFirmware: firmware), WatchAlarmFile(data: data) != nil else {
                        result.skippedSettings = true
                        continue
                    }
                } else if contents.manifest.firmware != firmware && Self.resourceDirectories.contains(where: path.hasPrefix) {
                    result.skippedResources = true
                    continue
                }

                DispatchQueue.main.async { [data] in progress(index, contents.manifest.paths.count, data.count) }
                bleFs.createDir(path: path)
                guard bleFs.writeFile(data: data, path: path) else {
                    result.failed += 1
                    continue
                }

                if let settings {
                    result.restoredSettings = true
                    DeviceManager.shared.updateHeartRateBackgroundPeriod(from: settings)
                    DispatchQueue.main.async { DeviceManager.shared.updateSettings(settings.settings) }
                }
            }

            DispatchQueue.main.async { completion(result) }
        }
    }

    private func makeBackup(progress: @escaping Progress) throws -> URL? {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory.appendingPathComponent("InfiniLink Backup", isDirectory: true)
        try? fileManager.removeItem(at: directory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        guard let paths = filePaths(in: "/") else { return nil }
        for (index, path) in paths.enumerated() {
            DispatchQueue.main.async { progress(index, paths.count, 0) }
            let file = bleFs.readFile(path: path)
            guard file.valid else {
                log("Couldn't read \(path) for backup", caller: "WatchBackup", target: .ble)
                return nil
            }
            try file.data.write(to: directory.appendingPathComponent(String(index)))
        }

        let manifest = Manifest(firmware: DeviceManager.shared.firmware, date: Date(), paths: paths)
        try JSONEncoder().encode(manifest).write(to: directory.appendingPathComponent("manifest.json"))

        let zipURL = fileManager.temporaryDirectory.appendingPathComponent("InfiniTime Backup.zip")
        try? fileManager.removeItem(at: zipURL)
        try Zip.zipFiles(paths: fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil), zipFilePath: zipURL, password: nil, progress: nil)

        return zipURL
    }

    private func filePaths(in directory: String) -> [String]? {
        guard let entries = bleFs.listDir(path: directory) else { return nil }

        var paths = [String]()
        for entry in entries where entry.pathNames != "." && entry.pathNames != ".." {
            let path = (directory == "/" ? "" : directory) + "/" + entry.pathNames
            if entry.isDirectory {
                guard let children = filePaths(in: path) else { return nil }
                paths += children
            } else {
                paths.append(path)
            }
        }
        return paths
    }

    private func settingsFile(from data: Data, firmware old: String, to new: String) -> WatchSettingsFile? {
        guard let source = WatchSettingsFile(data: data), let expected = WatchSettingsFile.expectedVersion(forFirmware: new),
              var file = source.version == expected ? source : source.migrated(to: expected) else { return nil }

        let catalog = WatchFaceCatalog.shared
        let faceId = catalog.face(at: source.watchFace, firmware: old)?.id
        file.watchFace = catalog.faces(firmware: new).first { $0.id == faceId }?.index ?? 0
        return file
    }
}
