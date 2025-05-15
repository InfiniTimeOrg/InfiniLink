//
//  PullRequest.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/13/25.
//

import Foundation

struct PullRequest: Identifiable, Codable {
    let url: String
    let id: Int
    let node_id: String
    let html_url: String
    let diff_url: String
    let patch_url: String
    let issue_url: String
    let number: Int
    let state: String
    let locked: Bool
    let title: String
    let user: User
    let body: String?
    let created_at: Date
    let updated_at: Date
    let closed_at: Date?
    let merged_at: Date?
    let merge_commit_sha: String?
    let assignee: User?
    let assignees: [User]
    let requested_reviewers: [User]
    let labels: [PRLabel]?
    let milestone: Milestone?
    let draft: Bool
    let commits_url: String
    let review_comments_url: String
    let review_comment_url: String
    let comments_url: String
    let statuses_url: String
    let head: HeadBranch
}

struct HeadBranch: Codable {
    let label: String
    let ref: String
    let sha: String
}

struct PRLabel: Codable {
    let id: Int
    let node_id: String
    let url: String
    let name: String
    let description: String
    let color: String
    let `default`: Bool
}

struct Milestone: Codable {
    let url: URL
    let html_url: URL
    let labels_url: URL
    let id: Int
    let node_id: String
    let number: Int
    let state: String
    let title: String
    let description: String?
    let creator: User
    let open_issues: Int
    let closed_issues: Int
    let created_at: Date
    let updated_at: Date
    let due_on: Date?
    let closed_at: Date?
}

struct User: Codable {
    let login: String
    let id: Int
    let node_id: String
    let avatar_url: String
    let gravatar_id: String?
    let url: String
    let html_url: String
    let followers_url: String
    let following_url: String
    let gists_url: String
    let starred_url: String
    let subscriptions_url: String
    let organizations_url: String
    let repos_url: String
    let events_url: String
    let received_events_url: String
    let type: String
    let user_view_type: String
    let site_admin: Bool
}

struct Branch: Codable {
    let label: String
    let ref: String
    let sha: String
    let user: User
    let repo: Repository
}

struct Repository: Codable {
    let id: Int
    let node_id: String
    let name: String
    let full_name: String
    let `private`: Bool
    let owner: User
    let html_url: String
    let description: String
    let fork: Bool
    let url: String
    let forks_url: String
    let keys_url: String
    let collaborators_url: String
    let teams_url: String
    let hooks_url: String
    let issue_events_url: String
    let events_url: String
    let assignees_url: String
    let branches_url: String
    let tags_url: String
    let blobs_url: String
    let git_tags_url: String
    let git_refs_url: String
    let trees_url: String
    let statuses_url: String
    let languages_url: String
    let stargazers_url: String
    let contributors_url: String
    let subscribers_url: String
    let subscription_url: String
    let commits_url: String
    let git_commits_url: String
    let comments_url: String
    let issue_comment_url: String
    let contents_url: String
    let compare_url: String
    let merges_url: String
    let archive_url: String
    let downloads_url: String
    let issues_url: String
    let pulls_url: String
    let milestones_url: String
    let notifications_url: String
    let labels_url: String
    let releases_url: String
    let deployments_url: String
    let created_at: String
    let updated_at: String
    let pushed_at: String
    let git_url: String
    let ssh_url: String
    let clone_url: String
    let svn_url: String
    let homepage: String
    let size: Int
    let stargazers_count: Int
    let watchers_count: Int
    let language: String
    let has_issues: Bool
    let has_projects: Bool
    let has_downloads: Bool
    let has_wiki: Bool
    let has_pages: Bool
    let has_discussions: Bool
    let forks_count: Int
    let mirror_url: String?
    let archived: Bool
    let disabled: Bool
    let open_issues_count: Int
    let license: License
    let allow_forking: Bool
    let is_template: Bool
    let web_commit_signoff_required: Bool
    let topics: [String]
    let visibility: String
    let forks: Int
    let open_issues: Int
    let watchers: Int
    let default_branch: String
}

struct License: Codable {
    let key: String
    let name: String
    let spdx_id: String
    let url: String
    let node_id: String
}
