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
	
	static let shared = ChartManager()
	private init() {}
	
	@Published var trueIfHeart = true
	@Published var trueIfBat = false
	
	enum DateRange {
		case hour
		case day
		case week
		case all
	}
	
	enum DateValue: Double {
		case hour = -3600
		case day = -86400
		case week = -604800
	}
	
	@Published var dateRange: DateRange = .all
	
	let viewContext = PersistenceController.shared.container.viewContext
	
	func addItem(dataPoint: DataPoint) {
		let newItem = ChartDataPoint(context: viewContext)
		newItem.timestamp = dataPoint.date
		newItem.value = dataPoint.value
		newItem.id = UUID()
		newItem.chart = dataPoint.chart
		do {
			try viewContext.save()
		} catch {
			print(error.localizedDescription)
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
			print(error.localizedDescription)
		}
	}
	
	func deleteItems(dataSet: [ChartDataPoint]) {
		for i in dataSet {
			viewContext.delete(i)
		}
		do {
			try viewContext.save()
		} catch {
			print(error.localizedDescription)
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
		case .all:
			dateValue = 0
		}
		return dateValue
	}
	
	func convert(results: FetchedResults<ChartDataPoint>) -> [LineChartDataPoint] {
		var dataPoints: [LineChartDataPoint] = []
		let dateFormat = DateFormatter()
		let timeRange = setTimeRange()
		dateFormat.dateFormat = "H:mm:ss"
		for data in results {
			if timeRange == 0 {
				dataPoints.append(LineChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!))
			} else if data.timestamp!.timeIntervalSinceNow >= setTimeRange() {
				dataPoints.append(LineChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!))
			}
		}
		return dataPoints
	}
	
	func filterDates(results: FetchedResults<ChartDataPoint>) {
		
	}
	
}
