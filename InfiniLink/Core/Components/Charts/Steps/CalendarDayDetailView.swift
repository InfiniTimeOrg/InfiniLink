//
//  CalendarDayDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 6/5/25.
//

import SwiftUI

struct CalendarDayDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedDay: Date
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedDay)
    }
    var progress: Double {
        return min(Double(stepPoint()?.steps ?? 0) / Double(DeviceManager.shared.settings.stepsGoal), 1)
    }
    var percentComplete: String {
        return String(format: "%.0f", progress * 100)
    }
    
    func stepPoint() -> StepCounts? {
        let points = ChartManager.shared.stepPoints()
        return points.first(where: { Calendar.current.isDate(selectedDay, equalTo: $0.timestamp!, toGranularity: .day)})
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Material.regular)
                        Group {
                            if let daySteps = stepPoint()?.steps, daySteps > 0 {
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
                    .frame(maxHeight: geo.size.height / 2.2)
                    Text("You took \(stepPoint()?.steps ?? 0) steps on \(dayName)")
                        .font(.title2.weight(.semibold))
                    Text("That's \(percentComplete)% of your goal.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
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
}

#Preview {
    GeometryReader { geo in
        CalendarDayDetailView(selectedDay: .constant(Date().addingTimeInterval(-86400)))
            .frame(height: geo.size.height / 2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 120)
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
