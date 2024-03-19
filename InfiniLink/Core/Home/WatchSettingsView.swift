//
//  WatchSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 2/11/24.
//

import SwiftUI

struct WatchSettingsView: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presMode
    
    @State var settings: Settings? = nil
    
    var body: some View {
        if UptimeManager.shared.connectTime != nil {
            content
        } else {
            DFUWithoutBLE(title: NSLocalizedString("pinetime_not_available", comment: ""), subtitle: NSLocalizedString("please_check_your_connection_and_try_again", comment: ""))
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Text(NSLocalizedString("watch_settings", comment: ""))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                Button {
                    presMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Material.regular)
                        .clipShape(Circle())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            if let settings = settings {
                ScrollView {
                    VStack {
                        HStack {
                            Text(NSLocalizedString("display_timeout", comment: ""))
                            Spacer()
                            Text("\(settings.screenTimeOut / 1000) Seconds")
                                .foregroundColor(.gray)
                        }
                        .modifier(RowModifier(style: .capsule))
                        // TODO: Don't display until handling for multiple cases is implemented
//                        HStack {
//                            Text(NSLocalizedString("display_wakeup", comment: ""))
//                            Spacer()
//                            Group {
//                                switch settings.wakeUpMode {
//                                case .SingleTap:
//                                    Text("Single Tap")
//                                case .DoubleTap:
//                                    Text("Double Tap")
//                                case .RaiseWrist:
//                                    Text("Raise Wrist")
//                                case .Shake:
//                                    Text("Shake Wake")
//                                case .LowerWrist:
//                                    Text("Lower Wrist")
//                                }
//                            }
//                            .foregroundColor(.gray)
//                        }
//                        .modifier(RowModifier(style: .capsule))
                        HStack {
                            Text(NSLocalizedString("brightness_level", comment: ""))
                            Spacer()
                            Group {
                                switch settings.brightLevel {
                                case .Low:
                                    Text("Low")
                                case .Mid:
                                    Text("Mid")
                                case .High:
                                    Text("High")
                                }
                            }
                            .foregroundColor(.gray)
                        }
                        .modifier(RowModifier(style: .capsule))
                        HStack {
                            Text(NSLocalizedString("time_format", comment: ""))
                            Spacer()
                            Group {
                                switch settings.clockType {
                                case .H12:
                                    Text("12 Hour")
                                case .H24:
                                    Text("24 Hour")
                                }
                            }
                            .foregroundColor(.gray)
                        }
                        .modifier(RowModifier(style: .capsule))
                        HStack {
                            Text(NSLocalizedString("steps_goal", comment: ""))
                            Spacer()
                            Text("\(settings.stepsGoal)")
                                .foregroundColor(.gray)
                        }
                        .modifier(RowModifier(style: .capsule))
                        HStack {
                            Text(NSLocalizedString("weather", comment: ""))
                            Spacer()
                            Group {
                                switch settings.weatherFormat {
                                case .Metric:
                                    Text("Metric")
                                case .Imperial:
                                    Text("Imperial")
                                }
                            }
                            .foregroundColor(.gray)
                        }
                        .modifier(RowModifier(style: .capsule))
                        HStack {
                            Text(NSLocalizedString("hourly_chimes", comment: ""))
                            Spacer()
                            Group {
                                switch settings.chimesOption {
                                case .None:
                                    Text("None")
                                case .Hours:
                                    Text("Hour")
                                case .HalfHours:
                                    Text("Half Hour")
                                }
                            }
                            .foregroundColor(.gray)
                        }
                        .modifier(RowModifier(style: .capsule))
                    }
                    .padding()
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

struct WatchFaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
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
    }
}

#Preview {
    WatchSettingsView(settings: Settings(version: 7, stepsGoal: 10000, screenTimeOut: 1500, clockType: .H12, weatherFormat: .Imperial, notificationStatus: .On, watchFace: 2, chimesOption: .None, pineTimeStyle: .init(), watchFaceInfineat: .init(), wakeUpMode: .SingleTap, shakeWakeThreshold: 1500, brightLevel: .Mid))
}
