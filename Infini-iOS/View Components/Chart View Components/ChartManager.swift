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
	
	@Published var dateRange: DateRange = .day
	@Published var currentChart: chartSelection = .battery
	var lastChartWasHeart = UserDefaults.standard.value(forKey: "lastStatusViewWasHeart") as? Bool ?? false
	
	let viewContext = PersistenceController.shared.container.viewContext
	
	static let shared = ChartManager()
	
	private init() {
		if lastChartWasHeart {
			currentChart = .heart
		} else {
			currentChart = .battery
		}
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
	
	func setTimeRange() -> Double {
		var dateValue: Double = 0
		switch dateRange {
		case .hour:
			dateValue = -3600
		case .day:
			dateValue = -86400
		case .week:
			dateValue = -604800
		}
		return dateValue
	}
	
	func convert(results: FetchedResults<ChartDataPoint>) -> [LineChartDataPoint] {
		var dataPoints: [LineChartDataPoint] = []
		let dateFormat = DateFormatter()
		let timeRange = setTimeRange()
		dateFormat.dateFormat = "MMM d\nH:mm:ss"
		for data in results {
			if timeRange == 0 {
				dataPoints.append(LineChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!))
			} else if data.timestamp!.timeIntervalSinceNow >= setTimeRange() {
				dataPoints.append(LineChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!))
			}
		}
		return dataPoints
	}
}
