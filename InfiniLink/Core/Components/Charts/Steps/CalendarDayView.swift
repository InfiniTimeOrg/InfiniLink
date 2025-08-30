//
//  CalendarDayView.swift
//  InfiniLink
//
//  Created by Liam Willey on 6/5/25.
//

import SwiftUI

struct CalendarDayView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var deviceManager = DeviceManager.shared
    
    let value: CalendarDay
    let stepPoint: StepCounts?
    
    var background: AnyShapeStyle {
        return colorScheme == .dark ? AnyShapeStyle(Material.regular) : AnyShapeStyle(Color(.systemBackground))
    }
    
    init(_ value: CalendarDay, point: StepCounts?) {
        self.value = value
        self.stepPoint = point
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.8), style: value.day == -1 ? StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7]) : StrokeStyle(lineWidth: 0))
                .background(value.day == -1 ? AnyShapeStyle(Color.clear) : background)
                .clipShape(Circle())
            let label = Text("\(value.day)")
                .font(.system(size: 16).weight(.medium))
                .opacity(value.day == -1 ? 0 : 1)
            if deviceManager.settings.stepsGoal > 0 && value.day != -1 {
                let progress = min(Double(stepPoint?.steps ?? 0) / Double(deviceManager.settings.stepsGoal), 1)
                PieSlice(progress: progress)
                    .fill(Color.blue.opacity(0.8))
                label
                    .foregroundStyle(progress > 0.5 ? Color.white : Color.primary)
            } else {
                label
            }
        }
        .frame(minWidth: 42, maxWidth: 55, minHeight: 42, maxHeight: 55)
        .frame(maxWidth: .infinity)
    }
}
