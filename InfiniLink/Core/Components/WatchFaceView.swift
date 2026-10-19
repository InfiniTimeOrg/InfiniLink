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
    
    @State private var date = Date()
    
    let watchface: UInt8?
    let device: Device?
    let prideFlag: UInt8?
    
    init(watchface: UInt8? = nil, device: Device? = nil, prideFlag: UInt8? = nil) {
        self.watchface = watchface
        self.device = device
        self.prideFlag = prideFlag
    }
    
    // The faces are laid out at 185 and scaled, since all their offsets were tuned at that size
    private static let designSize: CGFloat = 185
    
    var body: some View {
        GeometryReader { geometry in
            face
                .frame(width: Self.designSize, height: Self.designSize)
                .scaleEffect(min(geometry.size.width, geometry.size.height) / Self.designSize, anchor: .topLeading)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { newDate in
            self.date = newDate
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Watch face preview"))
    }
    
    private var face: some View {
        GeometryReader { geometry in
            ZStack {
                Image(.watchScreen)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                ZStack {
                    ZStack {
                        switch watchface ?? deviceManager.settings.watchFace {
                        case 0:
                            Digital(geometry: .constant(geometry), date: $date, device: device)
                        case 1:
                            Analog(geometry: .constant(geometry), date: $date)
                        case 2:
                            PineTimeStyle(geometry: .constant(geometry), date: $date, device: device)
                        case 3:
                            Terminal(geometry: .constant(geometry), date: $date, device: device)
                        case 4:
                            Infineat(geometry: .constant(geometry), date: $date, device: device)
                        case 5:
                            Casio(geometry: .constant(geometry), date: $date, device: device)
                        case 6:
                            PrideFlag(geometry: .constant(geometry), date: $date, flag: prideFlag ?? UInt8(UserDefaults.standard.integer(forKey: "prideFlag")))
                        default:
                            CustomWatchFace(index: watchface ?? deviceManager.settings.watchFace)
                                .frame(width: geometry.size.width, height: geometry.size.height)
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
                Image(.watchBorder)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .brightness(colorScheme == .dark ? 0.0 : 0.04)
            }
        }
    }
}

struct CustomWatchFace: View {
    @ObservedObject var catalog = WatchFaceCatalog.shared
    
    let index: UInt8
    
    var body: some View {
        if let image = catalog.image(for: index) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Text(catalog.name(for: index))
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct PineTimeStyle: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
    @Binding var date: Date
    
    let device: Device?
    
    func hour24() -> Bool {
        if let device {
            return device.clockType == 0
        } else {
            return deviceManager.hour24
        }
    }
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
            if !hour24() {
                CustomTextView(text: Calendar.current.component(.hour, from: date) >= 12 ? "P\nM" : "A\nM", font: .custom("JetBrainsMono-ExtraBold", size: geometry.size.width * 0.075), lineSpacing: -4)
                    .foregroundColor(getColor(for: .time))
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
            }
            if !hour24() {
                let currentHour = Calendar.current.component(.hour, from: date)
                let hour24 = currentHour > 12 ? currentHour - 12 : (currentHour == 0 ? 12 : currentHour)
                let hourString = String(format: "%02d", hour24)
                let minuteString = String(format: "%02d", Calendar.current.component(.minute, from: date))
                
                CustomTextView(text: "\(hourString)\n\(minuteString)", font: .custom("OpenSans-light", size: geometry.size.width * 0.62), lineSpacing: -geometry.size.width * 0.35)
                    .foregroundColor(getColor(for: .time))
                    .position(x: geometry.size.width / 2.3, y: geometry.size.height / 2.0)
            } else {
                let hourString = String(format: "%02d", Calendar.current.component(.hour, from: date))
                let minuteString = String(format: "%02d", Calendar.current.component(.minute, from: date))
                
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
    }
}

struct Analog: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry: GeometryProxy
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
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct PrideFlag: View {
    @Binding var geometry: GeometryProxy
    @Binding var date: Date
    
    let flag: UInt8
    
    private var stripes: [Color] {
        switch flag {
        case 1:
            return [.rgb(0x00, 0xbf, 0xf3), .rgb(0xf4, 0x9a, 0xc1), .white, .rgb(0xf4, 0x9a, 0xc1), .rgb(0x00, 0xbf, 0xf3)]
        case 2:
            return [.rgb(0xd6, 0x02, 0x70), .rgb(0xd6, 0x02, 0x70), .rgb(0x9b, 0x4f, 0x96), .rgb(0x00, 0x38, 0xa8), .rgb(0x00, 0x38, 0xa8)]
        case 3:
            return [.red, .rgb(0xef, 0x76, 0x27), .rgb(0xff, 0x9b, 0x55), .white, .rgb(0xd4, 0x61, 0xa6), .rgb(0xb5, 0x56, 0x90), .rgb(0xa5, 0x00, 0x62)]
        default:
            return [.rgb(0x07, 0x8d, 0x70), .rgb(0x26, 0xce, 0xaa), .rgb(0x98, 0xe8, 0xc1), .white, .rgb(0x00, 0xbf, 0xf3), .rgb(0x50, 0x49, 0xcc), .rgb(0x3d, 0x1a, 0x78)]
        }
    }
    private var timeColor: Color {
        flag == 2 ? .white : .black
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(stripes.indices, id: \.self) { index in
                    stripes[index]
                }
            }
            CustomTextView(text: String(format: "%02d:%02d", Calendar.current.component(.hour, from: date), Calendar.current.component(.minute, from: date)), font: .custom("JetBrainsMono-Bold", size: geometry.size.width * 0.175), lineSpacing: 0)
                .foregroundColor(timeColor)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct Digital: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var geometry: GeometryProxy
    @Binding var date: Date
    
    let device: Device?
    
    var twelveHour: Int {
        let hour = Calendar.current.component(.hour, from: date)
        return hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
    }
    
    func hour24() -> Bool {
        if let device {
            return device.clockType == 0
        } else {
            return deviceManager.hour24
        }
    }
    
    var body: some View {
        ZStack {
            if !hour24() {
                CustomTextView(text: Calendar.current.component(.hour, from: date) > 12 ? "PM" : "AM", font: .custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085), lineSpacing: 0)
                    .foregroundColor(.white)
                    .frame(width: geometry.size.width, height: geometry.size.height / 3.95, alignment: .topTrailing)
            }
            if !hour24() {
                CustomTextView(text: "\(twelveHour):\(String(format: "%02d", Calendar.current.component(.minute, from: date)))", font: .custom("JetBrainsMono-ExtraBold", size: geometry.size.width * 0.33), lineSpacing: 0)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.9)
            } else {
                CustomTextView(text: "\(String(format: "%02d", Calendar.current.component(.hour, from: date))):\(String(format: "%02d", Calendar.current.component(.minute, from: date)))", font: .custom("JetBrainsMono-ExtraBold", size: geometry.size.width * 0.33), lineSpacing: 0)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.9)
            }
            CustomTextView(text: {
                let current = date
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

struct Infineat: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Binding var geometry: GeometryProxy
    @Binding var date: Date
    
    let device: Device?
    
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
    
    private var scale: CGFloat {
        geometry.size.width / 240
    }
    private var colors: [Color] {
        let index = Int(device?.watchFaceInfineat?.colorIndex ?? Int16(deviceManager.settings.watchFaceInfineat.colorIndex))
        return Self.colorSchemes[Self.colorSchemes.indices.contains(index) ? index : 0]
    }
    private var showSideCover: Bool {
        device?.watchFaceInfineat?.showSideCover ?? deviceManager.settings.watchFaceInfineat.showSideCover
    }
    private var is24Hour: Bool {
        if let device {
            return device.clockType == 0
        }
        return deviceManager.hour24
    }
    
    // Overlay so the text doesn't push the layout around
    private func label(_ text: String, font: String, size: CGFloat, color: Color, centerX: CGFloat, baseline: CGFloat, leading: Bool = false) -> some View {
        Color.clear
            .frame(width: 0, height: 0)
            .overlay(alignment: Alignment(horizontal: leading ? .leading : .center, vertical: .firstTextBaseline)) {
                Text(text)
                    .font(.custom(font, size: size * scale))
                    .foregroundColor(color)
                    .fixedSize()
            }
            .offset(x: centerX * scale, y: baseline * scale)
    }
    
    var body: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let displayHour = is24Hour ? hour : (hour % 12 == 0 ? 12 : hour % 12)
        let battery = bleManager.hasLoadedBatteryLevel ? bleManager.batteryLevel : 100
        
        ZStack(alignment: .topLeading) {
            Color.clear
            if showSideCover {
                Canvas { context, _ in
                    for (index, line) in Self.lines.enumerated() {
                        var path = Path()
                        path.move(to: CGPoint(x: line.0.x * scale, y: line.0.y * scale))
                        path.addLine(to: CGPoint(x: line.1.x * scale, y: line.1.y * scale))
                        context.stroke(path, with: .color(colors[index]), style: StrokeStyle(lineWidth: Self.lineWidths[index] * scale, lineCap: .butt))
                    }
                }
            }
            Image(.pineLogo)
                .resizable()
                .renderingMode(showSideCover ? .original : .template)
                .foregroundColor(.white)
                .frame(width: 23 * scale, height: 31 * scale)
                .offset(x: 15 * scale, y: 106 * scale)
            Rectangle()
                .fill(colors[4].opacity(190 / 255))
                .frame(width: 24 * scale, height: max(1, 32 * (100 - battery) / 100) * scale)
                .offset(x: 15 * scale, y: 105 * scale)
            // Same as the firmware, hours and minutes are at the top and bottom of a 185px box 10px above center
            label(String(format: "%02d", displayHour), font: "BebasNeue-Regular", size: 120, color: .white, centerX: 120, baseline: is24Hour ? 103 : 108)
            label(String(format: "%02d", calendar.component(.minute, from: date)), font: "BebasNeue-Regular", size: 120, color: .white, centerX: 120, baseline: 202)
            if !is24Hour {
                label(hour >= 12 ? "PM" : "AM", font: "Teko-Light", size: 28, color: .white, centerX: 212, baseline: 46, leading: true)
            }
            label({
                let formatter = DateFormatter()
                formatter.dateFormat = "E dd"
                return formatter.string(from: date)
            }(), font: "Teko-Light", size: 28, color: Self.gray, centerX: 210, baseline: 129)
            Color.clear
                .frame(width: 0, height: 0)
                .overlay(alignment: Alignment(horizontal: .center, vertical: .firstTextBaseline)) {
                    Text("\(bleManager.stepCount)")
                        .font(.custom("Teko-Light", size: 28 * scale))
                        .foregroundColor(Self.gray)
                        .fixedSize()
                        .overlay(alignment: .leading) {
                            Image(systemName: "shoeprints.fill")
                                .rotationEffect(Angle(degrees: 90))
                                .font(.system(size: 16 * scale))
                                .foregroundColor(Self.gray)
                                .fixedSize()
                                .alignmentGuide(HorizontalAlignment.leading) { $0[.trailing] + 5 * scale }
                        }
                }
                .offset(x: 130 * scale, y: 238 * scale)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        .clipped()
    }
}

struct Terminal: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var geometry: GeometryProxy
    @Binding var date: Date
    
    let device: Device?
    
    func hour24() -> Bool {
        if let device {
            return device.clockType == 0
        } else {
            return deviceManager.hour24
        }
    }
    
    private func row(_ index: Int) -> CGFloat {
        return (36.9 + CGFloat(index) * 21.5) * geometry.size.width / 240
    }
    
    private var batteryColor: Color {
        let hue = (1 - exp(-4 * bleManager.batteryLevel / 100)) * 120
        return Color(hue: hue / 360, saturation: 1, brightness: 1)
    }
    
    private func line(_ text: Text, at index: Int) -> some View {
        text
            .font(.custom("JetBrainsMono-Bold", size: geometry.size.width * 0.085))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .position(x: geometry.size.width / 2.0, y: row(index))
    }
    
    var body: some View {
        let currentHour = Calendar.current.component(.hour, from: date)
        let currentMinute = Calendar.current.component(.minute, from: date)
        let currentSecond = Calendar.current.component(.second, from: date)
        let lightGray = Color.rgb(0xb0, 0xb0, 0xb0)
        // Weather row was added in 1.16
        let showsWeather = (device?.firmware ?? deviceManager.firmware).compare("1.16.0", options: .numeric) != .orderedAscending
        let time = hour24() ? String(format: "%02d:%02d:%02d", currentHour, currentMinute, currentSecond) : String(format: "%02d:%02d:%02d %@", currentHour % 12 == 0 ? 12 : currentHour % 12, currentMinute, currentSecond, currentHour >= 12 ? "PM" : "AM")
        
        ZStack {
            line(Text("user@watch:~ $ now").foregroundColor(lightGray), at: 0)
            line(Text("[TIME] ").foregroundColor(.white) + Text(time).foregroundColor(.rgb(0x11, 0xcc, 0x55)), at: 1)
            line(Text("[DATE] ").foregroundColor(.white) + Text(String(format: "%04d-%02d-%02d", Calendar.current.component(.year, from: date), Calendar.current.component(.month, from: date), Calendar.current.component(.day, from: date))).foregroundColor(.rgb(0x00, 0x7f, 0xff)), at: 2)
            line(Text("[BATT] ").foregroundColor(.white) + Text("\(Int(bleManager.batteryLevel))%").foregroundColor(batteryColor), at: 3)
            line(Text("[STEP] ").foregroundColor(.white) + Text("\(bleManager.stepCount) steps").foregroundColor(.rgb(0xff, 0xb0, 0x00)), at: 4)
            line(Text("[L_HR] ").foregroundColor(.white) + Text(bleManager.heartRate == 0 ? "---" : "\(Int(bleManager.heartRate)) bpm").foregroundColor(.white), at: 5)
            if showsWeather {
                line(Text("[WTHR] ").foregroundColor(.white) + Text("---").foregroundColor(.rgb(0xff, 0xdd, 0x00)), at: 6)
            }
            line(Text("[STAT] ").foregroundColor(.white) + Text("Connected").foregroundColor(.white), at: showsWeather ? 7 : 6)
            line(Text("user@watch:~ $").foregroundColor(lightGray), at: showsWeather ? 8 : 7)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }
}

struct Casio: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var geometry: GeometryProxy
    @Binding var date: Date
    
    let device: Device?
    
    func hour24() -> Bool {
        if let device {
            return device.clockType == 0
        } else {
            return deviceManager.hour24
        }
    }
    
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
                    
                    let weekOfYear = Calendar.current.component(.weekOfYear, from: date)
                    
                    return "WK\(weekOfYear)\n\(dateFormatter.string(from: date).uppercased())"
                }(),
                font: .custom("repetitionscrolling", size: geometry.size.width * 0.16),
                lineSpacing: 0
            )
            .frame(width: geometry.size.width / 1.04, height: geometry.size.height / 1.15, alignment: .topLeading)
            CustomTextView(
                text: {
                    let calendar = Calendar.current
                    let now = date
                    
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
                    let now = date
                    
                    let month = calendar.component(.month, from: now)
                    let day = calendar.component(.day, from: now)
                    
                    return "\(month)-\(day)"
                }(),
                font: .custom("7-Segment", size: geometry.size.width * 0.16),
                lineSpacing: 0
            )
            .frame(width: geometry.size.width / 1.08, height: geometry.size.height / 2.25, alignment: .topTrailing)
            CustomTextView(text: {
                let currentHour = Calendar.current.component(.hour, from: date)
                var hourString = ""
                
                if hour24() {
                    hourString = String(format: "%d", currentHour)
                } else {
                    let hour24 = currentHour % 12 == 0 ? 12 : currentHour
                    hourString = "\(hour24)"
                }
                let minuteString = String(format: "%02d", Calendar.current.component(.minute, from: date))
                
                return "\(hourString):\(minuteString)"
            }(), font: .custom("7-Segment", size: geometry.size.width * 0.44), lineSpacing: 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .position(x: geometry.size.width / 2.1, y: geometry.size.height / 1.4)
            if !hour24() {
                CustomTextView(text: "\(Calendar.current.component(.hour, from: date) >= 12 ? "P" : "A")", font: .custom("JetBrainsMono-Bold", size: geometry.size.width * 0.08), lineSpacing: 0)
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

#Preview {
    WatchFaceView(watchface: 2)
        .frame(width: 300, height: 300)
}
