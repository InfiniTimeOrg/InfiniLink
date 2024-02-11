//
//  WatchSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 2/11/24.
//

import SwiftUI

struct WatchSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presMode
    
    @State var settings: Settings? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Button {
                    presMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                Text(NSLocalizedString("watch_settings", comment: ""))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                /*
                 Button {
                 // Save updated settings to watch?
                 } label: {
                 Text(NSLocalizedString("save", comment: ""))
                 .padding(14)
                 .font(.body.weight(.semibold))
                 .foregroundColor(Color.white)
                 .background(Color.blue)
                 .clipShape(Capsule())
                 .foregroundColor(.primary)
                 }
                 .disabled(changedName == deviceInfo.deviceName)
                 .opacity(changedName == deviceInfo.deviceName ? 0.5 : 1.0)
                 */
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            if let settings = settings {
                ScrollView {
                    VStack {
                        VStack {
                            switch settings.watchFace {
                            case 0:
                                if settings.clockType == .H12 {
                                    Image("digital12H")
                                        .resizable()
                                } else {
                                    Image("digital24H")
                                        .resizable()
                                }
                            case 1:
                                Image("analog")
                                    .resizable()
                            case 2:
                                if settings.clockType == .H12 {
                                    Image("PTS12HStepStyle2")
                                        .resizable()
                                } else {
                                    Image("PTS24HStepStyle1")
                                        .resizable()
                                }
                            case 3:
                                if settings.clockType == .H12 {
                                    Image("terminal12H")
                                        .resizable()
                                } else {
                                    Image("terminal24H")
                                        .resizable()
                                }
                            case 4:
                                EmptyView()
                                // Image("infineat12H")
                                //      .resizable()
                            default:
                                Image("digital24H")
                                    .resizable()
                            }
                        }
                        .padding(16)
                        .padding(.vertical, 4)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(.gray, lineWidth: 1)
                                .opacity(0.4)
                        )
                        .frame(maxWidth: 155, maxHeight: 155)
                        .padding(26)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .onAppear {
            BLEFSHandler.shared.readSettings { settings in
                self.settings = settings
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }
}

#Preview {
    WatchSettingsView(settings: Settings(version: 7, stepsGoal: 10000, screenTimeOut: 1500, clockType: .H12, weatherFormat: .Imperial, notificationStatus: .On, watchFace: 2, chimesOption: .None, pineTimeStyle: .init(), watchFaceInfineat: .init(), shakeWakeThreshold: 1500, brightLevel: 1))
}
