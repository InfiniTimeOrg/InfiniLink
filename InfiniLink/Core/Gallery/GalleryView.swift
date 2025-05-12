//
//  GalleryView.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/12/25.
//

import SwiftUI
import Kingfisher

struct GalleryView: View {
    @ObservedObject var galleryViewModel = GalleryManager.shared
    
    @State private var searchText: String = ""
    
    private func filteredListings(_ listings: [GalleryListing]) -> [GalleryListing] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return listings
        }
        return listings.filter({ $0.name.lowercased().contains(searchText.lowercased())})
    }
    
    var body: some View {
        VStack {
            if galleryViewModel.isLoading {
                ProgressView()
            } else {
                List {
                    Section("Watch Faces") {
                        ForEach(filteredListings(galleryViewModel.watchfaces)) { face in
                            GalleryRowView(face)
                        }
                    }
                    Section("Applications") {
                        ForEach(filteredListings(galleryViewModel.applications)) { app in
                            GalleryRowView(app)
                        }
                    }
                }
                .searchable(text: $searchText)
            }
        }
        .navigationTitle("Gallery")
    }
}

struct GalleryRowView: View {
    let listing: GalleryListing
    
    init(_ listing: GalleryListing) {
        self.listing = listing
    }
    
    var body: some View {
        NavigationLink {
            EmptyView()
        } label: {
            HStack(spacing: 14) {
//                if let image = listing.screenshotURL {
//                    KFImage(image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 50, height: 50)
//                        .clipShape(.rect(cornerRadius: 10))
//                } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
//                }
                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(listing.name)
                            .fontWeight(.semibold)
                        Text(listing.description)
                            .lineLimit(1)
                            .font(.system(size: 15))
                            .foregroundStyle(.gray)
                    }
                    if let state = listing.state {
                        let color: Color = {
                            switch state {
                            case "pending":
                                return .orange
                            case "approved":
                                return .green
                            case "rejected":
                                return .red
                            default:
                                return .blue
                            }
                        }()
                        
                        Text(state)
                            .font(.caption)
                            .padding(3)
                            .padding(.horizontal, 5)
                            .foregroundStyle(color)
                            .background(color.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(color, lineWidth: 1)
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GalleryView()
            .navigationBarTitleDisplayMode(.inline)
    }
}
