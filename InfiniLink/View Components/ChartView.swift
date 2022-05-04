//
//  BLEStatusView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/13/21.
//

import Foundation
import SwiftUI

struct StepsChartView: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @Environment(\.colorScheme) var scheme
    var body: some View {
        NavigationLink(destination: StepView()) {
            VStack {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.blue)
                    Text("Steps")
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    //bleManager.stepCount
                    Text(String(bleManagerVal.stepCount))
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .font(.system(size: 28))
                        .bold()
                    Text("with a goal of \(stepCountGoal)")
                        .foregroundColor(.gray)
                        .bold()
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
        }
    }
}


struct HeartChartView: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var scheme
    var body: some View {
        NavigationLink(destination: HeartView()) {
            VStack {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Heart Rate")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    Text(String(Int(bleManagerVal.heartBPM)))
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .font(.system(size: 28))
                        .bold()
                    Text("BPM")
                        .foregroundColor(.gray)
                        .bold()
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
        }
    }
}

struct BatteryMenu: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.colorScheme) var scheme
    var body: some View {
        NavigationLink(destination: BatteryView()) {
            VStack {
                HStack {
                    Image(systemName: "battery." + String(Int(round(Double(String(format: "%.0f",   bleManager.batteryLevel))! / 25) * 25)))
                        .imageScale(.large)
                        .foregroundColor(.green)
                    Text("Battery")
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    Text(String(format: "%.0f", bleManager.batteryLevel))
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .font(.system(size: 28))
                        .bold()
                    Text("%")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
        }
    }
}

struct ChartView: View {
	
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	
	var body: some View {
        return VStack {
            List() {
                Section(header: Text("Steps")
                    .font(.system(size: 14))
                    .bold()
                    .padding(1)) {
                        StepsChartView()
                    }
                Section(header: Text("Heart Rate")
                    .font(.system(size: 14))
                    .bold()
                    .padding(1)) {
                        HeartChartView()
                    }
                if bleManager.isConnectedToPinetime {
                    Section(header: Text("Battery")
                        .font(.system(size: 14))
                        .bold()
                        .padding(1)) {
                            BatteryMenu()
                        }
                }
            }
            .listStyle(.insetGrouped)
        }
	}
}

