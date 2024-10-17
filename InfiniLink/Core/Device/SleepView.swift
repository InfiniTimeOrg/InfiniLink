//
//  SleepView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct TableView: View {
    let data: [[String]]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(0..<data.count, id: \.self) { rowIndex in
                HStack {
                    ForEach(0..<data[rowIndex].count, id: \.self) { colIndex in
                        Text(data[rowIndex][colIndex])
                            .frame(minWidth: 100, alignment: .leading)
                            .padding(5)
                            .border(Color.gray)
                    }
                }
            }
        }
        .padding()
    }
}

struct SleepView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var sleepController = SleepController.shared
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: "8", units: "Hours", icon: "bed.double.fill", accent: .purple), width: geo.size.width) {
                        HStack {
                            DetailHeaderSubItemView(title: "Deep", value: "2.5hrs")
                            DetailHeaderSubItemView(title: "Core", value: "5hrs")
                            DetailHeaderSubItemView(title: "REM", value: "2hrs")
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                Section {
                    TableView(data: sleepController.sleepData)
                }
            }
        }
        .navigationTitle("Sleep")
        .onAppear {
            if bleManager.blefsTransfer != nil {
                sleepController.getSleepCSV()
            }
        }
    }
}

#Preview {
    SleepView()
}
