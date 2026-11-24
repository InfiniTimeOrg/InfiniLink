//
//  AutoUpdateManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 11/23/26.
//

import SwiftUI

class AutoUpdateManager: ObservableObject {
    static let shared = AutoUpdateManager()

    @AppStorage("automaticUpdates") var enabled = false
    @AppStorage("lastAutomaticUpdateAttempt") private var lastAttempt: Double = 0
    @AppStorage("offeredAutomaticUpdates") private var offered = false

    @Published var showOffer = false

    static let chargingMinutes = 60

    private let bleManager = BLEManager.shared
    private let downloadManager = DownloadManager.shared
    private let deviceManager = DeviceManager.shared

    private var updatingTo: String?

    private var learnedSleepRange: Range<Int>? {
        let nights = SleepManager.shared.recentNights()
        guard nights.count >= 2, let fellAsleep = nights.map({ SleepManager.nightMinute($0.start) }).max(), let wokeUp = nights.map({ SleepManager.nightMinute($0.end) }).min() else { return nil }

        let start = fellAsleep + 60, end = wokeUp - 30
        return end - start >= 30 ? start..<end : nil
    }

    private var isNight: Bool {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let schedule = SleepManager.shared.schedule
        let (start, end) = schedule.enabled ? (schedule.bedtime, schedule.wake) : (0, 6 * 60)

        return start <= end ? (start..<end).contains(minute) : (minute >= start || minute < end)
    }

    private var isSafeTime: Bool {
        guard let chargingSince = ChargingManager.shared.chargingSince, Date().timeIntervalSince(chargingSince) >= TimeInterval(Self.chargingMinutes * 60) else { return false }

        if let range = learnedSleepRange {
            return range.contains(SleepManager.nightMinute(Date()))
        }
        return isNight
    }

    func checkIfNeeded() {
        // So a failure doesn't keep retrying
        guard enabled, Date().timeIntervalSince1970 - lastAttempt > 12 * 3600, isSafeTime else { return }

        downloadManager.getUpdates()

        let dfuUpdater = DFUUpdater.shared
        guard bleManager.hasLoadedCharacteristics, !bleManager.isDeviceInRecoveryMode, bleManager.dfuControlPointCharacteristic != nil,
              downloadManager.updateAvailable, !downloadManager.updateStarted, !downloadManager.externalResources, !dfuUpdater.local, dfuUpdater.stage == .idle,
              deviceManager.firmware.compare(downloadManager.updateVersion, options: .numeric) == .orderedAscending else { return }

        lastAttempt = Date().timeIntervalSince1970
        updatingTo = downloadManager.updateVersion
        log("Starting automatic update to \(downloadManager.updateVersion)", type: .info, caller: "AutoUpdateManager", target: .dfu)
        downloadManager.startSoftwareUpdate()
    }

    func updateFinished(installed: Bool) {
        guard let version = updatingTo else {
            // Once, after they update by hand
            if installed && !enabled && !offered && !DFUUpdater.shared.local {
                offered = true
                // Let the update screen finish closing first
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showOffer = true
                }
            }
            return
        }
        updatingTo = nil

        if installed {
            NotificationManager.shared.sendWhenAwake(AppNotification(title: NSLocalizedString("Watch Updated", comment: ""), subtitle: String(localized: "\(deviceManager.name) was updated to InfiniTime \(version) overnight.")))
        } else {
            NotificationManager.shared.sendWhenAwake(AppNotification(title: NSLocalizedString("Automatic Update Failed", comment: ""), subtitle: String(localized: "\(deviceManager.name) couldn't be updated to InfiniTime \(version). Open Software Update to try again.")))
        }
    }
}
