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
    @ObservedObject var bleFS = BLEFSHandler.shared
    
    @State private var showLocalFileSheet = false
    @State private var showResourcePickerSheet = false
    
    @Environment(\.dismiss) var dismiss
    
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
        GeometryReader { geo in
            List {
                Section {
                    NavigationLink {
                        other
                    } label: {
                        Text("Other Versions")
                    }
                }
                Section {
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
            }
            .navigationBarBackButtonHidden(dfuUpdater.isUpdating)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Software Update")
        }
        .onAppear {
            if downloadManager.releases.isEmpty {
                downloadManager.getReleases()
            }
        }
    }
    
    var other: some View {
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
                        
                        switch result {
                        case .success(_):
                            dfuUpdater.firmwareSelected = true
                            dfuUpdater.local = true
                            
                            if downloadManager.externalResources {
                                dfuUpdater.resourceFilename = fileUrl.lastPathComponent
                            } else {
                                dfuUpdater.firmwareFilename = fileUrl.lastPathComponent
                            }
                            downloadManager.updateSize = fileSize(from: fileUrl)
                            
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                        
                        fileUrl.stopAccessingSecurityScopedResource()
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
                        dfuUpdater.firmwareURL = fileUrl.absoluteURL
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
        }
        .navigationTitle("Other Versions")
        .toolbar {
            Button {
                downloadManager.getReleases()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
    }
    
    var newUpdate: some View {
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
            if downloadManager.updateStarted {
                Group {
                    if downloadManager.externalResources {
                        ProgressView(value: Double(BLEFSHandler.shared.progress), total: Double(BLEFSHandler.shared.externalResourcesSize))
                    } else {
                        ProgressView(dfuUpdater.dfuState, value: dfuUpdater.percentComplete, total: Double(100))
                    }
                }
            }
            ScrollView {
                Text(downloadManager.updateBody)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 120)
            if BLEManager.shared.isConnectedToPinetime {
                Button {
                    if downloadManager.updateStarted {
                        dfuUpdater.stopTransfer()
                        downloadManager.updateStarted = false
                    } else {
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
                    }
                } label: {
                    Text(downloadManager.updateStarted ? "Cancel Update" : "Update Now")
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(downloadManager.updateStarted ? Color(.darkGray).opacity(0.5) : Color.blue)
                        .foregroundStyle(downloadManager.updateStarted ? .red : .white)
                        .font(.body.weight(.semibold))
                        .clipShape(Capsule())
                }
            } else {
                Text("\(DeviceInfoManager.shared.deviceName) needs to be connected to update its software.")
                    .foregroundStyle(.gray)
                    .font(.system(size: 14).weight(.semibold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(12)
            }
        }
    }
    
    var noUpdate: some View {
        Group {
            if downloadManager.loadingReleases {
                ProgressView("Checking for updates...")
            } else {
                VStack(spacing: 3) {
                    Text(DeviceInfoManager.shared.firmware)
                        .font(.title.weight(.bold))
                    Text("InfiniTime is up-to-date.")
                        .foregroundStyle(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        SoftwareUpdateView()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                DeviceInfoManager.shared.firmware = "1.14.1"
                DownloadManager.shared.updateAvailable = true
                DownloadManager.shared.updateBody = "Testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing."
                DownloadManager.shared.updateVersion = "1.14.2"
                DFUUpdater.shared.firmwareFilename = "Da Test"
            }
    }
}
