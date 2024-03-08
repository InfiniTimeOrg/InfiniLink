//
//  DFUPullRequestDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/7/24.
//

import SwiftUI
import NetworkImage
import MarkdownUI
import SwiftyJSON

struct DFUPullRequestDetailView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var dfuUpdater = DFU_Updater.shared
    
    @Environment(\.presentationMode) var presMode
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var externalResources: Bool
    
    let pr: PullRequest
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {presMode.wrappedValue.dismiss()}) {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                Text("#\(String(pr.number))")
                    .foregroundColor(.gray)
                    .font(.title2.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            Divider()
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        // NetworkImage is needed by Markdown UI, so we may as make use of it
                        NetworkImage(url: URL(string: pr.user.avatar_url)) { state in
                            switch state {
                            case .empty:
                                ProgressView()
                            case .success(let image, _):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "circle.slash")
                                    .imageScale(.large)
                                    .font(.body.weight(.semibold))
                                    .padding(12)
                                    .background(Material.regular)
                                    .clipShape(Circle())
                            }
                        }
                        .frame(width: 45, height: 45)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(pr.title)
                                .font(.title.bold())
                                .lineLimit(3)
                            Text("By @\(pr.user.login)")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    Divider()
                        .padding(.horizontal, -16)
                    Group {
                        if pr.body.isEmpty {
                            Text("No description provided.")
                        } else {
                            Markdown(pr.body.replacingOccurrences(of: "\n", with: "\n\n"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                        .padding(.horizontal, -16)
                    VStack(spacing: 10) {
                        Button(action: {
                            downloadManager.fetchWorkflowRun(dfu: true, pr: pr) { artifact in
                                print(artifact)
                                dfuUpdater.firmwareFilename = artifact.name
                                dfuUpdater.firmwareSelected = true
                                dfuUpdater.local = false
                                downloadManager.updateAvailable = true
                                downloadManager.updateVersion = "Unknown"
                                downloadManager.updateBody = pr.body
                                downloadManager.updateSize = 0
                                downloadManager.browser_download_url = artifact.archive_download_url
                                
                                externalResources = false
                                
                                presMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text("Use Software Update")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        Button(action: {
                            downloadManager.fetchWorkflowRun(dfu: false, pr: pr) { artifact in
                                print(artifact)
                                dfuUpdater.firmwareFilename = artifact.name
                                dfuUpdater.firmwareSelected = true
                                dfuUpdater.local = false
                                downloadManager.updateAvailable = true
                                downloadManager.updateVersion = ""
                                downloadManager.updateSize = 0
                                downloadManager.browser_download_url = artifact.archive_download_url
                                
                                externalResources = true
                                
                                presMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text("Use External Resources")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    // Use data from most recent PR
    DFUPullRequestDetailView(externalResources: .constant(false), pr: PullRequest(id: 0, title: "PhotoStyle Watch Face", url: "URL", draft: false, number: 2023, user: GHUser(id: 0, login: "username", avatar_url: "https://avatars.githubusercontent.com/u/131915465?v=4"), body: "Testing...", closed_at: nil, merged_at: nil))
}
