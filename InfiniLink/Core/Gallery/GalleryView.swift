//
//  GalleryView.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/12/25.
//

import SwiftUI
import NetworkImage
import MarkdownUI

enum PullRequestType {
    case watchface
    case app
    case other
}

struct GalleryView: View {
    @Environment(\.openURL) var openURL
    
    @ObservedObject var galleryViewModel = GalleryManager.shared
    
    @State private var searchText: String = ""
    
    private func filteredPullRequests(_ type: PullRequestType) -> [PullRequest] {
        var filteredPrs = [PullRequest]()
    
        filteredPrs = galleryViewModel.pullRequests.filter { pr in
            if let labels = pr.labels {
                let isWatchface = labels.contains(where: { $0.name == "new watchface" })
                let isApp = labels.contains(where: { $0.name == "new app" })
                
                switch type {
                case .watchface:
                    return isWatchface
                case .app:
                    return isApp
                case .other:
                    // Return everything that's not an app or watchface because it's already been listed in another section
                    return !isWatchface && !isApp
                }
            }
            // There aren't any labels for the PR, so don't return anything if we're only looking for apps or watch faces
            return type != .other
        }
        
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty {
            return filteredPrs
        } else {
            return filteredPrs.filter { $0.title.lowercased().contains(query) }
        }
    }
    
    var body: some View {
        VStack {
            if galleryViewModel.isLoading {
                ProgressView()
            } else {
                List {
                    Section("Watch Faces") {
                        ForEach(filteredPullRequests(.watchface)) { pr in
                            GalleryRowView(pr)
                        }
                    }
                    Section("Applications") {
                        ForEach(filteredPullRequests(.app)) { pr in
                            GalleryRowView(pr)
                        }
                    }
                    Section("Watch Faces") {
                        ForEach(filteredPullRequests(.other)) { pr in
                            GalleryRowView(pr)
                        }
                    }
                    Section {
                        let font = Font.system(size: 12)
                        HStack(spacing: 1) {
                            Text("Data is fetched from GitHub. ")
                                .foregroundStyle(.secondary)
                            Text("See Source")
                                .font(font.weight(.semibold))
                                .foregroundStyle(.blue)
                                .onTapGesture {
                                    openURL(URL(string: "https://github.com/InfiniTimeOrg/InfiniTime/pulls")!)
                                }
                        }
                        .font(font)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .searchable(text: $searchText)
            }
        }
        .navigationTitle("Gallery")
    }
}

struct GalleryRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var galleryManager = GalleryManager.shared
    
    let pullRequest: PullRequest
    
    init(_ pullRequest: PullRequest) {
        self.pullRequest = pullRequest
    }
    
    var body: some View {
        NavigationLink {
            GalleryDetailView(pullRequest)
        } label: {
            HStack(spacing: 8) {
                let dimensions = CGFloat(70)
                ZStack {
                    Image(.watchScreen)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    // TODO: add image here?
                }
                .frame(width: dimensions, height: dimensions)
                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pullRequest.title)
                            .fontWeight(.semibold)
                        if let body = pullRequest.body {
                            Text(body)
                                .lineLimit(2)
                                .font(.system(size: 15))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
        }
    }
}

struct GalleryDetailView: View {
    @Environment(\.openURL) var openURL
    
    @ObservedObject var galleryManager = GalleryManager.shared
    
    let pullRequest: PullRequest
    
    init(_ pullRequest: PullRequest) {
        self.pullRequest = pullRequest
    }
    
    var body: some View {
        GeometryReader { geo in
            if !galleryManager.isLoading {
                List {
                    Section {
                        VStack(spacing: 0) {
                            WatchScreenshotView(with: nil, geo: geo)
                            VStack(spacing: 6) {
                                Text(pullRequest.title)
                                    .font(.title.weight(.bold))
//                                Text(listing.shortDescription)
//                                    .foregroundStyle(.primary.opacity(0.5))
                            }
                            .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height / 3)
                        .padding(.vertical, 10)
                    }
                    Section {
                        Button("Install to \(DeviceManager.shared.name)") {
                            
                        }
                    }
//                    if let screenshots = listing.screenshots, screenshots.count > 1 {
//                        Section("Screenshots") {
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                HStack(spacing: 0) {
//                                    ForEach(screenshots, id: \.self) { url in
//                                        WatchScreenshotView(with: url, dimensions: CGSize(width: geo.size.width * 1.2, height: geo.size.height * 2))
//                                    }
//                                }
//                                .padding(.horizontal)
//                            }
//                        }
//                        .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
//                    }
                    if let body = pullRequest.body {
                        Section("Description") {
                            Markdown(body)
                        }
                    }
                    Section {
                        AboutRowView("Author", value: pullRequest.user.login)
                        AboutRowView("State", value: pullRequest.state.capitalized)
                        HStack {
                            Text("Planned Release")
                            Spacer()
                            if let milestone = pullRequest.milestone {
                                let open = Double(milestone.open_issues)
                                let closed = Double(milestone.closed_issues)
                                let progress = Double(open / (open + closed))
                                let width = geo.size.width / 3.5
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.6))
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green)
                                        .frame(width: CGFloat(width * progress))
                                }
                                .frame(maxWidth: width)
                                .frame(height: 7)
                            }
                            Spacer()
                            Text(pullRequest.milestone?.title ?? "None")
                                .foregroundStyle(.gray)
                        }
                        /*
                        NavigationLink {
                            List {
                                
                            }
                            .navigationTitle("Comments")
                        } label: {
                            Text("Comments")
                        }
                         */
                    }
                    Section {
                        Button("Open on GitHub") {
                            guard let url = URL(string: pullRequest.html_url) else { return }
                            
                            openURL(url)
                        }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
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
            if let imageUrl = url {
                NetworkImage(url: imageUrl) { image in
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .tint(.white)
                }
                .frame(maxHeight: (geo?.size.width ?? dimensions!.width) / 4.6)
            }
        }
        .frame(width: (geo?.size.width ?? dimensions!.width) / 2.6)
        .frame(maxWidth: (geo?.size.width ?? dimensions!.width) / 2)
    }
}

#Preview {
    NavigationStack {
        GalleryView()
            .navigationBarTitleDisplayMode(.inline)
//        let listing = GalleryManager.shared.watchfaces.first(where: { $0.id == "photoface" }) ?? GalleryListing(id: "fdafdsa", name: "Photo Face", screenshots: [URL(string: "/screenshots/digitalFace1.png")!], description: "Testing description", shortDescription: "Little short description", prNumber: 2237)
//        GalleryDetailView(listing: listing)
    }
}
