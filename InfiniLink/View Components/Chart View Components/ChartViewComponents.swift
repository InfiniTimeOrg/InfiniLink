//
//  ChartViewComponents.swift
//  InfiniLink
//
//  Created by John Stanley on 5/11/22.
//

import SwiftUI

struct BarView: View {

    var value: CGFloat
    var cornerRadius: CGFloat
    var width: CGFloat
    var valueHeight: CGFloat
    var height: CGFloat
    
    var body: some View {
        VStack {
            ZStack (alignment: .bottom) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .frame(width: width, height: height).foregroundColor(.clear)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .frame(width: width, height: value * (height / valueHeight)).foregroundColor(value > 20 ? .green : .red)
                Rectangle()
                    .frame(width: width, height: (value * (height / valueHeight)) / 2).foregroundColor(value > 20 ? .green : .red)
                
            }
            Spacer()
        }
        
    }
}

struct HorizontalLines: View {
    var numbLines: Int
    var sizes: CGSize
    var height: CGFloat
    
    var body: some View {
        VStack(alignment: .center) {
            ForEach((1...numbLines).reversed(), id: \.self) {numb in
                Rectangle()
                    .frame(width: sizes.width, height: 1).foregroundColor(Color(light: .lightGray, dark: .darkGray))
                if numb != 1 {
                    Spacer(minLength: (height - CGFloat(numbLines)) / CGFloat(numbLines - 1))
                }
            }
            Spacer()
        }
    }
}

struct verticalLines: View {
    var numbLines: Int
    var sizes: CGSize
    var height: CGFloat
    
    var body: some View {
        
        VStack(alignment: .center) {
            HStack(alignment: .center) {
                ForEach((1...numbLines).reversed(), id: \.self) {numb in
                    VStack() {
                        ForEach((1...20).reversed(), id: \.self) {_ in
                            Rectangle()
                                .frame(width: 1, height: height / ((20 * 2) - 1)).foregroundColor(Color(light: .lightGray, dark: .darkGray))
                            if numb != 15 {Spacer(minLength: height / ((20 * 2) - 1))}
                        }
                    }
                    if numb != 1 {
                        Spacer(minLength: (sizes.width - CGFloat(numbLines)) / CGFloat(numbLines - 1))
                    }
                }
            }
            Spacer()
        }
    }
}

extension UIColor {
  convenience init(light: UIColor, dark: UIColor) {
    self.init { traitCollection in
      switch traitCollection.userInterfaceStyle {
      case .light, .unspecified:
        return light
      case .dark:
        return dark
      @unknown default:
        return light
      }
    }
  }
}

extension Color {
  init(light: Color, dark: Color) {
    self.init(UIColor(light: UIColor(light), dark: UIColor(dark)))
  }
}
