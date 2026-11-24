//
//  GitHubBuilds.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import Foundation

struct GitHubPullRequest: Identifiable {
    let number: Int
    let title: String
    let body: String
    let url: URL
    let author: String
    let buildID: Int
    let branch: String
    let builtAt: Date

    var id: Int { number }
}

class GitHubBuilds: ObservableObject {
    static let shared = GitHubBuilds()

    private let repository = "InfiniTimeOrg/InfiniTime"

    @Published private(set) var pullRequests = [GitHubPullRequest]()
    @Published private(set) var isLoading = false

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    @MainActor
    func loadPullRequests() async throws {
        struct PullRequest: Decodable {
            let number: Int
            let title: String
            let body: String?
            let html_url: URL
            let user: User?
            let head: Head
        }
        struct User: Decodable {
            let login: String
        }
        struct Head: Decodable {
            let sha: String
            let ref: String
        }
        struct RunsResponse: Decodable {
            let workflow_runs: [Run]
        }
        struct Run: Decodable {
            let id: Int
            let head_sha: String
            let updated_at: Date
        }

        isLoading = true
        defer { isLoading = false }

        async let pulls: [PullRequest] = get("https://api.github.com/repos/\(repository)/pulls?state=open&sort=updated&direction=desc&per_page=100")
        async let runs: RunsResponse = get("https://api.github.com/repos/\(repository)/actions/workflows/main.yml/runs?event=pull_request&status=success&per_page=100")

        var latestRuns = [String: Run]()
        for run in try await runs.workflow_runs where latestRuns[run.head_sha] == nil {
            latestRuns[run.head_sha] = run
        }

        pullRequests = try await pulls.compactMap { pullRequest in
            guard let run = latestRuns[pullRequest.head.sha], Date().timeIntervalSince(run.updated_at) < 90 * 24 * 3600 else { return nil }

            return GitHubPullRequest(number: pullRequest.number, title: pullRequest.title, body: pullRequest.body ?? "", url: pullRequest.html_url, author: pullRequest.user?.login ?? "ghost", buildID: run.id, branch: pullRequest.head.ref, builtAt: run.updated_at)
        }
    }

    func downloadFirmware(for pullRequest: GitHubPullRequest) async throws -> URL {
        let artifact = "InfiniTime DFU \(pullRequest.branch.replacingOccurrences(of: "/", with: "-")).zip"
        let url = URL(string: "https://nightly.link/\(repository)/actions/runs/\(pullRequest.buildID)")!.appendingPathComponent(artifact)

        let (downloaded, response) = try await URLSession.shared.download(from: url)
        if (response as? HTTPURLResponse)?.statusCode == 404 {
            throw GitHubError(NSLocalizedString("This build doesn't have a firmware file, or it has expired.", comment: ""))
        }
        try check(response, Data())

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("GitHubBuild-\(pullRequest.buildID)", isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let firmware = directory.appendingPathComponent("InfiniTime-\(pullRequest.number).zip")
        try FileManager.default.moveItem(at: downloaded, to: firmware)
        return firmware
    }

    private func get<T: Decodable>(_ url: String) async throws -> T {
        var request = URLRequest(url: URL(string: url)!)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        try check(response, data)
        return try decoder.decode(T.self, from: data)
    }

    private func check(_ response: URLResponse, _ data: Data) throws {
        struct ErrorResponse: Decodable {
            let message: String
        }

        guard let http = response as? HTTPURLResponse else { return }

        if http.statusCode == 429 || (http.statusCode == 403 && http.value(forHTTPHeaderField: "x-ratelimit-remaining") == "0") {
            throw GitHubError(NSLocalizedString("GitHub is limiting requests right now. Please try again later.", comment: ""))
        }
        if !(200..<400).contains(http.statusCode) {
            let message = (try? decoder.decode(ErrorResponse.self, from: data))?.message ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw GitHubError(String(format: NSLocalizedString("GitHub returned an error (%d): %@", comment: ""), http.statusCode, message))
        }
    }
}

struct GitHubError: LocalizedError {
    let errorDescription: String?

    init(_ message: String) {
        errorDescription = message
    }
}
