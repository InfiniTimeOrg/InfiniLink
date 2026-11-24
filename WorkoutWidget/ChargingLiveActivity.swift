//
//  ChargingLiveActivity.swift
//  WorkoutWidget
//
//  Created by Liam Willey on 11/23/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

private func durationText(_ duration: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = [.day, .hour, .minute]
    formatter.maximumUnitCount = 1
    return formatter.string(from: duration) ?? ""
}

struct ChargingStatusText: View {
    let state: ChargingAttributes.ContentState

    private var status: Text {
        if state.isFull {
            return Text("Charged")
        } else if let fullAt = state.fullAt, fullAt > Date() {
            return Text("Full at \(fullAt.formatted(.dateTime.hour().minute()))")
        } else {
            return Text("Charging")
        }
    }

    var body: some View {
        Group {
            if let uptime = state.uptime, uptime > 0 {
                status + Text(" • Lasts ~\(durationText(uptime)) if unplugged")
            } else {
                status
            }
        }
        .font(.system(size: 15.5))
        .foregroundStyle(.secondary)
    }
}

struct ChargingWatchSymbol: View { // No sf symbol for this
    var body: some View {
        Image(systemName: "applewatch")
            .font(.system(size: 18, weight: .medium))
            .overlay {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 5.5, weight: .black))
            }
            .foregroundStyle(.green)
    }
}

struct ChargingRing: View {
    let state: ChargingAttributes.ContentState
    let size: CGFloat

    var body: some View {
        let lineWidth = size / 9
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: Double(state.level) / 100)
                .stroke(Color.green, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(state.level)")
                .font(.system(size: size * 0.4, weight: .semibold))
                .monospacedDigit()
        }
        .padding(lineWidth / 2)
        .foregroundStyle(.green)
        .frame(width: size, height: size)
    }
}

struct ChargingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChargingAttributes.self) { context in
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.deviceName)
                        .font(.headline)
                        .lineLimit(1)
                    ChargingStatusText(state: context.state)
                }
                Spacer(minLength: 0)
                ChargingRing(state: context.state, size: 44)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.attributes.deviceName)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            ChargingStatusText(state: context.state)
                        }
                        Spacer(minLength: 0)
                        ChargingRing(state: context.state, size: 44)
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                ChargingWatchSymbol()
            } compactTrailing: {
                Text("\(context.state.level)")
                    .font(.system(size: 14.5, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.green)
            } minimal: {
                ChargingWatchSymbol()
            }
            .keylineTint(.green)
        }
    }
}
