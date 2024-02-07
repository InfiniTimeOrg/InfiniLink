//
//  FileSystemDebug.swift
//  InfiniLink
//
//  Created by Jen on 1/28/24.
//

import SwiftUI

struct FileSystemDebug: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    //@FocusState private var isTextFieldFocused: Bool
    @State private var commandHistory : [String] = []
    @State private var command = ""
    
    @State private var fsBusy : Bool = false
    
    let homeDirectory = "/"
    @State private var directory = "/"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                Text(NSLocalizedString("file_system", comment: ""))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            VStack {
                ScrollView {
                    ForEach(commandHistory, id: \.self) { history in
                        Text(history)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal)
                    }
                    if fsBusy == false {
                        Text("user@watch \(homeDirectory == directory ? "~" : directory) % \(command)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal)
                    }
                }
                
                Divider()
                HStack {
                    VStack {
                        TextField("Enter command", text: $command)
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                            //.focused($isTextFieldFocused)
                            .keyboardType(.alphabet)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            //.textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.leading)
                    Button(action: {
                        if fsBusy == false {
                            commandHistory.append("user@watch \(homeDirectory == directory ? "~" : directory) % \(command)")
                            handleCommand(command: command)
                            command = ""
                        }
                    }) {
                        Text("Submit")
                            .padding(15)
                            //.padding(.trailing)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            //.cornerRadius(10)
                    }
                    .padding(.trailing)
                }
                .padding(.bottom, 10)
            }
        }
        .navigationBarBackButtonHidden()
        //.onAppear {
        //    isTextFieldFocused = true
        //}
    }
    
    enum ClockType: UInt8 {
        case H24 = 0
        case H12 = 1
    }
    
    enum WeatherFormat: UInt8 {
        case Metric = 0
        case Imperial = 1
    }
    
    enum Notification: UInt8 {
        case On = 0
        case Off = 1
        case Sleep = 2
    }
    
    enum ChimesOption: UInt8 {
        case None = 0
        case Hours = 1
        case HalfHours = 2
    }
    
    enum WakeUpMode: UInt8 {
        case SingleTap = 0
        case DoubleTap = 1
        case RaiseWrist = 2
        case Shake = 3
        case LowerWrist = 4
    }
    
    enum Colors: UInt8 {
        case White = 0
        case Silver = 1
        case Gray = 2
        case Black = 3
        case Red = 4
        case Maroon = 5
        case Yellow = 6
        case Olive = 7
        case Lime = 8
        case Green = 9
        case Cyan = 10
        case Teal = 11
        case Blue = 12
        case Navy = 13
        case Magenta = 14
        case Purple = 15
        case Orange = 16
        case Pink = 17
    }
    
    enum PTSGaugeStyle: UInt8 {
        case Full = 0
        case Half = 1
        case Numeric = 2
    }
    
    enum PTSWeather: UInt8 {
        case On = 0
        case Off = 1
    }
    
    struct PineTimeStyle {
        let ColorTime : Colors = .Teal
        let ColorBar : Colors = .Teal
        let ColorBG : Colors = .Black
        let gaugeStyle : PTSGaugeStyle = .Full
        let weatherEnable : PTSWeather = .Off
    }
    
    struct WatchFaceInfineat {
        let showSideCover : Bool = true
        let colorIndex : UInt8 = 0
    }


    struct Settings {
        let version: Int32
        let stepsGoal: Int32
        let screenTimeOut: Int32
        let clockType: ClockType
        let weatherFormat: WeatherFormat
        let notificationStatus: Notification
        let watchFace: UInt8
        let chimesOption: ChimesOption
        let pineTimeStyle: PineTimeStyle
        //let watchFaceInfineat: WatchFaceInfineat
        //let wakeUpMode: WakeUpMode
        //let shakeWakeThreshold: UInt16
        //let brightLevel: UInt8
        
    }
    
    func handleCommand(command: String) {
        fsBusy = true
        let commands = command.components(separatedBy: " ")
        BLEFSHandler.shared.progress = 0
        
        switch commands[0] {
        case "read":
            if commands.count <= 1 {
                commandHistory.append("ERROR: insignificant arguments.")
                fsBusy = false
                return
            }
            let path = getDir(input: commands[1])
            
            DispatchQueue.global(qos: .default).async {
                let readFile = BLEFSHandler.shared.readFile(path: path, offset: 0)
                if !readFile.valid {commandHistory.append("ERROR: failed to move '\(commands[1])'.")} else {
                    if commands[1] == "settings.dat" {
                        let settings = readFile.data.withUnsafeBytes { ptr -> Settings in
                            return ptr.load(as: Settings.self)
                        }
                        commandHistory.append("Version: \(settings.version)")
                        commandHistory.append("StepsGoal: \(settings.stepsGoal)")
                        commandHistory.append("ScreenTimeOut: \(settings.screenTimeOut)")
                        commandHistory.append("ClockType: \(settings.clockType)")
                        commandHistory.append("WeatherFormat: \(settings.weatherFormat)")
                        commandHistory.append("NotificationStatus: \(settings.notificationStatus)")
                        commandHistory.append("WatchFace: \(settings.watchFace)")
                        commandHistory.append("ChimesOption: \(settings.chimesOption)")
                        commandHistory.append("PineTimeStyle: \(settings.pineTimeStyle)")
                        //commandHistory.append("WatchFaceInfineat: \(settings.watchFaceInfineat)")
                        //commandHistory.append("WakeUpMode: \(settings.wakeUpMode)")
                        //commandHistory.append("ShakeWakeThreshold: \(settings.shakeWakeThreshold)")
                        //commandHistory.append("BrightLevel: \(settings.brightLevel)")
                        
                    }
                    commandHistory.append("Total File Length: \(readFile.totalLength)")
                }
                fsBusy = false
            }
        case "write":
            if commands.count <= 1 {
                commandHistory.append("ERROR: insignificant arguments.")
                fsBusy = false
                return
            }
            let path = getDir(input: commands[1])
            let data = "0700000088130000983a00000100000200031111010000000100000000000000000000009600000002000000".hexToData()!
            
            DispatchQueue.global(qos: .default).async {
                let writeFile = BLEFSHandler.shared.writeFile(data: data, path: path, offset: 0)
                if !writeFile.valid {commandHistory.append("ERROR: failed to move '\(commands[1])'.")}
                commandHistory.append("Total Free Space: \(writeFile.freeSpace)")
                fsBusy = false
            }
        case "ls":
            DispatchQueue.global(qos: .default).async {
                let newDir = commands.count == 1 ? directory : getDir(input: commands[1])
                let dirLS = BLEFSHandler.shared.listDir(path: newDir)
                if dirLS.valid {
                    for dir in dirLS.ls {
                        commandHistory.append("\(dir.pathNames)")
                    }
                } else {
                    commandHistory.append("ERROR: dir '\(newDir)' is not valid.")
                }
                fsBusy = false
            }
        case "cd":
            if commands.count > 1 {
                let newDir = getDir(input: commands[1])
                DispatchQueue.global(qos: .default).async {
                    let dirLS = BLEFSHandler.shared.listDir(path: newDir)
                    if dirLS.valid {
                        directory = newDir
                    } else {
                        commandHistory.append("ERROR: dir '\(newDir)' is not valid.")
                    }
                    fsBusy = false
                }
            } else {
                directory = homeDirectory
                fsBusy = false
            }
        case "mkdir":
            if commands.count <= 1 {
                commandHistory.append("ERROR: no arguments.")
                fsBusy = false
                return
            }
            let newDir = getDir(input: commands[1])
            
            DispatchQueue.global(qos: .default).async {
                let mkDir = BLEFSHandler.shared.makeDir(path: newDir)
                if !mkDir {commandHistory.append("ERROR: failed to create '\(commands[1])'.")}
                fsBusy = false
            }
        case "rm":
            if commands.count <= 1 {
                commandHistory.append("ERROR: insignificant arguments.")
                fsBusy = false
                return
            }
            let newDir = getDir(input: commands[1])
            
            DispatchQueue.global(qos: .default).async {
                let rmDir = BLEFSHandler.shared.deleteFile(path: newDir)
                if !rmDir {commandHistory.append("ERROR: failed to remove '\(commands[1])'.")}
                fsBusy = false
            }
        case "mv":
            if commands.count <= 2 {
                commandHistory.append("ERROR: insignificant arguments.")
                fsBusy = false
                return
            }
            let oldPath = getDir(input: commands[1])
            let newPath = getDir(input: commands[2])
            
            DispatchQueue.global(qos: .default).async {
                let rmDir = BLEFSHandler.shared.moveFileOrDir(oldPath: oldPath, newPath: newPath)
                if !rmDir {commandHistory.append("ERROR: failed to move '\(commands[1])' to '\(commands[2])'.")}
                fsBusy = false
            }
        default:
            commandHistory.append("ERROR: command '\(commands[0])' not found.")
            fsBusy = false
        }
    }
    
    func getDir(input: String) -> String {
        return input.first == "/" ? input : directory.last == "/" ? "\(directory)\(input)" : "\(directory)/\(input)"
    }
}

extension String {
    func hexToData() -> Data? {
        let len = self.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = self.index(self.startIndex, offsetBy: i*2)
            let k = self.index(j, offsetBy: 2)
            let bytes = self[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        return data
    }
}

#Preview {
    FileSystemDebug()
}

