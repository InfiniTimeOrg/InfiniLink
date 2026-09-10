//
//  CalendarDayDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 6/5/25.
//

import SwiftUI

struct CalendarDayDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var chartManager = ChartManager.shared
    
    @Binding var selectedDetent: PresentationDetent
    @Binding var stepPoint: StepCounts?
    
    private let fitnessCalculator = FitnessCalculator()
    
    let date: Date
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    var progress: Double {
        return min(Double(stepPoint?.steps ?? 0) / Double(DeviceManager.shared.settings.stepsGoal), 1)
    }
    var percentComplete: Int {
        return Int((progress * 100).rounded())
    }
    
    init(_ selectedPoint: Binding<StepCounts?>, selectedDetent: Binding<PresentationDetent>, selectedDate date: Date) {
        self._stepPoint = selectedPoint
        self.date = selectedPoint.wrappedValue?.timestamp ?? date
        self._selectedDetent = selectedDetent
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 14) {
                        VStack {
                            progressCircle(geo)
                            Text("You took \(stepPoint?.steps ?? 0) steps on \(dayName)")
                                .font(selectedDetent == .medium ? .title2 : .title)
                                .fontWeight(selectedDetent == .medium ? .semibold : .bold)
                                .transition(.opacity.animation(.easeInOut))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(percentComplete == 100 ? "You reached your goal, keep up the good work!" : "That's \(progress, format: .percent.precision(.fractionLength(0))) of your goal.")
                                .foregroundStyle(.secondary)
                                .lineLimit(selectedDetent == .medium ? 1 : nil)
                        }
                        .multilineTextAlignment(.center)
//                        if selectedDetent == .medium {
//                            VStack(spacing: 4) {
//                                Image(systemName: "chevron.up").font(.body.weight(.medium))
//                                Text("Swipe up for more details")
//                            }
//                            .font(.subheadline)
//                            .foregroundStyle(.gray)
//                        } else {
//                            StepMenuItemView(steps: Int(stepPoint?.steps ?? 0))
//                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
//                    .animation(.easeInOut(duration: 0.3), value: selectedDetent)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func progressCircle(_ geo: GeometryProxy) -> some View {
        ZStack {
            Rectangle()
                .fill(Material.regular)
                .clipShape(Circle())
            Group {
                if let daySteps = stepPoint?.steps, daySteps > 0 {
                    PieSlice(progress: progress)
                        .foregroundStyle(.blue)
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .shadow(color: .primary, radius: 25)
                } else {
                    Text(0, format: .percent)
                }
            }
            .font(.system(size: 42).weight(.semibold))
        }
        .frame(width: geo.size.width / 2.4, height: geo.size.width / 2.4)
        .fixedSize()
    }
}
