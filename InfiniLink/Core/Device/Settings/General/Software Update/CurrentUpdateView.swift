//
//  CurrentUpdateView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/28/24.
//

import SwiftUI

struct CurrentUpdateView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var dfuUpdater = DFUUpdater.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    
    @State private var backgroundScaled = true
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 150, height: 150)
                .foregroundStyle(.orange)
                .blur(radius: 50)
                .scaleEffect(backgroundScaled ? 1.4 : 1)
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(dfuUpdater.dfuState.isEmpty ? "Preparing to update" : dfuUpdater.dfuState)...\(dfuUpdater.percentComplete == 0 ? "" : String(format: "%.0f", dfuUpdater.percentComplete) + "%")")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                    Text(deviceManager.getName(for: bleManager.pairedDeviceID ?? ""))
                        .font(.title.weight(.bold))
                }
                Button {
                    dfuUpdater.stopTransfer()
                    dfuUpdater.isUpdating = false
                    downloadManager.updateStarted = false
                } label: {
                    Text("Cancel Update")
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .frame(maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                backgroundScaled.toggle()
            }
        }
    }
}

#Preview {
    CurrentUpdateView()
}
