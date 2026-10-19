//
//  WatchFaceCatalog.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

struct WatchFaceEntry: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    var isCustom = false
    var imageFile: String? // An optional photo of the face used as its preview
    var minimumFirmware: String?
    var index: UInt8 = 0 // Value in InfiniTime's WatchFace enum
}

class WatchFaceCatalog: ObservableObject {
    static let shared = WatchFaceCatalog()

    // InfiniTime's default order
    static let builtIn = [
        WatchFaceEntry(id: "digital", name: "Digital"),
        WatchFaceEntry(id: "analog", name: "Analog"),
        WatchFaceEntry(id: "pineTimeStyle", name: "PineTimeStyle"),
        WatchFaceEntry(id: "terminal", name: "Terminal"),
        WatchFaceEntry(id: "infineat", name: "Infineat"),
        WatchFaceEntry(id: "casio", name: "Casio G7710"),
        WatchFaceEntry(id: "numerals", name: "Numerals", minimumFirmware: "1.17.0"),
        WatchFaceEntry(id: "prideFlag", name: "Pride Flag", minimumFirmware: "1.16.0")
    ]

    @Published private var customFaces: [WatchFaceEntry] = [] {
        didSet { save() }
    }
    @Published private var order: [String] = [] {
        didSet { save() }
    }
    @Published private var hiddenIds: Set<String> = [] {
        didSet { save() }
    }
    // Newer firmware faces the user turned on
    @Published private var shownIds: Set<String> = [] {
        didSet { save() }
    }

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "customWatchFaces"), let faces = try? JSONDecoder().decode([WatchFaceEntry].self, from: data) {
            customFaces = faces
        }
        order = defaults.stringArray(forKey: "watchFaceOrder") ?? []
        hiddenIds = Set(defaults.stringArray(forKey: "hiddenWatchFaceIds") ?? [])
        shownIds = Set(defaults.stringArray(forKey: "shownWatchFaceIds") ?? [])
    }

    private func isOnFirmware(_ face: WatchFaceEntry, _ firmware: String) -> Bool {
        face.minimumFirmware.map { firmware.compare($0, options: .numeric) != .orderedAscending } ?? true
    }

    func isShown(_ face: WatchFaceEntry, firmware: String = DeviceManager.shared.firmware) -> Bool {
        isOnFirmware(face, firmware) ? !hiddenIds.contains(face.id) : shownIds.contains(face.id)
    }

    func setShown(_ shown: Bool, for face: WatchFaceEntry) {
        if isOnFirmware(face, DeviceManager.shared.firmware) {
            if shown {
                hiddenIds.remove(face.id)
            } else {
                hiddenIds.insert(face.id)
            }
        } else if shown {
            shownIds.insert(face.id)
        } else {
            shownIds.remove(face.id)
        }
    }

    var allFaces: [WatchFaceEntry] {
        ordered(Self.builtIn + customFaces)
    }

    // Hidden faces still take up a value
    func faces(firmware: String = DeviceManager.shared.firmware) -> [WatchFaceEntry] {
        let available = ordered(Self.builtIn + customFaces).filter { isOnFirmware($0, firmware) || shownIds.contains($0.id) }

        return available.enumerated().map { position, face in
            var face = face
            face.index = UInt8(clamping: position)
            return face
        }
    }

    private func ordered(_ available: [WatchFaceEntry]) -> [WatchFaceEntry] {
        var ordered = order.compactMap { id in available.first { $0.id == id } }
        // New faces go in their default spot
        for (position, face) in available.enumerated() where !ordered.contains(where: { $0.id == face.id }) {
            ordered.insert(face, at: min(position, ordered.count))
        }
        return ordered
    }

    var visibleFaces: [WatchFaceEntry] {
        faces().filter { isShown($0) }
    }

    func face(at index: UInt8, firmware: String = DeviceManager.shared.firmware) -> WatchFaceEntry? {
        faces(firmware: firmware).first { $0.index == index }
    }

    func name(for index: UInt8) -> String {
        face(at: index)?.name ?? String(format: NSLocalizedString("Watch Face %d", comment: ""), Int(index))
    }

    func addCustomFace(name: String) {
        customFaces.append(WatchFaceEntry(id: "custom-" + UUID().uuidString, name: name, isCustom: true))
    }

    func moveFaces(from source: IndexSet, to destination: Int) {
        var ids = allFaces.map { $0.id }
        ids.move(fromOffsets: source, toOffset: destination)
        order = ids
    }

    func removeFaces(at offsets: IndexSet) {
        let ids = offsets.map { allFaces[$0] }.filter { $0.isCustom }.map { $0.id }

        customFaces.filter { ids.contains($0.id) }.forEach { deleteImage($0.imageFile) }
        customFaces.removeAll { ids.contains($0.id) }
        order.removeAll { ids.contains($0) }
        hiddenIds.subtract(ids)
    }

    func resetToDefaults() {
        customFaces.forEach { deleteImage($0.imageFile) }
        customFaces = []
        order = []
        hiddenIds = []
        shownIds = []
    }

    private static var imageDirectory: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("WatchFaces")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func deleteImage(_ file: String?) {
        guard let file else { return }
        try? FileManager.default.removeItem(at: Self.imageDirectory.appendingPathComponent(file))
    }

    func setImage(_ image: UIImage?, for face: WatchFaceEntry) {
        guard let position = customFaces.firstIndex(where: { $0.id == face.id }) else { return }

        deleteImage(customFaces[position].imageFile)
        customFaces[position].imageFile = nil
        if let data = image?.jpegData(compressionQuality: 0.8) {
            let file = UUID().uuidString + ".jpg"
            if (try? data.write(to: Self.imageDirectory.appendingPathComponent(file))) != nil {
                customFaces[position].imageFile = file
            }
        }
    }

    // Previews redraw every second, so cache the photos
    private var imageCache = [String: UIImage]()

    func image(for face: WatchFaceEntry) -> UIImage? {
        guard let file = face.imageFile else { return nil }
        if let cached = imageCache[file] {
            return cached
        }
        let image = UIImage(contentsOfFile: Self.imageDirectory.appendingPathComponent(file).path)
        imageCache[file] = image
        return image
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(try? JSONEncoder().encode(customFaces), forKey: "customWatchFaces")
        defaults.set(order, forKey: "watchFaceOrder")
        defaults.set(Array(hiddenIds), forKey: "hiddenWatchFaceIds")
        defaults.set(Array(shownIds), forKey: "shownWatchFaceIds")
    }
}
