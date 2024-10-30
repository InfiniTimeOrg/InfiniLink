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
    
    let dfuUpdater = DFUUpdater.shared
    
    @Published var tasks: [URLSessionTask] = []
    @Published var downloading = false
    @Published var autoUpgrade: Result!
    @Published var lastCheck: Date!
    
    @AppStorage("releases") var releases: [Result] = []
    @AppStorage("buildArtifacts") var buildArtifacts: [Artifact] = []
    
    @AppStorage("githubAuthToken") var githubAuthToken: String?
    
    @Published var updateVersion: String = "0.0.0"
    @Published var updateBody: String = ""
    
    @Published var updateSize: Int = 0
    
    @Published var browser_download_url: URL = URL(fileURLWithPath: "")
    @Published var browser_download_resources_url: URL = URL(fileURLWithPath: "")
    
    @Published var updateStarted: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var startTransfer: Bool = false
    @Published var loadingReleases: Bool = false
    @Published var loadingArtifacts: Bool = false
    @Published var externalResources: Bool = false
    
    private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var downloadTask: URLSessionDownloadTask!
    private var isDownloadingResources = false
    private var hasDownloadedResources = false
    
    struct Asset: Codable {
        let id: Int
        let name: String
        let browser_download_url: URL
        let size: Int
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
    
    struct ArtifactResponse: Codable {
        let total_count: Int
        let artifacts: [Artifact]
    }
    
    struct Artifact: Codable {
        let id: Int
        let name: String
        let size_in_bytes: String
        let url: String
        let archive_download_url: String
        let expired: Bool
        let created_at: String
        let updated_at: String
        let expires_at: String
    }
    
    func setupTest(forFile: String) {
        DFUUpdater.shared.firmwareFilename = forFile
        DFUUpdater.shared.firmwareSelected = true
        DFUUpdater.shared.local = false
    }
    
    func checkForUpdates(currentVersion: String) -> Bool {
        for i in releases {
            if i.tag_name.first != "v" {
                let comparison = currentVersion.compare(i.tag_name, options: .numeric)
                if comparison == .orderedAscending && comparison != .orderedSame {
                    dfuUpdater.firmwareFilename = chooseAsset(response: i).name
                    dfuUpdater.firmwareSelected = true
                    dfuUpdater.local = false
                    
                    updateVersion = i.tag_name
                    updateBody = i.body
                    updateSize = chooseAsset(response: i).size
                    autoUpgrade = i
                    browser_download_url = chooseAsset(response: i).browser_download_url
                    browser_download_resources_url = chooseResources(response: i).browser_download_url
                    
                    return true
                }
            }
        }
        return false
    }
    
    func getUpdateResources() {
        getReleases()
        getWorkflowRuns()
    }
    
    func getReleases() {
        self.loadingReleases = true
        self.releases = []
        
        guard let url = URL(string: "https://api.github.com/repos/InfiniTimeOrg/InfiniTime/releases") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode([Result].self, from: data)
                    
                    DispatchQueue.main.async {
                        for release in result {
                            if release.tag_name.first != "v" {
                                self.releases.append(release)
                            }
                        }
                        
                        self.updateAvailable = self.checkForUpdates(currentVersion: DeviceManager.shared.firmware)
                        self.loadingReleases = false
                    }
                } catch {
                    print("Error decoding JSON")
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
        
        URLSession.shared.dataTask(with: url) { data, response, error in
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
                    print("Error decoding JSON")
                }
            }
        }.resume()
    }
    
    func getBuildArtifacts(for run: WorkflowRun, completion: @escaping([Artifact]) -> Void) {
        guard let url = URL(string: run.artifacts_url) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(ArtifactResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        completion(result.artifacts)
                    }
                } catch {
                    print("Error decoding JSON")
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
        
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
        self.downloadTask = downloadTask
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
        } catch let fmerror {
            print(fmerror.localizedDescription)
        }
        
        DispatchQueue.main.async {
            if !self.hasDownloadedResources && self.dfuUpdater.updateResourcesWithFirmware {
                self.isDownloadingResources = true
                self.startDownload(url: self.browser_download_resources_url)
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
            print(error.localizedDescription)
        }
    }
}
