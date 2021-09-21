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
		} catch {
			print(error.localizedDescription)
		}
	}
	
	func deleteAll(dataSet: FetchedResults<ChartDataPoint>) {
		for i in dataSet {
			viewContext.delete(i)
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
	
	func convert(results: FetchedResults<ChartDataPoint>) -> [LineChartDataPoint] {
		var dataPoints: [LineChartDataPoint] = []
		let dateFormat = DateFormatter()
		dateFormat.dateFormat = "H:mm:ss"
		for data in results {
			dataPoints.append(LineChartDataPoint(value: data.value, xAxisLabel: "Time", description: dateFormat.string(from: data.timestamp!), date: data.timestamp!))
		}
		return dataPoints
	}
	
}
