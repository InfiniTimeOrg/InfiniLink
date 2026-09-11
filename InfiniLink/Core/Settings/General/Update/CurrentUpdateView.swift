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
    
    @State private var backgroundScaled = true
    @State private var showConfirmation = false
    
    private var failureMessage: String? {
        if case .failed(let message) = dfuUpdater.stage { return message }
        return nil
    }
    
    private var statusText: String {
        switch dfuUpdater.stage {
        case .idle:
            return NSLocalizedString("Preparing", comment: "")
        case .downloading:
            return NSLocalizedString("Downloading", comment: "")
        case .uploadingResources:
            return dfuUpdater.statusDetail.isEmpty ? NSLocalizedString("Updating resources", comment: "") : dfuUpdater.statusDetail
        case .installing:
            return dfuUpdater.statusDetail.isEmpty ? NSLocalizedString("Installing", comment: "") : dfuUpdater.statusDetail
        case .failed:
            return ""
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 150, height: 150)
                .foregroundStyle(.orange)
                .blur(radius: 50)
                .scaleEffect(backgroundScaled ? 1.4 : 1)
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    if let failureMessage {
                        Text("Update Failed")
                            .font(.title.weight(.bold))
                        Text(failureMessage)
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 0) {
                            Text("\(statusText)... ")
                            if dfuUpdater.percentComplete != 0 {
                                Text(dfuUpdater.percentComplete / 100, format: .percent.precision(.fractionLength(0)))
                            }
                        }
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                        Text(deviceManager.name)
                            .font(.title.weight(.bold))
                    }
                }
                if failureMessage != nil {
                    Button {
                        dfuUpdater.dismissError()
                    } label: {
                        Text("Close")
                            .padding(14)
                            .font(.body.weight(.semibold))
                            .background(Color.gray)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                } else {
                    Button {
                        showConfirmation = true
                    } label: {
                        Text("Cancel Update")
                            .padding(14)
                            .font(.body.weight(.semibold))
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .disabled(dfuUpdater.stage == .uploadingResources)
                    .opacity(dfuUpdater.stage == .uploadingResources ? 0.5 : 1)
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
        .alert("Are you sure you want to stop this update?", isPresented: $showConfirmation) {
            Button(role: .destructive) {
                dfuUpdater.cancel()
            } label: {
                Text("Stop Update")
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

#Preview {
    CurrentUpdateView()
}
