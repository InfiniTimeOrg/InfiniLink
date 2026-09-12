//
//  HeartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import CoreData

struct HeartView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var chartManager = ChartManager.shared

    @State private var samples: [HeartRateSample] = []

    var values: [Double] {
        return samples.map { $0.value }
    }

    func load() async {
        samples = await chartManager.heartRateSamples()
    }

    func heartRate(for val: Double) -> String {
        return val > 0 ? String(format: "%.0f", val) : "--"
    }
    func units(for seconds: Int) -> String {
        if seconds >= 172800 {
            return NSLocalizedString("Several days ago", comment: "")
        } else if seconds >= 86400 {
            let days = seconds / 86400
            return NSLocalizedString("\(days) day\(days == 1 ? "" : "s") ago", comment: "")
        } else if seconds >= 3600 {
            let hours = seconds / 3600
            return NSLocalizedString("\(hours) hour\(hours == 1 ? "" : "s") ago", comment: "")
        } else if seconds >= 60 {
            let minutes = seconds / 60
            return NSLocalizedString("\(minutes) minute\(minutes == 1 ? "" : "s") ago", comment: "")
        }
        return NSLocalizedString("Now", comment: "")
    }
    func timestamp(for date: Date?) -> String? {
        guard let timeInterval = date?.timeIntervalSinceNow else { return nil }

        return units(for: Int(abs(timeInterval)))
    }

    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: String(format: "%.0f", values.last ?? 0), subtitle: timestamp(for: samples.last?.date), units: "BPM", icon: "heart.fill", accent: .red), width: geo.size.width, animate: (samples.last?.date.timeIntervalSinceNow ?? 60) < 60) {
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                HeartChartView()
            }
        }
        .navigationTitle("Heart Rate")
        .task {
            await load()
        }
        .onChange(of: bleManager.heartRate) { _ in
            Task { await load() }
        }
        .toolbar {
            NavigationLink {
                HeartSettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    NavigationView {
        HeartView()
            .onAppear {
                BLEManager.shared.heartRate = 76
            }
            .navigationBarTitleDisplayMode(.inline)
    }
}
