//
//  StepsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//  
//
    

import SwiftUI

struct HeartView: View {
    @AppStorage("lastStatusViewWasHeart") var lastStatusViewWasHeart: Bool = false
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var colorScheme
    let chartManager = ChartManager.shared
    
    var body: some View {
        return VStack {
            List() {
                HStack {
                    Image(systemName: "heart.fill")
                        .imageScale(.large)
                        .foregroundColor(.red)
                    Text(String(Int(bleManagerVal.heartBPM)) + " " + NSLocalizedString("bpm", comment: ""))
                        .foregroundColor(.red)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        chartManager.currentChart = .heart
                        SheetManager.shared.sheetSelection = .chartSettings
                        SheetManager.shared.showSheet = true
                    } label: {
                        Image(systemName: "gear")
                            .padding(.vertical)
                    }
                }
                
                HeartChart()
            }
            .navigationBarTitle(Text(NSLocalizedString("heart_tilte", comment: ""))) //.font(.subheadline), displayMode: .inline)
        }
        .onAppear() {
            print("Heart")
            chartManager.currentChart = .heart
            lastStatusViewWasHeart = true
        }
    }
}
