//
//  DFULeanMore.swift
//  InfiniLink
//
//  Created by John Stanley on 11/17/21.
//

import SwiftUI

struct DFULearnMore: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    
    //@ObservedObject var downloadManager
    //@AppStorage("updateAvailable") var updateAvailable: Bool = false
    
    @State var openFile = false
    @State var updateStarted: Bool = false
    
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading) {
                List {
                    Section() {
                        Text(DownloadManager.shared.updateBody)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(.max)
                    }
                    .padding(2)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationBarTitle(Text("Learn More").font(.subheadline), displayMode: .inline)
    }
}
