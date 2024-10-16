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
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    let date = Date()
    
    @Binding var watchface: UInt8?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("WatchScreen")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                ZStack {
                    ZStack {
                        switch watchface == nil ? deviceManager.settings.watchFace : watchface {
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
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
    
    func getColor(for pts: PineTimeStyleColor) -> Color {
        switch pts {
        case .time:
            switch deviceManager.settings.pineTimeStyle.ColorTime {
            case .White:
                return .white
            case .Silver:
                return .silver
            case .Gray:
                return .gray
            case .Black:
                return .black
            case .Red:
                return .red
            case .Maroon:
                return .maroon
            case .Yellow:
                return .yellow
            case .Olive:
                return .olive
            case .Lime:
                return .lime
            case .Green:
                return .green
            case .Cyan:
                return .cyan
            case .Teal:
                return .teal
            case .Blue:
                return .blue
            case .Navy:
                return .navy
            case .Magenta:
                return Color(.magenta)
            case .Purple:
                return .white
            case .Orange:
                return .orange
            case .Pink:
                return .pink
            }
        case .background:
            switch deviceManager.settings.pineTimeStyle.ColorBG {
            case .White:
                return .white
            case .Silver:
                return .silver
            case .Gray:
                return .gray
            case .Black:
                return .black
            case .Red:
                return .red
            case .Maroon:
                return .maroon
            case .Yellow:
                return .yellow
            case .Olive:
                return .olive
            case .Lime:
                return .lime
            case .Green:
                return .green
            case .Cyan:
                return .cyan
            case .Teal:
                return .teal
            case .Blue:
                return .blue
            case .Navy:
                return .navy
            case .Magenta:
                return Color(.magenta)
            case .Purple:
                return .white
            case .Orange:
                return .orange
            case .Pink:
                return .pink
            }
        case .sidebar:
            switch deviceManager.settings.pineTimeStyle.ColorBar {
            case .White:
                return .white
            case .Silver:
                return .silver
            case .Gray:
                return .gray
            case .Black:
                return .black
            case .Red:
                return .red
            case .Maroon:
                return .maroon
            case .Yellow:
                return .yellow
            case .Olive:
                return .olive
            case .Lime:
                return .lime
            case .Green:
                return .green
            case .Cyan:
                return .cyan
            case .Teal:
                return .teal
            case .Blue:
                return .blue
            case .Navy:
                return .navy
            case .Magenta:
                return Color(.magenta)
            case .Purple:
                return .white
            case .Orange:
                return .orange
            case .Pink:
                return .pink
            }
        }
    }
    
    enum PineTimeStyleColor {
        case time
        case background
        case sidebar
    }
    
    var body: some View {
        ZStack {
            getColor(for: .background)
            if !deviceManager.hour24 {
                CustomTextView(text: Calendar.current.component(.hour, from: Date()) >= 12 ? "P\nM" : "A\nM", font: .custom("JetBrainsMono-ExtraBold", size: geometry.size.width * 0.075), lineSpacing: -4)
                    .foregroundColor(getColor(for: .time))
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
            }
            if Calendar.current.component(.hour, from: Date()) >= 12 && !deviceManager.hour24 {
                let currentHour = Calendar.current.component(.hour, from: Date())
                let hour24 = currentHour > 12 ? currentHour - 12 : (currentHour == 0 ? 12 : currentHour)
                let hourString = String(format: "%02d", hour24)
                let minuteString = String(format: "%02d", Calendar.current.component(.minute, from: Date()))
                
                CustomTextView(text: "\(hourString)\n\(minuteString)", font: .custom("OpenSans-light", size: geometry.size.width * 0.62), lineSpacing: -geometry.size.width * 0.35)
                    .foregroundColor(getColor(for: .time))
                    .position(x: geometry.size.width / 2.3, y: geometry.size.height / 2.0)
            } else {
                let hourString = String(format: "%02d", Calendar.current.component(.hour, from: Date()))
                let minuteString = String(format: "%02d", Calendar.current.component(.minute, from: Date()))
                
                CustomTextView(text: "\(hourString)\n\(minuteString)", font: .custom("OpenSans-light", size: geometry.size.width * 0.62), lineSpacing: -geometry.size.width * 0.35)
                    .foregroundColor(getColor(for: .time))
                    .position(x: geometry.size.width / 2.3, y: geometry.size.height / 2.0)
            }
            GeometryReader { geometry in
                Rectangle()
                    .foregroundColor(getColor(for: .sidebar))
                    .position(x: geometry.size.width - ((geometry.size.width / 6.0) / 2), y: geometry.size.height / 2 - 2)
                    .frame(width: geometry.size.width / 6.0, height: geometry.size.height + 4, alignment: .center)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct AnalogWF: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            let hour = Calendar.current.component(.hour, from: Date())
            let hour24 = Double(hour % 12 == 0 ? 12 : hour % 12)
            let minute = Double(Calendar.current.component(.minute, from: Date()))
            
            Image("AnalogFace")
                .resizable()
            Image("AnalogHour")
                .resizable()
                .rotationEffect(Angle(degrees: ((hour24 * 60) + minute) / 2))
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
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            if !deviceManager.hour24 {
                CustomTextView(text: Calendar.current.component(.hour, from: Date()) > 12 ? "PM" : "AM", font: .custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085), lineSpacing: 0)
                    .foregroundColor(.white)
                    .frame(width: geometry.size.width, height: geometry.size.height / 1.95, alignment: .topTrailing)
            }
            if Calendar.current.component(.hour, from: Date()) > 12 && !deviceManager.hour24 {
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
            CustomTextView(text: {
                let current = Date()
                let formatter = DateFormatter()
                
                formatter.dateFormat = "EEE MMM d yyyy"
                
                return formatter.string(from: current).uppercased()
            }(), font: .custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085), lineSpacing: 0)
                .foregroundColor(Color(.lightGray))
                .frame(width: geometry.size.width, height: geometry.size.height / 1.6, alignment: .bottom)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct InfineatWF: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var geometry: GeometryProxy
    
    let orangeColors: [Color] = [
        Color(red: 0xfd / 255.0, green: 0x87 / 255.0, blue: 0x2b / 255.0),
        Color(red: 0xf0 / 255.0, green: 0x59 / 255.0, blue: 0x3b / 255.0),
        Color.maroon,
        Color(red: 0xfd / 255.0, green: 0x7a / 255.0, blue: 0x0a / 255.0),
        Color(red: 0xe8 / 255.0, green: 0x51 / 255.0, blue: 0x02 / 255.0),
        Color(red: 0xea / 255.0, green: 0x1c / 255.0, blue: 0x00 / 255.0)
    ]
    
    let blueColors: [Color] = [
        Color(red: 0xe7 / 255.0, green: 0xf8 / 255.0, blue: 0xff / 255.0),
        Color(red: 0x16 / 255.0, green: 0x36 / 255.0, blue: 0xff / 255.0),
        Color(red: 0x18 / 255.0, green: 0x2a / 255.0, blue: 0x8b / 255.0),
        Color(red: 0xe7 / 255.0, green: 0xf8 / 255.0, blue: 0xff / 255.0),
        Color(red: 0x59 / 255.0, green: 0x91 / 255.0, blue: 0xff / 255.0),
        Color(red: 0x16 / 255.0, green: 0x36 / 255.0, blue: 0xff / 255.0)
    ]
    
    let greenColors: [Color] = [
        Color(red: 0xb8 / 255.0, green: 0xff / 255.0, blue: 0x9b / 255.0),
        Color(red: 0x08 / 255.0, green: 0x86 / 255.0, blue: 0x08 / 255.0),
        Color(red: 0x00 / 255.0, green: 0x4a / 255.0, blue: 0x00 / 255.0),
        Color(red: 0xb8 / 255.0, green: 0xff / 255.0, blue: 0x9b / 255.0),
        Color(red: 0x62 / 255.0, green: 0xd5 / 255.0, blue: 0x15 / 255.0),
        Color(red: 0x00 / 255.0, green: 0x74 / 255.0, blue: 0x00 / 255.0)
    ]
    
    let rainbowColors: [Color] = [
        Color(red: 0x2d / 255.0, green: 0xa4 / 255.0, blue: 0x00 / 255.0),
        Color(red: 0xac / 255.0, green: 0x09 / 255.0, blue: 0xc4 / 255.0),
        Color(red: 0xfe / 255.0, green: 0x03 / 255.0, blue: 0x03 / 255.0),
        Color(red: 0x0d / 255.0, green: 0x57 / 255.0, blue: 0xff / 255.0),
        Color(red: 0xe0 / 255.0, green: 0xb9 / 255.0, blue: 0x00 / 255.0),
        Color(red: 0xe8 / 255.0, green: 0x51 / 255.0, blue: 0x02 / 255.0)
    ]
    
    let grayColors: [Color] = [
        Color(red: 0xee / 255.0, green: 0xee / 255.0, blue: 0xee / 255.0),
        Color(red: 0x98 / 255.0, green: 0x95 / 255.0, blue: 0x9b / 255.0),
        Color(red: 0x19 / 255.0, green: 0x19 / 255.0, blue: 0x19 / 255.0),
        Color(red: 0xee / 255.0, green: 0xee / 255.0, blue: 0xee / 255.0),
        Color(red: 0x91 / 255.0, green: 0x91 / 255.0, blue: 0x91 / 255.0),
        Color(red: 0x3a / 255.0, green: 0x3a / 255.0, blue: 0x3a / 255.0)
    ]
    
    let nordBlueColors: [Color] = [
        Color(red: 0xc3 / 255.0, green: 0xda / 255.0, blue: 0xf2 / 255.0),
        Color(red: 0x4d / 255.0, green: 0x78 / 255.0, blue: 0xce / 255.0),
        Color(red: 0x15 / 255.0, green: 0x34 / 255.0, blue: 0x51 / 255.0),
        Color(red: 0xc3 / 255.0, green: 0xda / 255.0, blue: 0xf2 / 255.0),
        Color(red: 0x5d / 255.0, green: 0x8a / 255.0, blue: 0xd2 / 255.0),
        Color(red: 0x21 / 255.0, green: 0x51 / 255.0, blue: 0x8a / 255.0)
    ]
    
    let nordGreenColors: [Color] = [
        Color(red: 0xd5 / 255.0, green: 0xf0 / 255.0, blue: 0xe9 / 255.0),
        Color(red: 0x23 / 255.0, green: 0x83 / 255.0, blue: 0x73 / 255.0),
        Color(red: 0x1d / 255.0, green: 0x41 / 255.0, blue: 0x3f / 255.0),
        Color(red: 0xd5 / 255.0, green: 0xf0 / 255.0, blue: 0xe9 / 255.0),
        Color(red: 0x2f / 255.0, green: 0xb8 / 255.0, blue: 0xa2 / 255.0),
        Color(red: 0x11 / 255.0, green: 0x70 / 255.0, blue: 0x5a / 255.0)
    ]
    
    func infineatColor(for item: InfineatItem) -> Color {
        let colorIndex = deviceManager.settings.watchFaceInfineat.colorIndex
        
        switch item {
        case .base:
            switch colorIndex {
            case 0:
                return orangeColors[2]
            case 1:
                return blueColors[2]
            case 2:
                return greenColors[2]
            case 3:
                return rainbowColors[2]
            case 4:
                return grayColors[2]
            case 5:
                return nordBlueColors[2]
            case 6:
                return nordGreenColors[2]
            default:
                return orangeColors[2]
            }
        case .bottom:
            switch colorIndex {
            case 0:
                return orangeColors[1]
            case 1:
                return blueColors[1]
            case 2:
                return greenColors[1]
            case 3:
                return rainbowColors[1]
            case 4:
                return grayColors[1]
            case 5:
                return nordBlueColors[1]
            case 6:
                return nordGreenColors[1]
            default:
                return orangeColors[1]
            }
        case .topTop:
            switch colorIndex {
            case 0:
                return orangeColors[4]
            case 1:
                return blueColors[4]
            case 2:
                return greenColors[4]
            case 3:
                return rainbowColors[4]
            case 4:
                return grayColors[4]
            case 5:
                return nordBlueColors[4]
            case 6:
                return nordGreenColors[4]
            default:
                return orangeColors[4]
            }
        case .topBottom:
            switch colorIndex {
            case 0:
                return orangeColors[5]
            case 1:
                return blueColors[5]
            case 2:
                return greenColors[5]
            case 3:
                return rainbowColors[5]
            case 4:
                return grayColors[5]
            case 5:
                return nordBlueColors[5]
            case 6:
                return nordGreenColors[5]
            default:
                return orangeColors[5]
            }
        case .midBottom:
            switch colorIndex {
            case 0:
                return orangeColors[3]
            case 1:
                return blueColors[3]
            case 2:
                return greenColors[3]
            case 3:
                return rainbowColors[3]
            case 4:
                return grayColors[3]
            case 5:
                return nordBlueColors[3]
            case 6:
                return nordGreenColors[3]
            default:
                return orangeColors[3]
            }
        case .midTop:
            switch colorIndex {
            case 0:
                return orangeColors[0]
            case 1:
                return blueColors[0]
            case 2:
                return greenColors[0]
            case 3:
                return rainbowColors[0]
            case 4:
                return grayColors[0]
            case 5:
                return nordBlueColors[0]
            case 6:
                return nordGreenColors[0]
            default:
                return orangeColors[0]
            }
        }
    }
    
    var body: some View {
        ZStack {
            if !deviceManager.hour24 {
                CustomTextView(text: Calendar.current.component(.hour, from: Date()) >= 12 ? "PM" : "AM", font: .custom("Teko-Light", size: geometry.size.width * 0.125), lineSpacing: 0)
                    .foregroundColor(.white)
                    .frame(width: geometry.size.width, height: geometry.size.height / 1.35, alignment: .topTrailing)
            }
            if Calendar.current.component(.hour, from: Date()) >= 12 && !deviceManager.hour24 {
                let currentHour = Calendar.current.component(.hour, from: Date())
                let hour24 = currentHour % 12 == 0 ? 12 : currentHour % 12
                let hourString = String(format: "%02d", hour24)
                let minuteString = String(format: "%02d", Calendar.current.component(.minute, from: Date()))
                
                VStack(alignment: .center, spacing: -28) {
                    Text(hourString)
                    Text(minuteString)
                }
                .font(.custom("BebasNeue-Regular", size: geometry.size.width * 0.44))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.9)
            } else {
                let hourString = String(format: "%02d", Calendar.current.component(.hour, from: Date()))
                let minuteString = String(format: "%02d", Calendar.current.component(.minute, from: Date()))
                
                VStack(alignment: .center, spacing: -28) {
                    Text(hourString)
                    Text(minuteString)
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
                CustomTextView(text: "\(bleManager.stepCount)", font: .custom("Teko-Light", size: geometry.size.width * 0.118), lineSpacing: 0)
            }
            .foregroundColor(.gray)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
            .padding(.bottom, -16)
            ZStack {
                Rectangle()
                    .frame(width: 19)
                    .frame(height: geometry.size.height / 1.5, alignment: .topLeading)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                    .foregroundColor(infineatColor(for: .midTop))
                    .rotationEffect(Angle(degrees: 49))
                    .offset(x: -36, y: -48)
                Rectangle()
                    .frame(width: 19)
                    .frame(height: geometry.size.height / 1.5, alignment: .bottomLeading)
                    .frame(maxHeight: .infinity, alignment: .bottomLeading)
                    .foregroundColor(infineatColor(for: .bottom))
                    .opacity(0.8)
                    .rotationEffect(Angle(degrees: -22))
                    .offset(x: -16, y: 14)
                Rectangle()
                    .frame(width: 26, alignment: .leading)
                    .offset(x: -9)
                    .foregroundColor(infineatColor(for: .base))
                Rectangle()
                    .frame(width: 26)
                    .frame(height: geometry.size.height / 1.5, alignment: .topLeading)
                    .frame(maxHeight: .infinity, alignment: .bottomLeading)
                    .foregroundColor(infineatColor(for: .midBottom))
                    .rotationEffect(Angle(degrees: -42))
                    .offset(x: -31, y: 38)
                ZStack {
                    DiamondShape()
                    // .fill(bleManager.infineatWatchFace?.showSideCover ?? true ? Color.white : Color.clear)
                        .fill(Color.white)
                        .frame(width: 50, height: 75)
                        .offset(x: -5)
                    Image("pine_logo")
                        .resizable()
                        .frame(width: 19, height: 25)
                }
                Rectangle()
                    .frame(width: 38)
                    .frame(height: geometry.size.height / 1.3, alignment: .topLeading)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                    .foregroundColor(infineatColor(for: .topTop))
                    .rotationEffect(Angle(degrees: 18))
                    .offset(x: -32, y: -16)
                Rectangle()
                    .frame(width: 38)
                    .frame(height: geometry.size.height / 1.3, alignment: .topLeading)
                    .frame(maxHeight: .infinity, alignment: .bottomLeading)
                    .foregroundColor(infineatColor(for: .topBottom))
                    .rotationEffect(Angle(degrees: -18))
                    .offset(x: -32, y: 16)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        .clipped()
    }
}

struct TerminalWF: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var geometry: GeometryProxy
    
    let currentHour = Calendar.current.component(.hour, from: Date())
    let currentMinute = Calendar.current.component(.minute, from: Date())
    let currentSecond = Calendar.current.component(.second, from: Date())
    
    var body: some View {
        ZStack {
            Text("user@watch:~ $ now")
                .foregroundColor(.white)
                .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 6.5)
            if !deviceManager.hour24 {
                Group {
                    Text("[TIME]").foregroundColor(.white) + Text("\(String(format: "%02d", currentHour % 12 == 0 ? 12 : currentHour % 12)):\(String(format: "%02d", currentMinute)):\(String(format: "%02d", currentSecond)) \(currentHour >= 12 ? "PM" : "AM")").foregroundColor(.green)
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
                Text("[STEP]").foregroundColor(.white) + Text("\(bleManager.stepCount) steps").foregroundColor(Color(red: 1, green: 0.2, blue: 0.5))
            }
            .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.95)
            Group {
                Text("[L_HR]").foregroundColor(.white) + Text("\(bleManager.heartRate == 0 ? "---" : "\(bleManager.heartRate)")").foregroundColor(.red)
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
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.28)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct CasioWF: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var geometry: GeometryProxy
    
    let colorText: Color = Color(red: 152 / 255.0, green: 182 / 255.0, blue: 154 / 255.0)
    
    var body: some View {
        ZStack {
            Image(.casio)
                .resizable()
                .aspectRatio(contentMode: .fill)
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
            .frame(width: geometry.size.width / 1.04, height: geometry.size.height / 1.15, alignment: .topLeading)
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
                font: .custom("7-Segment", size: geometry.size.width * 0.16),
                lineSpacing: 0
            )
            .frame(width: geometry.size.width / 1.04, height: geometry.size.height / 1.25, alignment: .topTrailing)
            CustomTextView(
                text: {
                    let calendar = Calendar.current
                    let now = Date()
                    
                    let month = calendar.component(.month, from: now)
                    let day = calendar.component(.day, from: now)
                    
                    return "\(month)-\(day)"
                }(),
                font: .custom("7-Segment", size: geometry.size.width * 0.16),
                lineSpacing: 0
            )
            .frame(width: geometry.size.width / 1.08, height: geometry.size.height / 2.25, alignment: .topTrailing)
            CustomTextView(text: {
                let currentHour = Calendar.current.component(.hour, from: Date())
                var hourString = ""
                
                if deviceManager.hour24 {
                    hourString = String(format: "%d", currentHour)
                } else {
                    let hour24 = currentHour % 12 == 0 ? 12 : currentHour
                    hourString = "\(hour24)"
                }
                let minuteString = String(format: "%02d", Calendar.current.component(.minute, from: Date()))
                
                return "\(hourString):\(minuteString)"
            }(), font: .custom("7-Segment", size: geometry.size.width * 0.44), lineSpacing: 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .position(x: geometry.size.width / 2.1, y: geometry.size.height / 1.4)
            if !deviceManager.hour24 {
                CustomTextView(text: "\(Calendar.current.component(.hour, from: Date()) >= 12 ? "P" : "A")", font: .custom("JetBrainsMono-Bold", size: geometry.size.width * 0.08), lineSpacing: 0)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                    .padding(.leading, 6)
                    .padding(.top, -5)
            }
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

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topPoint = CGPoint(x: rect.midX, y: rect.minY)
        let rightPoint = CGPoint(x: rect.maxX, y: rect.midY)
        let bottomPoint = CGPoint(x: rect.midX, y: rect.maxY)
        let leftPoint = CGPoint(x: rect.minX, y: rect.midY)
        
        path.move(to: topPoint)
        
        path.addLine(to: rightPoint)
        path.addLine(to: bottomPoint)
        path.addLine(to: leftPoint)
        path.closeSubpath()
        
        return path
    }
}

enum InfineatItem {
    case base
    case bottom
    case topTop
    case topBottom
    case midBottom
    case midTop
}

#Preview {
    NavigationView {
        GeometryReader { geometry in
            WatchFaceView(watchface: .constant(5))
                .padding(22)
                .frame(width: geometry.size.width / 1.65, height: geometry.size.width / 1.65, alignment: .center)
                .clipped(antialiased: true)
        }
    }
}
