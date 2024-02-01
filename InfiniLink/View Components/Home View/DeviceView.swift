//
//  DeviceView.swift
//  InfiniLink
//
//  Created by John Stanley on 11/16/21.
//

import CoreLocation
import SwiftUI
import BottomSheet

struct DeviceView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @ObservedObject var uptimeManager = UptimeManager.shared
    @ObservedObject var weatherController = WeatherController.shared
    
    @AppStorage("watchNotifications") var watchNotifications: Bool = true
    @AppStorage("batteryNotification") var batteryNotification: Bool = false
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("autoconnectToDevice") var autoconnectToDevice: Bool = false
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @AppStorage("showDisconnectAlert") var showDisconnectConfDialog: Bool = false
    @AppStorage("weatherData") var weatherData: Bool = true
    
    //@State private var bottomSheetPosition: BottomSheetPosition = .relative(0.6)
    
    @State var sheetPosition : CGPoint = .zero
    @State private var childPos: CGFloat = 0
    
    struct RoundedCornersShape: Shape {
        let corners: UIRectCorner
        let radius: CGFloat
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var currentUptime: TimeInterval!
    
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var dateFormatter = DateComponentsFormatter()
    private let locationManager = CLLocationManager()
    
    @State private var particles: [Particle] = []
    @State private var particleTimer: Timer?
    
    var icon: String {
        switch bleManagerVal.weatherInformation.icon {
        case 0:
            return "sun.max.fill"
        case 1:
            return "cloud.sun.fill"
        case 2, 3:
            return "cloud.fill"
        case 4, 5:
            return "cloud.rain.fill"
        case 6:
            return "cloud.bolt.rain.fill"
        case 7:
            return "cloud.snow.fill"
        case 8:
            return "cloud.fog.fill"
        default:
            return "slash.circle"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // To stop content from scrolling under safe area
            //            Rectangle()
            //                .frame(height: 1)
            //                .foregroundColor(.clear)
            ZStack() {
                if colorScheme == .dark {
                    Color.darkestGray.ignoresSafeArea()
                } else {
                    Color.secondaryBackground.ignoresSafeArea()
                }
                ZStack {
                    ForEach(particles) { particle in
                        Circle()
                            .fill(Color(hue: particle.hue, saturation: 1, brightness: 1).opacity(particle.opacity))
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                            .animation(Animation.easeInOut(duration: 2.0).delay(0.5).repeatForever(autoreverses: true))
                    }
                }
                .blur(radius: 70)
                .onAppear {
                    particleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 2.0)) {
                            particles.append(Particle())
                        }
                    }
                }
                .onDisappear {
                    particleTimer?.invalidate()
                    particleTimer = nil
                }
                .onReceive(Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()) { _ in
                    for i in 0..<particles.count {
                        particles[i].position.x += particles[i].drift.width
                        particles[i].position.y += particles[i].drift.height
                        particles[i].opacity = (1 - (Date().timeIntervalSince(particles[i].creationDate) / particles[i].lifetime)) / 9.0
                    }
                    particles.removeAll(where: { $0.opacity <= 0 })
                }
                VStack(spacing: 20) {
                    GeometryReader { geometry in
                        Image("WatchHomePage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height / 4.0, alignment: .center)
                            .position(x: geometry.size.width / 2, y: (((self.childPos - 350) * 0.145) + geometry.size.height * 0.25).clamped(to: geometry.size.height*0.198...geometry.size.height*1.0))
                        
                            .shadow(color: .black, radius: 16, x: 0, y: 0)
                        VStack(alignment: .center, spacing: 12) {
                            
                            if !bleManager.isConnectedToPinetime {
                                Text(NSLocalizedString("not_connected", comment: ""))
                                    .foregroundColor(.primary)
                                    .font(.title.weight(.bold))
                                    .shadow(color: .black, radius: colorScheme == .dark ? 16 : 0, x: 0, y: 0)
                                HStack(spacing: 7) {
                                    ProgressView()
                                    Text(NSLocalizedString("connecting", comment: ""))
                                        .shadow(color: .black, radius: colorScheme == .dark ? 16 : 0, x: 0, y: 0)
                                }
                                .foregroundColor(.gray)
                            } else {
                                Text(deviceInfo.deviceName == "" ? "InfiniTime" : deviceInfo.deviceName)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .bold()
                                    .font(.title.weight(.thin))
                                    .shadow(color: .black, radius: colorScheme == .dark ? 16 : 0, x: 0, y: 0)
                                    .position(x: geometry.size.width / 2, y: ((self.childPos - 200) * 0.17).clamped(to: -22...geometry.size.height*0.3))
                            }
                        }
                        .padding(.top)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    }
                }
                    ScrollView() {
                        GeometryReader{ geo in
                            AnyView(Color.clear
                            .frame(width: 0, height: 0)
                            .preference(key: SizePreferenceKey.self, value: geo.frame(in: .global).minY)
                            )}.onPreferenceChange(SizePreferenceKey.self) { preferences in
                                self.childPos = preferences
                        }
                            
                        //Spacer(minLength: 350)
                        //Divider()
                        //    .padding(.vertical, 10)
                        //    .padding(.horizontal, -16)
                        VStack() {
                            VStack(spacing: 10) {
                                // Use Lazy Grids?
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        NavigationLink(destination: BatteryView()) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 5) {
                                                    Text(NSLocalizedString("battery_tilte", comment: ""))
                                                        .font(.title3.weight(.semibold))
                                                    Text(String(format: "%.0f", bleManager.batteryLevel) + "%")
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.body.weight(.medium))
                                            }
                                            .aspectRatio(1, contentMode: .fill)
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(20)
                                        }
                                        NavigationLink(destination: DFUView()) {
                                            HStack {
                                                Text(NSLocalizedString("software_update", comment: ""))
                                                    .multilineTextAlignment(.leading)
                                                    .font(.title3.weight(.semibold))
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.body.weight(.medium))
                                            }
                                            .aspectRatio(1, contentMode: .fill)
                                            //.frame(height: 44)
                                            //.frame(width: .infinity, height: .infinity, alignment: .center)
                                            .padding()
                                            //.padding(.vertical)
                                            .background(Color.gray.opacity(0.3))
                                            .foregroundColor(.primary)
                                            .cornerRadius(20)
                                        }
                                    }
                                    HStack(spacing: 8) {
                                        NavigationLink(destination: StepView().navigationBarHidden(true)) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 5) {
                                                    Text(NSLocalizedString("step_count", comment: ""))
                                                        .font(.title3.weight(.semibold))
                                                    Text("\(bleManagerVal.stepCount)")
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.body.weight(.medium))
                                            }
                                            .aspectRatio(1, contentMode: .fill)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(20)
                                        }
                                        NavigationLink(destination: HeartView()) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 5) {
                                                    Text(NSLocalizedString("heart_rate", comment: ""))
                                                        .font(.title3.weight(.semibold))
                                                    Text(String(format: "%.0f", bleManagerVal.heartBPM) + " " + NSLocalizedString("bpm", comment: "BPM"))
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.body.weight(.medium))
                                            }
                                            .aspectRatio(1, contentMode: .fill)
                                            .padding()
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(20)
                                        }
                                    }

                                    if weatherData {
                                        VStack {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(NSLocalizedString("weather", comment: ""))
                                                        .font(.headline)
                                                    if bleManagerVal.loadingWeather {
                                                        Text(NSLocalizedString("loading", comment: "Loading..."))
                                                    } else {
                                                        if (UnitTemperature.current == .celsius && deviceData.chosenWeatherMode == "System") || deviceData.chosenWeatherMode == "Metric" {
                                                            Text(String(Int(round(bleManagerVal.weatherInformation.temperature))) + "°" + "C")
                                                                .font(.title.weight(.semibold))
                                                        } else {
                                                            Text(String(Int(round(bleManagerVal.weatherInformation.temperature * 1.8 + 32))) + "°" + "F")
                                                                .font(.title.weight(.semibold))
                                                        }
                                                    }
                                                }
                                                .font(.title.weight(.semibold))
                                                Spacer()
                                                VStack {
                                                    if bleManagerVal.loadingWeather {
                                                        Image(systemName: "circle.slash")
                                                    } else {
                                                        Image(systemName: icon)
                                                    }
                                                }
                                                .font(.title.weight(.medium))
                                            }
                                        }
                                        .padding()
                                        .background(LinearGradient(colors: [.blue, .yellow], startPoint: .leading, endPoint: .trailing))
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                        Spacer()
                                            .frame(height: 6)
                                    }
                                }
                                if DownloadManager.shared.updateAvailable {
                                    NavigationLink(destination: DFUView()) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(NSLocalizedString("software_update_available", comment: "Software Update Available"))
                                                    .font(.title2.weight(.semibold))
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.body.weight(.medium))
                                            }
                                            Text(DownloadManager.shared.updateVersion)
                                                .foregroundColor(.gray)
                                                .font(.headline)
                                            Spacer()
                                                .frame(height: 5)
                                            Text(DownloadManager.shared.updateBody)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(4)
                                        }
                                        .foregroundColor(.primary)
                                        .modifier(RowModifier(style: .standard))
                                    }
                                }
                                VStack {
                                    NavigationLink(destination: RenameView()) {
                                        HStack {
                                            Text(NSLocalizedString("name", comment: ""))
                                            Text(deviceInfo.deviceName)
                                                .foregroundColor(.gray)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .modifier(RowModifier(style: .capsule))
                                    }
                                    .opacity(bleManager.isConnectedToPinetime ? 1.0 : 0.5)
                                    .disabled(!bleManager.isConnectedToPinetime)
                                    HStack {
                                        Text(NSLocalizedString("software_version", comment: ""))
                                        Spacer()
                                        Text(deviceInfo.firmware)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                        
                                    }
                                    .modifier(RowModifier(style: .capsule))
                                    HStack {
                                        Text(NSLocalizedString("model_name", comment: ""))
                                        Text(deviceInfo.modelNumber)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                        
                                    }
                                    .modifier(RowModifier(style: .capsule))
                                    HStack {
                                        Text(NSLocalizedString("last_disconnect", comment: ""))
                                        Spacer()
                                        if UptimeManager.shared.lastDisconnect != nil {
                                            Text(uptimeManager.dateFormatter.string(from: uptimeManager.lastDisconnect))
                                                .foregroundColor(.gray)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                        }
                                    }
                                    .modifier(RowModifier(style: .capsule))
                                    HStack {
                                        Text(NSLocalizedString("uptime", comment: ""))
                                        Spacer()
                                        if currentUptime != nil {
                                            Text((dateFormatter.string(from: currentUptime) ?? ""))
                                                .foregroundColor(.gray)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                        }
                                    }
                                    .modifier(RowModifier(style: .capsule))
                                }
                                .onReceive(timer, perform: { _ in
                                    if uptimeManager.connectTime != nil {
                                        currentUptime = -uptimeManager.connectTime.timeIntervalSinceNow
                                    }
                                })
                                Spacer()
                                    .frame(height: 6)
                                VStack {
                                    if bleManager.isConnectedToPinetime {
                                        Toggle(isOn: $bleManager.autoconnectToDevice) {
                                            Text(NSLocalizedString("autoconnect_to_this", comment: "") + " \(deviceInfo.modelNumber)")
                                        }.onChange(of: bleManager.autoconnectToDevice) { newValue in
                                            autoconnect = bleManager.autoconnectToDevice
                                            if bleManager.autoconnectToDevice == false {
                                                autoconnectUUID = ""
                                            } else {
                                                autoconnectUUID = bleManager.setAutoconnectUUID
                                            }
                                        }
                                        .modifier(RowModifier(style: .capsule))
                                    }
                                    Toggle(NSLocalizedString("enable_watch_notifications", comment: ""), isOn: $watchNotifications)
                                        .modifier(RowModifier(style: .capsule))
                                    Toggle(NSLocalizedString("notify_about_low_battery", comment: ""), isOn: $batteryNotification)
                                        .modifier(RowModifier(style: .capsule))
                                    Button {
                                        SheetManager.shared.sheetSelection = .notification
                                        SheetManager.shared.showSheet = true
                                    } label: {
                                        Text(NSLocalizedString("send_notification_to", comment: "") + " \(deviceInfo.modelNumber)")
                                            .frame(maxWidth: .infinity)
                                            .foregroundColor(.blue)
                                            .modifier(RowModifier(style: .capsule))
                                    }
                                    .opacity(!watchNotifications || !bleManager.isConnectedToPinetime ? 0.5 : 1.0)
                                    .disabled(!watchNotifications || !bleManager.isConnectedToPinetime)
                                    Button {
                                        BLEWriteManager.init().sendLostNotification()
                                    } label: {
                                        Text(NSLocalizedString("find_lost_device", comment: "") + " \(deviceInfo.modelNumber)")
                                            .frame(maxWidth: .infinity)
                                            .foregroundColor(.blue)
                                            .modifier(RowModifier(style: .capsule))
                                    }
                                    .opacity(!watchNotifications || !bleManager.isConnectedToPinetime ? 0.5 : 1.0)
                                    .disabled(!watchNotifications || !bleManager.isConnectedToPinetime)
                                }
                                Spacer()
                                    .frame(height: 6)
                                VStack {
                                    Button {
                                        showDisconnectConfDialog.toggle()
                                    } label: {
                                        Text(NSLocalizedString("disconnect", comment: "") + " \(deviceInfo.modelNumber)")
                                            .frame(maxWidth: .infinity)
                                            .foregroundColor(.red)
                                            .font(.body.weight(.semibold))
                                            .modifier(RowModifier(style: .capsule))
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                            .padding(.bottom)
                        }
                        
                    }
                    //                    .background(RoundedRectangle(cornerRadius: 32)
                    //                        .foregroundColor(.black)
                    //                        .shadow(color: .black, radius: 32, x: 0, y: 0))
                    //.padding()
                    .onAppear {
                            DownloadManager.shared.updateAvailable = DownloadManager.shared.checkForUpdates(currentVersion: BLEDeviceInfo.shared.firmware)
                    }
            }
        }
        //.background(Color.darkestGray)
    }
}


enum RowModifierStyle {
    case capsule
    case standard
}

struct RowModifier: ViewModifier {
    var style: RowModifierStyle
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.gray.opacity(0.15))
            .foregroundColor(.primary)
            .cornerRadius(style == .capsule ? 40 : 15)
    }
}

#Preview {
    NavigationView {
        DeviceView()
            .onAppear {
                BLEManager.shared.isConnectedToPinetime = true
                BLEManagerVal.shared.firmwareVersion = "1.13.0"
            }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
    let drift: CGSize
    let creationDate: Date
    let lifetime: TimeInterval
    let hue: Double
    
    init() {
        position = CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                           y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
        size = CGFloat.random(in: 175...300)
        opacity = 0
        drift = CGSize(width: CGFloat.random(in: -0.2...0.2), height: CGFloat.random(in: -0.2...0.2))
        creationDate = Date()
        lifetime = Double.random(in: 3...5)
        hue = Double.random(in: 0...1)
    }
}

struct SizePreferenceKey: PreferenceKey {
        typealias Value = CGFloat
        static var defaultValue: Value = 0

        static func reduce(value: inout Value, nextValue: () -> Value) {
            value = nextValue()
        }
}

extension FloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return max(min(self, range.upperBound), range.lowerBound)
    }
}

public extension Color {

    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif
}
