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
    
    @AppStorage("showNewDownloadsOnly") var showNewDownloadsOnly: Bool = false
    
    @State var openFile = false
    @State var showOlderVersionView = false
    @State var externalResources = false

    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                ZStack {
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
                        Spacer()
                    }
                    Text(NSLocalizedString("software_update", comment: "Software Update"))
                        .foregroundColor(.primary)
                        .font(.title.weight(.bold))
                    if !(showNewDownloadsOnly) && !externalResources{
                        HStack(spacing: 15) {
                            Spacer()
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
                                DownloadView(openFile: $openFile)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                Divider()
                GeometryReader { geometryProxy in
                    ScrollView {
                        PullToRefreshView(coordinateSpaceName: "pullToRefresh") {
                            downloadManager.getDownloadUrls(currentVersion: BLEDeviceInfo.shared.firmware)
                        }
                        VStack {
                            if externalResources {
                                ExternalResources(updateStarted: $downloadManager.updateStarted, externalResources: $externalResources)
                            } else {
                                if downloadManager.updateAvailable && dfuUpdater.firmwareSelected {
                                    NewUpdate(updateStarted: $downloadManager.updateStarted, openFile: $openFile)
                                } else {
                                    NoUpdate(externalResources: $externalResources)
                                }
                            }
                            Spacer()
                        }
                        .frame(
                            width: geometryProxy.size.width,
                            height: geometryProxy.size.height,
                            alignment: .topLeading
                        )
                    }.coordinateSpace(name: "pullToRefresh")
                }
                HStack {
//                    Button {
//                        externalResources.toggle()
//                    } label: {
//                        Text(NSLocalizedString(externalResources ? "software_update" : "external_resources", comment: ""))
//                            .frame(maxWidth: .infinity)
//                            .padding(16)
//                            .background(Color.gray.opacity(0.15))
//                            .foregroundColor(colorScheme == .dark ? .white : .darkGray)
//                            .clipShape(Capsule())
//                    }
//                    if !(showNewDownloadsOnly) && !externalResources{
//                        Button {
//                            showOlderVersionView.toggle()
//                        } label: {
//                            Image(systemName: "doc")
//                                .aspectRatio(1, contentMode: .fit)
//                                .imageScale(.medium)
//                                .font(.body.weight(.semibold))
//                                .padding(16)
//                                .foregroundColor(colorScheme == .dark ? .white : .darkGray)
//                                .background(Color.gray.opacity(0.15))
//                            //.clipShape(Circle())
//                                .clipShape(Capsule())
//                        }
//                        .sheet(isPresented: $showOlderVersionView) {
//                            DownloadView(openFile: $openFile)
//                        }
//                    }
                }
                .padding()
                
            }
            .fileImporter(isPresented: $openFile, allowedContentTypes: [.zip]) {(res) in
                // this fileImporter allows user to select the zip from local storage. DFU updater just wants the local URL to the file, so we're opening privileged access, grabbing the url, and closing privileged access
                do{
                    let fileUrl = try res.get()
                    
                    guard fileUrl.startAccessingSecurityScopedResource() else { return }
                    
                    dfuUpdater.firmwareSelected = true
                    dfuUpdater.firmwareFilename = fileUrl.lastPathComponent
                    dfuUpdater.firmwareURL = fileUrl.absoluteURL
                    
                    fileUrl.stopAccessingSecurityScopedResource()
                } catch{
                    DebugLogManager.shared.debug(error: error.localizedDescription, log: .dfu, date: Date())
                }
            }
            VStack {
                if dfuUpdater.transferCompleted {
                    DFUComplete()
                        .cornerRadius(10)
                        .onAppear() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                                dfuUpdater.transferCompleted = false
                            })
                            downloadManager.updateStarted = false
                            dfuUpdater.firmwareURL = URL(fileURLWithPath: "")
                            dfuUpdater.firmwareSelected = false
                            dfuUpdater.firmwareFilename = ""
                            downloadManager.updateAvailable = downloadManager.checkForUpdates(currentVersion: downloadManager.updateVersion)
                        }
                }
            }
            .transition(.opacity).animation(.easeInOut(duration: 1.0))
        }
        .navigationBarBackButtonHidden()
    }
}

struct PullToRefreshView: View {

    var coordinateSpaceName: String
    var action: () -> Void

    @State private var ratio: CGFloat = 0
    @State private var isRefreshing: Bool = false

    private let threshold: CGFloat = 50

    var body: some View {
        GeometryReader { proxy in
            if proxy.frame(in: .named(coordinateSpaceName)).midY > threshold {
                Spacer()
                    .onAppear {
                        isRefreshing = true
                    }
            
            } else if proxy.frame(in: .named(coordinateSpaceName)).maxY < 6 {
                Spacer()
                    .frame {
                        let x = $0.origin.y + 6
                        ratio = max(0, min(1, x / threshold))
                    }
                    .onAppear {
                        guard isRefreshing else { return }
                    
                        isRefreshing = false
                        action()
                    }
            }
        
            progressView
        }
        .padding(.top, -threshold)
    }

    private var progressView: some View {
        ZStack {
            ActivityIndicatorView(isAnimating: $isRefreshing, style: .medium)
                .scaleEffect(1.3)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .opacity(ratio)
    }
}

struct ActivityIndicatorView: View {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
}

extension ActivityIndicatorView: UIViewRepresentable {
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicatorView>) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: style)
        view.hidesWhenStopped = false
        return view
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicatorView>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

extension View {

    func frame(perform: @escaping (CGRect) -> Void) -> some View {
        background(
            GeometryReader {
                Color.clear
                    .preference(key: FramePreferenceKey.self, value: $0.frame(in: .global))
            }
        )
        .onPreferenceChange(FramePreferenceKey.self) { value in
            DispatchQueue.main.async { perform(value) }
        }
    }
}

struct FramePreferenceKey: PreferenceKey {
     
     static var defaultValue: CGRect = .zero
   
     static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
 }



struct NewUpdate: View {
    @Binding var updateStarted: Bool
    
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    
    @AppStorage("showNewDownloadsOnly") var showNewDownloadsOnly: Bool = false
    
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
                                .environmentObject(dfuUpdater)
                        } else {HStack {Spacer()}}
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
                    .multilineTextAlignment(.center)
                    .padding(4)
                }
        }
        .padding(20)
    }
}

struct ExternalResources: View {
    @Binding var updateStarted: Bool
    @Binding var externalResources: Bool
    
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    
    @AppStorage("showNewDownloadsOnly") var showNewDownloadsOnly: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
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
                        Text("External Resources")
                            .font(.headline)
                        Text("\(Int(ceil(Double(DownloadManager.shared.updateSize) / 1000.0))) KB")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        if updateStarted {
                            DFUProgressBar()
                                .environmentObject(dfuUpdater)
                        } else {HStack {Spacer()}}
                    }
                }
                HStack {
                    Text(NSLocalizedString("external_resources_info", comment: ""))
                }
                .lineLimit(4)
                .padding(.vertical, 12)
            }
            if !updateStarted {
                Button {
                    externalResources.toggle()
                } label: {
                    Text(NSLocalizedString("Back to Software Update", comment: ""))
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            DFUStartTransferButton(updateStarted: $updateStarted, firmwareSelected: $dfuUpdater.firmwareSelected, externalResources: .constant(true))
        }
        .padding(20)
    }
}

struct NoUpdate: View {
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    
    @Binding var externalResources: Bool
    
    var body: some View {
        Spacer()
        VStack {
            VStack(alignment: .center , spacing: 6) {
                Text("InfiniTime \(deviceInfo.firmware)")
                    .foregroundColor(.gray)
                    .font(.title2.weight(.semibold))
                Text("InfiniTime " + NSLocalizedString("up_to_date", comment: ""))
                    .foregroundColor(.gray)
                Button {
                    externalResources.toggle()
                } label: {
                    Text(NSLocalizedString("external_resources", comment: ""))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                        //.font(.subheadline.weight(.light))
                        .padding()
                        //.background(Color.gray.opacity(0.15))
                        //.foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        //.clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
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
