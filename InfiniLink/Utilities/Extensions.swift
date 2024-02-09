//
//  Extensions.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/5/24.
//

import Foundation
import UIKit
import SwiftUI

extension UINavigationController {
    override open func viewDidLoad() {
        @AppStorage("lockNavigation") var lockNavigation = false
        
        super.viewDidLoad()
        if !lockNavigation {
            interactivePopGestureRecognizer?.delegate = nil
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
