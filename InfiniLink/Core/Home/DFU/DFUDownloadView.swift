//
//  DFUDownloadView.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/24/21.
//
//


import Foundation
import SwiftUI

struct DownloadView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    @ObservedObject var networkManager = NetworkManager.shared
    
    @Environment(\.presentationMode) var presentation
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var openFile: Bool
    @Binding var externalResources: Bool
    
    @State var showResourcePicker = false
    
    @State var showReleases = true
    @State var showPullRequests = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Text(NSLocalizedString("downloads", comment: "Downloads"))
                        .foregroundColor(.primary)
                        .font(.title.weight(.bold))
                    Spacer()
                    DFURefreshButton()
                    Button {
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .padding(14)
                            .font(.body.weight(.semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                Divider()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack {
                            Button {
                                openFile = true
                            } label: {
                                Text(NSLocalizedString("use_local_file", comment: ""))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .fileImporter(isPresented: $openFile, allowedContentTypes: [.zip]) { (res) in
                                do {
                                    let fileUrl = try res.get()
                                    
                                    guard fileUrl.startAccessingSecurityScopedResource() else { return }
                                    
                                    dfuUpdater.local = true
                                    downloadManager.updateAvailable = true
                                    downloadManager.updateBody = ""
                                    downloadManager.updateSize = 0
                                    
                                    dfuUpdater.firmwareSelected = true
                                    dfuUpdater.firmwareFilename = fileUrl.lastPathComponent
                                    dfuUpdater.firmwareURL = fileUrl.absoluteURL
                                    
                                    externalResources = false
                                    
                                    fileUrl.stopAccessingSecurityScopedResource()
                                    presentation.wrappedValue.dismiss()
                                } catch {
                                    DebugLogManager.shared.debug(error: error.localizedDescription, log: .dfu, date: Date())
                                }
                            }
                            if BLEManager.shared.blefsTransfer != nil {
                                Button {
                                    showResourcePicker = true
                                } label: {
                                    Text(NSLocalizedString("update_external_resources", comment: ""))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                                .fileImporter(isPresented: $showResourcePicker, allowedContentTypes: [.zip]) { (res) in
                                    do {
                                        let fileUrl = try res.get()
                                        
                                        guard fileUrl.startAccessingSecurityScopedResource() else { return }
                                        
                                        dfuUpdater.firmwareSelected = true
                                        dfuUpdater.resourceFilename = fileUrl.lastPathComponent
                                        dfuUpdater.firmwareURL = fileUrl.absoluteURL
                                        
                                        externalResources = true
                                        
                                        fileUrl.stopAccessingSecurityScopedResource()
                                        presentation.wrappedValue.dismiss()
                                    } catch {
                                        DebugLogManager.shared.debug(error: error.localizedDescription, log: .dfu, date: Date())
                                    }
                                }
                            }
                        }
                        VStack {
                            ForEach(downloadManager.results, id: \.tag_name) { i in
                                Button {
                                    let asset = downloadManager.chooseAsset(response: i)
                                    dfuUpdater.firmwareFilename = asset.name
                                    dfuUpdater.firmwareSelected = true
                                    dfuUpdater.local = false
                                    downloadManager.updateAvailable = true
                                    downloadManager.updateVersion = i.tag_name
                                    downloadManager.updateBody = i.body
                                    downloadManager.updateSize = asset.size
                                    downloadManager.browser_download_url = asset.browser_download_url
                                    
                                    externalResources = false
                                    
                                    presentation.wrappedValue.dismiss()
                                } label: {
                                    Text(i.tag_name)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Material.regular)
                                        .foregroundColor(.primary)
                                        .clipShape(Capsule())
                                }
                                .disabled(!networkManager.getNetworkState())
                                .opacity(!networkManager.getNetworkState() ? 0.5 : 1.0)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    NavigationView {
        DownloadView(openFile: .constant(false), externalResources: .constant(false))
    }
}
