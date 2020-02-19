//
//  emgPeripheralModel.swift
//  TestIos
//
//  Created by kehlin swain on 1/7/20.
//  Copyright © 2020 kehlin swain. All rights reserved.
//

import Foundation
import CoreBluetooth

struct EMGStruct {
    var peroneals = [Double]()
    var tibAnterior = [Double]()
    var latGastroc = [Double]()
    var medGastroc = [Double]()
}

class EMGPeripheral: NSObject, CBPeripheralDelegate {
    
    static let shared = EMGPeripheral()
    private override init() {} // Prohibit explicit initialization
    
//    var btManager : CBCentralManager
//    var peripherals : [Peripheral]?
    var emgSession = EMGStruct()
    var sessionDataValues = [[Double]]()
    var isStartClicked = false
       
//    init(btManager: CBCentralManager, peripherals: [Peripheral]) {
//        self.btManager = btManager
//        self.peripherals = peripherals
//
//   }
    
    deinit {
        
    }
    
    fileprivate func setupPeripherals() {
        
        BluetoothPreferences.peripherals?.forEach { peripheral in
            print("we have peripherals")
            peripheral.peripheral.delegate = self
            peripheral.peripheral.discoverServices([BluetoothPreferences.serviceUUID])
            self.sessionDataValues.append([Double]())
//            self.btReceiverHolderTypesArray.append(-1)
        }
    }
    
    func startOrStopCollection (startClicked: Bool){
        if startClicked == true {
            self.isStartClicked = true
            self.setupPeripherals()
        }else {
            self.isStartClicked = false
            
        }
    }
    
    func getEmgData () -> EMGStruct {
        return self.emgSession
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        /// check for error
        if let error = error {
            print("ERROR didDiscoverCharacteristicsFor service \(error)")
            return
        }
        print("we are in the discover services for our class")
        
        if let pServices = peripheral.services {
            for service in pServices {
                if service.uuid == BluetoothPreferences.serviceUUID{
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
   func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        /// check for error
        if let error = error {
            print("ERROR didDiscoverServices \(error)")
            return
        }
        
        if let sCharacteristics = service.characteristics {
            for characteristic in sCharacteristics {
                if characteristic.uuid == BluetoothPreferences.charUUID{
                    //potential spot for turning on and off bluetooth (change notify value after testing will the data be passed into the object
                    if isStartClicked{
                      peripheral.setNotifyValue(true, for: characteristic)
                    } else {
                      peripheral.setNotifyValue(false, for: characteristic)
                    }
                }
            }
        }
    }
    
     func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
         /// Check for error
         if let error = error {
             print("ERROR didUpdateValue \(error)")
             return
         }
         
         /// Check if ids coincide
         if characteristic.uuid == BluetoothPreferences.charUUID {
             // Get dataSessionValue
             let emgDataList = emgDataConvert(from: characteristic)
             
            if self.isStartClicked {
                //print(emgDataList)
                 for sessionDataValue in emgDataList {
                    if let preferencePeripherals = BluetoothPreferences.peripherals {
                         for i in 0..<preferencePeripherals.count {
                         
                             if peripheral == preferencePeripherals[i].peripheral {
                                 // self.sessionDataValues[i].append(sessionDataValue)
                                 //self.btReceiverHolderTypesArray[i] = preferencePeripherals[i].type!
                                 switch preferencePeripherals[i].type!{
                                 /// append storage array for sensors involved 0 - Medial Gastroc 1 - Posterial Mediall, 2 - Tibilar Anterior  3- Peroneals
                                 case 1:
                                     //self.peroneals.append(sessionDataValue)
                                    self.emgSession.peroneals.append(sessionDataValue)
                                     break
                                 case 2:
//                                     self.tibAnterior.append(sessionDataValue)
                                     self.emgSession.tibAnterior.append(sessionDataValue)
                                     break
                                 case 3:
//                                     self.latGastroc.append(sessionDataValue)
                                     self.emgSession.tibAnterior.append(sessionDataValue)
                                     break
                                 case 4:
//                                    self.medGastroc.append(sessionDataValue)
                                    self.emgSession.medGastroc.append(sessionDataValue)
                                     break
                                 default:
                                     break
                             
                                 }
                           }
                      }
                        //save data to getter
                  }
              }
          }
       }
   }
}

extension EMGPeripheral: BluetoothControllerDelegate{
    func didAddPeripherals(array: [Peripheral]?, btmanager: CBCentralManager?) {
        BluetoothPreferences.peripherals = array
        BluetoothPreferences.btManager = btmanager
    }
}
