//
//  UptimeManager.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/27/21.
//  
//
    

import Foundation

class UptimeManager: ObservableObject {
	static let shared = UptimeManager()
	
	@Published var connectTime: Date!
	@Published var lastDisconnect: Date!
	@Published var dateFormatter = DateFormatter()
	@Published var uptimeFormatter = DateIntervalFormatter()
	
	init() {
		dateFormatter.dateFormat = "M/dd H:mm:ss"
		uptimeFormatter.timeStyle = .short
	}
	
	
}
