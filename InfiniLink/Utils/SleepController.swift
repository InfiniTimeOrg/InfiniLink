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
    
    @Published var sleep = SleepData(hours: 0, core: 0, rem: 0, deep: 0, awake: 0)
    
    @Published var sleepData = [[String]]()
    
    func getSleepCSV() {
        bleFs.readMiscFile("/SleepTracker_Data.csv") { data in
            do {
                self.sleepData = try self.bleFs.convertDataToReadableFile(data: data, fileExtension: "csv") as! [[String]]
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
