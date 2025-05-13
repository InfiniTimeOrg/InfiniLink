//
//  GalleryManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/12/25.
//

import Foundation

struct GalleryResponse: Codable {
    let version: Int
    let applications: [GalleryListing]
    let watchfaces: [GalleryListing]
}
struct GalleryListing: Identifiable, Codable {
    let id: String
    let name: String
    let screenshots: [URL]?
    let state: String?
    let description: String
    let shortDescription: String
    let author: String
    let prURL: URL
    let firmwareZipURL: URL
    let resourcesZipURL: URL
}

class GalleryManager: ObservableObject {
    static let shared = GalleryManager()
    
    private let listingURL = "https://raw.githubusercontent.com/InfiniTimeOrg/InfiniLink/gallery/gallery/listings.json"
    
    @Published var watchfaces: [GalleryListing] = []
    @Published var applications: [GalleryListing] = []
    @Published var error: Error?
    @Published var isLoading = false
    
    init() {
        getListings()
    }
    
    func getListings() {
        isLoading = true
        
        URLSession.shared.dataTask(with: URL(string: listingURL)!) { data, response, error in
            if let error {
                self.setError(error)
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(GalleryResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.applications = response.applications
                    self.watchfaces = response.watchfaces
                    self.isLoading = false
                }
            } catch {
                self.setError(error)
            }
        }.resume()
    }
    
    private func setError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.isLoading = false
        }
            
        log(error.localizedDescription, caller: "GalleryManager", target: .app)
    }
}
