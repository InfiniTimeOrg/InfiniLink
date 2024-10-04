//
//  SoftwareUpdateView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct SoftwareUpdateView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    other
                } label: {
                    Text("Other Versions")
                }
            }
        }
        .navigationTitle("Software Update")
    }
    
    var other: some View {
        List {
            Section {
                NavigationLink {
                    
                } label: {
                    Text("Use Local File")
                }
            }
            Section {
                // TODO: replace with updates from GitHub
                ForEach(1...15, id: \.self) { index in
                    Text("\(index)")
                }
            }
        }
        .navigationTitle("Other Versions")
    }
}

#Preview {
    NavigationView {
        SoftwareUpdateView()
            .navigationBarTitleDisplayMode(.inline)
    }
}
