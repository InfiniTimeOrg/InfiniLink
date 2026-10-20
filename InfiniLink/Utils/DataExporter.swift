//
//  DataExporter.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import CoreData
import Zip

struct DataExporter {
    enum DataType: String, CaseIterable, Identifiable {
        case heartRate = "Heart Rate"
        case steps = "Steps"
        case battery = "Battery"
        case sleep = "Sleep"
        case exercise = "Exercise"
        case motion = "Motion"

        var id: String { rawValue }
        var fileName: String {
            rawValue.lowercased().replacingOccurrences(of: " ", with: "-") + ".csv"
        }
    }

    let persistenceController = PersistenceController.shared

    private let dateFormatter = ISO8601DateFormatter()

    func export(_ types: Set<DataType>, since start: Date?, deviceId: String, completion: @escaping (URL?) -> Void) {
        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("InfiniLink Export", isDirectory: true)
            try? FileManager.default.removeItem(at: directory)

            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

                var files = [URL]()
                for type in DataType.allCases where types.contains(type) {
                    let url = directory.appendingPathComponent(type.fileName)
                    try csv(for: type, since: start, deviceId: deviceId, context: context).write(to: url, atomically: true, encoding: .utf8)
                    files.append(url)
                }

                let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("InfiniLink Export.zip")
                try? FileManager.default.removeItem(at: zipURL)
                try Zip.zipFiles(paths: files, zipFilePath: zipURL, password: nil, progress: nil)

                completion(zipURL)
            } catch {
                log("Error exporting data: \(error.localizedDescription)", caller: "DataExporter")
                completion(nil)
            }
        }
    }

    private func csv(for type: DataType, since start: Date?, deviceId: String, context: NSManagedObjectContext) throws -> String {
        func predicate(_ key: String) -> NSPredicate {
            if let start {
                return NSPredicate(format: "deviceId == %@ AND \(key) >= %@", deviceId, start as NSDate)
            }
            return NSPredicate(format: "deviceId == %@", deviceId)
        }
        func date(_ date: Date?) -> String {
            date.map { dateFormatter.string(from: $0) } ?? ""
        }

        switch type {
        case .heartRate:
            let request: NSFetchRequest<HeartDataPoint> = HeartDataPoint.fetchRequest()
            request.predicate = predicate("timestamp")
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            return "timestamp,bpm\n" + (try context.fetch(request)).map { "\(date($0.timestamp)),\($0.value)" }.joined(separator: "\n")
        case .steps:
            let request: NSFetchRequest<StepCounts> = StepCounts.fetchRequest()
            request.predicate = predicate("timestamp")
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            return "timestamp,steps\n" + (try context.fetch(request)).map { "\(date($0.timestamp)),\($0.steps)" }.joined(separator: "\n")
        case .battery:
            let request: NSFetchRequest<BatteryDataPoint> = BatteryDataPoint.fetchRequest()
            request.predicate = predicate("timestamp")
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            return "timestamp,percent\n" + (try context.fetch(request)).map { "\(date($0.timestamp)),\($0.value)" }.joined(separator: "\n")
        case .sleep:
            let request: NSFetchRequest<SleepSession> = SleepSession.fetchRequest()
            request.predicate = predicate("start")
            request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: true)]
            return "start,end,asleep_minutes,awake_minutes\n" + (try context.fetch(request)).map { "\(date($0.start)),\(date($0.end)),\($0.asleepMinutes),\($0.awakeMinutes)" }.joined(separator: "\n")
        case .exercise:
            let request: NSFetchRequest<UserExercise> = UserExercise.fetchRequest()
            request.predicate = predicate("startDate")
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
            return "type,start,end,steps,distance_meters,kcal\n" + (try context.fetch(request)).map { "\($0.exerciseId ?? ""),\(date($0.startDate)),\(date($0.endDate)),\($0.steps),\($0.distance),\($0.caloriesBurned)" }.joined(separator: "\n")
        case .motion:
            let request: NSFetchRequest<MotionActivityPoint> = MotionActivityPoint.fetchRequest()
            request.predicate = predicate("timestamp")
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            return "timestamp,activity\n" + (try context.fetch(request)).map { "\(date($0.timestamp)),\($0.value)" }.joined(separator: "\n")
        }
    }
}
