//
//  WatchFace.swift
//  InfiniLink
//
//  Created by Jen on 2/9/24.
//

import Foundation
import SwiftUI
import Combine


struct WatchFace: View {
    @Environment(\.colorScheme) var colorScheme
    let date = Date()
    
    var Watchface = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("WatchScreen")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(color: colorScheme == .dark ? Color.black : Color.secondary, radius: 16, x: 0, y: 0)
                    .brightness(colorScheme == .dark ? -0.02 : 0.035)
                ZStack() {
                    ZStack {
                        PineTimeStyle(geometry: .constant(geometry))
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
                    .scaleEffect(0.53, anchor: .center)
                    .frame(width: geometry.size.width, height: geometry.size.width, alignment: .center)
                    .position(x: geometry.size.width / 2, y: geometry.size.width / 2 - 2)
                    .brightness(colorScheme == .dark ? 0.015 : 0.125)
                    .clipped()
                }
                .frame(width: geometry.size.width, height: geometry.size.width, alignment: .center)
                .clipped()
                Image("WatchHomeClear")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .brightness(colorScheme == .dark ? 0.0 : 0.04)
            }
        }
    }
}

struct PineTimeStyle: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var geometry : GeometryProxy
    let date = Date()
    
    var hour24 : Bool = false
    
    var body: some View {
        ZStack {
            if !hour24 {
                CustomTextView(text: "P\nM", font: .custom("JetBrainsMono-ExtraBold", size: geometry.size.width * 0.075), lineSpacing: -4)
                    .foregroundColor(.white)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
            }
            if Calendar.current.component(.hour, from: date) > 12 && !hour24{
                CustomTextView(text: "\(String(format: "%02d", Calendar.current.component(.hour, from: date) - 12))\n\(String(format: "%02d", Calendar.current.component(.minute, from: date)))", font: .custom("OpenSans-light", size: geometry.size.width * 0.62), lineSpacing: -geometry.size.width * 0.35)
                    .foregroundColor(.white)
                    .position(x: geometry.size.width / 2.3, y: geometry.size.height / 2.0)
            } else {
                CustomTextView(text: "\(String(format: "%02d", Calendar.current.component(.hour, from: date)))\n\(String(format: "%02d", Calendar.current.component(.minute, from: date)))", font: .custom("OpenSans-light", size: geometry.size.width * 0.62), lineSpacing: -geometry.size.width * 0.35)
                    .foregroundColor(.white)
                    .position(x: geometry.size.width / 2.3, y: geometry.size.height / 2.0)
            }
            GeometryReader { geometry in
                Rectangle()
                    .foregroundColor(.gray)
                    .position(x: geometry.size.width - ((geometry.size.width / 6.0) / 2), y: geometry.size.height / 2 - 2)
                    .frame(width: geometry.size.width / 6.0, height: geometry.size.height + 4, alignment: .center)
            }
        }
    }
}

struct CustomTextView: View {
    var text: String
    var font: Font
    var lineSpacing: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(text.components(separatedBy: "\n"), id: \.self) { line in
                Text(line)
                    .font(font)
            }
        }
    }
}

#Preview {
    NavigationView {
        DeviceView()
            .onAppear {
                BLEManager.shared.isConnectedToPinetime = true
                BLEManagerVal.shared.firmwareVersion = "1.14.0"
            }
    }
}
