//
//  DebugViewShareButton.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/29/21.
//  
//
    

import Foundation

import SwiftUI
enum Coordinator {
  static func topViewController(_ viewController: UIViewController? = nil) -> UIViewController? {
	let vc = viewController ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
	if let navigationController = vc as? UINavigationController {
	  return topViewController(navigationController.topViewController)
	} else if let tabBarController = vc as? UITabBarController {
	  return tabBarController.presentedViewController != nil ? topViewController(tabBarController.presentedViewController) : topViewController(tabBarController.selectedViewController)
	  
	} else if let presentedViewController = vc?.presentedViewController {
	  return topViewController(presentedViewController)
	}
	return vc
  }
}

extension DebugView {
	func shareApp(text: String) {
	let textToShare = text
	let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
	
	let viewController = Coordinator.topViewController()
	activityViewController.popoverPresentationController?.sourceView = viewController?.view
	viewController?.present(activityViewController, animated: true, completion: nil)
  }
}

