//
//  CustomizationView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/14/24.
//

import SwiftUI

struct CustomizationView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var bleFs = BLEFSHandler.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    func row(_ title: String, value: String) -> some View {
        return HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.gray)
        }
    }
    var body: some View {
        GeometryReader { geo in
            List {
                Group { // Add .disabled modifer to List children to avoid disabling scroll
                    Section {
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    ForEach(0...5, id: \.self) { index in
                                        let isSelected = (deviceManager.settings.watchFace == UInt8(index))
                                        
                                        Button {
                                            bleFs.setWatchFace(&deviceManager.settings, face: UInt8(index))
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
                                    proxy.scrollTo(Int(deviceManager.settings.watchFace), anchor: .center)
                                }
                            }
                            .padding(.horizontal, -16)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    if bleManager.pairedDevice.settingsVersion > 7 {
                        Section {
                            NavigationLink {
                                
                            } label: {
                                row(NSLocalizedString("Always On", comment: ""), value: bleManager.pairedDevice.alwaysOnDisplay ? "On" : "Off")
                            }
                        }
                    }
                    Section {
                        NavigationLink {
                            
                        } label: {
                            row(NSLocalizedString("Screen Timeout", comment: ""), value: String(bleManager.pairedDevice.screenTimeout / 1000) + " " + NSLocalizedString("Seconds", comment: ""))
                        }
                        NavigationLink {
                            
                        } label: {
                            row(NSLocalizedString("Clock Type", comment: ""), value: {
                                switch bleManager.pairedDevice.clockType {
                                case 1:
                                    return "12 Hour"
                                default:
                                    return "24 Hour"
                                }
                            }())
                        }
                        NavigationLink {
                            
                        } label: {
                            row(NSLocalizedString("Weather Format", comment: ""), value: {
                                switch bleManager.pairedDevice.weatherFormat {
                                case 1:
                                    return NSLocalizedString("Imperial", comment: "")
                                default:
                                    return NSLocalizedString("Metric", comment: "")
                                }
                            }())
                        }
                    }
                }
                .disabled(bleManager.blefsTransfer == nil)
            }
        }
        .navigationBarTitle("Customization")
    }
}

#Preview {
    CustomizationView()
}
