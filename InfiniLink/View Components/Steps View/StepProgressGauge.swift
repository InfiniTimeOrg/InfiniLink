//
//  StepProgressGauge.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//  
//
    

import SwiftUI

struct StepProgressGauge: View {
	@Binding var currentCount: Float
	
	var body: some View {
		ZStack {
			Circle()
				.stroke(lineWidth: 20.0)
				.opacity(0.3)
				.foregroundColor(Color.blue)
			Circle()
				.trim(from: 0.0, to: CGFloat(min(currentCount, 1.0)))
				.stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
				.foregroundColor(Color.blue)
		}
	}
}
