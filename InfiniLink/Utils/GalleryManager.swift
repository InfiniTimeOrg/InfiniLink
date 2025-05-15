//
//  GalleryManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/12/25.
//

import Foundation

class GalleryManager: ObservableObject {
    static let shared = GalleryManager()
    static let listingURL = "https://infinitimeorg.github.io/InfiniLink-gallery"
    
    @Published var pullRequests = [PullRequest]()
    @Published var error: Error?
    @Published var isLoading = false
    
    init() {
        fetchAllPullRequests()
    }
    
    func fetchAllPullRequests() {
        var all: [PullRequest] = []
        let nextURL = URL(string: "https://api.github.com/repos/InfiniTimeOrg/InfiniTime/pulls?per_page=100&state=open")

        func fetch(url: URL) {
            DispatchQueue.main.async {
                self.isLoading = true
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            // request.setValue("Bearer \()", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, _ in
                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse else { return }

                do {
                    var prs = [PullRequest]()
                    let decoder = JSONDecoder()
                    
                    decoder.dateDecodingStrategy = .iso8601
                    prs = try decoder.decode([PullRequest].self, from: data)
                    all += prs
                    
                    if let linkHeader = httpResponse.value(forHTTPHeaderField: "Link"),
                       let next = self.parseNextLink(from: linkHeader) {
                        fetch(url: next)
                    } else {
                        // We're done fetching all the pulls, update the UI
                        DispatchQueue.main.async {
                            self.pullRequests = all
                            self.isLoading = false
                        }
                    }
                } catch {
                    self.setError(error)
                }
            }.resume()
        }

        if let url = nextURL {
            fetch(url: url)
        }
    }
    
    func parseNextLink(from linkHeader: String) -> URL? {
        let links = linkHeader.components(separatedBy: ",")
        for link in links {
            let parts = link.components(separatedBy: ";")
            if parts.count == 2,
               parts[1].trimmingCharacters(in: .whitespaces) == #"rel="next""# {
                let urlString = parts[0].trimmingCharacters(in: CharacterSet(charactersIn: " <>"))
                return URL(string: urlString)
            }
        }
        return nil
    }
    
    private func setError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.isLoading = false
        }
            
        log(error.localizedDescription, caller: "GalleryManager", target: .app)
    }
}
