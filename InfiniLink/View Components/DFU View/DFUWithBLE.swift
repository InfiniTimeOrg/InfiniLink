//
//  DFUWithBLE.swift
//  DFUWithBLE
//
//  Created by Alex Emry on 9/15/21.
//
//


import Foundation
import SwiftUI

extension UIScreen {
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
}

struct DFUWithBLE: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presMode
    
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    
    @AppStorage("lockNavigation") var lockNavigation = false
    
    @State var openFile = false
    @State var showOlderVersionView = false
    @State var externalResources = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(spacing: 15) {
                Button {
                    presMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                .disabled(lockNavigation)
                .opacity(lockNavigation ? 0.5 : 1.0)
                Text(NSLocalizedString("software_update", comment: "Software Update"))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                HStack(spacing: 6) {
                    DFURefreshButton()
                    Button {
                        showOlderVersionView.toggle()
                    } label: {
                        Image(systemName: "doc")
                            .imageScale(.medium)
                            .font(.body.weight(.semibold))
                            .padding(14)
                            .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .sheet(isPresented: $showOlderVersionView) {
                        DownloadView(openFile: $openFile, externalResources: $externalResources)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            VStack {
                if externalResources && !(dfuUpdater.resourceFilename.isEmpty) {
                    ScrollView {
                        ExternalResources(updateStarted: $downloadManager.updateStarted, openFile: $openFile)
                    }
                } else {
                    if downloadManager.updateAvailable && dfuUpdater.firmwareSelected {
                        ScrollView {
                            NewUpdate(updateStarted: $downloadManager.updateStarted, openFile: $openFile)
                        }
                    } else {
                        NoUpdate(externalResources: $externalResources, showFilePicker: $openFile)
                    }
                }
            }
        }
        .fileImporter(isPresented: $openFile, allowedContentTypes: [.zip]) {(res) in
            // this fileImporter allows user to select the zip from local storage. DFU updater just wants the local URL to the file, so we're opening privileged access, grabbing the url, and closing privileged access
            do {
                let fileUrl = try res.get()
                
                guard fileUrl.startAccessingSecurityScopedResource() else { return }
                
                dfuUpdater.firmwareSelected = true
                if externalResources {
                    dfuUpdater.resourceFilename = fileUrl.lastPathComponent
                } else {
                    dfuUpdater.firmwareFilename = fileUrl.lastPathComponent
                }
                dfuUpdater.firmwareURL = fileUrl.absoluteURL
                
                fileUrl.stopAccessingSecurityScopedResource()
            } catch {
                DebugLogManager.shared.debug(error: error.localizedDescription, log: .dfu, date: Date())
            }
        }
        //            VStack {
        //                if dfuUpdater.transferCompleted {
        //                    DFUComplete()
        //                        .cornerRadius(10)
        //                        .onAppear() {
        //                            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
        //                                dfuUpdater.transferCompleted = false
        //                            })
        //                            downloadManager.updateStarted = false
        //                            dfuUpdater.firmwareURL = URL(fileURLWithPath: "")
        //                            dfuUpdater.firmwareSelected = false
        //                            dfuUpdater.firmwareFilename = ""
        //                            downloadManager.updateAvailable = downloadManager.checkForUpdates(currentVersion: downloadManager.updateVersion)
        //                        }
        //                }
        //            }
        //            .transition(.opacity).animation(.easeInOut(duration: 1.0))
        .alert(isPresented: $dfuUpdater.transferCompleted) {
            Alert(title: Text(NSLocalizedString("success", comment: "Success!")), message: Text(NSLocalizedString("The transfer was successfully completed.", comment: "The transfer was successfully completed.")))
        }
        .navigationBarBackButtonHidden()
    }
}

struct NewUpdate: View {
    @Binding var updateStarted: Bool
    
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    
    @Environment(\.colorScheme) var scheme
    
    @Binding var openFile: Bool
    
    @State var showLearnMoreView = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: 10) {
                    Image("InfiniTime")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 65, height: 65)
                    VStack(alignment: .leading, spacing: 5) {
                        if dfuUpdater.local == false {
                            Text("InfiniTime \(DownloadManager.shared.updateVersion)")
                                .font(.headline)
                        } else {
                            Text(dfuUpdater.firmwareFilename)
                                .font(.headline)
                        }
                        Text("\(Int(ceil(Double(DownloadManager.shared.updateSize) / 1000.0))) KB")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        if updateStarted {
                            DFUProgressBar()
                        } else {
                            HStack {
                                Spacer()
                            }
                        }
                    }
                }
                HStack {
                    if dfuUpdater.local == false {
                        if #available(iOS 15.0, *) {
                            Text(try! AttributedString(markdown: DownloadManager.shared.updateBody, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                        } else {
                            Text(DownloadManager.shared.updateBody)
                        }
                    } else {
                        Text(NSLocalizedString("local_file_info", comment: ""))
                    }
                }
                .lineLimit(4)
                .padding(.vertical, 12)
            }
            if dfuUpdater.local == false {
                Button {
                    showLearnMoreView = true
                } label: {
                    Text(NSLocalizedString("learn_more", comment: ""))
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
                .sheet(isPresented: $showLearnMoreView) {
                    VStack(spacing: 0) {
                        HStack {
                            Text(NSLocalizedString("learn_more", comment: "Learn More"))
                                .foregroundColor(.primary)
                                .font(.title.weight(.bold))
                            Spacer()
                            Button {
                                showLearnMoreView = false
                            } label: {
                                Image(systemName: "xmark")
                                    .imageScale(.medium)
                                    .padding(14)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(scheme == .dark ? .white : .darkGray)
                                    .background(Color.gray.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        Divider()
                        ScrollView {
                            VStack {
                                if #available(iOS 15.0, *) {
                                    Text(try! AttributedString(markdown: DownloadManager.shared.updateBody, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                                } else {
                                    Text(DownloadManager.shared.updateBody)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            DFUStartTransferButton(updateStarted: $updateStarted, firmwareSelected: $dfuUpdater.firmwareSelected, externalResources: .constant(false))
                .disabled(bleManager.batteryLevel <= 50)
                .opacity(bleManager.batteryLevel <= 50 ? 0.5 : 1.0)
            if bleManager.batteryLevel <= 50 {
                Text("To update, please make sure \(deviceInfo.deviceName)'s battery level is over 50 percent")
                    .foregroundColor(.gray)
                    .font(.system(size: 15))
                    .padding(2)
            }
        }
        .padding(20)
    }
}

struct ExternalResources: View {
    @Binding var updateStarted: Bool
    @Binding var openFile: Bool
    
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: 10) {
                    Image("InfiniTime")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 65, height: 65)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(dfuUpdater.resourceFilename)
                            .font(.headline)
                        Text("\(Int(ceil(Double(DownloadManager.shared.updateSize) / 1000.0))) KB")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        if updateStarted {
                            DFUProgressBar()
                                .environmentObject(dfuUpdater)
                        } else {
                            HStack {
                                Spacer()
                            }
                        }
                    }
                }
                Text(NSLocalizedString("external_resources_info", comment: ""))
                    .lineLimit(4)
                    .padding(.vertical, 12)
            }
            DFUStartTransferButton(updateStarted: $updateStarted, firmwareSelected: $dfuUpdater.firmwareSelected, externalResources: .constant(true))
        }
        .padding(20)
    }
}

struct NoUpdate: View {
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    
    @Binding var externalResources: Bool
    @Binding var showFilePicker: Bool
    
    var body: some View {
        Spacer()
        VStack {
            VStack(alignment: .center , spacing: 20) {
                VStack(alignment: .center , spacing: 6) {
                    Text("InfiniTime \(deviceInfo.firmware)")
                        .foregroundColor(.gray)
                        .font(.title2.weight(.semibold))
                    Text("InfiniTime " + NSLocalizedString("up_to_date", comment: ""))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        Spacer()
    }
}

struct DFURefreshButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var downloadManager = DownloadManager.shared
    
    var body: some View {
        Button {
            downloadManager.getDownloadUrls(currentVersion: BLEDeviceInfo.shared.firmware)
        } label: {
            VStack {
                if downloadManager.loadingResults {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.counterclockwise")
                        .imageScale(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                }
            }
            .padding(14)
            .font(.body.weight(.semibold))
            .background(Color.gray.opacity(0.15))
            .clipShape(Circle())
        }
        .disabled(downloadManager.loadingResults)
    }
}

#Preview {
    NavigationView {
        DFUWithBLE()
            .onAppear {
                BLEDeviceInfo.shared.firmware = "1.14.0"
            }
    }
}
