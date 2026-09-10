//
//  DownloadManager.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/26/21.
//  
//
    

import Foundation
import NordicDFU
import SwiftUI

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

class DownloadManager: NSObject, ObservableObject {
    static var shared = DownloadManager()
    
    lazy var dfuUpdater = DFUUpdater.shared
    
    @Published var tasks: [URLSessionTask] = []
    @Published var autoUpgrade: Result!
    @Published var lastCheck: Date!
    
    @AppStorage("releases") var releases: [Result] = []
    @AppStorage("lastTimeReleasesFetched") var lastTimeReleasesFetched: Double = 0
    
    @Published var updateVersion: String = "0.0.0"
    @Published var updateBody: String = ""
    
    @Published var updateSize: Int = 0
    
    @Published var browserDownloadUrl: URL = URL(fileURLWithPath: "")
    @Published var browserDownloadResourcesUrl: URL = URL(fileURLWithPath: "")
    
    @Published var hasCheckedForUpdatesBefore: Bool = false
    @Published var updateStarted: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var loadingAppReleases: Bool = false
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
    
    struct Result: Codable {
        let tag_name: String
        let body: String
        let assets: [Asset]
        var zipAsset: Asset!
        
        private enum CodingKeys: String, CodingKey {
            case tag_name, body, assets
        }
    }
    
    struct WorkflowRunResponse: Codable {
        let total_count: Int
        let workflow_runs: [WorkflowRun]
    }
    
    struct WorkflowRun: Codable {
        let id: Int
        let name: String
        let head_branch: String
        let head_sha: String
        let display_title: String
        let run_number: Int
        let event: String
        let status: String
        let conclusion: String
        let workflow_id: Int
        let url: String
        let created_at: String
        let updated_at: String
        let run_attempt: Int
        let run_started_at: String
        let artifacts_url: String
        let workflow_url: String
    }
    
    struct ArtifactsResponse: Codable {
        let total_count: Int
        let artifacts: [Artifact]
    }
    
    struct Artifact: Codable {
        let id: Int
        let nodeID: String
        let name: String
        let sizeInBytes: Int
        let url: String
        let archiveDownloadURL: String
        let expired: Bool
        let createdAt: String
        let updatedAt: String
        let expiresAt: String
        let workflowRun: ArtifactWorkflowRun
        
        enum CodingKeys: String, CodingKey {
            case id
            case nodeID = "node_id"
            case name
            case sizeInBytes = "size_in_bytes"
            case url
            case archiveDownloadURL = "archive_download_url"
            case expired
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case expiresAt = "expires_at"
            case workflowRun = "workflow_run"
        }
    }
    
    struct ArtifactWorkflowRun: Codable {
        let id: Int
        let repositoryID: Int
        let headRepositoryID: Int
        let headBranch: String
        let headSHA: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case repositoryID = "repository_id"
            case headRepositoryID = "head_repository_id"
            case headBranch = "head_branch"
            case headSHA = "head_sha"
        }
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
        guard !(dfuUpdater.local && dfuUpdater.firmwareSelected) else { return } // The user picked a local file; don't override it
        
        let installed = DeviceManager.shared.firmware
        let latest = releases
            .filter { $0.tag_name.first != "v" }
            .max { $0.tag_name.compare($1.tag_name, options: .numeric) == .orderedAscending }
        
        guard let latest, installed.compare(latest.tag_name, options: .numeric) == .orderedAscending else {
            updateAvailable = false
            return
        }
        
        let asset = chooseAsset(response: latest)
        
        dfuUpdater.firmwareFilename = asset.name
        dfuUpdater.firmwareSelected = true
        dfuUpdater.local = false
        
        updateAvailable = true
        updateVersion = latest.tag_name
        updateBody = latest.body
        updateSize = asset.size
        autoUpgrade = latest
        browserDownloadUrl = asset.browser_download_url
        browserDownloadResourcesUrl = chooseResources(response: latest).browser_download_url
    }
    
    func getUpdates() {
        let now = Date()
        
        // Make sure we haven't checked for updates in the past 30 minutes
        if (now.timeIntervalSince1970 - lastTimeReleasesFetched) > (30 * 20) {
            log("Fetching releases", type: .info, caller: "DownloadManager")
            
            getInfiniTimeReleases()
            getInfiniLinkReleases()
            
            lastTimeReleasesFetched = now.timeIntervalSince1970
        }
    }
    
    func getInfiniLinkReleases() {
        self.loadingAppReleases = true
        
        URLSession.shared.dataTask(with: URLRequest(url: URL(string: "https://api.github.com/repos/InfiniTimeOrg/InfiniLink/releases")!)) { data, response, error in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode([Result].self, from: data)
                    
                    DispatchQueue.main.async { [self] in
                        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                            log("Could not retrieve app version", caller: "DownloadManager")
                            return
                        }
                        
                        for release in result {
                            if let update = newVersion(release.tag_name.replacingOccurrences(of: "v", with: ""), than: appVersion), Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? true : !update.isBeta {
                                appUpdate = update
                                return
                            }
                        }
                    }
                } catch {
                    log("Error decoding InfiniLink releases JSON: \(error.localizedDescription)", caller: "DownloadManager")
                }
                
                DispatchQueue.main.async {
                    self.loadingAppReleases = false
                }
            }
        }.resume()
    }
    
    func getInfiniTimeReleases() {
        self.loadingReleases = true
        
        URLSession.shared.dataTask(with: URLRequest(url: URL(string: "https://api.github.com/repos/InfiniTimeOrg/InfiniTime/releases")!)) { data, response, error in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode([Result].self, from: data)
                    
                    DispatchQueue.main.async {
                        self.releases = result.filter { $0.tag_name.first != "v" }
                        self.evaluateFirmwareUpdate()
                    }
                } catch {
                    log("Error decoding InfiniTime releases JSON: \(error.localizedDescription)", caller: "DownloadManager")
                }
                
                DispatchQueue.main.async {
                    self.loadingReleases = false
                }
            }
        }.resume()
    }
    
    func chooseAsset(response: Result) -> Asset {
        for x in response.assets {
            if x.name.suffix(4) == ".zip" && x.name.contains("pinetime-mcuboot-app-dfu") {
                return x
            }
        }
        return Asset(id: Int(), name: String(), browser_download_url: URL(fileURLWithPath: ""), size: 0)
    }
    
    func chooseResources(response: Result) -> Asset {
        for x in response.assets {
            if x.name.suffix(4) == ".zip" && x.name.contains("infinitime-resources") {
                return x
            }
        }
        return Asset(id: Int(), name: String(), browser_download_url: URL(fileURLWithPath: ""), size: 0)
    }
    
    func startSoftwareUpdate(externalResourcesOnly: Bool) {
        dfuUpdater.beginDownloading()
        
        if externalResourcesOnly {
            downloadQueue = [.resources]
        } else if dfuUpdater.updateResourcesWithFirmware {
            downloadQueue = [.firmware, .resources]
        } else {
            downloadQueue = [.firmware]
        }
        
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
            if externalResources {
                dfuUpdater.installResourcesOnly()
            } else {
                dfuUpdater.install()
            }
            return
        }
        
        downloadQueue.removeFirst()
        activeDownload = item
        
        let url = item == .resources ? browserDownloadResourcesUrl : browserDownloadUrl
        downloadTask = urlSession.downloadTask(with: URLRequest(url: url))
        downloadTask?.resume()
    }
    
    func clearUpdate() {
        updateVersion = "0.0.0"
        updateBody = ""
        updateSize = 0
        browserDownloadUrl = URL(fileURLWithPath: "")
        browserDownloadResourcesUrl = URL(fileURLWithPath: "")
        updateStarted = false
        updateAvailable = false
        externalResources = false
        cancelActiveDownload()
    }
    
    private func updateTasks() {
        urlSession.getAllTasks { tasks in
            DispatchQueue.main.async {
                self.tasks = tasks
            }
        }
    }
}

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten _: Int64, totalBytesExpectedToWrite _: Int64) {
    }
    
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
