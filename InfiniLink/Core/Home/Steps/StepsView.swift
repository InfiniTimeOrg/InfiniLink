//
//  StepsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//
//

import SwiftUI

struct StepView: View {
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presMode
    
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    
    @State private var progress: Float = 0
    @State private var showStepCountAlert: Bool = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var existingStepCounts: FetchedResults<StepCounts>
    
    func getStepHistoryAsString(date: Date) -> String {
        for stepCount in existingStepCounts {
            if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: date) {
                let formattedSteps = NumberFormatter.localizedString(from: NSNumber(value: stepCount.steps), number: .decimal)
                return formattedSteps
            }
        }
        return "0"
    }
    
    func getStepHistoryAsInt(date: Date) -> Int32 {
        for stepCount in existingStepCounts {
            if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: date) { //(stepCount.timestamp!, to: date, toGranularity: .day) == .orderedSame {
                return stepCount.steps
            }
        }
        return 0
    }
    
    func updateProgress() {
        let today = Date()
        let formattedSteps = getStepHistoryAsString(date: today)
        
        if let steps = Float(formattedSteps) {
            progress = min(steps / Float(stepCountGoal), 1.0)
        }
    }
    
    var body: some View {
        GeometryReader { g in
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
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                    Text(NSLocalizedString("steps", comment: "Steps"))
                        .foregroundColor(.primary)
                        .font(.title.weight(.bold))
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                Divider()
                VStack {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 10.0)
                            .opacity(0.3)
                            .foregroundColor(Color.gray)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(min((Float(getStepHistoryAsInt(date: Date()))/Float(stepCountGoal)), 1.0)))
                            .stroke(style: StrokeStyle(lineWidth: 15.0, lineCap: .round, lineJoin: .round))
                            .foregroundColor(Color.blue)
                            .rotationEffect(Angle(degrees: 270.0))
                        VStack {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 30).weight(.semibold))
                                .imageScale(.large)
                            VStack(spacing: 3) {
                                Text(getStepHistoryAsString(date: Date()))
                                Button {
                                    showStepCountAlert.toggle()
                                } label: {
                                    Text("\(stepCountGoal)")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
                                .alert(isPresented: $showStepCountAlert) {
                                    Alert(title: Text(NSLocalizedString("update_step_count_goal_on_watch_1", comment: "To change your step goal, navigate to settings on") + " \(deviceInfo.deviceName) " + NSLocalizedString("update_step_count_goal_on_watch_2", comment: "and change it there.")))
                                }
                            }
                        }
                        .font(.system(size: 30).weight(.bold))
                        .foregroundColor(.blue)
                    }
                    .padding(30)
                    VStack {
                        Text("Weekly Steps")
                            .font(.title2.weight(.semibold))
                            .padding(.bottom, 25)
                        StepWeeklyChart(stepCountGoal: $stepCountGoal)
                            .frame(height: (g.size.width / 2.2), alignment: .center)
                    }
                    .ignoresSafeArea()
                    .padding(20)
                    .background(Material.regular)
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                }
            }
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    StepView()
}
