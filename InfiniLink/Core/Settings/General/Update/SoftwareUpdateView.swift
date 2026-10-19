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
    @ObservedObject var bleManager = BLEManager.shared
    
    var body: some View {
        GeometryReader { geo in
            List {
                if !bleManager.isReconnectingAfterUpdate {
                    Section {
                        NavigationLink {
                            OtherUpdateVersions()
                        } label: {
                            Text("Other Versions")
                        }
                    }
                }
                if bleManager.isReconnectingAfterUpdate {
                    Section {
                        HStack(spacing: 10) {
                            ListRowIconView(icon: "gear.badge", color: .gray)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(bleManager.isInstallingUpdate ? "Installing..." : "Updating...")
                                    .fontWeight(.bold)
                                Text("\(deviceManager.name) is installing the update.")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            ProgressView()
                        }
                    }
                } else if downloadManager.externalResources {
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
                downloadManager.getUpdates()
            }
        }
    }
    
    var newUpdate: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(.infiniTime)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 3) {
                                Group {
                                    if !dfuUpdater.local {
                                        Text("InfiniTime " + downloadManager.updateVersion)
                                    } else {
                                        Text(downloadManager.externalResources ? "External Resources" : dfuUpdater.firmwareFilename)
                                    }
                                }
                                .font(.headline)
                                Text({
                                    if downloadManager.externalResources {
                                        return dfuUpdater.resourceFilename
                                    } else {
                                        return "\(Int(ceil(Double(downloadManager.updateSize) / 1000))) KB"
                                    }
                                }())
                                .lineLimit(1)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    ScrollView {
                        ReleaseNotesView(markdown: downloadManager.updateBody)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: dfuUpdater.local ? 50 : 300)
                }
            }
            let updateDisabled = !bleManager.isDeviceInRecoveryMode &&
                                 (!bleManager.hasLoadedCharacteristics || bleManager.batteryLevel <= 10)
            Section {
                if !dfuUpdater.local && !bleManager.isDeviceInRecoveryMode {
                    Toggle("Update External Resources", isOn: $dfuUpdater.updateResourcesWithFirmware)
                }
                Button {
                    if dfuUpdater.local {
                        dfuUpdater.install()
                    } else {
                        downloadManager.startSoftwareUpdate()
                    }
                } label: {
                    Text("Update Now")
                }
            } footer: {
                if updateDisabled {
                    Text(!bleManager.hasLoadedCharacteristics ? "\(deviceManager.name) needs to be connected to update its software." : "\(deviceManager.name)'s battery must be charged to at least \(0.1, format: .percent) to update its software.")
                }
            }
            .disabled(updateDisabled)
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

struct ReleaseNotesView: View {
    let markdown: String
    
    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    private func imageURL(_ line: String) -> URL? {
        if let match = line.wholeMatch(of: #/!\[[^\]]*\]\((\S+?)(?:\s+"[^"]*")?\)/#) {
            return URL(string: String(match.1))
        }
        if let match = line.wholeMatch(of: #/<img\s[^>]*src="([^"]+)"[^>]*>/#) {
            return URL(string: String(match.1))
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(markdown.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("#") {
                    Text(inline(trimmed.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)))
                        .font(.title3.bold())
                } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•")
                        Text(inline(String(trimmed.dropFirst(2))))
                    }
                } else if let url = imageURL(trimmed) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                } else if !trimmed.isEmpty {
                    Text(inline(trimmed))
                }
            }
        }
    }
}

struct OtherUpdateVersions: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var showLocalFileSheet = false
    @State private var showResourcePickerSheet = false
    
    @ObservedObject var dfuUpdater = DFUUpdater.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    var body: some View {
        List {
            Section {
                Button {
                    showLocalFileSheet = true
                } label: {
                    Text("Use Local File")
                }
                .fileImporter(isPresented: $showLocalFileSheet, allowedContentTypes: [.zip]) { result in
                    do {
                        downloadManager.selectLocalFirmware(try result.get())
                        dismiss()
                    } catch {
                        log("Error getting firmware file: \(error.localizedDescription)", caller: "OtherUpdateVersions")
                    }
                }
                if !bleManager.isDeviceInRecoveryMode {
                    Button {
                        showResourcePickerSheet = true
                    } label: {
                        Text("Update External Resources")
                    }
                    .fileImporter(isPresented: $showResourcePickerSheet, allowedContentTypes: [.zip]) { result in
                        do {
                            downloadManager.selectLocalResources(try result.get())
                            dismiss()
                        } catch {
                            log("Error getting resource file: \(error.localizedDescription)", caller: "OtherUpdateVersions")
                        }
                    }
                }
            } footer: {
                if !bleManager.isDeviceInRecoveryMode {
                    Text("External resources are fonts and images that are required for some apps and watch faces.")
                }
            }
            Section("Releases") {
                if downloadManager.releases.isEmpty && !downloadManager.loadingReleases {
                    Text("There aren't any available releases.")
                } else {
                    ForEach(downloadManager.releases, id: \.tag_name) { release in
                        Button {
                            downloadManager.selectRelease(release)
                            dismiss()
                        } label: {
                            Text(release.tag_name)
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Other Versions")
        .toolbar {
            if downloadManager.loadingReleases {
                ProgressView()
            } else if !downloadManager.hasCheckedForUpdatesBefore {
                Button {
                    downloadManager.getInfiniTimeReleases()
                    downloadManager.hasCheckedForUpdatesBefore = true
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
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
