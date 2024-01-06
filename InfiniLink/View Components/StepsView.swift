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
                            .background(Color.gray.opacity(0.2))
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
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                Divider()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack {
                            StepProgressGauge(stepCountGoal: $stepCountGoal, calendar: false)
                                .padding()
                                .frame(width: (g.size.width / 1.8), height: (g.size.width / 1.8), alignment: .center)
                            Button(action: {
                                SheetManager.shared.sheetSelection = .stepSettings
                                SheetManager.shared.showSheet = true
                            }) {
                                Text(NSLocalizedString("change_step_goal", comment: "Change Step Goal"))
                                    .padding()
                                    .padding(.horizontal, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .padding(.bottom)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        VStack {
                            Text("Weekly Steps")
                                .font(.title2.weight(.semibold))
                                .padding(.bottom, 25)
                            StepWeeklyChart(stepCountGoal: $stepCountGoal)
                                .frame(height: (g.size.width / 2.2), alignment: .center)
                        }
                        .padding(22)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 2.5)
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                        HStack {
                            StepCalendarView(stepCountGoal: $stepCountGoal)
                                .padding()
                                .frame(alignment: .init(horizontal: .center, vertical: .top))
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 2.5)
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                }
            }
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    StepView()
}
