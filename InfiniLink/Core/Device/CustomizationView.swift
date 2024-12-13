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
    
    @State private var clockType = 0
    @State private var weatherFormat = 0
    
    func setSettings() {
        self.clockType = Int(deviceManager.settings.clockType.rawValue)
        self.weatherFormat = Int(deviceManager.settings.weatherFormat.rawValue)
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
                    Section {
                        NavigationLink {

                        } label: {
                            HStack {
                                Text("Screen Timeout")
                                Spacer()
                                Text(String(bleManager.pairedDevice.screenTimeout / 1000) + " " + NSLocalizedString("Seconds", comment: ""))
                                    .foregroundStyle(.gray)
                            }
                        }
                        Picker(selection: $clockType) {
                            ForEach(0...1, id: \.self) { type in
                                Text(type == 1 ? "12 Hour" : "24 Hour")
                                    .tag(type)
                            }
                        } label: {
                            Text("Clock Type")
                        }
                        Picker(selection: $weatherFormat) {
                            ForEach(0...1, id: \.self) { type in
                                Text(type == 1 ? "Imperial" : "Metric")
                                    .tag(type)
                            }
                        } label: {
                            Text("Weather Format")
                        }
                    }
                    .pickerStyle(NavigationLinkPickerStyle())
                }
                .disabled(bleManager.blefsTransfer == nil)
            }
        }
        .navigationBarTitle("Customization")
        .onAppear {
            setSettings()
        }
        .onChange(of: bleManager.blefsTransfer) { _ in
            setSettings()
        }
    }
}

#Preview {
    CustomizationView()
}
