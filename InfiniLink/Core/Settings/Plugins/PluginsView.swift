//
//  PluginsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import SwiftUI

struct PendingPluginImport: Identifiable {
    let plugin: Plugin
    let source: String
    
    var id: String { plugin.id }
}

struct PluginsView: View {
    @ObservedObject var pluginManager = PluginManager.shared
    
    @State private var pendingImport: PendingPluginImport?
    @State private var showFileImporter = false
    @State private var showURLAlert = false
    @State private var urlText = ""
    @State private var isDownloading = false
    @State private var importError: String?
    
    var body: some View {
        List {
            Section {
                if pluginManager.plugins.isEmpty {
                    Text("No Plugins")
                        .foregroundStyle(.gray)
                }
                ForEach(pluginManager.plugins) { plugin in
                    NavigationLink {
                        PluginDetailView(id: plugin.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(plugin.name)
                                if let description = plugin.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }
                            Spacer()
                            Text(plugin.enabled ? "On" : "Off")
                                .foregroundStyle(.gray)
                        }
                    }
                }
            } footer: {
                Text("Plugins can talk to your watch and add new features to InfiniLink. Only install plugins from sources you trust.")
            }
        }
        .navigationTitle("Plugins")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isDownloading {
                    ProgressView()
                } else {
                    Menu {
                        Button {
                            if let source = UIPasteboard.general.string {
                                prepareImport(source)
                            }
                        } label: {
                            Label("Paste Code", systemImage: "doc.on.clipboard")
                        }
                        Button {
                            showFileImporter = true
                        } label: {
                            Label("Choose File...", systemImage: "folder")
                        }
                        Button {
                            showURLAlert = true
                        } label: {
                            Label("From URL...", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.javaScript, .plainText]) { result in
            do {
                let url = try result.get()
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                
                prepareImport(try String(contentsOf: url, encoding: .utf8))
            } catch {
                importError = error.localizedDescription
            }
        }
        .alert("Import from URL", isPresented: $showURLAlert) {
            TextField("URL", text: $urlText)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {}
            Button("Import") {
                Task {
                    await importFromURL()
                }
            }
        }
        .alert("Couldn't Import Plugin", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
        .sheet(item: $pendingImport) { pending in
            PluginImportView(pending: pending)
        }
    }
    
    func prepareImport(_ source: String, url: URL? = nil) {
        do {
            pendingImport = PendingPluginImport(plugin: try Plugin.parse(source, downloadURL: url), source: source)
        } catch {
            importError = error.localizedDescription
        }
    }
    
    func importFromURL() async {
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespaces)), url.scheme == "https" || url.scheme == "http" else {
            importError = NSLocalizedString("Enter a valid URL.", comment: "")
            return
        }
        
        isDownloading = true
        defer { isDownloading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            prepareImport(String(decoding: data, as: UTF8.self), url: url)
            urlText = ""
        } catch {
            importError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        PluginsView()
    }
}
