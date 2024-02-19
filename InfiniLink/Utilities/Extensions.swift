//
//  Extensions.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/5/24.
//

import Foundation
import UIKit
import SwiftUI

extension View {
    func blurredSheet<Content: View>(_ style: AnyShapeStyle,show: Binding<Bool>,onDismiss: @escaping ()->(),@ViewBuilder content: @escaping ()->Content)->some View{
        self
            .sheet(isPresented: show, onDismiss: onDismiss) {
                if #available(iOS 16.4, *) {
                    content()
                        .presentationBackground(style)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    content()
                        .background(RemovebackgroundColor())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            Rectangle()
                                .fill(style)
                                .ignoresSafeArea(.container, edges: .all)
                        }
                }
            }
    }
}

extension UINavigationController {
    override open func viewDidLoad() {
        @AppStorage("lockNavigation") var lockNavigation = false
        
        super.viewDidLoad()
        if !lockNavigation {
            interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

fileprivate struct RemovebackgroundColor: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            uiView.superview?.superview?.backgroundColor = .clear
        }
    }
}

extension String {
    func hexToData() -> Data? {
        let len = self.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = self.index(self.startIndex, offsetBy: i*2)
            let k = self.index(j, offsetBy: 2)
            let bytes = self[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        return data
    }
}

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
    let size = image.size
    
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}

func cropImage(image: UIImage) -> UIImage? {
    let shorterSide = min(image.size.width, image.size.height)
    let squareRect = CGRect(x: 0, y: 0, width: shorterSide, height: shorterSide)

    guard let cgImage = image.cgImage,
          let croppedCGImage = cgImage.cropping(to: squareRect)
    else {
        return nil
    }

    return UIImage(cgImage: croppedCGImage)
}
