//
//  SleepController.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/16/24.
//

import Foundation

class SleepController: ObservableObject {
    static let shared = SleepController()
    
    let bleFs = BLEFSHandler.shared
    
    @Published var sleep: SleepData?
    
    var totalSleepMinutes: Int? {
        if let sleep {
            return Int(sleep.endDate.timeIntervalSince(sleep.startDate)) / 60
        }
        return nil
    }
    
    // Right now this controller is mostly empty, but it will be used in the future if an algorithm is developed for tracking
}
