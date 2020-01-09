//
//  Peripheral.swift
//  TestIos
//
//  Created by kehlin swain on 10/16/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import Foundation
import CoreBluetooth

public class Peripheral {
    let name: String
    let peripheral: CBPeripheral
    var isSelected = false
    var isAlive = false
    var type: Int?
    
    init (name: String, peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.name = name
    }
}
