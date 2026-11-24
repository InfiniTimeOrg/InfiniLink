//
//  GitHubBuilds.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import UIKit
import AuthenticationServices
import Security

struct GitHubPullRequest: Identifiable {
    let number: Int
    let title: String
    let body: String
    let url: URL
    let author: String
    let buildID: Int
    let builtAt: Date

    var id: Int { number }
}

class GitHubBuilds: NSObject, ObservableObject, URLSessionTaskDelegate, ASWebAuthenticationPresentationContextProviding {
    static let shared = GitHubBuilds()

    static let clientID = "Iv23li9CMf26YR1xGkaD"
    static let clientSecret = Bundle.main.object(forInfoDictionaryKey: "GitHubClientSecret") as? String ?? ""
    static let redirectURI = "infinilink://github-callback"

    private let repository = "InfiniTimeOrg/InfiniTime"
    private let keychainService = "InfiniLink GitHub"

    @Published private(set) var isSignedIn = false
    @Published private(set) var pullRequests = [GitHubPullRequest]()
    @Published private(set) var isLoading = false

    private var authSession: ASWebAuthenticationSession?

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    override init() {
        super.init()
        isSignedIn = token != nil
    }

    @MainActor
    func signIn() async throws {
        struct TokenResponse: Decodable {
            let accessToken: String?

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
            }
        }

        let state = UUID().uuidString
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Self.clientID),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "state", value: state)
        ]

        let callback = try await authenticate(components.url!)
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard items.first(where: { $0.name == "state" })?.value == state, let code = items.first(where: { $0.name == "code" })?.value else {
            throw GitHubError(NSLocalizedString("GitHub couldn't complete sign in. Please try again.", comment: ""))
        }

        let response: TokenResponse = try await post("https://github.com/login/oauth/access_token", [
            "client_id": Self.clientID,
            "client_secret": Self.clientSecret,
            "code": code,
            "redirect_uri": Self.redirectURI
        ])
        guard let token = response.accessToken else {
            throw GitHubError(NSLocalizedString("GitHub couldn't complete sign in. Please try again.", comment: ""))
        }

        saveToken(token)
        isSignedIn = true
    }

    func signOut() {
        deleteToken()
        isSignedIn = false
        pullRequests = []
    }

    @MainActor
    private func authenticate(_ url: URL) async throws -> URL {
        defer { authSession = nil }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "infinilink") { url, error in
                if let url {
                    continuation.resume(returning: url)
                } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(throwing: CancellationError())
                } else {
                    continuation.resume(throwing: error ?? GitHubError(NSLocalizedString("GitHub couldn't complete sign in. Please try again.", comment: "")))
                }
            }
            session.presentationContextProvider = self
            authSession = session
            session.start()
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
    }

    @MainActor
    func loadPullRequests(search: String = "") async throws {
        struct SearchResponse: Decodable {
            struct Results: Decodable {
                let search: Search
            }
            struct Search: Decodable {
                let nodes: [PullRequest]
            }
            struct PullRequest: Decodable {
                let number: Int
                let title: String
                let body: String
                let url: URL
                let author: Author?
                let commits: Commits
            }
            struct Author: Decodable {
                let login: String
            }
            struct Commits: Decodable {
                let nodes: [Commit]
            }
            struct Commit: Decodable {
                let commit: CommitDetails
            }
            struct CommitDetails: Decodable {
                let checkSuites: CheckSuites
            }
            struct CheckSuites: Decodable {
                let nodes: [CheckSuite]
            }
            struct CheckSuite: Decodable {
                let workflowRun: WorkflowRun?
                let checkRuns: CheckRuns
            }
            struct CheckRuns: Decodable {
                let nodes: [CheckRun]
            }
            struct CheckRun: Decodable {
                let conclusion: String?
                let completedAt: Date?
            }
            struct WorkflowRun: Decodable {
                let databaseId: Int
                let workflow: Workflow
            }
            struct Workflow: Decodable {
                let resourcePath: String
            }
            struct Message: Decodable {
                let message: String
            }

            let data: Results?
            let errors: [Message]?
        }

        isLoading = true
        defer { isLoading = false }

        let query = """
        query($q: String!) {
          search(query: $q, type: ISSUE, first: 30) {
            nodes {
              ... on PullRequest {
                number
                title
                body
                url
                author { login }
                commits(last: 1) {
                  nodes {
                    commit {
                      checkSuites(first: 10) {
                        nodes {
                          workflowRun { databaseId workflow { resourcePath } }
                          checkRuns(first: 1, filterBy: { checkName: "build-firmware" }) {
                            nodes { conclusion completedAt }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        """
        let search = search.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        let response: SearchResponse = try await post("https://api.github.com/graphql", GraphQLRequest(query: query, variables: ["q": "repo:\(repository) is:pr is:open sort:updated-desc \(search)"]))
        guard let results = response.data else {
            throw GitHubError(response.errors?.first?.message ?? NSLocalizedString("GitHub couldn't load pull requests.", comment: ""))
        }

        pullRequests = results.search.nodes.compactMap { pullRequest in
            let suite = pullRequest.commits.nodes.last?.commit.checkSuites.nodes.first {
                $0.workflowRun?.workflow.resourcePath.hasSuffix("/main.yml") == true
            }
            guard let suite, let run = suite.workflowRun, let build = suite.checkRuns.nodes.first, build.conclusion == "SUCCESS", let builtAt = build.completedAt, Date().timeIntervalSince(builtAt) < 90 * 24 * 3600 else { return nil }

            return GitHubPullRequest(number: pullRequest.number, title: pullRequest.title, body: pullRequest.body, url: pullRequest.url, author: pullRequest.author?.login ?? "ghost", buildID: run.databaseId, builtAt: builtAt)
        }
    }

    func downloadFirmware(for pullRequest: GitHubPullRequest) async throws -> URL {
        struct ArtifactsResponse: Decodable {
            let artifacts: [Artifact]
        }
        struct Artifact: Decodable {
            let name: String
            let expired: Bool
            let archiveDownloadURL: URL

            enum CodingKeys: String, CodingKey {
                case name
                case expired
                case archiveDownloadURL = "archive_download_url"
            }
        }

        let response: ArtifactsResponse = try await get("https://api.github.com/repos/\(repository)/actions/runs/\(pullRequest.buildID)/artifacts")
        guard let artifact = response.artifacts.first(where: { $0.name.hasPrefix("InfiniTime DFU") && !$0.expired }) else {
            throw GitHubError(NSLocalizedString("This build doesn't have a firmware file, or it has expired.", comment: ""))
        }

        let storageURL = try await redirectLocation(for: artifact.archiveDownloadURL)
        let (downloaded, _) = try await URLSession.shared.download(from: storageURL)

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
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        try check(response, data)
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Decodable>(_ url: String, _ body: some Encodable) async throws -> T {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try check(response, data)
        return try decoder.decode(T.self, from: data)
    }

    private func redirectLocation(for url: URL) async throws -> URL {
        guard let token else { throw GitHubError(NSLocalizedString("Sign in to GitHub to download builds.", comment: "")) }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, let location = http.value(forHTTPHeaderField: "Location"), let redirect = URL(string: location) else {
            try check(response, data)
            throw GitHubError(NSLocalizedString("GitHub didn't return a download for this build.", comment: ""))
        }
        return redirect
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        return nil
    }

    private func check(_ response: URLResponse, _ data: Data) throws {
        struct ErrorResponse: Decodable {
            let message: String
        }

        guard let http = response as? HTTPURLResponse else { return }

        if http.statusCode == 401 {
            throw GitHubError(NSLocalizedString("Your GitHub sign in expired. Please sign in again.", comment: ""), signInExpired: true)
        }
        if http.statusCode == 429 || (http.statusCode == 403 && http.value(forHTTPHeaderField: "x-ratelimit-remaining") == "0") {
            throw GitHubError(NSLocalizedString("GitHub is limiting requests right now. Please try again later.", comment: ""))
        }
        if !(200..<400).contains(http.statusCode) {
            let message = (try? decoder.decode(ErrorResponse.self, from: data))?.message ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw GitHubError(String(format: NSLocalizedString("GitHub returned an error (%d): %@", comment: ""), http.statusCode, message))
        }
    }

    var token: String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }

        return String(data: data, encoding: .utf8)
    }

    private func saveToken(_ token: String) {
        deleteToken()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: Data(token.utf8)
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct GraphQLRequest: Encodable {
    let query: String
    let variables: [String: String]
}

struct GitHubError: LocalizedError {
    let errorDescription: String?
    let signInExpired: Bool

    init(_ message: String, signInExpired: Bool = false) {
        errorDescription = message
        self.signInExpired = signInExpired
    }
}
