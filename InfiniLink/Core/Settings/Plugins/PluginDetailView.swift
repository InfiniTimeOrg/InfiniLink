//
//  PluginDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import SwiftUI

struct PluginDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var pluginManager = PluginManager.shared
    
    let id: String
    
    @State private var values: [String: String] = [:]
    @State private var settingsChanged = false
    @State private var showDeleteConfirmation = false
    @State private var showClearDataConfirmation = false
    @State private var hasStoredData = false
    @State private var showInfo = false
    @State private var showLogs = false
    
    var plugin: Plugin? {
        pluginManager.plugins.first { $0.id == id }
    }
    
    var body: some View {
        if let plugin {
            content(plugin)
        }
    }
    
    func content(_ plugin: Plugin) -> some View {
        List {
            Section {
                Toggle("Enabled", isOn: Binding(get: { plugin.enabled }, set: { pluginManager.setEnabled($0, for: id) }))
            } footer: {
                if let description = plugin.description {
                    Text(description)
                }
            }
            if !plugin.params.isEmpty {
                Section("Settings") {
                    ForEach(plugin.params, id: \.name) { param in
                        field(for: param)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showInfo = true
                    } label: {
                        Label("Info", systemImage: "info.circle")
                    }
                    Button {
                        showLogs = true
                    } label: {
                        Label("Logs", systemImage: "doc.text")
                    }
                    Divider()
                    if hasStoredData {
                        Button(role: .destructive) {
                            showClearDataConfirmation = true
                        } label: {
                            Label("Clear Stored Data", systemImage: "eraser")
                        }
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Plugin", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .confirmationDialog("Are you sure you want to clear \(plugin.name)'s stored data?", isPresented: $showClearDataConfirmation, titleVisibility: .visible) {
                    Button("Clear Stored Data", role: .destructive) {
                        PluginStore.setStorage([:], for: id)
                        hasStoredData = false
                        pluginManager.restart(id)
                    }
                }
                .confirmationDialog("Are you sure you want to delete \(plugin.name)?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        pluginManager.delete(plugin)
                        dismiss()
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showInfo) {
            PluginInfoView(plugin: plugin)
        }
        .navigationDestination(isPresented: $showLogs) {
            DebugLogListView(target: .plugin, caller: plugin.name)
                .navigationTitle("Logs")
        }
        .navigationTitle(plugin.name)
        .onAppear {
            hasStoredData = !PluginStore.storage(for: id).isEmpty
            for param in plugin.params {
                values[param.name] = PluginStore.value(of: param, for: id) ?? param.defaultValue ?? ""
            }
        }
        .onDisappear {
            // Plugins only read settings when they start
            if settingsChanged {
                settingsChanged = false
                pluginManager.restart(id)
            }
        }
    }
    
    @ViewBuilder
    func field(for param: PluginParam) -> some View {
        let value = Binding(get: { values[param.name] ?? "" }, set: { newValue in
            values[param.name] = newValue
            PluginStore.setValue(newValue, of: param, for: id)
            settingsChanged = true
        })
        
        switch param.kind {
        case .string:
            LabeledContent(param.name) {
                TextField("Not Set", text: value)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            }
        case .secret:
            LabeledContent(param.name) {
                SecureField("Not Set", text: value)
                    .multilineTextAlignment(.trailing)
            }
        case .int:
            LabeledContent(param.name) {
                TextField("Not Set", text: value)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
        case .boolean:
            Toggle(param.name, isOn: Binding(get: { value.wrappedValue == "true" }, set: { value.wrappedValue = $0 ? "true" : "false" }))
        }
    }
}

struct PluginInfoView: View {
    let plugin: Plugin
    
    var body: some View {
        List {
            if !plugin.permissions.isEmpty {
                Section("Permissions") {
                    ForEach(plugin.permissions, id: \.self) { permission in
                        ListRowDetailView(title: permission.title, subtitle: permission.subtitle, icon: permission.icon, iconColor: permission.color)
                    }
                }
            }
            Section {
                AboutRowView("ID", value: plugin.id)
                if let author = plugin.author {
                    AboutRowView("Author", value: author)
                }
                if let url = plugin.downloadURL {
                    AboutRowView("Source", value: url.absoluteString)
                        .lineLimit(1)
                }
            }
            Section {
                NavigationLink("Code") {
                    PluginSourceView(source: PluginStore.source(for: plugin.id) ?? "")
                }
            }
        }
        .navigationTitle("Info")
    }
}

struct PluginSourceView: View {
    let source: String
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(source)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding()
        }
        .navigationTitle("Code")
        .navigationBarTitleDisplayMode(.inline)
    }
}
