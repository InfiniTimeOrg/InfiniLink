//
//  WatchFace.swift
//  InfiniLink
//
//  Created by Jen on 2/9/24.
//

import Foundation
import SwiftUI
import Combine


struct WatchFaceView: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var colorScheme
    
    let date = Date()
    
    @Binding var watchface: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("WatchScreen")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(color: colorScheme == .dark ? Color.black : Color.secondary, radius: 16, x: 0, y: 0)
                    .brightness(colorScheme == .dark ? -0.03 : 0.015)
                ZStack {
                    ZStack {
                        switch watchface == -1 ? bleManagerVal.watchFace : watchface {
                        case 0:
                            DigitalWF(geometry: .constant(geometry))
                        case 1:
                            AnalogWF(geometry: .constant(geometry))
                        case 2:
                            PineTimeStyleWF(geometry: .constant(geometry))
                        case 3:
                            TerminalWF(geometry: .constant(geometry))
                        case 4:
                            InfineatWF(geometry: .constant(geometry))
                        case 5:
                            CasioWF(geometry: .constant(geometry))
                        default:
                            ProgressView()
                                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
                    .scaleEffect(0.53, anchor: .center)
                    .frame(width: geometry.size.width, height: geometry.size.width, alignment: .center)
                    .position(x: geometry.size.width / 2, y: geometry.size.width / 2 - 2)
                    .brightness(colorScheme == .dark ? 0.015 : 0.125)
                    .clipped()
                }
                .frame(width: geometry.size.width, height: geometry.size.width, alignment: .center)
                .clipped()
                Image("WatchHomeClear")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .brightness(colorScheme == .dark ? 0.0 : 0.04)
            }
        }
    }
}

struct PineTimeStyleWF: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
    
    var hour24: Bool {
        switch bleManagerVal.timeFormat {
        case .H12:
            return false
        case .H24:
            return true
        default:
            return true
        }
    }
    
    var backgroundColor: Color {
        switch bleManagerVal.pineTimeStyleData?.ColorBG {
        case .White:
            return .white
        case .Silver:
            return .lightGray
        case .Gray:
            return .gray
        case .Black:
            return .clear
        case .Red:
            return .red
        case .Maroon:
            // Add more accurate color
            return .red
        case .Yellow:
            return .yellow
        case .Olive:
            // Add more accurate color
            return .green
        case .Lime:
            // Add more accurate color
            return .green
        case .Green:
            return .green
        case .Cyan:
            return .cyan
        case .Teal:
            return .teal
        case .Blue:
            return .blue
        case .Navy:
            // Add more accurate color
            return .blue
        case .Magenta:
            // Add more accurate color
            return .purple
        case .Purple:
            return .white
        case .Orange:
            return .orange
        case .Pink:
            return .pink
        case nil:
            return .teal
        }
    }
    var barColor: Color {
        switch bleManagerVal.pineTimeStyleData?.ColorBar {
        case .White:
            return .white
        case .Silver:
            return .lightGray
        case .Gray:
            return .gray
        case .Black:
            return .clear
        case .Red:
            return .red
        case .Maroon:
            // Add more accurate color
            return .red
        case .Yellow:
            return .yellow
        case .Olive:
            // Add more accurate color
            return .green
        case .Lime:
            // Add more accurate color
            return .green
        case .Green:
            return .green
        case .Cyan:
            return .cyan
        case .Teal:
            return .teal
        case .Blue:
            return .blue
        case .Navy:
            // Add more accurate color
            return .blue
        case .Magenta:
            // Add more accurate color
            return .purple
        case .Purple:
            return .white
        case .Orange:
            return .orange
        case .Pink:
            return .pink
        case nil:
            return .teal
        }
    }
    var timeColor: Color {
        switch bleManagerVal.pineTimeStyleData?.ColorTime {
        case .White:
            return .white
        case .Silver:
            return .lightGray
        case .Gray:
            return .gray
        case .Black:
            return .clear
        case .Red:
            return .red
        case .Maroon:
            // Add more accurate color
            return .red
        case .Yellow:
            return .yellow
        case .Olive:
            // Add more accurate color
            return .green
        case .Lime:
            // Add more accurate color
            return .green
        case .Green:
            return .green
        case .Cyan:
            return .cyan
        case .Teal:
            return .teal
        case .Blue:
            return .blue
        case .Navy:
            // Add more accurate color
            return .blue
        case .Magenta:
            // Add more accurate color
            return .purple
        case .Purple:
            return .white
        case .Orange:
            return .orange
        case .Pink:
            return .pink
        case nil:
            return .teal
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor
            if !hour24 {
                CustomTextView(text: Calendar.current.component(.hour, from: Date()) > 12 ? "P\nM" : "A\nM", font: .custom("JetBrainsMono-ExtraBold", size: geometry.size.width * 0.075), lineSpacing: -4)
                    .foregroundColor(timeColor)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
            }
            if Calendar.current.component(.hour, from: Date()) > 12 && !hour24 {
                CustomTextView(text: "\(String(format: "%02d", Calendar.current.component(.hour, from: Date()) - 12))\n\(String(format: "%02d", Calendar.current.component(.minute, from: Date())))", font: .custom("OpenSans-light", size: geometry.size.width * 0.62), lineSpacing: -geometry.size.width * 0.35)
                    .foregroundColor(timeColor)
                    .position(x: geometry.size.width / 2.3, y: geometry.size.height / 2.0)
            } else {
                CustomTextView(text: "\(String(format: "%02d", Calendar.current.component(.hour, from: Date())))\n\(String(format: "%02d", Calendar.current.component(.minute, from: Date())))", font: .custom("OpenSans-light", size: geometry.size.width * 0.62), lineSpacing: -geometry.size.width * 0.35)
                    .foregroundColor(timeColor)
                    .position(x: geometry.size.width / 2.3, y: geometry.size.height / 2.0)
            }
            GeometryReader { geometry in
                Rectangle()
                    .foregroundColor(barColor)
                    .position(x: geometry.size.width - ((geometry.size.width / 6.0) / 2), y: geometry.size.height / 2 - 2)
                    .frame(width: geometry.size.width / 6.0, height: geometry.size.height + 4, alignment: .center)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct AnalogWF: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            let hour = Calendar.current.component(.hour, from: Date())
            let hour12 = Double(hour >= 12 ? hour - 12 : hour)
            let minute = Double(Calendar.current.component(.minute, from: Date()))
            Image("AnalogFace")
                .resizable()
            Image("AnalogHour")
                .resizable()
                .rotationEffect(Angle(degrees: ((hour12 * 60) + minute) / 2))
            Image("AnalogMin")
                .resizable()
                .rotationEffect(Angle(degrees: minute * 6))
            Image("AnalogSec")
                .resizable()
                .rotationEffect(Angle(degrees: Double(Calendar.current.component(.second, from: Date())) * 6))
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct DigitalWF: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
    
    var hour24: Bool {
        switch bleManagerVal.timeFormat {
        case .H12:
            return false
        case .H24:
            return true
        default:
            return true
        }
    }
    
    var body: some View {
        ZStack {
            if !hour24 {
                CustomTextView(text: Calendar.current.component(.hour, from: Date()) > 12 ? "PM" : "AM", font: .custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085), lineSpacing: 0)
                    .foregroundColor(.white)
                    .frame(width: geometry.size.width, height: geometry.size.height / 1.95, alignment: .topTrailing)
            }
            if Calendar.current.component(.hour, from: Date()) > 12 && !hour24 {
                CustomTextView(text: "\(Calendar.current.component(.hour, from: Date()) - 12):\(String(format: "%02d", Calendar.current.component(.minute, from: Date())))", font: .custom("JetBrainsMono-ExtraBold", size: geometry.size.width * 0.33), lineSpacing: 0)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.9)
            } else {
                CustomTextView(text: "\(String(format: "%02d", Calendar.current.component(.hour, from: Date()))):\(String(format: "%02d", Calendar.current.component(.minute, from: Date())))", font: .custom("JetBrainsMono-ExtraBold", size: geometry.size.width * 0.33), lineSpacing: 0)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.9)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct InfineatWF: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
    
    var hour24: Bool {
        switch bleManagerVal.timeFormat {
        case .H12:
            return false
        case .H24:
            return true
        default:
            return true
        }
    }
    func infineatColor(from color: Colors) -> Color {
        switch color {
        case .White:
            return Color.white
        case .Silver:
            return Color.gray
        case .Gray:
            return Color.gray
        case .Black:
            return Color.black
        case .Red:
            return Color("Red")
        case .Maroon:
            return Color("Maroon")
        case .Yellow:
            return Color("Yellow")
        case .Olive:
            return Color.green
        case .Green:
            return Color.green
        case .Cyan:
            return Color.cyan
        case .Teal:
            return Color.teal
        case .Blue:
            return Color.blue
        case .Navy:
            return Color.blue
        case .Magenta:
            return Color.purple
        case .Purple:
            return Color.purple
        case .Orange:
            return Color("Orange")
        case .Pink:
            return Color.pink
        default:
            return Color.red
        }
    }
    
    var body: some View {
        ZStack {
            if hour24 {
                CustomTextView(text: Calendar.current.component(.hour, from: Date()) > 12 ? "PM" : "AM", font: .custom("Teko-Light", size: geometry.size.width * 0.125), lineSpacing: 0)
                    .foregroundColor(.white)
                    .frame(width: geometry.size.width, height: geometry.size.height / 1.35, alignment: .topTrailing)
            }
            if Calendar.current.component(.hour, from: Date()) > 12 && !hour24 {
                VStack(alignment: .center, spacing: -28) {
                    Text("\(String(format: "%02d", Calendar.current.component(.hour, from: Date()) - 12))")
                    Text("\(String(format: "%02d", Calendar.current.component(.minute, from: Date())))")
                }
                .font(.custom("BebasNeue-Regular", size: geometry.size.width * 0.44))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.9)
            } else {
                VStack(alignment: .center, spacing: -28) {
                    Text("\(String(format: "%02d", Calendar.current.component(.hour, from: Date())))")
                    Text("\(String(format: "%02d", Calendar.current.component(.minute, from: Date())))")
                }
                .font(.custom("BebasNeue-Regular", size: geometry.size.width * 0.44))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.9)
                    
            }
            CustomTextView(
                text: {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "E dd"
                    return dateFormatter.string(from: Date())
                }(),
                font: .custom("Teko-Light", size: geometry.size.width * 0.118),
                lineSpacing: 0
            )
            .foregroundColor(.gray)
            .frame(width: geometry.size.width, height: geometry.size.height / 2.2, alignment: .trailing)
            Image("bluetooth")
                .resizable()
                .frame(width: 18, height: 20)
                .frame(width: geometry.size.width / 1.14, height: geometry.size.height / 2.8, alignment: .bottomTrailing)
            HStack(spacing: 4) {
                Image(systemName: "shoeprints.fill")
                    .rotationEffect(Angle(degrees: 90))
                    .font(.system(size: geometry.size.width * 0.08))
                CustomTextView(text: "\(bleManagerVal.stepCount)", font: .custom("Teko-Light", size: geometry.size.width * 0.118), lineSpacing: 0)
            }
            .foregroundColor(.gray)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
            .padding(.bottom, -16)
            if bleManagerVal.infineatWatchface?.showSideCover ?? true {
                ZStack {
                    Rectangle()
                        .frame(width: 19)
                        .frame(height: geometry.size.height / 1.5, alignment: .topLeading)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                        .foregroundColor(infineatColor(from: .Yellow))
                        .rotationEffect(Angle(degrees: 49))
                        .offset(x: -36, y: -44)
                    Rectangle()
                        .frame(width: 19)
                        .frame(height: geometry.size.height / 1.5, alignment: .bottomLeading)
                        .frame(maxHeight: .infinity, alignment: .bottomLeading)
                        .foregroundColor(infineatColor(from: .Orange))
                        .opacity(0.8)
                        .rotationEffect(Angle(degrees: -16))
                        .offset(x: -6, y: 12)
                    Rectangle()
                        .frame(width: 26, alignment: .leading)
                        .offset(x: -5)
                        .foregroundColor(infineatColor(from: .Maroon))
                    Rectangle()
                        .frame(width: 26)
                        .frame(height: geometry.size.height / 1.5, alignment: .topLeading)
                        .frame(maxHeight: .infinity, alignment: .bottomLeading)
                        .foregroundColor(infineatColor(from: .Yellow))
                        .rotationEffect(Angle(degrees: -38))
                        .offset(x: -26, y: 30)
                    Rectangle()
                        .frame(width: 38)
                        .frame(height: geometry.size.height / 1.3, alignment: .topLeading)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                        .foregroundColor(infineatColor(from: .Orange))
                        .rotationEffect(Angle(degrees: 18))
                        .offset(x: -28, y: -16)
                    Rectangle()
                        .frame(width: 38)
                        .frame(height: geometry.size.height / 1.3, alignment: .topLeading)
                        .frame(maxHeight: .infinity, alignment: .bottomLeading)
                        .foregroundColor(infineatColor(from: .Red))
                        .rotationEffect(Angle(degrees: -18))
                        .offset(x: -28, y: 16)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
            }
            Image("pine_logo")
                .resizable()
                .frame(width: 20, height: 26)
                .frame(width: geometry.size.width / 1.15, height: geometry.size.height, alignment: .leading)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct TerminalWF: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
    
    var hour24: Bool {
        switch bleManagerVal.timeFormat {
        case .H12:
            return false
        case .H24:
            return true
        default:
            return true
        }
    }
    
    let currentHour = Calendar.current.component(.hour, from: Date())
    let currentMinute = Calendar.current.component(.minute, from: Date())
    let currentSecond = Calendar.current.component(.second, from: Date())
    
    var body: some View {
        ZStack {
            Text("user@watch:~ $ now")
                .foregroundColor(.white)
                .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 6.9)
            if !hour24 {
                Group {
                    Text("[TIME]").foregroundColor(.white) + Text("\(String(format: "%02d", (currentHour % 12 == 0) ? 12 : currentHour % 12)):\(String(format: "%02d", currentMinute)):\(String(format: "%02d", currentSecond)) \(currentHour >= 12 ? "PM" : "AM")").foregroundColor(.green)
                }
                .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 4.1)
            } else {
                Group {
                    Text("[TIME]").foregroundColor(.white) + Text("\(String(format: "%02d", currentHour)):\(String(format: "%02d", currentMinute)):\(String(format: "%02d", currentSecond))").foregroundColor(.green)
                }
                .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 4.1)
            }
            Group {
                Text("[DATE]").foregroundColor(.white) + Text("\(String(format: "%04d-%02d-%02d", Calendar.current.component(.year, from: Date()), Calendar.current.component(.month, from: Date()), Calendar.current.component(.day, from: Date())))").foregroundColor(.blue)
            }
            .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .position(x: geometry.size.width / 2.0, y: geometry.size.height / 3)
            Group {
                Text("[BATT]").foregroundColor(.white) + Text("\(Int(bleManager.batteryLevel))%").foregroundColor(Color(red: 0, green: 0.4, blue: 0.2))
            }
            .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.36)
            Group {
                Text("[STEP]").foregroundColor(.white) + Text("\(bleManagerVal.stepCount) steps").foregroundColor(Color(red: 1, green: 0.2, blue: 0.5))
            }
            .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.95)
            Group {
                Text("[L_HR]").foregroundColor(.white) + Text("\(bleManagerVal.heartBPM == 0 ? "---" : "\(bleManagerVal.heartBPM)")").foregroundColor(.red)
            }
            .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.655)
            Group {
                Text("[STAT]").foregroundColor(.white) + Text("Connected").foregroundColor(.blue)
            }
            .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.445)
            Text("user@watch:~ $")
                .foregroundColor(.white)
                .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.27)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct CasioWF: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
    
    let colorText: Color = Color(red: 152 / 255.0, green: 182 / 255.0, blue: 154 / 255.0)
    
    var hour24: Bool {
        switch bleManagerVal.timeFormat {
        case .H12:
            return false
        case .H24:
            return true
        default:
            return true
        }
    }
    
    var body: some View {
        ZStack {
            Image("casio")
                .scaleEffect(0.81)
            CustomTextView(text: String(Int(bleManager.batteryLevel)), font: .custom("open_sans_light", size: geometry.size.width * 0.09), lineSpacing: 0)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topTrailing)
            .padding(.trailing, 22)
            CustomTextView(
                text: {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "E"
                    
                    let weekOfYear = Calendar.current.component(.weekOfYear, from: Date())
                    
                    return "WK\(weekOfYear)\n\(dateFormatter.string(from: Date()).uppercased())"
                }(),
                font: .custom("repetitionscrolling", size: geometry.size.width * 0.16),
                lineSpacing: 0
            )
            .frame(width: geometry.size.width / 1.04, height: geometry.size.height / 1.2, alignment: .topLeading)
            CustomTextView(
                text: {
                    let calendar = Calendar.current
                    let now = Date()
                    
                    let startOfYear = calendar.startOfDay(for: calendar.date(from: DateComponents(year: calendar.component(.year, from: now)))!)
                    let endOfYear = calendar.startOfDay(for: calendar.date(byAdding: DateComponents(year: 1, day: -1), to: calendar.date(from: DateComponents(year: calendar.component(.year, from: now)))!)!)
                    
                    let daysIn = calendar.dateComponents([.day], from: startOfYear, to: now).day! + 1
                    let daysLeft = calendar.dateComponents([.day], from: now, to: endOfYear).day! + 1
                    
                    return "\(daysIn)-\(daysLeft)"
                }(),
                font: .custom("open_sans_light ", size: geometry.size.width * 0.13),
                lineSpacing: 0
            )
            .frame(width: geometry.size.width / 1.04, height: geometry.size.height / 1.3, alignment: .topTrailing)
            CustomTextView(
                text: {
                    let calendar = Calendar.current
                    let now = Date()
                    
                    let month = calendar.component(.month, from: now)
                    let day = calendar.component(.day, from: now)
                    
                    return "\(month)- \(day)"
                }(),
                font: .custom("open_sans_light ", size: geometry.size.width * 0.13),
                lineSpacing: 0
            )
            .frame(width: geometry.size.width / 1.08, height: geometry.size.height / 2.25, alignment: .topTrailing)
            if Calendar.current.component(.hour, from: Date()) > 12 && !hour24 {
                CustomTextView(text: "\(Calendar.current.component(.hour, from: Date()) - 12):\(String(format: "%02d", Calendar.current.component(.minute, from: Date())))", font: .custom("7-segment", size: geometry.size.width * 0.36), lineSpacing: 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.30)
            } else {
                CustomTextView(text: "\(String(format: "%02d", Calendar.current.component(.hour, from: Date()))):\(String(format: "%02d", Calendar.current.component(.minute, from: Date())))", font: .custom("7-segment", size: geometry.size.width * 0.36), lineSpacing: 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.30)
            }
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: geometry.size.width * 0.08))
                    .foregroundColor(bleManagerVal.heartBPM != 0 ? colorText : .gray)
                    .opacity(bleManagerVal.heartBPM != 0 ? 1.0 : 0.5)
                if bleManagerVal.heartBPM != 0 {
                    CustomTextView(text: String(Int(bleManagerVal.heartBPM)), font: .custom("open_sans_light", size: geometry.size.width * 0.11), lineSpacing: 0)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
            .padding(.leading, 10)
            .padding(.bottom, bleManagerVal.heartBPM != 0 ? 0 : -4)
            HStack(spacing: 4) {
                Image(systemName: "shoeprints.fill")
                    .rotationEffect(Angle(degrees: 90))
                    .font(.system(size: geometry.size.width * 0.08))
                CustomTextView(text: "\(bleManagerVal.stepCount)", font: .custom("open_sans_light", size: geometry.size.width * 0.11), lineSpacing: 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomTrailing)
            .padding(.trailing, 10)
            .padding(.bottom, -4)
        }
        .foregroundColor(colorText)
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct CustomTextView: View {
    var text: String
    var font: Font
    var lineSpacing: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(text.components(separatedBy: "\n"), id: \.self) { line in
                Text(line)
                    .font(font)
            }
        }
    }
}

#Preview {
    NavigationView {
        GeometryReader { geometry in
            WatchFaceView(watchface: .constant(4))
                .padding(22)
                .frame(width: geometry.size.width / 1.65, height: geometry.size.width / 1.65, alignment: .center)
                .clipped(antialiased: true)
        }
    }
}
