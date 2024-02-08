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
