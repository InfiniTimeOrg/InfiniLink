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
}

struct DataPoint {
	let date: Date
	let value: Double
	let chart: Int16
}

class ChartManager: ObservableObject {
	
	@Published var currentChart: chartSelection = .battery
	var lastChartWasHeart = UserDefaults.standard.value(forKey: "lastStatusViewWasHeart") as? Bool ?? false
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
	}
	
	enum DateValue: Double {
		case hour = -3600
		case day = -86400
		case week = -604800
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
}
