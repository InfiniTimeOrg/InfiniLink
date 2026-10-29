//
//  SleepSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/28/26.
//

import SwiftUI

struct SleepSettingsView: View {
    @ObservedObject var sleepManager = SleepManager.shared

    private func timeItem(_ title: LocalizedStringKey, icon: String, minute: Int) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
                    .textCase(.uppercase)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.gray)
            Text(SleepSchedule.time(minute))
                .font(.title2.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }

    var body: some View {
        List {
            Section(footer: Text("Your schedule helps tell your night's sleep apart from naps, and sets when you get a bedtime reminder.")) {
                Toggle("Sleep Schedule", isOn: $sleepManager.schedule.enabled.animation())
            }
            if sleepManager.schedule.enabled {
                Section(header: Text("Days Active"), footer: Text("Bedtime reminders are only sent on these days.")) {
                    SleepScheduleDaysView(days: $sleepManager.schedule.days)
                        .padding(.vertical, 4)
                }
                Section {
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            timeItem("Bedtime", icon: "bed.double.fill", minute: sleepManager.schedule.bedtime)
                            Divider()
                                .frame(height: 40)
                            timeItem("Wake Up", icon: "alarm.fill", minute: sleepManager.schedule.wake)
                        }
                        SleepScheduleDial(bedtime: $sleepManager.schedule.bedtime, wake: $sleepManager.schedule.wake)
                            .padding(.horizontal, 12)
                        Text(Duration.seconds(sleepManager.schedule.goalMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))
                            .font(.headline)
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct SleepScheduleDaysView: View {
    @Binding var days: [Int]

    var body: some View {
        let calendar = Calendar.current

        HStack {
            ForEach(0..<7, id: \.self) { offset in
                let day = (calendar.firstWeekday - 1 + offset) % 7 + 1
                let selected = days.contains(day)

                Button {
                    // Keep at least one day like apple health
                    if !selected {
                        days.append(day)
                    } else if days.count > 1 {
                        days.removeAll { $0 == day }
                    }
                } label: {
                    Text(calendar.veryShortStandaloneWeekdaySymbols[day - 1])
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(selected ? Color.indigo : Color(.tertiarySystemFill))
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Text(calendar.standaloneWeekdaySymbols[day - 1]))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

struct SleepScheduleDial: View {
    @Binding var bedtime: Int
    @Binding var wake: Int

    private enum DragTarget: Equatable {
        case bedtime
        case wake
        case both(start: Int, bedtime: Int, wake: Int)
        case ignored
    }

    @State private var dragTarget: DragTarget?

    private let minimumMinutes = 60
    private let feedback = UISelectionFeedbackGenerator()

    // Keep midnight at the top
    private func angle(_ minute: Int) -> Angle {
        .degrees(Double(minute) / 1440 * 360 - 90)
    }

    private func point(_ minute: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = angle(minute).radians
        return CGPoint(x: center.x + radius * cos(radians), y: center.y + radius * sin(radians))
    }

    // Snaps to 5 minutes like apple health
    private func minute(at location: CGPoint, center: CGPoint) -> Int {
        var degrees = atan2(location.y - center.y, location.x - center.x) * 180 / .pi + 90
        if degrees < 0 {
            degrees += 360
        }
        return Int((degrees / 360 * 288).rounded()) % 288 * 5
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return hour % 6 == 0 ? date.formatted(.dateTime.hour()) : date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)))
    }

    private func set(_ binding: Binding<Int>, to minute: Int) {
        let minute = (minute + 1440) % 1440
        guard binding.wrappedValue != minute else { return }

        binding.wrappedValue = minute
        feedback.selectionChanged()
    }

    // Dragging one end into the other pushes it along
    private func setBedtime(_ minute: Int) {
        set($bedtime, to: minute)
        let length = (wake - bedtime + 1440) % 1440
        if length < minimumMinutes {
            set($wake, to: bedtime + minimumMinutes)
        } else if length > 1440 - minimumMinutes {
            set($wake, to: bedtime - minimumMinutes)
        }
    }

    private func setWake(_ minute: Int) {
        set($wake, to: minute)
        let length = (wake - bedtime + 1440) % 1440
        if length < minimumMinutes {
            set($bedtime, to: wake - minimumMinutes)
        } else if length > 1440 - minimumMinutes {
            set($bedtime, to: wake + minimumMinutes)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let ringWidth = size * 0.14
            let radius = (size - ringWidth) / 2
            let length = (wake - bedtime + 1440) % 1440

            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: ringWidth)
                    .frame(width: radius * 2, height: radius * 2)
                Circle()
                    .trim(from: 0, to: Double(length) / 1440)
                    .stroke(Color.indigo, style: StrokeStyle(lineWidth: ringWidth - 8, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(angle(bedtime))
                ForEach(0..<96, id: \.self) { tick in
                    let isHour = tick % 4 == 0
                    Capsule()
                        .fill(Color.gray.opacity(isHour ? 0.8 : 0.4))
                        .frame(width: isHour ? 2 : 1, height: isHour ? 6 : 4)
                        .offset(y: -(radius - ringWidth / 2 - 8))
                        .rotationEffect(.degrees(Double(tick) / 96 * 360))
                }
                ForEach(Array(stride(from: 0, to: 24, by: 2)), id: \.self) { hour in
                    Text(hourLabel(hour))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(hour % 6 == 0 ? Color.primary : Color.gray)
                        .position(point(hour * 60, radius: radius - ringWidth / 2 - 26, center: center))
                }
                ForEach([("bed.double.fill", bedtime), ("alarm.fill", wake)], id: \.0) { icon, minute in
                    Image(systemName: icon)
                        .font(.system(size: ringWidth * 0.4, weight: .semibold))
                        .foregroundStyle(.white)
                        .position(point(minute, radius: radius, center: center))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let current = minute(at: value.location, center: center)

                        if dragTarget == nil {
                            // Grab whichever end is closer, or the arc to move both
                            let start = value.startLocation
                            func distance(_ minute: Int) -> CGFloat {
                                let handle = point(minute, radius: radius, center: center)
                                return hypot(handle.x - start.x, handle.y - start.y)
                            }
                            let startMinute = minute(at: start, center: center)
                            let onRing = abs(hypot(start.x - center.x, start.y - center.y) - radius) <= ringWidth / 2

                            if min(distance(bedtime), distance(wake)) <= ringWidth {
                                dragTarget = distance(bedtime) <= distance(wake) ? .bedtime : .wake
                            } else if onRing && (startMinute - bedtime + 1440) % 1440 <= length {
                                dragTarget = .both(start: startMinute, bedtime: bedtime, wake: wake)
                            } else {
                                dragTarget = .ignored
                            }
                            feedback.prepare()
                        }

                        switch dragTarget {
                        case .bedtime:
                            setBedtime(current)
                        case .wake:
                            setWake(current)
                        case .both(let start, let originalBedtime, let originalWake):
                            set($bedtime, to: originalBedtime + current - start)
                            set($wake, to: originalWake + current - start)
                        default:
                            break
                        }
                    }
                    .onEnded { _ in
                        dragTarget = nil
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityRepresentation {
            Stepper("Bedtime, \(SleepSchedule.time(bedtime))", value: Binding(get: { bedtime }, set: { setBedtime($0) }), in: 0...1435, step: 5)
            Stepper("Wake Up, \(SleepSchedule.time(wake))", value: Binding(get: { wake }, set: { setWake($0) }), in: 0...1435, step: 5)
        }
    }
}

#Preview {
    NavigationStack {
        SleepSettingsView()
    }
}
