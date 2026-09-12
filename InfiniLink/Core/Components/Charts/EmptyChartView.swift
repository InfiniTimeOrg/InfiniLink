//
//  EmptyChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/9/25.
//

import SwiftUI

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            let top = CGPoint(x: rect.maxX, y: rect.minY)
            let bottom = CGPoint(x: rect.maxX, y: rect.maxY)
            
            path.move(to: top)
            path.addLine(to: bottom)
        }
    }
}

struct EmptyChartView: View {
    let chartType: ChartType
    
    private let backgroundColor = Color.primary.opacity(0.35)
    
    init(_ chartType: ChartType) {
        self.chartType = chartType
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .stroke(backgroundColor, lineWidth: 1)
            HStack(spacing: 0) {
                ForEach(1...4, id: \.self) { _ in
                    Line()
                        .stroke(backgroundColor, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(maxWidth: .infinity)
                }
            }
            VStack(spacing: 5) {
                Image(systemName: chartType.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color(.lightGray))
                VStack {
                    Text("Nothing to see here")
                        .font(.title2.weight(.bold))
                    Text("There isn't any \(chartType.rawValue) data to show")
                        .foregroundStyle(.gray)
                }
            }
            .multilineTextAlignment(.center)
            .padding()
        }
        .frame(height: 280)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

#Preview {
    EmptyChartView(.steps)
}
