//
//  CustomizationView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/14/24.
//

import SwiftUI

struct CustomizationView: View {
    @ObservedObject var deviceInfoManager = DeviceInfoManager.shared
    @ObservedObject var bleFs = BLEFSHandler.shared
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(0...5, id: \.self) { index in
                                    let isSelected = (deviceInfoManager.settings.watchFace == UInt8(index))
                                    
                                    Button {
                                        bleFs.setWatchFace(&deviceInfoManager.settings, face: UInt8(index))
                                        withAnimation {
                                            proxy.scrollTo(index, anchor: .center)
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            WatchFaceView(watchface: .constant(UInt8(index)))
                                                .frame(width: 180, height: 180)
                                                .padding(.bottom, -12)
                                            Image(systemName: "checkmark")
                                                .padding(10)
                                                .imageScale(.small)
                                                .foregroundStyle(Color.white)
                                                .background(Color.blue)
                                                .clipShape(Circle())
                                                .opacity(isSelected ? 1 : 0)
                                        }
                                    }
                                    .opacity(isSelected ? 1 : 0.5)
                                    .id(index)
                                }
                            }
                            .padding(.horizontal)
                            .onAppear {
                                proxy.scrollTo(Int(deviceInfoManager.settings.watchFace), anchor: .center)
                            }
                        }
                        .padding(.horizontal, -16)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                Section {
                    // Add other settings here
                }
            }
        }
        .navigationBarTitle("Customization")
    }
}

#Preview {
    CustomizationView()
}
