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
    
    @Binding var selectedDay: Date
    @Binding var selectedDetent: PresentationDetent
    
    private let fitnessCalculator = FitnessCalculator()
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedDay)
    }
    var progress: Double {
        return min(Double(stepPoint?.steps ?? 0) / Double(DeviceManager.shared.settings.stepsGoal), 1)
    }
    var percentComplete: String {
        return String(format: "%.0f", progress * 100)
    }
    var stepPoint: StepCounts? {
        let points = chartManager.stepPoints(predicate: chartManager.monthPredicate)
        let point = points.first(where: { Calendar.current.isDate(selectedDay, equalTo: $0.timestamp!, toGranularity: .day)})
        return point
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 14) {
                    Spacer()
                    VStack {
                        progressCircle(geo)
                        Text("You took \(stepPoint?.steps ?? 0) steps on \(dayName)")
                            .font(selectedDetent == .medium ? .title2 : .title)
                            .fontWeight(selectedDetent == .medium ? .semibold : .bold)
                            .transition(.opacity.animation(.easeInOut))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(percentComplete == "100" ? "Great job, you reached your daily step goal! Keep up the good work!" : "That's \(percentComplete)% of your goal.")
                            .foregroundStyle(.secondary)
                            .lineLimit(selectedDetent == .medium ? 1 : nil)
                    }
                    .multilineTextAlignment(.center)
                    Spacer()
                    if selectedDetent == .medium {
                        VStack(spacing: 4) {
                            Image(systemName: "chevron.up").font(.body.weight(.medium))
                            Text("Swipe up for more details")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    } else {
                        StepMenuItemView(steps: Int(stepPoint?.steps ?? 0))
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .animation(.easeInOut(duration: 0.3), value: selectedDetent)
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
            Circle()
                .fill(Material.regular)
            Group {
                if let daySteps = stepPoint?.steps, daySteps > 0 {
                    PieSlice(progress: progress)
                        .foregroundStyle(.blue)
                    Text("\(percentComplete)%")
                        .shadow(color: .primary, radius: 25)
                } else {
                    Text("\(0)%")
                }
            }
            .font(.system(size: 42).weight(.semibold))
        }
        .frame(width: geo.size.width / 2.2)
        .fixedSize()
    }
}

#Preview {
    GeometryReader { geo in
        CalendarDayDetailView(selectedDay: .constant(Date().addingTimeInterval(-86400)), selectedDetent: .constant(.medium))
            .frame(height: geo.size.height / 2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 120)
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
