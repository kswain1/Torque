//
//  BluetoothPreferences.swift
//  TestIos
//
//  Created by kehlin swain on 10/16/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import Foundation
import CoreBluetooth

struct BluetoothPreferences {
    //Bluetooth Preferences properties
    static let charUUID = CBUUID(string: "e5f49879-6ee1-479e-bfec-3d35e13d3b88")
    static let serviceUUID = CBUUID(string: "7309203e-349d-4c11-ac6b-baedd1819764")
    static let serviceString = "7309203e-349d-4c11-ac6b-baedd1819764"
    static let lightServiceString = CBUUID(string:"b8637601-a003-436d-a995-2a7f20bcb3d4")
//    static let charUUID = CBUUID(string: "ec0e"))
//    static let serviceUUID = CBUUID(string: "ec00")
//    static let serviceString = "EC00"
    //Bluetooth Persistance properties
    static var btManager: CBCentralManager?
    static var peripherals: [Peripheral]?
}

