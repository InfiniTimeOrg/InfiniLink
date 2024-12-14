//
//  SleepView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct SleepView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var sleepController = SleepController.shared
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: String(sleepController.sleep.hours), units: "Hours", icon: "bed.double.fill", accent: .purple), width: geo.size.width) {
                        HStack {
                            DetailHeaderSubItemView(title: "Deep", value: String(sleepController.sleep.deep), unit: "hrs")
                            DetailHeaderSubItemView(title: "Core", value: String(sleepController.sleep.core), unit: "hrs")
                            DetailHeaderSubItemView(title: "REM", value: String(sleepController.sleep.rem), unit: "hrs")
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                if !sleepController.sleepData.isEmpty {
                    Section {
                        TableView(data: sleepController.sleepData)
                    }
                } else {
                    Section {
                        Text("There isn't any available sleep data.")
                    }
                }
            }
        }
        .navigationTitle("Sleep")
        .onAppear {
            if bleManager.blefsTransfer != nil && bleManager.hasLoadedCharacteristics {
                sleepController.getSleepCSV()
            }
        }
    }
}

#Preview {
    SleepView()
}
