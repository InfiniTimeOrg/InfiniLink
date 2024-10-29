//
//  CurrentlyUpdatingView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/28/24.
//

import SwiftUI

struct CurrentlyUpdatingView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var dfuUpdater = DFUUpdater.shared
    
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
                    Text("Updating...56%")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(.darkGray))
                    Text(deviceManager.getName(for: bleManager.pairedDeviceID ?? ""))
                        .font(.title.weight(.bold))
                }
                Button {
                    dfuUpdater.stopTransfer()
                } label: {
                    Text("Abort Update")
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
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                backgroundScaled.toggle()
            }
        }
    }
}

#Preview {
    CurrentlyUpdatingView()
}
