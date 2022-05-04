//
//  StepsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//  
//
    

import SwiftUI


struct StepProgress: View {
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.colorScheme) var scheme
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var chartPoints: FetchedResults<StepCounts>
    
    var body: some View {
        StepProgressGauge(stepCountGoal: $stepCountGoal, calendar: false)
    }
}

struct StepWeekly: View {
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.colorScheme) var scheme
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var chartPoints: FetchedResults<StepCounts>
    
    var body: some View {
        StepWeeklyChart(stepCountGoal: $stepCountGoal)
    }
}

struct StepCalendar: View {
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.colorScheme) var scheme
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var chartPoints: FetchedResults<StepCounts>
    
    var body: some View {
        StepCalendarView(stepCountGoal: $stepCountGoal)
    }
}



struct StepView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        return GeometryReader { g in
            VStack {
                List() {
                    Section() {
                        HStack {
                            StepProgress()
                                .padding()
                                .frame(width: (g.size.width / 1.8), height: (g.size.width / 1.8), alignment: .center)
                        }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Section() {
                        VStack {
                            Spacer(minLength: 20.0)
                            StepWeekly()
                                .frame(height: (g.size.width / 2.2), alignment: .center)
                        }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Section() {
                        HStack {
                            StepCalendar()
                                .padding()
                                .frame(alignment: .init(horizontal: .center, vertical: .top))
                                .frame(height: (g.size.width), alignment: .center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationBarTitle(Text("Steps").font(.subheadline), displayMode: .inline)
            }
        }
    }
}
