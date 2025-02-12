//
//  RecoveryModeView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/28/24.
//

import SwiftUI

struct RecoveryModeView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    @State private var showUpdateView = false
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 12) {
                Image(.infiniTime)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 75, height: 75)
                Group {
                    Text("InfiniTime") + Text(" Recovery").foregroundColor(.red)
                }
                .font(.system(size: 28).weight(.bold))
                Text("It looks like your watch is in recovery mode. You'll need to update it to continue.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary.opacity(0.8))
                Button {
                    showUpdateView = true
                } label: {
                    Text("Continue to Update")
                        .padding(12)
                        .padding(.horizontal, 6)
                        .font(.body.weight(.semibold))
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding()
                .fullScreenCover(isPresented: $showUpdateView) {
                    NavigationView {
                        SoftwareUpdateView()
                            .toolbar {
                                Button("Cancel") {
                                    showUpdateView = false
                                }
                            }
                    }
                    .navigationViewStyle(.stack)
                }
            }
            Spacer()
        }
        .padding(24)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RecoveryModeView()
}
