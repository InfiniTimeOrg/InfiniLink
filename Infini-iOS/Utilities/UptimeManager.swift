//
//  UptimeManager.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/23/21.
//  
//
    

import Foundation

class UptimeManager: ObservableObject {
	static let shared = UptimeManager()
	
	@Published var secondsElapsed: Double = 0.0
	private var timer = Timer()
	
	func start() {
		timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
			self.secondsElapsed += 1
		}
	}
	
	func stop() {
		timer.invalidate()
	}
	
}
