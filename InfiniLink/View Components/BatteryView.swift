//
//  StepsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//  
//
    


import SwiftUI

struct BatteryView: View {
    @AppStorage("lastStatusViewWasHeart") var lastStatusViewWasHeart: Bool = false
    @ObservedObject var bleManager = BLEManager.shared
    let chartManager = ChartManager.shared
    
    var body: some View {
        return VStack {
            List() {
                
                Section {
                    BatteryContentView()
                }
            }
			.navigationBarTitle(Text(NSLocalizedString("battery_tilte", comment: ""))) //.font(.subheadline), displayMode: .inline)
        }
        .onAppear() {
            print("Battery")
            chartManager.currentChart = .battery
            lastStatusViewWasHeart = false
        }
    }
}
