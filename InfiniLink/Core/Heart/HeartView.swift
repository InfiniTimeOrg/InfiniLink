//
//  StepsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//
//

import Accelerate
import SwiftUI

struct HeartView: View {
    @AppStorage("lastStatusViewWasHeart") var lastStatusViewWasHeart: Bool = false
    
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presMode
    
    let chartManager = ChartManager.shared
    
    @State private var animationAmount: CGFloat = 1
    
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
            if dataPoints.count < 2 {
                VStack(alignment: .center, spacing: 14) {
                    Spacer()
                    Image(systemName: "heart")
                        .imageScale(.large)
                        .font(.system(size: 40).weight(.semibold))
                        .foregroundColor(.red)
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("oops", comment: ""))
                            .font(.largeTitle.weight(.bold))
                        Text(NSLocalizedString("insufficient_heart_rate_data", comment: ""))
                            .font(.title2.weight(.semibold))
                    }
                    Spacer()
                }
            } else {
                VStack {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 10.0)
                            .opacity(0.3)
                            .foregroundColor(Color.gray)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(min(bleManagerVal.heartBPM / 250, 1.0)))
                            .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, lineJoin: .round))
                            .foregroundColor(.red)
                            .rotationEffect(Angle(degrees: 90.0 - Double(bleManagerVal.heartBPM / 250) * 180.0))
                        VStack(spacing: 5) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 35))
                                .imageScale(.large)
                            Text(String(format: "%.0f", bleManagerVal.heartBPM) + " " + NSLocalizedString("bpm", comment: "BPM"))
                                .font(.system(size: 32).weight(.bold))
                            if dataPoints.count >= 5 {
                                let points = dataPoints.map { $0.value }.filter { $0 > 50 && $0 < 200 }
                                
                                if !points.isEmpty {
                                    let meanValue = vDSP.mean(points)
                                    let formattedAvg = String(Int(meanValue))
                                    
                                    Text("Avg: " + formattedAvg + " " + NSLocalizedString("bpm", comment: "BPM"))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .foregroundColor(.red)
                    }
                    .padding(30)
                }
                VStack {
                    HeartChart()
                        .padding(.top, 10)
                }
                .ignoresSafeArea()
                .padding(20)
                .background(Material.regular)
                .cornerRadius(30, corners: [.topLeft, .topRight])
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
