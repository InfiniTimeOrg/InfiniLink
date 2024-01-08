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
    
	var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(NSLocalizedString("downloads", comment: "Downloads"))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                Button {
                    downloadManager.getDownloadUrls(currentVersion: BLEDeviceInfo.shared.firmware)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                Button {
                    presentation.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .imageScale(.medium)
                        .padding(16)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
			ScrollView {
                VStack(spacing: 20) {
                    Button {
                        openFile.toggle()
                        
                        dfuUpdater.local = true
                        downloadManager.updateAvailable = true
                        downloadManager.updateBody = ""
                        downloadManager.updateSize = 0
                    } label: {
                        Text(NSLocalizedString("use_local_file", comment: ""))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
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
                                presentation.wrappedValue.dismiss()
                            } label: {
                                Text(i.tag_name)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding()
			}
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
                presentation.wrappedValue.dismiss()
            } catch{
                DebugLogManager.shared.debug(error: error.localizedDescription, log: .dfu, date: Date())
            }
        }
	}
}

#Preview {
    NavigationView {
        DownloadView(openFile: .constant(false))
    }
}
