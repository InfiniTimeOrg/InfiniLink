//
//  PluginImportView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import SwiftUI

struct PluginImportView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var pluginManager = PluginManager.shared
    
    let pending: PendingPluginImport
    
    @State private var installError: String?
    
    var plugin: Plugin { pending.plugin }
    var isUpdate: Bool {
        pluginManager.plugins.contains { $0.id == plugin.id }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    AboutRowView("Name", value: plugin.name)
                    if let author = plugin.author {
                        AboutRowView("Author", value: author)
                    }
                    AboutRowView("ID", value: plugin.id)
                } footer: {
                    if let description = plugin.description {
                        Text(description)
                    }
                }
                Section {
                    if plugin.permissions.isEmpty {
                        Text("None")
                            .foregroundStyle(.gray)
                    }
                    ForEach(plugin.permissions, id: \.self) { permission in
                        ListRowDetailView(title: permission.title, subtitle: permission.subtitle, icon: permission.icon, iconColor: permission.color)
                    }
                } header: {
                    Text("Permissions")
                } footer: {
                    Text("This plugin will be able to talk to your watch while InfiniLink is running. Only install plugins from sources you trust.")
                }
            }
            .navigationTitle(isUpdate ? "Update Plugin" : "Install Plugin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isUpdate ? "Update" : "Install") {
                        do {
                            try pluginManager.install(plugin, source: pending.source)
                            dismiss()
                        } catch {
                            installError = error.localizedDescription
                        }
                    }
                }
            }
            .alert("Couldn't Install Plugin", isPresented: Binding(get: { installError != nil }, set: { if !$0 { installError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(installError ?? "")
            }
        }
    }
}
