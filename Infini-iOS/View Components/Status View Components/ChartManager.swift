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

class ChartManager {
	
	static let shared = ChartManager()
	private init() {}
	
	//@Environment(\.managedObjectContext) var viewContext
	let viewContext = PersistenceController.shared.container.viewContext
	
	func addItem(dataPoint: DataPoint) {
		let newItem = ChartDataPoint(context: viewContext)
		newItem.timestamp = dataPoint.date
		newItem.value = dataPoint.value
		newItem.id = UUID()
		newItem.chart = dataPoint.chart
		do {
			try viewContext.save()
			if newItem.chart == ChartsAsInts.heart.rawValue {
				print("hrm save successful")
			} else {
				print("batt save successful")
			}
		} catch {
			//fatalError(error.localizedDescription)
			print(error)
		}
	}
	
	func convert(results: FetchedResults<ChartDataPoint>, chart: Int16) -> [LineChartDataPoint] {
		var dataPoints: [LineChartDataPoint] = []
		let dateFormat = DateFormatter()
		dateFormat.dateFormat = "H:mm:ss"
		for data in results {
			if data.chart == chart {
				dataPoints.append(LineChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!))
			}
		}
		return dataPoints
	}
	
}
