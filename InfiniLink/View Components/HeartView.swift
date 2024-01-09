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
    @Environment(\.presentationMode) var presMode
    
    let chartManager = ChartManager.shared
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)], predicate: NSPredicate(format: "chart == 0"))
    private var chartPoints: FetchedResults<ChartDataPoint>
    
    var body: some View {
        let dataPoints = ChartManager.shared.convert(results: chartPoints)
        
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Button {
                    presMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                Text(NSLocalizedString("heart_rate", comment: "Heart Rate"))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                Button {
                    chartManager.currentChart = .heart
                    SheetManager.shared.sheetSelection = .chartSettings
                    SheetManager.shared.showSheet = true
                } label: {
                    Image(systemName: "gear")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            if dataPoints.count < 1 {
                VStack(alignment: .center, spacing: 14) {
                    Spacer()
                    Image(systemName: "heart")
                        .imageScale(.large)
                        .font(.system(size: 30).weight(.semibold))
                        .foregroundColor(.red)
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("oops!", comment: "").capitalized)
                            .font(.largeTitle.weight(.bold))
                        Text(NSLocalizedString("insufficient_heart_rate_data", comment: ""))
                            .font(.title2.weight(.semibold))
                    }
                    Spacer()
                }
            } else {
                HStack {
                    Image(systemName: "heart.fill")
                    Text(String(format: "%d", bleManagerVal.heartBPM))
                    Text(NSLocalizedString("bpm", comment: "BPM"))
                }
                .padding()
                .font(.body.weight(.semibold))
                .foregroundColor(.red)
                Divider()
                    .padding(.bottom)
                HeartChart()
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            chartManager.currentChart = .heart
            lastStatusViewWasHeart = true
        }
    }
}

#Preview {
    NavigationView {
        HeartView()
    }
}
