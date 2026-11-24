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
    
    var isImport = false
    
    @State private var resourceError: String?
    @State private var showCancelConfirmation = false
    @State private var showOtherVersions = false
    
    var body: some View {
        GeometryReader { geo in
            List {
                if !isImport && !bleManager.isReconnectingAfterUpdate && !downloadManager.updateStarted {
                    Section {
                        Button {
                            showOtherVersions = true
                        } label: {
                            HStack {
                                Text("Other Versions")
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
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
                } else if downloadManager.externalResources || downloadManager.updateAvailable {
                    newUpdate
                } else {
                    noUpdate
                        .frame(height: geo.size.height / 1.5)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Software Update")
            .navigationDestination(isPresented: $showOtherVersions) {
                OtherUpdateVersions {
                    showOtherVersions = false
                }
            }
            .toolbar {
                if !isImport {
                    NavigationLink {
                        SoftwareUpdateSettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        }
        .onAppear {
            if downloadManager.releases.isEmpty {
                downloadManager.getUpdates()
            }
        }
        .onChange(of: dfuUpdater.stage) { stage in // Resource uploads stay on this screen, so show the error here instead of leaving it on the banner
            if case .failed(let message) = stage, downloadManager.externalResources {
                resourceError = message
                dfuUpdater.dismissError()
            }
        }
        .alert("Update Failed", isPresented: Binding(
            get: { resourceError != nil },
            set: { if !$0 { resourceError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(resourceError ?? "")
        }
        .alert("Are you sure you want to stop this update?", isPresented: $showCancelConfirmation) {
            Button("Stop Update", role: .destructive) {
                dfuUpdater.cancel()
            }
            Button("Cancel", role: .cancel) { }
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
                                Group {
                                    if let file = dfuUpdater.resourceFile, downloadManager.updateStarted {
                                        Text("Uploading file \(file.index) of \(file.count)...")
                                    } else if downloadManager.updateStarted {
                                        Text("\(dfuUpdater.statusText)...")
                                    } else if downloadManager.externalResources {
                                        Text(dfuUpdater.resourceFilename)
                                    } else {
                                        Text("\(Int(ceil(Double(downloadManager.updateSize) / 1000))) KB")
                                    }
                                }
                                .lineLimit(1)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                if downloadManager.updateStarted {
                                    ProgressView(value: dfuUpdater.percentComplete, total: 100)
                                }
                            }
                        }
                    }
                    ReleaseNotesView(markdown: downloadManager.updateBody)
                }
            }
            if !downloadManager.updateStarted {
                let updateDisabled = !bleManager.isDeviceInRecoveryMode &&
                                     (!bleManager.hasLoadedCharacteristics || (bleManager.batteryLevel <= 10 && bleManager.chargeState != .charging))
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
            } else {
                Section {
                    Button("Stop Update", role: .destructive) {
                        showCancelConfirmation = true
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

struct ReleaseNotesView: View {
    let markdown: String
    
    @State private var contentHeight: CGFloat = 0
    
    private let maxHeight: CGFloat = 400
    
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
        // Scroll long release notes instead of stretching the section
        ScrollView {
            notes
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .frame(height: min(contentHeight, maxHeight))
        .scrollDisabled(contentHeight <= maxHeight)
    }
    
    var notes: some View {
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
    @State private var showInvalidFileAlert = false
    
    let onSelectDevelopmentBuild: () -> Void
    
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
                        if downloadManager.selectLocalFile(try result.get()) {
                            dismiss()
                        } else {
                            showInvalidFileAlert = true
                        }
                    } catch {
                        log("Error getting local file: \(error.localizedDescription)", caller: "OtherUpdateVersions")
                    }
                }
            } footer: {
                if !bleManager.isDeviceInRecoveryMode {
                    Text("Choose a firmware update or external resources. External resources are fonts and images that are required for some apps and watch faces.")
                }
            }
            Section {
                NavigationLink("Development Builds (beta)") {
                    GitHubBuildsView(onSelect: onSelectDevelopmentBuild)
                }
            } footer: {
                Text("Install builds of InfiniTime made by GitHub Actions. Requires you to sign in to GitHub.")
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
        .alert("Couldn't Open File", isPresented: $showInvalidFileAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(bleManager.isDeviceInRecoveryMode ? "This file isn't a firmware update." : "This file isn't a firmware update or external resources.")
        }
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
