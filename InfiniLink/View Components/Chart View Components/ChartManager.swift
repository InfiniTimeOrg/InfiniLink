//
//  ChartManager.swift
//  ChartManager
//
//  Created by Alex Emry on 9/19/21.
//

import Foundation
import SwiftUI
import CoreData

import SwiftUICharts

enum ChartsAsInts: Int16 {
	case heart = 0
	case battery = 1
    case connected = 2
}

struct DataPoint {
	let date: Date
	let value: Double
	let chart: Int16
}

class ChartManager: ObservableObject {
	
	@Published var currentChart: chartSelection = .heart
	var lastChartWasHeart = UserDefaults.standard.value(forKey: "lastStatusViewWasHeart") as? Bool ?? true
	@Published var heartRangeSelectionState = DateSelectionState()
	@Published var batteryRangeSelectionState = DateSelectionState()
	
	let viewContext = PersistenceController.shared.container.viewContext
	
	static let shared = ChartManager()
	
	private init() {
		if lastChartWasHeart {
			currentChart = .heart
		} else {
			currentChart = .battery
		}
	}
	
	struct DateSelectionState {
		var dateRangeSelection: Int = 0
		
		// state variables for slider
		var hours: Float = 1
		var days: Float = 0
		var weeks: Float = 0
		
		// state variables for date picker
		var endDate = Date()
		var startDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? (Date() - 2419200)
	}
	
	@Published var trueIfHeart = true
	@Published var trueIfBat = false
	
	enum DateRange {
		case hour
		case day
		case week
		//case all
	}
	
	enum chartSelection {
		case heart
		case battery
        case connected
	}
	
	func addItem(dataPoint: DataPoint) {
		let newItem = ChartDataPoint(context: viewContext)
		newItem.timestamp = dataPoint.date
		newItem.value = dataPoint.value
		newItem.id = UUID()
		newItem.chart = dataPoint.chart
		do {
			try viewContext.save()
		} catch {
			DebugLogManager.shared.debug(error: "Error saving data point: \(error)", log: .app, date: Date())
		}
	}
	
	func deleteAll(dataSet: FetchedResults<ChartDataPoint>, chart: Int16) {
		for i in dataSet {
			if i.chart == chart {
				viewContext.delete(i)
			}
		}
		do {
			try viewContext.save()
		} catch {
			DebugLogManager.shared.debug(error: "Error deleting all chart data: \(error)", log: .app, date: Date())
		}
	}
    
    func deleteAllSteps(dataSet: FetchedResults<StepCounts>) {
        for i in dataSet {
            viewContext.delete(i)
        }
        do {
            try viewContext.save()
        } catch {
            DebugLogManager.shared.debug(error: "Error deleting chart data set: \(error)", log: .app, date: Date())
        }
    }
	
	func deleteItems(dataSet: [ChartDataPoint]) {
		for i in dataSet {
			viewContext.delete(i)
		}
		do {
			try viewContext.save()
		} catch {
			DebugLogManager.shared.debug(error: "Error deleting chart data set: \(error)", log: .app, date: Date())
		}
	}
	
	func convert(results: FetchedResults<ChartDataPoint>) -> [LineChartDataPoint] {
		var dateRangeSelection: DateSelectionState
		if currentChart == .heart {
			dateRangeSelection = heartRangeSelectionState
		} else {
            //batteryRangeSelectionState.days = 2
			dateRangeSelection = batteryRangeSelectionState
		}
		var dataPoints: [LineChartDataPoint] = []
		let dateFormat = DateFormatter()
		dateFormat.dateFormat = "MMM d\nH:mm:ss"
		for data in results {
			switch dateRangeSelection.dateRangeSelection {
			case 1:
				let dateSum = (dateRangeSelection.hours * -3600) +	(dateRangeSelection.days * -86400) + (dateRangeSelection.weeks * -604800)
				if data.timestamp!.timeIntervalSinceNow >= Double(dateSum) {
					dataPoints.append(LineChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!))
				}
			case 2:
				if data.timestamp! >= dateRangeSelection.startDate && data.timestamp! <= dateRangeSelection.endDate {
					dataPoints.append(LineChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!))
				}
			default:
                dataPoints.append(LineChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!))
			}
			
		}
		return dataPoints
	}
    
    func convertBat(results: FetchedResults<ChartDataPoint>, connected: FetchedResults<ChartDataPoint>) -> [BarChartDataPoint] {
        var dataPoints: [BarChartDataPoint] = []
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "MMM d\nH:mm:ss"
        let now = Date()
        let posHour = now.posHour()
        let oneDayAgo = posHour.addingTimeInterval(-24*60*60)
        let interval = (posHour.timeIntervalSince(oneDayAgo)) / 79

        var isConnected : Bool = false
        var lastValue : Double = 0.0
        
        for i in 0..<79 {
            let targetTime = oneDayAgo.addingTimeInterval(Double(i) * interval)
            
            if targetTime > now {
                dataPoints.append(BarChartDataPoint(value: 0.0, xAxisLabel: "Time", description: "", date: nil))
            } else {
                if let data = connected.last(where: { $0.timestamp!.timeIntervalSince(targetTime) < 0 }) {
                    isConnected = (data.value == 1)
                }
                if let data = results.last(where: { abs($0.timestamp!.timeIntervalSince(targetTime)) < interval/2 }) {
                    dataPoints.append(BarChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!, colour: ColourStyle(colour: colorForBatteryValue(value: data.value))))
                    lastValue = data.value
                } else {
                    if isConnected, let data = results.first(where: { $0.timestamp!.timeIntervalSince(targetTime) > 0 }) {
                        dataPoints.append(BarChartDataPoint(value: (lastValue + data.value) / 2.0, xAxisLabel: "Time", description: "", date: nil, colour: ColourStyle(colour: colorForBatteryValue(value: (lastValue + data.value) / 2.0))))
                    } else {
                        dataPoints.append(BarChartDataPoint(value: 0.0, xAxisLabel: "Time", description: "", date: nil))
                    }
                }
            }
        }
        return dataPoints
    }
    
    private func colorForBatteryValue(value: Double) -> Color {
        if value > 20 {
            return .green
        } else {
            return .red
        }
    }
}

extension Date {
    func posHour() -> Date {
        return Date(timeIntervalSinceReferenceDate:
                        (timeIntervalSinceReferenceDate / (3600.0)).rounded(.down) * (3600.0) + ((timeIntervalSinceReferenceDate / (3600.0)).rounded(.down) * (3600.0) - (timeIntervalSinceReferenceDate / (3600.0 * 3.0)).rounded(.down) * (3600.0 * 3.0)))
    }
}
#Preview {
    BatteryView()
}
