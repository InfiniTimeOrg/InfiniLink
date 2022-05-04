//
//  Test.swift
//  InfiniLink
//
//  Created by Micah Stanley on 4/10/22.
//

import Foundation
import CoreBluetooth
import SwiftUICharts
import SwiftUI


class BLEManagerVal: NSObject, ObservableObject {
    static let shared = BLEManagerVal()
    
    var notifyCharacteristic: CBCharacteristic!
    
    let cbuuidList = BLEManager.cbuuidList()
    var musicChars = BLEManager.musicCharacteristics()

    let settings = UserDefaults.standard
    
    // UI flag variables
    @Published var heartBPM: Double = 0                                    // published var to communicate the HRM data to the UI.

    @Published var firmwareVersion: String = "Disconnected"
    
    //@Published var stepCount: Int = 0
    @Published var stepCount: Int = 0
    @Published var stepCountTests: Int = 0
    @Published var stepCounting: Int = 0

    // Selecting and connecting variables
    @Published var deviceToConnect: Int!                                // When the user selects a device from the UI, that peripheral's ID goes in this var, which is passed to the peripheralDictionary
    @Published var autoconnectPeripheral: CBPeripheral!

    var batChartReconnect: Bool = true                                // skip first HRM transmission on every fresh connection to prevent saving of BS data
    
}

