//
//  SoftwareUpdateView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct SoftwareUpdateView: View {
    @ObservedObject var dfuUpdater = DFUUpdater.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var bleFs = BLEFSHandler.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    @State private var showLocalFileSheet = false
    @State private var showResourcePickerSheet = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    NavigationLink {
                        OtherUpdateVersions()
                    } label: {
                        Text("Other Versions")
                    }
                }
                if downloadManager.externalResources {
                    newUpdate
                } else {
                    if downloadManager.updateAvailable {
                        newUpdate
                    } else {
                        noUpdate
                            .frame(height: geo.size.height / 1.5)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Software Update")
        }
        .onAppear {
            if downloadManager.releases.isEmpty {
                downloadManager.getUpdateResources()
            }
        }
    }
    
    var newUpdate: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image("InfiniTime")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 3) {
                                Group {
                                    if !dfuUpdater.local {
                                        Text("InfiniTime " + DownloadManager.shared.updateVersion)
                                    } else {
                                        Text(downloadManager.externalResources ? "External Resources" : dfuUpdater.firmwareFilename)
                                    }
                                }
                                .font(.headline)
                                Text({
                                    if downloadManager.externalResources {
                                        return dfuUpdater.resourceFilename
                                    } else {
                                        return "\(Int(ceil(Double(DownloadManager.shared.updateSize) / 1000.0))) KB"
                                    }
                                }())
                                .lineLimit(1)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    ScrollView {
                        Text(downloadManager.updateBody)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: dfuUpdater.local ? 50 : 300)
                    if !bleManager.hasLoadedCharacteristics || bleManager.batteryLevel <= 15 {
                        Text({
                            if !bleManager.hasLoadedCharacteristics {
                                return "\(deviceManager.name) needs to be connected to update its software."
                            } else {
                                return "\(deviceManager.name)'s battery must be charged to at least 15% to update its software."
                            }
                        }())
                            .foregroundStyle(.gray)
                            .font(.system(size: 14).weight(.semibold))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                    }
                }
            }
            if bleManager.hasLoadedCharacteristics {
                Section {
                    if !dfuUpdater.local {
                        Toggle("Update External Resources", isOn: $dfuUpdater.updateResourcesWithFirmware)
                    }
                    Button {
                        dfuUpdater.percentComplete = 0
                        if downloadManager.externalResources {
                            downloadManager.startTransfer = true
                            downloadManager.startDownload(url: downloadManager.browser_download_resources_url)
                            downloadManager.updateStarted = true
                        } else {
                            if dfuUpdater.local {
                                dfuUpdater.transfer()
                                downloadManager.updateStarted = true
                            } else {
                                downloadManager.startTransfer = true
                                downloadManager.startDownload(url: downloadManager.browser_download_url)
                                
                                downloadManager.updateStarted = true
                            }
                        }
                    } label: {
                        Text("Update Now")
                    }
                }
            }
        }
    }
    
    var noUpdate: some View {
        Section {
            if downloadManager.loadingReleases {
                ProgressView("Checking for updates...")
            } else {
                VStack(spacing: 3) {
                    Text(deviceManager.firmware)
                        .font(.title.weight(.bold))
                    Text("InfiniTime is up-to-date.")
                        .foregroundStyle(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct OtherUpdateVersions: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var showLocalFileSheet = false
    @State private var showResourcePickerSheet = false
    @State private var showGithubAuthView = false
    
    @ObservedObject var dfuUpdater = DFUUpdater.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    
    func fileSize(from fileUrl: URL) -> Int {
        do {
            let resource = try fileUrl.resourceValues(forKeys:[.fileSizeKey])
            return resource.fileSize!
        } catch {
            print("Error: \(error)")
        }
        
        return 0
    }
    
    var body: some View {
        List {
            Section(footer: Text("External resources are fonts and images that are required for some apps and watch faces.")) {
                Button {
                    showLocalFileSheet = true
                } label: {
                    Text("Use Local File")
                }
                .fileImporter(isPresented: $showLocalFileSheet, allowedContentTypes: [.zip]) { result in
                    do {
                        let fileUrl = try result.get()
                        
                        guard fileUrl.startAccessingSecurityScopedResource() else { return }
                        
                        dfuUpdater.local = true
                        dfuUpdater.firmwareSelected = true
                        dfuUpdater.resourceFilename = fileUrl.lastPathComponent
                        dfuUpdater.firmwareFilename = fileUrl.lastPathComponent
                        dfuUpdater.firmwareURL = fileUrl.absoluteURL
                        downloadManager.updateBody = NSLocalizedString("This is a local firmware file and cannot be verified. Proceed at your own risk.", comment: "")
                        downloadManager.updateSize = fileSize(from: fileUrl)
                        
                        downloadManager.externalResources = false
                        downloadManager.updateAvailable = true
                        
                        fileUrl.stopAccessingSecurityScopedResource()
                        
                        dismiss()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                Button {
                    showResourcePickerSheet = true
                } label: {
                    Text("Update External Resources")
                }
                .fileImporter(isPresented: $showResourcePickerSheet, allowedContentTypes: [.zip]) { result in
                    do {
                        let fileUrl = try result.get()
                        
                        guard fileUrl.startAccessingSecurityScopedResource() else { return }
                        
                        dfuUpdater.firmwareSelected = true
                        dfuUpdater.resourceFilename = fileUrl.lastPathComponent
                        dfuUpdater.resourceURL = fileUrl.absoluteURL
                        downloadManager.updateBody = NSLocalizedString("External resources are fonts and images not included in the firmware required to use some apps and watch faces.", comment: "")
                        downloadManager.updateSize = fileSize(from: fileUrl)
                        
                        downloadManager.externalResources = true
                        
                        fileUrl.stopAccessingSecurityScopedResource()
                        
                        dismiss()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            Section {
                ForEach(downloadManager.releases, id: \.tag_name) { release in
                    Button {
                        let asset = downloadManager.chooseAsset(response: release)
                        
                        dfuUpdater.firmwareFilename = asset.name
                        dfuUpdater.firmwareSelected = true
                        dfuUpdater.local = false
                        downloadManager.updateAvailable = true
                        downloadManager.updateVersion = release.tag_name
                        downloadManager.updateBody = release.body
                        downloadManager.updateSize = asset.size
                        downloadManager.browser_download_url = asset.browser_download_url
                        
                        downloadManager.externalResources = false
                        
                        dismiss()
                    } label: {
                        Text(release.tag_name)
                            .foregroundStyle(Color.primary)
                    }
                }
            } header: {
                HStack {
                    Text("Releases")
                    if downloadManager.loadingReleases {
                        ProgressView()
                    }
                }
            }
            Section {
                if downloadManager.buildArtifacts.isEmpty && !downloadManager.loadingArtifacts {
                    Text("There aren't any available cloud builds")
                } else {
                    ForEach(downloadManager.buildArtifacts, id: \.id) { artifact in
                        Button {
                            if downloadManager.githubAuthToken == nil {
                                showGithubAuthView = true
                            } else {
                                // TODO: download and install firmware
                            }
                        } label: {
                            Text(artifact.name)
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("GitHub Actions")
                    if downloadManager.loadingArtifacts {
                        ProgressView()
                    }
                }
            }
        }
        .navigationTitle("Other Versions")
        .sheet(isPresented: $showGithubAuthView) {
            GithubAuthView()
        }
        .toolbar {
            Button {
                downloadManager.getUpdateResources()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
    }
}

#Preview {
    NavigationView {
        SoftwareUpdateView()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                DownloadManager.shared.updateAvailable = true
                DownloadManager.shared.updateBody = "Testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing."
                DownloadManager.shared.updateVersion = "1.14.2"
                DFUUpdater.shared.firmwareFilename = "Da Test"
            }
    }
}
