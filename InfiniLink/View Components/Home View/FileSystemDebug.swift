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
    
    func handleCommand(command: String) {
        fsBusy = true
        let commands = command.components(separatedBy: " ")
        
        switch commands[0] {
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
                commandHistory.append("ERROR: no arguments.")
                fsBusy = false
                return
            }
            let newDir = getDir(input: commands[1])
            
            DispatchQueue.global(qos: .default).async {
                let rmDir = BLEFSHandler.shared.deleteFile(path: newDir)
                if !rmDir {commandHistory.append("ERROR: failed to remove '\(commands[1])'.")}
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

#Preview {
    FileSystemDebug()
}

