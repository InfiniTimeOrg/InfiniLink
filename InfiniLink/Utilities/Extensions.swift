//
//  Extensions.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/5/24.
//

import Foundation
import UIKit

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
