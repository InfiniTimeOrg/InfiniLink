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
                            GalleryRowView(listing: face)
                        }
                    }
                    Section("Applications") {
                        ForEach(filteredListings(galleryViewModel.applications)) { app in
                            GalleryRowView(listing: app)
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
    @Environment(\.colorScheme) var colorScheme
    
    let listing: GalleryListing
    
    var body: some View {
        NavigationLink {
            GalleryDetailView(listing: listing)
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Image(.watchScreen)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .brightness(colorScheme == .dark ? 0.0 : 0.04)
                    if let image = listing.screenshots?.first {
                        KFImage(image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(.rect(cornerRadius: 10))
                    } else {
                        Image(systemName: "questionmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 70, height: 70)
                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(listing.name)
                            .fontWeight(.semibold)
                        Text(listing.shortDescription)
                            .lineLimit(2)
                            .font(.system(size: 15))
                            .foregroundStyle(.gray)
                    }
                    if let state = listing.state, state != "merged" {
                        let color: Color = {
                            switch state {
                            case "pending":
                                return .orange
                            case "approved":
                                return .green
                            default:
                                return .blue
                            }
                        }()
                        
                        Text(state.capitalized)
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

struct GalleryDetailView: View {
    @Environment(\.openURL) var openURL
    
    let listing: GalleryListing
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    VStack(spacing: 0) {
                        WatchScreenshotView(with: listing.screenshots?.first, geo: geo)
                        VStack(spacing: 6) {
                            Text(listing.name)
                                .font(.title.weight(.bold))
                            Text(listing.shortDescription)
                                .foregroundStyle(.primary.opacity(0.5))
                            Text("By " + listing.author)
                                .foregroundStyle(Color(.darkGray))
                                .font(.system(size: 15).weight(.semibold))
                        }
                        .multilineTextAlignment(.center)
//                        Button {
//                            
//                        } label: {
//                            Text("Install to \(DeviceManager.shared.name)")
//                                .padding(12)
//                                .foregroundStyle(Color.white)
//                                .background(Color.blue)
//                                .clipShape(Capsule())
//                        }
//                        .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height / 3)
                    .padding(.vertical, 10)
                    Button("Install to \(DeviceManager.shared.name)") {
                        
                    }
                }
                if let screenshots = listing.screenshots {
                    Section("Screenshots") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(screenshots, id: \.self) { url in
                                    WatchScreenshotView(with: url, dimensions: CGSize(width: geo.size.width * 1.2, height: geo.size.height * 2))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                }
                Section("Description") {
                    Text(listing.description)
                }
                Section {
                    AboutRowView("Author", value: listing.author)
                    if let state = listing.state {
                        AboutRowView("State", value: state.capitalized)
                    }
                    AboutRowView("Planned Release Version", value: "1.16.0")
                }
                Section {
                    Button("Open on GitHub") {
                        openURL(listing.prURL)
                    }
                }
            }
        }
//        .navigationTitle(listing.name)
//        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WatchScreenshotView: View {
    let url: URL?
    let geo: GeometryProxy?
    let dimensions: CGSize?
    
    init(with url: URL?, geo: GeometryProxy? = nil, dimensions: CGSize? = nil) {
        self.url = url
        // Both geo and dimensions are allowed to be nil, but only one will be at one time
        // This way we can pick which dimensions we want to use
        self.geo = geo
        self.dimensions = dimensions
    }
    
    var body: some View {
        ZStack {
            Image(.watchScreen)
                .resizable()
                .aspectRatio(contentMode: .fit)
            if let url {
                KFImage(url)
                    .placeholder {
                        ProgressView()
                            .tint(.white)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: (geo?.size.width ?? dimensions!.width) / 4.6)
            }
        }
        .frame(width: (geo?.size.width ?? dimensions!.width) / 2.6)
        .frame(maxWidth: (geo?.size.width ?? dimensions!.width) / 2)
    }
}

#Preview {
    NavigationStack {
//        GalleryView()
//            .navigationBarTitleDisplayMode(.inline)
        let listing = GalleryManager.shared.watchfaces.first(where: { $0.id == "photoface" })!
        GalleryDetailView(listing: listing)
    }
}
