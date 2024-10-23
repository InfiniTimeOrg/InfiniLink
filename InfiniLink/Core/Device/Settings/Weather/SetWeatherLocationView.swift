//
//  SetWeatherLocationView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/22/24.
//

import SwiftUI

struct SetWeatherLocationView: View {
    @ObservedObject var weatherController = WeatherController.shared
    
    @StateObject private var mapSearch = MapSearch()
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("setLocation") var setLocation = "Cupertino"
    @AppStorage("displayLocation") var displayLocation = "Cupertino"
    
    var body: some View {
        VStack {
            if mapSearch.locationResults.isEmpty {
                if mapSearch.searchTerm.isEmpty {
                    Text("Use the search bar to find a location.")
                        .frame(maxHeight: .infinity)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(20)
                } else {
                    ProgressView("Loading...")
                }
            } else {
                List(mapSearch.locationResults, id: \.self) { location in
                    Button {
                        displayLocation = location.title
                        setLocation = "\(location.title), \(location.subtitle)"
                        
                        LocationManager.shared.setLocation(setLocation)
                        
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.title)
                                .foregroundStyle(Color.primary)
                            Text(location.subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .searchable(text: $mapSearch.searchTerm, prompt: Text("Search for an address..."))
        .navigationTitle("Custom Location")
    }
}

#Preview {
    SetWeatherLocationView()
}
