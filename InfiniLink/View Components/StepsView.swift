//
//  StepsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//
//

import SwiftUI

struct StepView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presMode
    
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    
    @State private var progress: Float = 0
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var existingStepCounts: FetchedResults<StepCounts>
    
    func getStepHistory(date: Date) -> String {
        for stepCount in existingStepCounts {
            if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: date) {
                let formattedSteps = NumberFormatter.localizedString(from: NSNumber(value: stepCount.steps), number: .decimal)
                return formattedSteps
            }
        }
        return "0"
    }
    
    func updateProgress() {
        let today = Date()
        let formattedSteps = getStepHistory(date: today)
        
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
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                    Text(NSLocalizedString("steps", comment: "Steps"))
                        .foregroundColor(.primary)
                        .font(.title.weight(.bold))
                    Spacer()
                    Button {
                        SheetManager.shared.sheetSelection = .stepSettings
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
                VStack {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 10.0)
                            .opacity(0.3)
                            .foregroundColor(Color.gray)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(min(Float(Double(getStepHistory(date: Date()))! / 100.0), 1.0)))
                            .stroke(style: StrokeStyle(lineWidth: 15.0, lineCap: .round, lineJoin: .round))
                            .foregroundColor(Color.blue)
                            .rotationEffect(Angle(degrees: 270.0))
                        VStack {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 30).weight(.semibold))
                                .imageScale(.large)
                            VStack(spacing: 3) {
                                Text(getStepHistory(date: Date()))
                                Text("\(stepCountGoal)")
                                    .font(.body)
                                    .foregroundColor(.gray)
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
                    .background(Color.gray.opacity(0.2))
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
