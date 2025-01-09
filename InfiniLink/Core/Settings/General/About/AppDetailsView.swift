//
//  AppDetailsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/7/25.
//

import SwiftUI

struct AppDetailsView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("""
InfiniLink is the official iOS companion app for InfiniTime. To submit a bug report or request a feature, open an issue on InfiniLink's GitHub repository, or send feedback in TestFlight.

Receiving notifications on your InfiniTime device requires the Apple Notification Center Service, implemented in pull request #2217, linked below.

Music control from InfiniTime is available when using the Apple Music app, but system-wide media control will require the Apple Media Service to be implemented InfiniTime.

For more information on InfiniLink or InfiniTime, visit their GitHub repositories.
""")
                }
                Section {
                    Text("""
This new version of InfiniLink has not been localized yet, so if you can help translate, visit the InfiniLink GitHub repo to a pull request!
""")
                }
                Section("Links") {
                    Button("Pull Request #2217 on GitHub") {
                        guard let url = URL(string: "https://github.com/InfiniTimeOrg/InfiniTime/pull/2217") else { return }
                        
                        openURL(url)
                    }
                }
                Section {
                    Button("InfiniLink on TestFlight") {
                        guard let url = URL(string: testFlightLink) else { return }
                        
                        openURL(url)
                    }
                    Button("InfiniLink on GitHub") {
                        guard let url = URL(string: "https://github.com/InfiniTimeOrg/InfiniLink") else { return }
                        
                        openURL(url)
                    }
                    Button("InfiniTime on GitHub") {
                        guard let url = URL(string: "https://github.com/InfiniTimeOrg/InfiniTime") else { return }
                        
                        openURL(url)
                    }
                }
            }
            .navigationTitle("About InfiniLink")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AppDetailsView()
}
