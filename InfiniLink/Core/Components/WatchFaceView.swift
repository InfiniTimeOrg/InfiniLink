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
    @ObservedObject var catalog = WatchFaceCatalog.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var date = Date()
    
    let settings: Settings?
    let device: Device?
    
    init(settings: Settings? = nil, device: Device? = nil) {
        self.settings = settings
        self.device = device
    }
    
    private var faceSettings: Settings {
        settings ?? device.map { Settings(device: $0) } ?? deviceManager.settings
    }
    private var firmware: String {
        device?.firmware ?? deviceManager.firmware
    }
    
    // Share of the watch image taken up by the screen
    private static let screenFraction: CGFloat = 0.53
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let screenSize = size * Self.screenFraction
            
            ZStack {
                Image(.watchScreen)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                screen
                    .frame(width: 240, height: 240)
                    .clipped()
                    .scaleEffect(screenSize / 240)
                    .frame(width: screenSize, height: screenSize)
                    .offset(y: -size * 0.011)
                    .brightness(colorScheme == .dark ? 0.015 : 0.125)
                Image(.watchBorder)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .brightness(colorScheme == .dark ? 0.0 : 0.04)
            }
            .frame(width: size, height: size)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { newDate in
            self.date = newDate
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Watch face preview"))
    }
    
    // Drawn at the watch's 240x240 resolution
    private var screen: some View {
        let settings = faceSettings
        let entry = catalog.face(at: settings.watchFace, firmware: firmware)
        
        return ZStack {
            switch entry?.id {
            case "digital":
                Digital(date: $date, settings: settings)
            case "analog":
                Analog(date: $date)
            case "pineTimeStyle":
                PineTimeStyle(date: $date, settings: settings)
            case "terminal":
                Terminal(date: $date, settings: settings, firmware: firmware)
            case "infineat":
                Infineat(date: $date, settings: settings)
            case "casio":
                Casio(date: $date, settings: settings)
            case "numerals":
                Numerals(date: $date, settings: settings)
            case "prideFlag":
                PrideFlag(date: $date, flag: settings.prideFlag)
            default:
                CustomWatchFace(face: entry, index: settings.watchFace)
            }
        }
    }
}

extension Settings {
    init(device: Device) {
        self.init()
        
        clockType = ClockType(rawValue: UInt8(clamping: device.clockType)) ?? .H24
        watchFace = UInt8(clamping: device.watchface)
        if let pts = device.pineTimeStyle {
            pineTimeStyle = PineTimeStyleData(
                ColorTime: Colors(rawValue: UInt8(clamping: pts.colorTime)) ?? .Teal,
                ColorBar: Colors(rawValue: UInt8(clamping: pts.colorBar)) ?? .Teal,
                ColorBG: Colors(rawValue: UInt8(clamping: pts.colorBG)) ?? .Black,
                gaugeStyle: PTSGaugeStyle(rawValue: UInt8(clamping: pts.guageStyle)) ?? .Full,
                weatherEnable: PTSWeather(rawValue: UInt8(clamping: pts.weatherEnable)) ?? .Off
            )
        }
        if let infineat = device.watchFaceInfineat {
            watchFaceInfineat = WatchFaceInfineat(showSideCover: infineat.showSideCover, colorIndex: UInt8(clamping: infineat.colorIndex))
        }
        prideFlag = UInt8(clamping: device.prideFlag)
    }
}

struct CustomWatchFace: View {
    @ObservedObject var catalog = WatchFaceCatalog.shared
    
    let face: WatchFaceEntry?
    let index: UInt8
    
    var body: some View {
        if let face, let image = catalog.image(for: face) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Text(face?.name ?? catalog.name(for: index))
                .font(.system(size: 39, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(21)
        }
    }
}

struct PineTimeStyle: View {
    @Binding var date: Date
    
    let settings: Settings
    
    private func color(_ color: Colors) -> Color {
        switch color {
        case .White:
            return .white
        case .Silver:
            return .rgb(0xc0, 0xc0, 0xc0)
        case .Gray:
            return .rgb(0x80, 0x80, 0x80)
        case .Black:
            return .black
        case .Red:
            return .rgb(0xff, 0x00, 0x00)
        case .Maroon:
            return .rgb(0xb0, 0x00, 0x00)
        case .Yellow:
            return .rgb(0xff, 0xff, 0x00)
        case .Olive:
            return .rgb(0xb0, 0xb0, 0x00)
        case .Lime:
            return .rgb(0x00, 0xff, 0x00)
        case .Green:
            return .rgb(0x00, 0xb0, 0x00)
        case .Cyan:
            return .rgb(0x00, 0xff, 0xff)
        case .Teal:
            return .rgb(0x00, 0xb0, 0xb0)
        case .Blue:
            return .rgb(0x00, 0x00, 0xff)
        case .Navy:
            return .rgb(0x00, 0x00, 0xb0)
        case .Magenta:
            return .rgb(0xff, 0x00, 0xff)
        case .Purple:
            return .rgb(0xb0, 0x00, 0xb0)
        case .Orange:
            return .rgb(0xff, 0xa5, 0x00)
        case .Pink:
            return .rgb(0xff, 0xae, 0xc9)
        }
    }
    
    var body: some View {
        let hour = Calendar.current.component(.hour, from: date)
        let is24Hour = settings.clockType == .H24
        let displayHour = is24Hour ? hour : (hour % 12 == 0 ? 12 : hour % 12)
        let timeColor = color(settings.pineTimeStyle.ColorTime)
        
        ZStack {
            color(settings.pineTimeStyle.ColorBG)
            if !is24Hour {
                CustomTextView(text: hour >= 12 ? "P\nM" : "A\nM", font: .custom("JetBrainsMono-Bold", size: 20), lineSpacing: -5)
                    .foregroundColor(timeColor)
                    .frame(width: 240, height: 240, alignment: .bottomLeading)
            }
            CustomTextView(text: "\(String(format: "%02d", displayHour))\n\(String(format: "%02d", Calendar.current.component(.minute, from: date)))", font: .custom("OpenSans-light", size: 140), lineSpacing: -78)
                .foregroundColor(timeColor)
                .position(x: 110, y: 120)
            Rectangle()
                .foregroundColor(color(settings.pineTimeStyle.ColorBar))
                .frame(width: 40, height: 240)
                .position(x: 220, y: 120)
        }
        .frame(width: 240, height: 240)
    }
}

struct Analog: View {
    @Binding var date: Date
    
    var minute: Double {
        return Double(Calendar.current.component(.minute, from: date))
    }
    var hour: Double {
        let hour = Calendar.current.component(.hour, from: date)
        return Double(hour % 12 == 0 ? 12 : hour % 12)
    }
    
    var body: some View {
        ZStack {
            Image(.analogFace)
                .resizable()
                .aspectRatio(contentMode: .fit)
            Image(.analogHour)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .rotationEffect(Angle(degrees: ((hour * 60) + minute) / 2))
            Image(.analogMin)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .rotationEffect(Angle(degrees: minute * 6))
            Image(.analogSec)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .rotationEffect(Angle(degrees: Double(Calendar.current.component(.second, from: date)) * 6))
        }
        .frame(width: 240, height: 240)
    }
}

struct PrideFlag: View {
    @Binding var date: Date
    
    let flag: UInt8
    
    private var stripes: [Color] {
        switch flag {
        case 1:
            return [.rgb(0x00, 0xbf, 0xf3), .rgb(0xf4, 0x9a, 0xc1), .white, .rgb(0xf4, 0x9a, 0xc1), .rgb(0x00, 0xbf, 0xf3)]
        case 2:
            return [.rgb(0xd6, 0x02, 0x70), .rgb(0xd6, 0x02, 0x70), .rgb(0x9b, 0x4f, 0x96), .rgb(0x00, 0x38, 0xa8), .rgb(0x00, 0x38, 0xa8)]
        case 3:
            return [.rgb(0xff, 0x00, 0x00), .rgb(0xef, 0x76, 0x27), .rgb(0xff, 0x9b, 0x55), .white, .rgb(0xd4, 0x61, 0xa6), .rgb(0xb5, 0x56, 0x90), .rgb(0xa5, 0x00, 0x62)]
        default:
            return [.rgb(0x07, 0x8d, 0x70), .rgb(0x26, 0xce, 0xaa), .rgb(0x98, 0xe8, 0xc1), .white, .rgb(0x00, 0xbf, 0xf3), .rgb(0x50, 0x49, 0xcc), .rgb(0x3d, 0x1a, 0x78)]
        }
    }
    
    var body: some View {
        let stripes = stripes
        let calendar = Calendar.current
        
        ZStack {
            ForEach(stripes.indices, id: \.self) { index in
                stripes[index]
                    .frame(width: 240, height: CGFloat(240 / stripes.count + 1))
                    .lvAlign(.topLeading, y: CGFloat(index * 240 / stripes.count))
            }
            Text(String(format: "%02d:%02d:%02d", calendar.component(.hour, from: date), calendar.component(.minute, from: date), calendar.component(.second, from: date)))
                .font(.custom("JetBrainsMono-Regular", size: 42))
                .foregroundColor(flag == 2 ? .white : .black)
                .lvAlign(.center, y: -1)
        }
        .frame(width: 240, height: 240)
    }
}

struct Digital: View {
    @Binding var date: Date
    
    let settings: Settings
    
    var body: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let is24Hour = settings.clockType == .H24
        
        ZStack {
            if is24Hour {
                Text(String(format: "%02d:%02d", hour, minute))
                    .font(.custom("JetBrainsMono-ExtraBold", size: 80))
                    .lvAlign(.center)
            } else {
                Text(String(format: "%2d:%02d", hour % 12 == 0 ? 12 : hour % 12, minute))
                    .font(.custom("JetBrainsMono-ExtraBold", size: 80))
                    .lvAlign(.trailing)
                // Aligned while empty, so the text starts at its right edge
                Text(hour >= 12 ? "PM" : "AM")
                    .font(.custom("JetBrainsMono-Bold", size: 20))
                    .fixedSize()
                    .frame(width: 0, alignment: .leading)
                    .lvAlign(.trailing, x: -30, y: -55)
            }
            Text(watchString(date, is24Hour ? "EEE d MMM yyyy" : "EEE MMM d yyyy").uppercased())
                .font(.custom("JetBrainsMono-Bold", size: 20))
                .foregroundColor(.rgb(0x99, 0x99, 0x99))
                .lvAlign(.center, y: 60)
        }
        .foregroundColor(.white)
        .frame(width: 240, height: 240)
    }
}

struct Infineat: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @Binding var date: Date
    
    let settings: Settings
    
    // Values from the firmware, in watch pixels
    private static let lines: [(CGPoint, CGPoint)] = [
        (CGPoint(x: 30, y: 25), CGPoint(x: 68, y: -8)),
        (CGPoint(x: 26, y: 167), CGPoint(x: 43, y: 216)),
        (CGPoint(x: 27, y: 40), CGPoint(x: 27, y: 196)),
        (CGPoint(x: 12, y: 182), CGPoint(x: 65, y: 249)),
        (CGPoint(x: 17, y: 99), CGPoint(x: 17, y: 144)),
        (CGPoint(x: 14, y: 81), CGPoint(x: 40, y: 127)),
        (CGPoint(x: 14, y: 163), CGPoint(x: 40, y: 118)),
        (CGPoint(x: -20, y: 124), CGPoint(x: 25, y: -11)),
        (CGPoint(x: -29, y: 89), CGPoint(x: 27, y: 254))
    ]
    private static let lineWidths: [CGFloat] = [18, 15, 14, 22, 20, 18, 18, 52, 48]
    private static let colorSchemes: [[Color]] = [
        [.rgb(0xfd, 0x87, 0x2b), .rgb(0xdb, 0x33, 0x16), .rgb(0x6f, 0x10, 0x00), .rgb(0xfd, 0x7a, 0x0a), .white, .white, .white, .rgb(0xe8, 0x51, 0x02), .rgb(0xea, 0x1c, 0x00)],
        [.rgb(0xe7, 0xf8, 0xff), .rgb(0x22, 0x32, 0xd0), .rgb(0x18, 0x2a, 0x8b), .rgb(0xe7, 0xf8, 0xff), .white, .white, .white, .rgb(0x59, 0x91, 0xff), .rgb(0x16, 0x36, 0xff)],
        [.rgb(0xb8, 0xff, 0x9b), .rgb(0x08, 0x86, 0x08), .rgb(0x00, 0x4a, 0x00), .rgb(0xb8, 0xff, 0x9b), .white, .white, .white, .rgb(0x62, 0xd5, 0x15), .rgb(0x00, 0x74, 0x00)],
        [.rgb(0x2d, 0xa4, 0x00), .rgb(0xac, 0x09, 0xc4), .rgb(0xfe, 0x03, 0x03), .rgb(0x0d, 0x57, 0xff), .white, .white, .white, .rgb(0xe0, 0xb9, 0x00), .rgb(0xe8, 0x51, 0x02)],
        [.rgb(0xee, 0xee, 0xee), .rgb(0x98, 0x95, 0x9b), .rgb(0x19, 0x19, 0x19), .rgb(0xee, 0xee, 0xee), .white, .white, .white, .rgb(0x91, 0x91, 0x91), .rgb(0x3a, 0x3a, 0x3a)],
        [.rgb(0xc3, 0xda, 0xf2), .rgb(0x4d, 0x78, 0xce), .rgb(0x15, 0x34, 0x51), .rgb(0xc3, 0xda, 0xf2), .white, .white, .white, .rgb(0x5d, 0x8a, 0xd2), .rgb(0x21, 0x51, 0x8a)],
        [.rgb(0xd5, 0xf0, 0xe9), .rgb(0x23, 0x83, 0x73), .rgb(0x1d, 0x41, 0x3f), .rgb(0xd5, 0xf0, 0xe9), .white, .white, .white, .rgb(0x2f, 0xb8, 0xa2), .rgb(0x11, 0x70, 0x5a)]
    ]
    private static let gray = Color.rgb(0x99, 0x99, 0x99)
    
    private var colors: [Color] {
        let index = Int(settings.watchFaceInfineat.colorIndex)
        return Self.colorSchemes[Self.colorSchemes.indices.contains(index) ? index : 0]
    }
    
    // Overlay so the text doesn't push the layout around
    private func label(_ text: String, font: String, size: CGFloat, color: Color, centerX: CGFloat, baseline: CGFloat, leading: Bool = false) -> some View {
        Color.clear
            .frame(width: 0, height: 0)
            .overlay(alignment: Alignment(horizontal: leading ? .leading : .center, vertical: .firstTextBaseline)) {
                Text(text)
                    .font(.custom(font, size: size))
                    .foregroundColor(color)
                    .fixedSize()
            }
            .offset(x: centerX, y: baseline)
    }
    
    var body: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let is24Hour = settings.clockType == .H24
        let showSideCover = settings.watchFaceInfineat.showSideCover
        let battery = bleManager.hasLoadedBatteryLevel ? Int(bleManager.batteryLevel) : 100
        
        ZStack(alignment: .topLeading) {
            Color.clear
            if showSideCover {
                Canvas { context, _ in
                    for (index, line) in Self.lines.enumerated() {
                        var path = Path()
                        path.move(to: line.0)
                        path.addLine(to: line.1)
                        context.stroke(path, with: .color(colors[index]), style: StrokeStyle(lineWidth: Self.lineWidths[index], lineCap: .butt))
                    }
                }
            }
            Image(.pineLogo)
                .resizable()
                .renderingMode(showSideCover ? .original : .template)
                .foregroundColor(.white)
                .frame(width: 23, height: 31)
                .lvAlign(.topLeading, x: 15, y: 106)
            (showSideCover ? colors[4] : .white)
                .opacity(190 / 255)
                .frame(width: 24, height: CGFloat(max(1, 32 * (100 - battery) / 100)))
                .lvAlign(.topLeading, x: 15, y: 105)
            label(String(format: "%02d", is24Hour ? hour : (hour % 12 == 0 ? 12 : hour % 12)), font: "BebasNeue-Regular", size: 120, color: .white, centerX: 120, baseline: is24Hour ? 103 : 108)
            label(String(format: "%02d", calendar.component(.minute, from: date)), font: "BebasNeue-Regular", size: 120, color: .white, centerX: 120, baseline: 202)
            if !is24Hour {
                label(hour >= 12 ? "PM" : "AM", font: "Teko-Light", size: 28, color: .white, centerX: 212, baseline: 46, leading: true)
            }
            Text(watchString(date, "EEE dd"))
                .font(.custom("Teko-Light", size: 28))
                .foregroundColor(Self.gray)
                .lvAlign(.top, x: 90, y: 110)
        }
        .foregroundColor(.white)
        .frame(width: 240, height: 240)
        .clipped()
    }
}

struct Terminal: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @Binding var date: Date
    
    let settings: Settings
    let firmware: String
    
    private var batteryColor: Color {
        let hue = (1 - exp(-4 * bleManager.batteryLevel / 100)) * 120
        return Color(hue: hue / 360, saturation: 1, brightness: 1)
    }
    
    private func row(_ index: Int) -> CGFloat {
        return 36.9 + CGFloat(index) * 21.5
    }
    
    private func line(_ text: Text, at index: Int) -> some View {
        text
            .font(.custom("JetBrainsMono-Bold", size: 20.4))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .position(x: 120, y: row(index))
    }
    
    var body: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let lightGray = Color.rgb(0xb0, 0xb0, 0xb0)
        // Weather row was added in 1.16
        let showsWeather = firmware.compare("1.16.0", options: .numeric) != .orderedAscending
        let time = settings.clockType == .H24 ? String(format: "%02d:%02d:%02d", hour, minute, second) : String(format: "%02d:%02d:%02d %@", hour % 12 == 0 ? 12 : hour % 12, minute, second, hour >= 12 ? "PM" : "AM")
        
        ZStack {
            line(Text("user@watch:~ $ now").foregroundColor(lightGray), at: 0)
            line(Text("[TIME] ") + Text(time).foregroundColor(.rgb(0x11, 0xcc, 0x55)), at: 1)
            line(Text("[DATE] ") + Text(String(format: "%04d-%02d-%02d", calendar.component(.year, from: date), calendar.component(.month, from: date), calendar.component(.day, from: date))).foregroundColor(.rgb(0x00, 0x7f, 0xff)), at: 2)
            line(Text("[BATT] ") + Text("\(Int(bleManager.batteryLevel))%").foregroundColor(batteryColor), at: 3)
            line(Text("[STEP] ") + Text("\(bleManager.stepCount) steps").foregroundColor(.rgb(0xff, 0xb0, 0x00)), at: 4)
            line(Text("[L_HR] ") + (bleManager.heartRate == 0 ? Text("---").foregroundColor(.rgb(0x50, 0x50, 0x50)) : Text("\(Int(bleManager.heartRate)) bpm").foregroundColor(.rgb(0xff, 0x40, 0x00))), at: 5)
            if showsWeather {
                line(Text("[WTHR] ") + Text("---").foregroundColor(.rgb(0xff, 0xdd, 0x00)), at: 6)
            }
            line(Text("[STAT] ") + Text("Connected").foregroundColor(.rgb(0x00, 0x50, 0xff)), at: showsWeather ? 7 : 6)
            line(Text("user@watch:~ $").foregroundColor(lightGray), at: showsWeather ? 8 : 7)
        }
        .frame(width: 240, height: 240)
    }
}

struct Casio: View {
    @Binding var date: Date
    
    let settings: Settings
    
    private let colorText = Color.rgb(0x98, 0xb6, 0x9a)
    
    var body: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let is24Hour = settings.clockType == .H24
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
        let weekday = calendar.component(.weekday, from: date) - 1
        // Same as strftime's %V in 24 hour mode and %U in 12 hour mode
        let weekNumber = is24Hour ? Calendar(identifier: .iso8601).component(.weekOfYear, from: date) : (dayOfYear - 1 + 7 - weekday) / 7
        
        ZStack {
            Image(.casio)
                .resizable()
                .aspectRatio(contentMode: .fill)
            CustomTextView(text: String(format: "WK%02d\n%@", weekNumber, watchString(date, "EEE").uppercased()), font: .custom("repetitionscrolling", size: 38.4), lineSpacing: 0)
                .frame(width: 230.8, height: 208.7, alignment: .topLeading)
            CustomTextView(text: String(format: "%3d-%3d", dayOfYear, daysInYear - dayOfYear), font: .custom("7-Segment", size: 38.4), lineSpacing: 0)
                .frame(width: 230.8, height: 192, alignment: .topTrailing)
            CustomTextView(text: String(format: "%3d-%2d", is24Hour ? day : month, is24Hour ? month : day), font: .custom("7-Segment", size: 38.4), lineSpacing: 0)
                .frame(width: 222.2, height: 106.7, alignment: .topTrailing)
            CustomTextView(text: String(format: is24Hour ? "%02d:%02d" : "%2d:%02d", is24Hour ? hour : (hour % 12 == 0 ? 12 : hour % 12), minute), font: .custom("7-Segment", size: 105.6), lineSpacing: 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .position(x: 114.3, y: 171.4)
            if !is24Hour {
                CustomTextView(text: hour >= 12 ? "P" : "A", font: .custom("JetBrainsMono-Bold", size: 19.2), lineSpacing: 0)
                    .frame(width: 240, height: 240, alignment: .leading)
                    .padding(.leading, 8)
                    .padding(.top, -6)
            }
        }
        .foregroundColor(colorText)
        .frame(width: 240, height: 240)
    }
}

struct Numerals: View {
    @Binding var date: Date
    
    let settings: Settings
    
    private func label(_ text: String, size: CGFloat, color: Color, x: CGFloat, y: CGFloat, width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        Text(text)
            .font(.custom("BloggerSans-Bold", size: size))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: width, height: height, alignment: .leading)
            .offset(x: x, y: y)
    }
    
    var body: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let is24Hour = settings.clockType == .H24
        let ampmColor = Color.rgb(0x99, 0x99, 0x99)
        
        ZStack(alignment: .topLeading) {
            Color.black
            label(String(format: "%02d", is24Hour ? hour : (hour % 12 == 0 ? 12 : hour % 12)), size: 140, color: .rgb(0x80, 0x80, 0x80), x: 90, y: -5, width: 165, height: 155)
            label(String(format: "%02d", calendar.component(.minute, from: date)), size: 140, color: .rgb(0x00, 0xff, 0xff), x: 90, y: 115, width: 165, height: 155)
            label(watchString(date, "EEE").uppercased(), size: 30, color: .white, x: 0, y: 0)
            label("\(calendar.component(.day, from: date))", size: 30, color: .white, x: 0, y: 36)
            if !is24Hour {
                label(hour >= 12 ? "P" : "A", size: 30, color: ampmColor, x: 2, y: 176)
                label("M", size: 30, color: ampmColor, x: 0, y: 210)
            }
        }
        .frame(width: 240, height: 240, alignment: .topLeading)
        .clipped()
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

extension View {
    // Matches lv_obj_align
    func lvAlign(_ alignment: Alignment, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        fixedSize()
            .frame(width: 240, height: 240, alignment: alignment)
            .offset(x: x, y: y)
    }
}

// The watch only shows English names
fileprivate func watchString(_ date: Date, _ format: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = format
    return formatter.string(from: date)
}

fileprivate struct PreviewRow<V: View>: View {
    let face: () -> V
    
    var body: some View {
        face()
            .frame(width: 240, height: 240)
            .background(Color.black)
    }
}

#Preview {
    let settings = Settings(
        version: 4,
        stepsGoal: 10000,
        screenTimeOut: 15000,
        alwaysOnDisplay: false,
        clockType: .H12,
        weatherFormat: .Metric,
        notificationStatus: .On,
        watchFace: 0,
        chimesOption: .None,
        pineTimeStyle: PineTimeStyleData(ColorTime: .Teal, ColorBar: .Teal, ColorBG: .Black, gaugeStyle: .Full, weatherEnable: .Off),
        watchFaceInfineat: WatchFaceInfineat(showSideCover: true, colorIndex: 0),
        wakeUpMode: .RaiseWrist,
        shakeWakeThreshold: 150,
        brightLevel: .Mid,
        prideFlag: 0
    )
    
    ScrollView {
        VStack(spacing: 24) {
            PreviewRow {
                PineTimeStyle(date: .constant(Date()), settings: settings)
            }
            PreviewRow {
                Digital(date: .constant(Date()), settings: settings)
            }
            PreviewRow {
                Analog(date: .constant(Date()))
            }
            
            PreviewRow {
                Terminal(date: .constant(Date()), settings: settings, firmware: "1.16.0")
            }
            PreviewRow {
                Infineat(date: .constant(Date()), settings: settings)
            }
            PreviewRow {
                Casio(date: .constant(Date()), settings: settings)
            }
            PreviewRow {
                Numerals(date: .constant(Date()), settings: settings)
            }
            PreviewRow {
                PrideFlag(date: .constant(Date()), flag: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
