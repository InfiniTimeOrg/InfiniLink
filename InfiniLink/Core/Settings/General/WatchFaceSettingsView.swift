//
//  WatchFaceSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI
import PhotosUI

struct WatchFaceSettingsView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var catalog = WatchFaceCatalog.shared

    // Shared with Customization so saving here doesn't drop changes made there
    @ObservedObject var editor: WatchSettingsEditor

    private let colorOptions: [(String, Colors)] = [
        ("White", .White), ("Silver", .Silver), ("Gray", .Gray), ("Black", .Black), ("Red", .Red), ("Maroon", .Maroon),
        ("Yellow", .Yellow), ("Olive", .Olive), ("Lime", .Lime), ("Green", .Green), ("Cyan", .Cyan), ("Teal", .Teal),
        ("Blue", .Blue), ("Navy", .Navy), ("Magenta", .Magenta), ("Purple", .Purple), ("Orange", .Orange), ("Pink", .Pink)
    ]
    private let infineatColors = ["Orange", "Blue", "Green", "Rainbow", "Gray", "Nord Blue", "Nord Green"]
    private let prideFlags = ["Gay", "Trans", "Bi", "Lesbian"]

    private func binding<T>(_ keyPath: WritableKeyPath<WatchSettingsFile, T>, default value: T) -> Binding<T> {
        Binding(
            get: { editor.file?[keyPath: keyPath] ?? value },
            set: { editor.file?[keyPath: keyPath] = $0 }
        )
    }

    private func colorPicker(_ title: LocalizedStringKey, _ keyPath: WritableKeyPath<WatchSettingsFile, UInt8>) -> some View {
        Picker(title, selection: binding(keyPath, default: 0)) {
            ForEach(colorOptions, id: \.1) { option in
                Text(LocalizedStringKey(option.0)).tag(option.1.rawValue)
            }
        }
    }

    var body: some View {
        ConnectedView {
            List {
                if editor.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let file = editor.file {
                    Section {
                        WatchFaceView(settings: file.settings)
                            .frame(width: 160, height: 160)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(Text("Preview of \(catalog.name(for: file.watchFace))"))
                    }
                    .listRowBackground(Color.clear)
                    Section("Watch Face") {
                        ForEach(catalog.visibleFaces) { face in
                            Button {
                                editor.file?.watchFace = face.index
                            } label: {
                                HStack {
                                    Text(LocalizedStringKey(face.name))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    if file.watchFace == face.index {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .accessibilityAddTraits(file.watchFace == face.index ? .isSelected : [])
                        }
                        NavigationLink("Manage Watch Faces") {
                            ManageWatchFacesView()
                        }
                    }
                    switch catalog.face(at: file.watchFace)?.id {
                    case "pineTimeStyle":
                        Section("PineTimeStyle") {
                            colorPicker("Time", \.ptsColorTime)
                            colorPicker("Bar", \.ptsColorBar)
                            colorPicker("Background", \.ptsColorBG)
                            Picker("Gauge", selection: binding(\.ptsGaugeStyle, default: 0)) {
                                Text("Full").tag(PTSGaugeStyle.Full.rawValue)
                                Text("Half").tag(PTSGaugeStyle.Half.rawValue)
                                Text("Numeric").tag(PTSGaugeStyle.Numeric.rawValue)
                            }
                            Toggle("Show Weather", isOn: Binding(
                                get: { file.ptsWeather == PTSWeather.On.rawValue },
                                set: { editor.file?.ptsWeather = $0 ? PTSWeather.On.rawValue : PTSWeather.Off.rawValue }
                            ))
                        }
                    case "infineat":
                        Section("Infineat") {
                            Picker("Colors", selection: binding(\.infineatColorIndex, default: 0)) {
                                ForEach(infineatColors.indices, id: \.self) { index in
                                    Text(LocalizedStringKey(infineatColors[index])).tag(UInt32(index))
                                }
                            }
                            Toggle("Show Side Cover", isOn: binding(\.infineatShowSideCover, default: true))
                        }
                    case "prideFlag":
                        Section("Pride Flag") {
                            Picker("Flag", selection: binding(\.prideFlag, default: 0)) {
                                ForEach(prideFlags.indices, id: \.self) { index in
                                    Text(LocalizedStringKey(prideFlags[index])).tag(Optional(UInt8(index)))
                                }
                            }
                        }
                    default:
                        EmptyView()
                    }
                    Section {
                        WatchSettingsSaveButton(editor: editor)
                    }
                } else if editor.loadFailed {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("InfiniLink couldn't read the settings from \(deviceManager.name). Watch face settings need InfiniTime 1.14 or later.")
                        if let detail = editor.failureDetail {
                            Text(detail)
                                .font(.footnote.monospaced())
                                .foregroundStyle(.gray)
                                .textSelection(.enabled)
                        }
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Watch Face")
    }
}

struct ManageWatchFacesView: View {
    @ObservedObject var catalog = WatchFaceCatalog.shared

    @State private var newName = ""
    @State private var showResetConfirmation = false

    var body: some View {
        List {
            Section {
                ForEach(catalog.allFaces) { face in
                    WatchFaceRow(face: face)
                        .deleteDisabled(!face.isCustom)
                }
                .onMove { source, destination in
                    catalog.moveFaces(from: source, to: destination)
                }
                .onDelete { offsets in
                    catalog.removeFaces(at: offsets)
                }
            } header: {
                Text("Watch Faces")
            } footer: {
                Text("Put these in the same order as the watch faces in your watch's firmware. Turn off faces that aren't included so they don't show up. Faces from newer versions of InfiniTime start off.")
            }
            Section(footer: Text("Add watch faces from custom firmware builds, then move them to where they are in the firmware. You can add a photo of each one to use as its preview.")) {
                HStack {
                    TextField("Name", text: $newName)
                    Button("Add") {
                        catalog.addCustomFace(name: newName.trimmingCharacters(in: .whitespaces))
                        newName = ""
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            Section {
                Button("Reset to Defaults", role: .destructive) {
                    showResetConfirmation = true
                }
            }
        }
        .navigationTitle("Manage Watch Faces")
        .toolbar {
            EditButton()
        }
        .confirmationDialog("Reset Watch Faces", isPresented: $showResetConfirmation) {
            Button("Reset to Defaults", role: .destructive) {
                catalog.resetToDefaults()
            }
        } message: {
            Text("Watch faces will go back to InfiniTime's order, all of them will be shown, and your custom watch faces will be removed.")
        }
    }
}

struct WatchFaceRow: View {
    @ObservedObject var catalog = WatchFaceCatalog.shared

    @State private var selectedPhoto: PhotosPickerItem?

    let face: WatchFaceEntry

    var body: some View {
        HStack {
            if let image = catalog.image(for: face) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            face.isCustom ? Text(verbatim: face.name) : Text(LocalizedStringKey(face.name))
            Spacer()
            if face.isCustom {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Text(face.imageFile == nil ? "Add Photo" : "Change Photo")
                }
                .buttonStyle(.borderless)
            }
            Toggle("Show \(face.name)", isOn: Binding(
                get: { catalog.isShown(face) },
                set: { catalog.setShown($0, for: face) }
            ))
            .labelsHidden()
        }
        .contextMenu {
            if face.imageFile != nil {
                Button(role: .destructive) {
                    catalog.setImage(nil, for: face)
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
        .onChange(of: selectedPhoto) { item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
                await MainActor.run {
                    catalog.setImage(image, for: face)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WatchFaceSettingsView(editor: WatchSettingsEditor())
    }
}
