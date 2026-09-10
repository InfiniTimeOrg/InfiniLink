//
//  ExerciseViewModel.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import Foundation
import SwiftUI
import CoreData
import HealthKit
import ActivityKit

class ExerciseViewModel: ObservableObject {
    static let shared = ExerciseViewModel()

    let healthKitManager = HealthKitManager.shared
    let deviceManager = DeviceManager.shared
    let bleManager = BLEManager.shared
    let routeRecorder = WorkoutRouteRecorder.shared
    let personalizationController = PersonalizationController.shared
    let bleWriteManager = BLEWriteManager()
    let persistenceController = PersistenceController.shared
    let userDefaults = UserDefaults(suiteName: AppGroup.identifier)

    @AppStorage("autoPauseExercise") var autoPauseExercise = false

    private var watchHapticsEnabled: Bool {
        return NotificationSettingsManager.shared.settings.exerciseSettings.watchHapticsEnabled
    }

    @Published private(set) var currentExercise: Exercise?
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var stepsTaken: Int = 0
    @Published private(set) var averageHeartRate: Double = 0
    @Published private(set) var maxHeartRate: Double = 0
    @Published var exercisePaused = false
    @Published private(set) var autoPaused = false
    @Published var recoverableSession: WorkoutSession?
    @Published var userExercises = [UserExercise]()
    @Published var pinnedExerciseIds = [String]()

    private var session: WorkoutSession?
    private var displayTimer: Timer?
    private var tickCount = 0
    private var liveActivity: Any?

    private var lastMovementAt = Date()
    private var lastRoutePointCount = 0
    private var lastStepsSeen = 0
    private var lastSplitMark = 0.0
    private let autoPauseThreshold: TimeInterval = 12

    // Recovered sessions older than this are assumed abandoned and discarded on launch
    private let recoveryWindow: TimeInterval = 60 * 60 * 12

    let exercises = [
        Exercise(id: "outdoor-run", name: "Outdoor Run", icon: "figure.run", components: [.heart, .steps, .location], pace: .jog),
        Exercise(id: "outdoor-cycle", name: "Outdoor Cycle", icon: "figure.outdoor.cycle", components: [.heart, .location], activityType: .cycling),
        Exercise(id: "indoor-run", name: "Indoor Run", icon: "figure.run.treadmill", components: [.heart, .steps], pace: .jog),
        Exercise(id: "indoor-cycle", name: "Indoor Cycle", icon: "figure.indoor.cycle", components: [.heart], activityType: .cycling),
        Exercise(id: "strength-training", name: "Strength Training", icon: "figure.strengthtraining.traditional", components: [.heart], activityType: .traditionalStrengthTraining),
        Exercise(id: "table-tennis", name: "Table Tennis", icon: "figure.table.tennis", components: [.heart], activityType: .tableTennis),
        Exercise(id: "tennis", name: "Tennis", icon: "figure.tennis", components: [.heart], activityType: .tennis),
        Exercise(id: "soccer", name: "Soccer", icon: "figure.indoor.soccer", components: [.heart, .steps], pace: .run, activityType: .soccer),
        Exercise(id: "basketball", name: "Basketball", icon: "figure.basketball", components: [.heart, .steps], pace: .run, activityType: .basketball),
        Exercise(id: "badminton", name: "Badminton", icon: "figure.badminton", components: [.heart, .steps], pace: .run, activityType: .badminton),
        Exercise(id: "boxing", name: "Boxing", icon: "figure.boxing", components: [.heart], activityType: .boxing),
        Exercise(id: "skiing", name: "Skiing", icon: "figure.skiing.downhill", components: [.heart], activityType: .downhillSkiing),
        Exercise(id: "bowling", name: "Bowling", icon: "figure.bowling", components: [.heart, .steps], activityType: .bowling),
        Exercise(id: "figure.golf", name: "Golf", icon: "figure.golf", components: [.heart, .steps], activityType: .golf),
        Exercise(id: "hockey", name: "Hockey", icon: "figure.hockey", components: [.heart, .steps], pace: .fastRun, activityType: .hockey)
    ]

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLiveActivityCommand), name: .workoutLiveActivityCommand, object: nil)

        getPinnedExercises()
        detectRecoverableSession()
        drainLiveActivityCommand()
    }

    func exercise(for id: String) -> Exercise? {
        return exercises.first(where: { $0.id == id })
    }

    func timeString() -> String {
        let total = Int(elapsed)
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    func startExercise(_ exercise: Exercise) {
        var session = WorkoutSession(exerciseId: exercise.id)
        session.lastWatchStepCount = bleManager.stepCount

        self.session = session
        currentExercise = exercise
        stepsTaken = 0
        elapsed = 0
        averageHeartRate = 0
        maxHeartRate = 0
        exercisePaused = false
        autoPaused = false
        resetMovementTracking()

        routeRecorder.reset()
        routeRecorder.start(recordingRoute: tracksRoute(exercise))

        WorkoutSessionStore.save(session)
        startDisplayTimer()
        startLiveActivity()
        sendWatchAlert("Started")
    }

    func pauseExercise() {
        beginPause(auto: false)
    }

    func resumeExercise() {
        endPause()
    }

    func endExercise(save: Bool) {
        stopDisplayTimer()
        endLiveActivity()

        let route = routeRecorder.points
        let distance = routeRecorder.distance
        routeRecorder.stop()

        if save, let exercise = currentExercise, let session {
            persistUserExercise(from: session, exercise: exercise, endDate: Date(), route: route, distanceMeters: distance)
        }

        session = nil
        currentExercise = nil
        stepsTaken = 0
        elapsed = 0
        averageHeartRate = 0
        maxHeartRate = 0
        exercisePaused = false
        autoPaused = false

        WorkoutSessionStore.clear()
        sendWatchAlert("Ended")
    }

    private func beginPause(auto: Bool) {
        guard var session, !session.isPaused else { return }

        session.pauseStartedAt = Date()
        session.routePoints = routeRecorder.points
        self.session = session
        exercisePaused = true
        autoPaused = auto

        // Auto-pause keeps location updates flowing so resumed movement can be detected
        if !auto {
            routeRecorder.stop()
            sendWatchAlert("Paused")
        }
        WorkoutSessionStore.save(session)
        updateElapsed()
        refreshLiveActivity()
    }

    private func endPause() {
        guard var session, let pauseStart = session.pauseStartedAt else { return }

        session.pausedIntervals.append(DateInterval(start: pauseStart, end: Date()))
        session.pauseStartedAt = nil
        self.session = session
        let wasAuto = autoPaused
        exercisePaused = false
        autoPaused = false
        resetMovementTracking()

        if !wasAuto {
            routeRecorder.start(recordingRoute: currentExercise.map(tracksRoute) ?? false, resuming: session.routePoints)
            sendWatchAlert("Resumed")
        }
        WorkoutSessionStore.save(session)
        updateElapsed()
        refreshLiveActivity()
    }

    private func tracksRoute(_ exercise: Exercise) -> Bool {
        return exercise.components.contains(.location)
    }

    private func resetMovementTracking() {
        lastMovementAt = Date()
        lastRoutePointCount = routeRecorder.points.count
        lastStepsSeen = stepsTaken
    }

    // Fed from BLECharacteristicHandler so metric accumulation doesn't depend on any view being on screen
    func ingestWatchSteps(_ total: Int) {
        guard var session else { return }

        if let last = session.lastWatchStepCount {
            // A drop means the watch counter rolled over at midnight, so treat the new total as the delta
            session.accumulatedSteps += total >= last ? total - last : total
        }
        session.lastWatchStepCount = total
        session.lastHeartbeat = Date()

        self.session = session
        stepsTaken = session.accumulatedSteps

        WorkoutSessionStore.save(session)
    }

    func ingestHeartRate(_ bpm: Int) {
        guard bpm > 0, var session else { return }

        session.heartRateSum += Double(bpm)
        session.heartRateSampleCount += 1
        session.maxHeartRate = Swift.max(session.maxHeartRate, Double(bpm))
        self.session = session

        averageHeartRate = session.averageHeartRate
        maxHeartRate = session.maxHeartRate
    }

    func resumeRecoveredSession() {
        guard var recovered = recoverableSession, let exercise = exercise(for: recovered.exerciseId) else {
            discardRecoveredSession()
            return
        }

        // Rebase the step counter so steps counted while the app was gone don't land in one huge delta
        recovered.lastWatchStepCount = bleManager.stepCount
        recovered.lastHeartbeat = Date()

        session = recovered
        currentExercise = exercise
        stepsTaken = recovered.accumulatedSteps
        averageHeartRate = recovered.averageHeartRate
        maxHeartRate = recovered.maxHeartRate
        exercisePaused = recovered.isPaused
        autoPaused = false
        recoverableSession = nil

        if !recovered.isPaused {
            routeRecorder.start(recordingRoute: tracksRoute(exercise), resuming: recovered.routePoints)
        }
        resetMovementTracking()
        lastSplitMark = (WorkoutRouteRecorder.totalDistance(of: recovered.routePoints) / splitUnitMeters).rounded(.down)
        WorkoutSessionStore.save(recovered)
        updateElapsed()
        startDisplayTimer()
        startLiveActivity()
    }

    func saveAndEndRecoveredSession() {
        guard let recovered = recoverableSession, let exercise = exercise(for: recovered.exerciseId) else {
            discardRecoveredSession()
            return
        }

        let distance = WorkoutRouteRecorder.totalDistance(of: recovered.routePoints)
        persistUserExercise(from: recovered, exercise: exercise, endDate: recovered.lastHeartbeat, route: recovered.routePoints, distanceMeters: distance)
        recoverableSession = nil
        WorkoutSessionStore.clear()
        endLiveActivity()
    }

    func discardRecoveredSession() {
        recoverableSession = nil
        WorkoutSessionStore.clear()
        endLiveActivity()
    }

    func setExercisePinned(_ exercise: Exercise) {
        if pinnedExerciseIds.contains(exercise.id) {
            pinnedExerciseIds.removeAll(where: { $0 == exercise.id })
        } else {
            pinnedExerciseIds.append(exercise.id)
        }
        setPinnedExercises()
    }

    func getPinnedExercises() {
        pinnedExerciseIds = userDefaults?.array(forKey: "pinnedExercises") as? [String] ?? []
    }

    func setPinnedExercises() {
        userDefaults?.set(pinnedExerciseIds, forKey: "pinnedExercises")
    }

    func isDateDuringExercise(_ date: Date) -> Bool {
        let exercises = ChartManager.shared.userExercises().filter { exercise in
            guard let endDate = exercise.endDate else { return true }

            // Use end date because it will be present in the day for the longest
            return Calendar.current.isDate(date, equalTo: endDate, toGranularity: .day)
        }

        return !exercises.isEmpty
    }

    private func detectRecoverableSession() {
        guard let saved = WorkoutSessionStore.load() else { return }

        let age = Date().timeIntervalSince(saved.lastHeartbeat)
        if age < recoveryWindow && exercise(for: saved.exerciseId) != nil {
            recoverableSession = saved
        } else {
            WorkoutSessionStore.clear()
            endLiveActivity()
        }
    }

    private func startDisplayTimer() {
        stopDisplayTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateElapsed()
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private func updateElapsed() {
        guard let session else { return }

        elapsed = session.elapsed()
        tickCount += 1

        let moved = routeRecorder.points.count > lastRoutePointCount || stepsTaken > lastStepsSeen
        if moved { lastMovementAt = Date() }
        lastRoutePointCount = routeRecorder.points.count
        lastStepsSeen = stepsTaken

        evaluateAutoPause(moved: moved)
        evaluateSplitHaptic()

        if tickCount % 10 == 0 && !exercisePaused {
            refreshLiveActivity()
        }

        // Periodic save so a crash while foregrounded still leaves a recent recovery point
        if tickCount % 30 == 0 {
            var refreshed = session
            refreshed.lastHeartbeat = Date()
            refreshed.routePoints = routeRecorder.points
            self.session = refreshed
            WorkoutSessionStore.save(refreshed)
        }
    }

    private func evaluateAutoPause(moved: Bool) {
        guard autoPauseExercise, let exercise = currentExercise, supportsAutoPause(exercise) else { return }

        if autoPaused {
            if moved { endPause() }
        } else if !exercisePaused && Date().timeIntervalSince(lastMovementAt) > autoPauseThreshold {
            beginPause(auto: true)
        }
    }

    private func evaluateSplitHaptic() {
        guard watchHapticsEnabled, let exercise = currentExercise, tracksRoute(exercise), !exercisePaused else { return }

        let reached = (routeRecorder.distance / splitUnitMeters).rounded(.down)
        if reached > lastSplitMark {
            lastSplitMark = reached
            let unit = personalizationController.units == .imperial ? "mi" : "km"
            sendWatchAlert("\(Int(reached)) \(unit)")
        }
    }

    private func supportsAutoPause(_ exercise: Exercise) -> Bool {
        return exercise.components.contains(.steps) || exercise.components.contains(.location)
    }

    private var splitUnitMeters: Double {
        return personalizationController.units == .imperial ? 1609.344 : 1000
    }

    private func sendWatchAlert(_ message: String) {
        guard watchHapticsEnabled else { return }

        bleWriteManager.sendNotification(AppNotification(title: NSLocalizedString("Workout", comment: ""), subtitle: NSLocalizedString(message, comment: "")))
    }

    func liveCalorieEstimate(for exercise: Exercise) -> Int {
        let calculator = FitnessCalculator()
        if exercise.components.contains(.steps) {
            return calculator.calculateCaloriesBurned(steps: stepsTaken)
        }
        return calculator.calculateCaloriesBurned(heartRate: averageHeartRate, durationSeconds: elapsed)
    }

    private func startLiveActivity() {
        guard #available(iOS 16.2, *), let exercise = currentExercise else { return }

        let controller = WorkoutLiveActivityController()
        controller.start(name: exercise.name, icon: exercise.icon, state: liveActivityState())
        liveActivity = controller
    }

    private func refreshLiveActivity() {
        guard #available(iOS 16.2, *), let controller = liveActivity as? WorkoutLiveActivityController else { return }

        controller.update(liveActivityState())
    }

    private func endLiveActivity() {
        guard #available(iOS 16.2, *) else { return }

        // Use a new controller when none is held (new session)
        // end() clears every activity anyways
        let controller = (liveActivity as? WorkoutLiveActivityController) ?? WorkoutLiveActivityController()
        controller.end()
        liveActivity = nil
    }

    @available(iOS 16.2, *)
    private func liveActivityState() -> WorkoutAttributes.ContentState {
        return WorkoutAttributes.ContentState(
            effectiveStart: Date().addingTimeInterval(-elapsed),
            pausedAt: exercisePaused ? Date() : nil,
            heartRate: Int(bleManager.heartRate),
            steps: stepsTaken,
            calories: currentExercise.map(liveCalorieEstimate) ?? 0,
            distanceMeters: routeRecorder.distance,
            showsSteps: currentExercise?.components.contains(.steps) ?? false,
            showsDistance: currentExercise?.components.contains(.location) ?? false,
            usesImperial: personalizationController.units == .imperial,
            usesKilojoules: personalizationController.energyUnit == .kilojoule
        )
    }

    @objc private func handleLiveActivityCommand() {
        DispatchQueue.main.async { [weak self] in
            self?.drainLiveActivityCommand()
        }
    }

    private func drainLiveActivityCommand() {
        guard let command = WorkoutCommandBox.take() else { return }

        switch command {
        case .pause:
            if currentExercise != nil && !exercisePaused { pauseExercise() }
        case .resume:
            if exercisePaused { resumeExercise() }
        case .end:
            if currentExercise != nil { endExercise(save: elapsed >= 30) }
        }
    }

    // Trapezoidal integration of heart rate over the samples' own time span
    private static func timeWeightedAverage(of points: [HeartDataPoint]) -> Double {
        let samples = points.compactMap { point -> (Date, Double)? in
            guard let timestamp = point.timestamp, point.value > 0 else { return nil }
            return (timestamp, point.value)
        }

        guard samples.count > 1 else { return samples.first?.1 ?? 0 }

        var area = 0.0
        for index in 1..<samples.count {
            let span = samples[index].0.timeIntervalSince(samples[index - 1].0)
            area += 0.5 * (samples[index].1 + samples[index - 1].1) * span
        }

        let total = samples[samples.count - 1].0.timeIntervalSince(samples[0].0)
        return total > 0 ? area / total : samples[0].1
    }

    private func persistUserExercise(from session: WorkoutSession, exercise: Exercise, endDate: Date, route: [RoutePoint], distanceMeters: Double) {
        let startDate = session.startDate
        let steps = session.accumulatedSteps
        let deviceId = deviceManager.pairedDeviceID
        let fitnessCalculator = FitnessCalculator()
        let routeJSON = route.count > 1 ? (try? JSONEncoder().encode(route)).flatMap { String(data: $0, encoding: .utf8) } : nil
        let device = HKDevice(name: deviceManager.name, manufacturer: deviceManager.manufacturer, model: deviceManager.modelNumber, hardwareVersion: deviceManager.hardwareRevision, firmwareVersion: deviceManager.firmware, softwareVersion: deviceManager.softwareRevision, localIdentifier: session.id.uuidString, udiDeviceIdentifier: nil)
        let context = persistenceController.container.newBackgroundContext()

        context.perform { [weak self] in
            let request: NSFetchRequest<HeartDataPoint> = HeartDataPoint.fetchRequest()
            request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \HeartDataPoint.timestamp, ascending: true)]
            let heartPoints = (try? context.fetch(request)) ?? []

            let averageHeartRate = Self.timeWeightedAverage(of: heartPoints)
            let duration = endDate.timeIntervalSince(startDate)
            let calories: Double = {
                if averageHeartRate > 0 {
                    return Double(fitnessCalculator.calculateCaloriesBurned(heartRate: averageHeartRate, durationSeconds: duration))
                }
                return Double(fitnessCalculator.calculateCaloriesBurned(steps: steps, pace: exercise.pace))
            }()

            let userExercise = UserExercise(context: context)
            userExercise.id = session.id
            userExercise.startDate = startDate
            userExercise.endDate = endDate
            userExercise.exerciseId = exercise.id
            userExercise.heartPoints = NSSet(array: heartPoints)
            userExercise.steps = Int32(steps)
            userExercise.caloriesBurned = Int32(calories)
            userExercise.distance = distanceMeters
            userExercise.routeJSON = routeJSON
            userExercise.deviceId = deviceId

            do {
                try context.save()
            } catch {
                log("Failed to save exercise: \(error.localizedDescription)", caller: "ExerciseViewModel")
            }

            let workout = HKWorkout(
                activityType: exercise.activityType,
                start: startDate,
                end: endDate,
                duration: duration,
                totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                totalDistance: distanceMeters > 0 ? HKQuantity(unit: .meter(), doubleValue: distanceMeters) : nil,
                device: device,
                metadata: nil
            )

            DispatchQueue.main.async {
                self?.healthKitManager.saveWorkout(workout, activeEnergyKcal: calories, from: startDate, to: endDate)
                self?.userExercises = ChartManager.shared.userExercises()
            }
        }
    }

    @objc private func applicationDidEnterBackground(_ notification: NSNotification) {
        stopDisplayTimer()

        guard var session else { return }
        session.lastHeartbeat = Date()
        session.routePoints = routeRecorder.points
        self.session = session
        WorkoutSessionStore.save(session)
    }

    @objc private func applicationWillEnterForeground(_ notification: NSNotification) {
        drainLiveActivityCommand()

        guard session != nil else { return }

        updateElapsed()
        startDisplayTimer()
        refreshLiveActivity()
    }
}
