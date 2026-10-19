//
//  WatchSettingsFile.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import Foundation

// settings.dat is a raw struct dump, so we only patch the bytes we change and leave the rest alone
struct WatchSettingsFile {
    // Offsets are from compiling SettingsData for the watch
    struct Layout {
        let size: Int
        let alwaysOnDisplay: Int?
        let clockType: Int
        let weatherFormat: Int
        let notificationStatus: Int
        let watchFace: Int
        let chimesOption: Int
        let pineTimeStyle: Int
        let prideFlag: Int?
        let infineat: Int
        let wakeUpMode: Int
        let shakeWakeThreshold: Int
        let brightLevel: Int
        let dfuAndFsEnabledOnBoot: Int?
        let heartRateBackgroundPeriod: Int?
    }

    static let layouts: [UInt32: Layout] = [
        // 1.14
        0x07: Layout(size: 44, alwaysOnDisplay: nil, clockType: 12, weatherFormat: 13, notificationStatus: 14, watchFace: 15, chimesOption: 16, pineTimeStyle: 17, prideFlag: nil, infineat: 24, wakeUpMode: 32, shakeWakeThreshold: 36, brightLevel: 40, dfuAndFsEnabledOnBoot: nil, heartRateBackgroundPeriod: nil),
        // 1.15
        0x08: Layout(size: 44, alwaysOnDisplay: 12, clockType: 13, weatherFormat: 14, notificationStatus: 15, watchFace: 16, chimesOption: 17, pineTimeStyle: 18, prideFlag: nil, infineat: 24, wakeUpMode: 32, shakeWakeThreshold: 36, brightLevel: 40, dfuAndFsEnabledOnBoot: nil, heartRateBackgroundPeriod: nil),
        // 1.16
        0x0a: Layout(size: 48, alwaysOnDisplay: 12, clockType: 13, weatherFormat: 14, notificationStatus: 15, watchFace: 16, chimesOption: 17, pineTimeStyle: 18, prideFlag: 23, infineat: 24, wakeUpMode: 32, shakeWakeThreshold: 36, brightLevel: 40, dfuAndFsEnabledOnBoot: 44, heartRateBackgroundPeriod: 46)
    ]

    private(set) var data: Data
    let layout: Layout

    init?(data: Data) {
        guard let version = Self.version(of: data), let layout = Self.layouts[version], data.count >= layout.size else { return nil }

        self.data = data
        self.layout = layout
    }

    static func version(of data: Data) -> UInt32? {
        guard data.count >= 4 else { return nil }

        let start = data.startIndex
        return UInt32(data[start]) | UInt32(data[start + 1]) << 8 | UInt32(data[start + 2]) << 16 | UInt32(data[start + 3]) << 24
    }

    static func expectedVersion(forFirmware firmware: String) -> UInt32? {
        if firmware.compare("1.16.0", options: .numeric) != .orderedAscending {
            return 0x0a
        } else if firmware.compare("1.15.0", options: .numeric) != .orderedAscending {
            return 0x08
        } else if firmware.compare("1.14.0", options: .numeric) != .orderedAscending {
            return 0x07
        }
        return nil
    }

    static func defaults(version: UInt32) -> WatchSettingsFile? {
        guard let layout = layouts[version] else { return nil }

        var bytes = [UInt8](repeating: 0, count: layout.size)
        bytes[0] = UInt8(version & 0xFF)
        guard var file = WatchSettingsFile(data: Data(bytes)) else { return nil }

        file.stepsGoal = 10000
        file.screenTimeOut = 15000
        file.ptsColorTime = Colors.Teal.rawValue
        file.ptsColorBar = Colors.Teal.rawValue
        file.ptsColorBG = Colors.Black.rawValue
        file.ptsWeather = PTSWeather.Off.rawValue
        file.infineatShowSideCover = true
        file.setUInt16(layout.shakeWakeThreshold, 150)
        file.setByte(layout.brightLevel, 3) // Medium
        file.dfuAndFsEnabledOnBoot = true
        if let offset = layout.heartRateBackgroundPeriod {
            file.setUInt16(offset, UInt16.max)
        }
        return file
    }

    private func byte(_ offset: Int) -> UInt8 {
        return data[data.startIndex + offset]
    }
    private mutating func setByte(_ offset: Int, _ value: UInt8) {
        data[data.startIndex + offset] = value
    }
    private func uint16(_ offset: Int) -> UInt16 {
        return UInt16(byte(offset)) | UInt16(byte(offset + 1)) << 8
    }
    private mutating func setUInt16(_ offset: Int, _ value: UInt16) {
        setByte(offset, UInt8(value & 0xFF))
        setByte(offset + 1, UInt8(value >> 8))
    }
    private func uint32(_ offset: Int) -> UInt32 {
        return UInt32(uint16(offset)) | UInt32(uint16(offset + 2)) << 16
    }
    private mutating func setUInt32(_ offset: Int, _ value: UInt32) {
        setUInt16(offset, UInt16(value & 0xFFFF))
        setUInt16(offset + 2, UInt16(value >> 16))
    }

    var version: UInt32 { uint32(0) }

    var stepsGoal: UInt32 {
        get { uint32(4) }
        set { setUInt32(4, newValue) }
    }
    var screenTimeOut: UInt32 {
        get { uint32(8) }
        set { setUInt32(8, newValue) }
    }
    var alwaysOnDisplay: Bool {
        get { layout.alwaysOnDisplay.map { byte($0) != 0 } ?? false }
        set { if let offset = layout.alwaysOnDisplay { setByte(offset, newValue ? 1 : 0) } }
    }
    var watchFace: UInt8 {
        get { byte(layout.watchFace) }
        set { setByte(layout.watchFace, newValue) }
    }
    var ptsColorTime: UInt8 {
        get { byte(layout.pineTimeStyle) }
        set { setByte(layout.pineTimeStyle, newValue) }
    }
    var ptsColorBar: UInt8 {
        get { byte(layout.pineTimeStyle + 1) }
        set { setByte(layout.pineTimeStyle + 1, newValue) }
    }
    var ptsColorBG: UInt8 {
        get { byte(layout.pineTimeStyle + 2) }
        set { setByte(layout.pineTimeStyle + 2, newValue) }
    }
    var ptsGaugeStyle: UInt8 {
        get { byte(layout.pineTimeStyle + 3) }
        set { setByte(layout.pineTimeStyle + 3, newValue) }
    }
    var ptsWeather: UInt8 {
        get { byte(layout.pineTimeStyle + 4) }
        set { setByte(layout.pineTimeStyle + 4, newValue) }
    }
    var prideFlag: UInt8? {
        get { layout.prideFlag.map { byte($0) } }
        set { if let offset = layout.prideFlag, let newValue { setByte(offset, newValue) } }
    }
    var infineatShowSideCover: Bool {
        get { byte(layout.infineat) != 0 }
        set { setByte(layout.infineat, newValue ? 1 : 0) }
    }
    var infineatColorIndex: UInt32 {
        get { uint32(layout.infineat + 4) }
        set { setUInt32(layout.infineat + 4, newValue) }
    }
    var heartRateBackgroundPeriod: UInt16? {
        get {
            guard let offset = layout.heartRateBackgroundPeriod else { return nil }
            let value = uint16(offset)
            return value == UInt16.max ? nil : value
        }
        set {
            guard let offset = layout.heartRateBackgroundPeriod else { return }
            setUInt16(offset, newValue ?? UInt16.max)
        }
    }
    var dfuAndFsEnabledOnBoot: Bool? {
        get { layout.dfuAndFsEnabledOnBoot.map { byte($0) != 0 } }
        set { if let offset = layout.dfuAndFsEnabledOnBoot, let newValue { setByte(offset, newValue ? 1 : 0) } }
    }
    var clockType: UInt8 {
        get { byte(layout.clockType) }
        set { setByte(layout.clockType, newValue) }
    }
    var weatherFormat: UInt8 {
        get { byte(layout.weatherFormat) }
        set { setByte(layout.weatherFormat, newValue) }
    }
    var notificationStatus: UInt8 {
        get { byte(layout.notificationStatus) }
        set { setByte(layout.notificationStatus, newValue) }
    }
    var chimesOption: UInt8 {
        get { byte(layout.chimesOption) }
        set { setByte(layout.chimesOption, newValue) }
    }
    // Off, AlwaysOn, Low (2), Medium (3), High (4)
    var brightLevel: UInt8 {
        get { byte(layout.brightLevel) }
        set { setByte(layout.brightLevel, newValue) }
    }
    var shakeWakeThreshold: UInt16 {
        get { uint16(layout.shakeWakeThreshold) }
        set { setUInt16(layout.shakeWakeThreshold, newValue) }
    }
    func isWakeUpModeOn(_ mode: WakeUpMode) -> Bool {
        return byte(layout.wakeUpMode) & (1 << mode.rawValue) != 0
    }
    mutating func setWakeUpMode(_ mode: WakeUpMode, enabled: Bool) {
        var bits = byte(layout.wakeUpMode)
        bits = enabled ? bits | (1 << mode.rawValue) : bits & ~(1 << mode.rawValue)
        if enabled && mode == .SingleTap {
            bits &= ~(1 << WakeUpMode.DoubleTap.rawValue)
        } else if enabled && mode == .DoubleTap {
            bits &= ~(1 << WakeUpMode.SingleTap.rawValue)
        }
        setByte(layout.wakeUpMode, bits)
    }
    var supportsAlwaysOnDisplay: Bool {
        return layout.alwaysOnDisplay != nil
    }
    var supportsBackgroundHeartRate: Bool {
        return layout.heartRateBackgroundPeriod != nil
    }
    var supportsPrideFlag: Bool {
        return layout.prideFlag != nil
    }

    var settings: Settings {
        let wakeBits = byte(layout.wakeUpMode)
        let wakeUpMode = (0..<5).first { wakeBits & (1 << $0) != 0 }.flatMap { WakeUpMode(rawValue: UInt8($0)) } ?? .SingleTap

        let brightLevel: BrightLevel = {
            switch byte(layout.brightLevel) {
            case 2: return .Low
            case 4: return .High
            default: return .Mid
            }
        }()

        return Settings(
            version: version,
            stepsGoal: stepsGoal,
            screenTimeOut: screenTimeOut,
            alwaysOnDisplay: alwaysOnDisplay,
            clockType: ClockType(rawValue: byte(layout.clockType)) ?? .H24,
            weatherFormat: WeatherFormat(rawValue: byte(layout.weatherFormat)) ?? .Metric,
            notificationStatus: Notification(rawValue: byte(layout.notificationStatus)) ?? .On,
            watchFace: watchFace,
            chimesOption: ChimesOption(rawValue: byte(layout.chimesOption)) ?? .None,
            pineTimeStyle: PineTimeStyleData(
                ColorTime: Colors(rawValue: ptsColorTime) ?? .Teal,
                ColorBar: Colors(rawValue: ptsColorBar) ?? .Teal,
                ColorBG: Colors(rawValue: ptsColorBG) ?? .Black,
                gaugeStyle: PTSGaugeStyle(rawValue: ptsGaugeStyle) ?? .Full,
                weatherEnable: PTSWeather(rawValue: ptsWeather) ?? .Off
            ),
            watchFaceInfineat: WatchFaceInfineat(showSideCover: infineatShowSideCover, colorIndex: UInt8(clamping: infineatColorIndex)),
            wakeUpMode: wakeUpMode,
            shakeWakeThreshold: uint16(layout.shakeWakeThreshold),
            brightLevel: brightLevel,
            prideFlag: prideFlag ?? 0
        )
    }
}
