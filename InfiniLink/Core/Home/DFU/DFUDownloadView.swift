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
                        Button {
                            externalResources = true
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
                            } catch{
                                DebugLogManager.shared.debug(error: error.localizedDescription, log: .dfu, date: Date())
                            }
                        }
                        ListHeader(title: "Releases", showList: $showReleases)
                        if showReleases {
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
                            }
                        }
                        ListHeader(title: NSLocalizedString("pull_requests", comment: ""), showList: $showPullRequests)
                        if showPullRequests {
                            ForEach(downloadManager.pulls, id: \.id) { pr in
                                NavigationLink {
                                    DFUPullRequestDetailView(externalResources: $externalResources, pr: pr)
                                } label: {
                                    HStack {
                                        Text(pr.title)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Material.regular)
                                    .foregroundColor(.primary)
                                    .cornerRadius(20)
                                }
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

struct ListHeader: View {
    let title: String
    
    @Binding var showList: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .padding(12)
                .foregroundColor(.primary)
                .background(Material.regular)
                .clipShape(Capsule())
                .textCase(.uppercase)
                .font(.footnote.weight(.semibold))
            Spacer()
            Button {
                withAnimation(.bouncy) {
                    showList.toggle()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .rotationEffect(Angle(degrees: showList ? 0 : 90))
                    .padding(12)
                    .foregroundColor(.primary)
                    .background(Material.regular)
                    .clipShape(Circle())
                    .font(.body.weight(.semibold))
            }
        }
        .padding(.bottom, 4)
        .padding(.top)
    }
}

#Preview {
    NavigationView {
        DownloadView(openFile: .constant(false), externalResources: .constant(false))
    }
}
