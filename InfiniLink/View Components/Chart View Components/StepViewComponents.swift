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
