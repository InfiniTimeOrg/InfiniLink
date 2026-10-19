//
//  DownloadManager.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/26/21.
//  
//
    

import Foundation
import SwiftUI

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    lazy var dfuUpdater = DFUUpdater.shared
    
    @Published var releases: [Release] = DownloadManager.cachedReleases(repo: "InfiniTime")?.filter { $0.tag_name.first != "v" } ?? []
    @AppStorage("lastTimeReleasesFetched") var lastTimeReleasesFetched: Double = 0
    
    @Published var updateVersion: String = "0.0.0"
    @Published var updateBody: String = ""
    
    @Published var updateSize: Int = 0
    
    @Published var browserDownloadUrl: URL?
    @Published var browserDownloadResourcesUrl: URL?
    
    @Published var hasCheckedForUpdatesBefore: Bool = false
    @Published var updateStarted: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var loadingReleases: Bool = false
    @Published var externalResources: Bool = false
    @Published var appUpdate: AppVersion?
    
    private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var downloadTask: URLSessionDownloadTask?
    
    private enum DownloadItem { case firmware, resources }
    private var downloadQueue: [DownloadItem] = []
    private var activeDownload: DownloadItem?
    
    struct Asset: Codable {
        let id: Int
        let name: String
        let browser_download_url: URL
        let size: Int
    }
    
    struct AppVersion {
        var id = UUID()
        let version: String
        let isBeta: Bool
    }
    
    struct Release: Codable {
        let tag_name: String
        let body: String?
        let assets: [Asset]
    }
    
    func newVersion(_ releaseVersion: String, than currentVersion: String) -> AppVersion? {
        let isBeta = releaseVersion.contains("beta")
        let releaseComponents = releaseVersion.versionComponents()
        let currentComponents = currentVersion.versionComponents()
        
        let newVersion = AppVersion(version: releaseVersion, isBeta: isBeta)
        
        for (release, current) in zip(releaseComponents, currentComponents) {
            if release > current {
                return newVersion
            }
            if release < current { return nil }
        }
        
        return releaseComponents.count > currentComponents.count ? newVersion : nil
    }
    
    func checkForFirmwareUpdate() {
        getUpdates()
        evaluateFirmwareUpdate()
    }
    
    // Re-run whenever the release list or the connected firmware changes, not just at launch
    func evaluateFirmwareUpdate() {
        guard !(dfuUpdater.local && dfuUpdater.firmwareSelected), !updateStarted else { return } // The user picked a local file; don't override it
        
        let installed = DeviceManager.shared.firmware
        let latest = releases
            .filter { $0.tag_name.first != "v" }
            .max { $0.tag_name.compare($1.tag_name, options: .numeric) == .orderedAscending }
        
        guard let latest, installed.compare(latest.tag_name, options: .numeric) == .orderedAscending else {
            updateAvailable = false
            return
        }
        
        selectRelease(latest)
    }
    
    // Each of these replaces whatever update was selected before
    func selectRelease(_ release: Release) {
        let asset = chooseAsset(response: release)
        
        dfuUpdater.local = false
        dfuUpdater.firmwareSelected = true
        dfuUpdater.firmwareFilename = asset?.name ?? ""
        dfuUpdater.firmwareURL = nil
        dfuUpdater.resourceURL = nil
        
        updateVersion = release.tag_name
        updateBody = release.body ?? ""
        updateSize = asset?.size ?? 0
        browserDownloadUrl = asset?.browser_download_url
        browserDownloadResourcesUrl = chooseResources(response: release)?.browser_download_url
        externalResources = false
        updateAvailable = true
    }
    
    func selectLocalFirmware(_ url: URL, notes: String = NSLocalizedString("This is a local firmware file and cannot be verified. Proceed at your own risk.", comment: "")) {
        dfuUpdater.local = true
        dfuUpdater.firmwareSelected = true
        dfuUpdater.firmwareFilename = url.lastPathComponent
        dfuUpdater.firmwareURL = url
        dfuUpdater.resourceURL = nil
        
        updateBody = notes
        updateSize = dfuUpdater.fileSize(from: url)
        externalResources = false
        updateAvailable = true
    }
    
    func selectLocalResources(_ url: URL) {
        dfuUpdater.local = true
        dfuUpdater.firmwareSelected = true
        dfuUpdater.firmwareURL = nil
        dfuUpdater.resourceFilename = url.lastPathComponent
        dfuUpdater.resourceURL = url
        
        updateBody = NSLocalizedString("External resources are fonts and images not included in the firmware required to use some apps and watch faces.", comment: "")
        updateSize = dfuUpdater.fileSize(from: url)
        externalResources = true
    }
    
    func getUpdates() {
        let now = Date().timeIntervalSince1970
        
        // Make sure we haven't checked for updates in the past 10 minutes
        guard now - lastTimeReleasesFetched > 60 * 10 else { return }
        
        log("Fetching releases", type: .info, caller: "DownloadManager")
        getInfiniTimeReleases()
        getInfiniLinkReleases()
    }
    
    func getInfiniLinkReleases() {
        fetchReleases(repo: "InfiniLink") { [self] result in
            guard let result else { return }
            guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                log("Could not retrieve app version", caller: "DownloadManager")
                return
            }
            let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
            
            appUpdate = result.lazy
                .compactMap { self.newVersion($0.tag_name.replacingOccurrences(of: "v", with: ""), than: appVersion) }
                .first { isTestFlight || !$0.isBeta }
        }
    }
    
    func getInfiniTimeReleases() {
        loadingReleases = true
        
        fetchReleases(repo: "InfiniTime") { [self] result in
            loadingReleases = false
            guard let result else { return }
            
            lastTimeReleasesFetched = Date().timeIntervalSince1970
            releases = result.filter { $0.tag_name.first != "v" }
            evaluateFirmwareUpdate()
        }
    }
    
    // Send the last ETag so unchanged lists come back as 304s, which don't count against GitHub's rate limit
    private func fetchReleases(repo: String, completion: @escaping ([Release]?) -> Void) {
        let cacheURL = Self.cacheURL(repo: repo)
        let etagKey = "\(repo)ReleasesETag"
        
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/InfiniTimeOrg/\(repo)/releases")!, cachePolicy: .reloadIgnoringLocalCacheData)
        if let etag = UserDefaults.standard.string(forKey: etagKey), FileManager.default.fileExists(atPath: cacheURL.path) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let http = response as? HTTPURLResponse
            var body: Data?
            
            switch http?.statusCode {
            case 200:
                body = data
                try? data?.write(to: cacheURL)
                UserDefaults.standard.set(http?.value(forHTTPHeaderField: "ETag"), forKey: etagKey)
            case 304:
                body = try? Data(contentsOf: cacheURL)
            default:
                log("Error fetching \(repo) releases: \(error?.localizedDescription ?? "status \(http?.statusCode ?? 0)")", caller: "DownloadManager")
            }
            
            var releases: [Release]?
            if let body {
                do {
                    releases = try JSONDecoder().decode([Release].self, from: body)
                } catch {
                    log("Error decoding \(repo) releases JSON: \(error.localizedDescription)", caller: "DownloadManager")
                }
            }
            
            DispatchQueue.main.async {
                completion(releases)
            }
        }.resume()
    }
    
    private static func cacheURL(repo: String) -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("\(repo)-releases.json")
    }
    
    private static func cachedReleases(repo: String) -> [Release]? {
        guard let data = try? Data(contentsOf: cacheURL(repo: repo)) else { return nil }
        return try? JSONDecoder().decode([Release].self, from: data)
    }
    
    func chooseAsset(response: Release) -> Asset? {
        response.assets.first { $0.name.hasSuffix(".zip") && $0.name.contains("pinetime-mcuboot-app-dfu") }
    }
    
    func chooseResources(response: Release) -> Asset? {
        response.assets.first { $0.name.hasSuffix(".zip") && $0.name.contains("infinitime-resources") }
    }
    
    func startSoftwareUpdate() {
        dfuUpdater.beginDownloading()
        downloadQueue = dfuUpdater.updateResourcesWithFirmware && browserDownloadResourcesUrl != nil ? [.firmware, .resources] : [.firmware]
        downloadNext()
    }
    
    func cancelActiveDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadQueue = []
        activeDownload = nil
    }
    
    private func downloadNext() {
        guard let item = downloadQueue.first else {
            activeDownload = nil
            dfuUpdater.install()
            return
        }
        
        downloadQueue.removeFirst()
        activeDownload = item
        
        guard let url = item == .resources ? browserDownloadResourcesUrl : browserDownloadUrl else {
            cancelActiveDownload()
            dfuUpdater.reportDownloadFailure()
            return
        }
        downloadTask = urlSession.downloadTask(with: URLRequest(url: url))
        downloadTask?.resume()
    }
    
    func clearUpdate() {
        updateVersion = "0.0.0"
        updateBody = ""
        updateSize = 0
        browserDownloadUrl = nil
        browserDownloadResourcesUrl = nil
        updateStarted = false
        updateAvailable = false
        externalResources = false
        cancelActiveDownload()
    }
}

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let item = activeDownload else { return }
        let filename = item == .resources ? "resources.zip" : "firmware.zip"
        
        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let savedURL = documentsURL.appendingPathComponent(filename)
            
            if FileManager.default.fileExists(atPath: savedURL.path) {
                try? FileManager.default.removeItem(at: savedURL)
            }
            try FileManager.default.moveItem(at: location, to: savedURL)
            
            DispatchQueue.main.async {
                switch item {
                case .firmware: self.dfuUpdater.firmwareURL = savedURL
                case .resources: self.dfuUpdater.resourceURL = savedURL
                }
                self.downloadNext()
            }
        } catch {
            log("Error saving downloaded \(filename): \(error.localizedDescription)", caller: "DownloadManager")
            DispatchQueue.main.async {
                self.cancelActiveDownload()
                self.dfuUpdater.reportDownloadFailure()
            }
        }
    }
    
    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        log(error.localizedDescription, caller: "DownloadManager")
        
        DispatchQueue.main.async {
            guard self.activeDownload != nil else { return }
            self.cancelActiveDownload()
            self.dfuUpdater.reportDownloadFailure()
        }
    }
}
