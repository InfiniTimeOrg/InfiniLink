//
//  DFUStartButtonColorSelector.swift
//  Infini-iOS
//
//  Created by Alex Emry on 10/3/21.
//  
//
    

import SwiftUI

extension DFUStartTransferButton {
	func buttonDisabled() -> Bool {
		if dfuUpdater.local {
			if firmwareSelected {
				return false
			} else {
				if updateStarted {
					return false
				} else {
					return true
				}
			}
		} else {
			if firmwareSelected {
				if downloadManager.downloading {
					return true
				} else {
					return false
				}
			} else {
				if updateStarted {
					return false
				} else {
					return true
				}
			}
		}
	}
	
	func colorChooser() -> Color {
		if colorScheme == .dark {
			if firmwareSelected {
				if downloadManager.downloading {
					return Color.darkestGray
				} else {
					return Color.darkGray
				}
			} else {
				if updateStarted {
					return Color.darkGray
				} else {
					return Color.darkestGray
				}
			}
		} else {
			if firmwareSelected {
				if downloadManager.downloading {
					return Color.lightGray
				} else {
					return Color.blue
				}
			} else {
				if updateStarted {
					return Color.blue
				} else {
					return Color.lightGray
				}
			}
		}
	}
}
