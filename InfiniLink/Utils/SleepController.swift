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
    
    @Published var sleepData = [[String]]()
    
    func getSleepCSV() {
        // TODO: update path string
        // TODO: add check to see if sleep csv is present
        let read = bleFs.readFile(path: "/SleepTracker_Data.csv", offset: 0)
        
        read.group.notify(queue: .main) {
            do {
                self.sleepData = try self.bleFs.convertDataToReadableFile(data: read.data, fileExtension: "csv") as! [[String]]
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
