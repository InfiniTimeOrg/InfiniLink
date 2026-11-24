//
//  GitHubBuildsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

struct GitHubBuildsView: View {
    @ObservedObject var gitHub = GitHubBuilds.shared
    @ObservedObject var downloadManager = DownloadManager.shared

    @Environment(\.openURL) var openURL

    @State private var pendingPullRequest: GitHubPullRequest?
    @State private var downloadingPullRequest: GitHubPullRequest?
    @State private var searchText = ""
    @State private var error: String?

    let onSelect: () -> Void

    private func perform(_ action: () async throws -> Void) async {
        do {
            try await action()
        } catch {
            if !(error is CancellationError) && !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }
    }

    private func install(_ pullRequest: GitHubPullRequest) async {
        downloadingPullRequest = pullRequest
        defer { downloadingPullRequest = nil }

        await perform {
            let firmware = try await gitHub.downloadFirmware(for: pullRequest)
            downloadManager.selectLocalFirmware(firmware, notes: pullRequest.body)
            onSelect()
        }
    }

    var body: some View {
        pullRequestList
        .navigationTitle("Development Builds")
        .alert("Install Development Build?", isPresented: Binding(get: { pendingPullRequest != nil }, set: { if !$0 { pendingPullRequest = nil } }), presenting: pendingPullRequest) { pullRequest in
            Button("Download") {
                Task { await install(pullRequest) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { pullRequest in
            Text(String(format: NSLocalizedString("#%d: %@\n\nThis build is from a pull request that may not have been reviewed. Only install it if you trust the code it was built from.", comment: ""), pullRequest.number, pullRequest.title))
        }
        .alert("Error", isPresented: Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
    }

    var filteredPullRequests: [GitHubPullRequest] {
        let search = searchText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        guard !search.isEmpty else { return gitHub.pullRequests }

        return gitHub.pullRequests.filter { String($0.number).hasPrefix(search) || $0.title.localizedCaseInsensitiveContains(search) || $0.author.localizedCaseInsensitiveContains(search) }
    }

    var pullRequestList: some View {
        List {
            Section {
                if gitHub.isLoading && gitHub.pullRequests.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if filteredPullRequests.isEmpty && !gitHub.isLoading {
                    (searchText.isEmpty ? Text("There aren't any pull requests with builds.") : Text("No pull requests match your search."))
                        .foregroundStyle(.gray)
                }
                ForEach(filteredPullRequests) { pullRequest in
                    Button {
                        pendingPullRequest = pullRequest
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pullRequest.title)
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(2)
                                Text(verbatim: "#\(pullRequest.number) • \(pullRequest.author) • \(pullRequest.builtAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            if downloadingPullRequest?.id == pullRequest.id {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(downloadingPullRequest != nil)
                    .contextMenu {
                        Button {
                            openURL(pullRequest.url)
                        } label: {
                            Label("View on GitHub", systemImage: "safari")
                        }
                    }
                }
            } footer: {
                Text("Open pull requests to InfiniTime with a successful build. Builds expire after 90 days and may be unstable.")
            }
        }
        .searchable(text: $searchText, prompt: Text("Search pull requests"))
        .refreshable {
            await perform { try await gitHub.loadPullRequests() }
        }
        .task {
            await perform { try await gitHub.loadPullRequests() }
        }
    }
}

#Preview {
    NavigationStack {
        GitHubBuildsView(onSelect: {})
    }
}
