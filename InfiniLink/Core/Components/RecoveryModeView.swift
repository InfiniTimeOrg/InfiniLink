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
            VStack(spacing: 10) {
                Image("InfiniTime")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 75, height: 75)
                Group {
                    Text("InfiniTime") + Text(" Recovery")
                        .foregroundColor(.red)
                }
                .font(.system(size: 25).weight(.bold))
            }
            Text("It looks like your watch is in recovery mode. You'll need to update it to continue.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
            Button {
                showUpdateView = true
            } label: {
                Text("Continue to Update")
                    .padding(14)
                    .font(.body.weight(.semibold))
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
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
            Spacer()
        }
        .padding(20)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RecoveryModeView()
}
