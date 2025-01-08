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
    @Published var downloading = false
    @Published var autoUpgrade: Result!
    @Published var lastCheck: Date!
    
    @AppStorage("releases") var releases: [Result] = []
    @AppStorage("buildArtifacts") var buildArtifacts: [Artifact] = []
    
    @Published var updateVersion: String = "0.0.0"
    @Published var updateBody: String = ""
    
    @Published var updateSize: Int = 0
    
    @Published var browserDownloadUrl: URL = URL(fileURLWithPath: "")
    @Published var browserDownloadResourcesUrl: URL = URL(fileURLWithPath: "")
    
    @Published var updateStarted: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var startTransfer: Bool = false
    @Published var loadingAppReleases: Bool = false
    @Published var loadingReleases: Bool = false
    @Published var loadingArtifacts: Bool = false
    @Published var externalResources: Bool = false
    @Published var appUpdate: AppVersion?
    
    private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var downloadTask: URLSessionDownloadTask!
    private var isDownloadingResources = false
    private var hasDownloadedResources = false
    
    var githubPAT: String {
        if let key = ProcessInfo.processInfo.environment["INFINITIME_PAT"] {
            return key
        }
        return ""
    }
    
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
    
    func checkForUpdates(currentVersion: String) -> Bool {
        getUpdates()
        
        for i in releases {
            if i.tag_name.first != "v" {
                let comparison = currentVersion.compare(i.tag_name, options: .numeric)
                if comparison == .orderedAscending && comparison != .orderedSame {
                    dfuUpdater.firmwareFilename = chooseAsset(response: i).name
                    dfuUpdater.firmwareSelected = true
                    dfuUpdater.local = false
                    
                    updateAvailable = true
                    updateVersion = i.tag_name
                    updateBody = i.body
                    updateSize = chooseAsset(response: i).size
                    autoUpgrade = i
                    browserDownloadUrl = chooseAsset(response: i).browser_download_url
                    browserDownloadResourcesUrl = chooseResources(response: i).browser_download_url
                    
                    return true
                }
            }
        }
        return false
    }
    
    func getUpdates() {
        getInfiniLinkReleases()
        getInfiniTimeReleases()
        getWorkflowRuns()
    }
    
    func getInfiniLinkReleases() {
        self.loadingAppReleases = true
        self.releases = []
        
        guard let url = URL(string: "https://api.github.com/repos/InfiniTimeOrg/InfiniLink/releases") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("token \(githubPAT)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
                        
                        self.loadingAppReleases = false
                    }
                } catch {
                    log("Error decoding InfiniLink releases JSON: \(error.localizedDescription)", caller: "DownloadManager")
                }
            }
        }.resume()
    }
    
    func getInfiniTimeReleases() {
        self.loadingReleases = true
        self.releases = []
        
        guard let url = URL(string: "https://api.github.com/repos/InfiniTimeOrg/InfiniTime/releases") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("token \(githubPAT)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode([Result].self, from: data)
                    
                    DispatchQueue.main.async {
                        for release in result {
                            if release.tag_name.first != "v" {
                                self.releases.append(release)
                            }
                        }
                        
                        self.loadingReleases = false
                    }
                } catch {
                    log("Error decoding InfiniTime releases JSON: \(error.localizedDescription)", caller: "DownloadManager")
                }
            }
        }.resume()
    }
    
    func getWorkflowRuns() {
        self.loadingArtifacts = true
        self.buildArtifacts = []
        
        guard let url = URL(string: "https://api.github.com/repos/InfiniTimeOrg/InfiniTime/actions/runs") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("token \(githubPAT)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(WorkflowRunResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        let filteredRuns = result.workflow_runs.filter { $0.name == "CI" }
                        let dispatchGroup = DispatchGroup()
                        
                        for run in filteredRuns {
                            dispatchGroup.enter()
                            self.getBuildArtifacts(for: run) { artifacts in
                                self.buildArtifacts.append(contentsOf: artifacts)
                                dispatchGroup.leave()
                            }
                        }
                        
                        dispatchGroup.notify(queue: .main) {
                            self.loadingArtifacts = false
                        }
                    }
                } catch {
                    log("Error decoding workflow runs JSON: \(error.localizedDescription)", caller: "DownloadManager")
                }
            }
        }.resume()
    }
    
    func getBuildArtifacts(for run: WorkflowRun, completion: @escaping([Artifact]) -> Void) {
        guard let url = URL(string: run.artifacts_url) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("token \(githubPAT)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(ArtifactsResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        completion(result.artifacts.filter({ $0.name.contains("DFU") }))
                    }
                } catch {
                    log("Error decoding artifacts JSON: \(error.localizedDescription)", caller: "DownloadManager")
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
    
    func startDownload(url: URL) {
        self.downloading = true
        
        var request = URLRequest(url: url)
        request.setValue("token \(githubPAT)", forHTTPHeaderField: "Authorization")
        
        self.downloadTask = urlSession.downloadTask(with: request)
        self.downloadTask.resume()
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
        do {
            
            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let savedURL = documentsURL.appendingPathComponent(
                isDownloadingResources ? "resources.zip" : "firmware.zip")
            
            // check for existing file and delete it if there is anything.
            if FileManager.default.fileExists(atPath: savedURL.path) {
                try? FileManager.default.removeItem(at: savedURL)
            }
            
            // move downloaded file out of ephemeral storage and tell DFU where to look
            try FileManager.default.moveItem(at: location, to: savedURL)
            
            DispatchQueue.main.async {
                if self.isDownloadingResources && self.dfuUpdater.resourceURL == nil {
                    self.dfuUpdater.resourceURL = savedURL
                    self.hasDownloadedResources = true
                } else {
                    self.dfuUpdater.firmwareURL = savedURL
                }
            }
        } catch {
            log("Error downloading resource or firmware: \(error.localizedDescription)", caller: "DownloadManager")
        }
        
        DispatchQueue.main.async {
            if !self.hasDownloadedResources && self.dfuUpdater.updateResourcesWithFirmware {
                self.isDownloadingResources = true
                self.startDownload(url: self.browserDownloadResourcesUrl)
            } else {
                if self.startTransfer {
                    self.startTransfer = false
                    self.dfuUpdater.isUpdating = true
                    self.downloading = false
                    
                    if self.externalResources {
                        BLEFSHandler.shared.downloadTransfer {}
                    } else {
                        DFUUpdater.shared.downloadTransfer()
                    }
                }
            }
        }
    }
    
    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            log(error.localizedDescription, caller: "DownloadManager")
        }
    }
}
