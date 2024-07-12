//
//  StepsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//
//



import SwiftUI

struct BatteryView: View {
    @Environment(\.presentationMode) var presMode
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("lastStatusViewWasHeart") var lastStatusViewWasHeart: Bool = false
    
    @ObservedObject var bleManager = BLEManager.shared
    
    let chartManager = ChartManager.shared
    
    var foregroundColor: Color {
        if bleManager.batteryLevel <= 10 {
            return .red
        } else if bleManager.batteryLevel <= 20 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Button {
                    presMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                Text(NSLocalizedString("battery_tilte", comment: "Battery"))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            VStack {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 10.0)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(Float(bleManager.batteryLevel.rounded() / 100.0), 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 15.0, lineCap: .round, lineJoin: .round))
                        .rotationEffect(Angle(degrees: 270.0))
                    VStack(spacing: 8) {
                        Image(systemName: "battery." + String(Int(round(Double(String(format: "%.0f",   bleManager.batteryLevel))! / 25) * 25)))
                            .font(.system(size: 35))
                            .imageScale(.large)
                        Text(String(format: "%.0f", bleManager.batteryLevel) + "%")
                            .font(.system(size: 40).weight(.bold))
                    }
                }
                .foregroundColor(foregroundColor)
                .padding(30)
                VStack {
                    Spacer()
                    Text(NSLocalizedString("battery_stats", comment: "").capitalized)
                        .font(.title2.weight(.semibold))
                    BatteryContentView()
                }
                .ignoresSafeArea()
                .padding(20)
                .background(Material.regular)
                .cornerRadius(30, corners: [.topLeft, .topRight])
            }
        }
        .onAppear {
            chartManager.currentChart = .battery
            lastStatusViewWasHeart = false
        }
        .navigationBarBackButtonHidden()
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    BatteryView()
}
