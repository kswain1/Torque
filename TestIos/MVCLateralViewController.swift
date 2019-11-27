//
//  MVCLateralViewController.swift
//  TestIos
//
//  Created by kehlin swain on 11/26/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import UIKit
import Foundation
import MLVerticalProgressView
import CoreBluetooth


/// Array holder for peripherals collected in view controller


class MVCLateralViewController: UIViewController {
    // MARK: Outlets
    @IBOutlet weak var verticalProgress: VerticalProgressView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    var timerProgress = Timer()
    var progressSeconds = Double(0.0)
    var isStartClicked = false
    
    // Peripherals Data
    var btReceiverHolderTypesArray = [Int]()
    var medGastro = [Double]()
    var latGastro = [Double]()
    var tibAnterior = [Double]()
    var peroneals = [Double]()
    //delegate method for peripherals view controller
    weak var mvcDelegate: MVCDelegate?
    
    override
    func viewDidLoad() {
        super.viewDidLoad()
        setupPeripherals()

    }
    

    
    @IBAction func start(_ sender: UIButton) {
        if (startButton.isSelected){
            self.isStartClicked = false
            timerProgress.invalidate()
        }else {
            //Start Timer
            self.isStartClicked = true
            self.progressView.progress = 0.0
            timerProgress = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MVCAnteriorViewController.updateTimer)), userInfo: nil, repeats: true)
            
        }
        
    }
    
    @objc func updateTimer() {
        progressSeconds += 1//This will decrement(count down)the seconds.
        let MVCTimer = 3.0
        if progressSeconds >= MVCTimer {
            timerProgress.invalidate()
//            self.startButton(self.startButton)
//            let leg = self.rightOrLeftLeg()
//            self.objParentVC.saveSessionData(leg: leg)
//            self.objParentVC.sessionDataValues.count
//            saveDataAlertView()
            print("We are counting down your timer")
            print("progress second Timer")
            self.progressSeconds = 0.0
            saveDataAlertView()
            
        }
//        self.lblProgressValue.text = "\(Int(progressSeconds))" //This will update the label.
        self.progressView.progress = Float(progressSeconds/MVCTimer)
//        self.progressViewTimer.progress = CGFloat(progressSeconds / MVCTimer)
    }
    
    
}

// Mark: Save Data Alert
extension MVCLateralViewController {
    func saveDataAlertView() {
        
        /// calulate Max MVC
        var MVC: Double = 0.0
         if (self.peroneals.capacity != 0) {
            MVC = peroneals.max()!
        }
        
        let alertView = UIAlertController(title: "Save MVC Session Data", message: "Peroneals MVC calculated: \(MVC) mv do you wish  to save?", preferredStyle: .alert )
        alertView.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
//            self.postDataToBackend()
            let mvcObject = ("Peroneals",MVC)
            self.mvcDelegate?.addMVC(MVC: mvcObject)
            _ = self.navigationController?.popViewController(animated: true)
        }))
        
        alertView.addAction(UIAlertAction(title: "Heck No", style: .cancel, handler: nil))
        self.present(alertView, animated:true)
    }
    
    /// Update Vertical Progress Bar
    public func updateProgressBar(emgData: Double) {
            let max_value = 20000.00
            let normalizedData = Float(emgData.remainder(dividingBy: max_value))
    //        let normalizedData = Float(emgData.divided(by: max_value))
            //Update On Main Thread
            DispatchQueue.main.async {
                self.verticalProgress.setProgress(progress: normalizedData, animated: true)
//                self.lblLateralValue.text = "\(emgData)"
            }
        }
   
}

// Mark: AnteriorView Controller Delagate call
extension MVCLateralViewController: BluetoothControllerDelegate{
    func didAddPeripherals(array: [Peripheral]?, btmanager: CBCentralManager?) {
        BluetoothPreferences.btManager = btmanager
        BluetoothPreferences.peripherals = array
    }
}

// Mark: SaveOutlets
extension MVCLateralViewController: CBPeripheralDelegate {
    fileprivate func setupPeripherals() {
//        sessionDataValues.removeAll()
        btReceiverHolderTypesArray.removeAll()
        
        BluetoothPreferences.peripherals?.forEach { peripheral in
            print("MVC ANterior we have peripherals")
            peripheral.peripheral.delegate = self
            peripheral.peripheral.discoverServices([BluetoothPreferences.serviceUUID])
//            self.sessionDataValues.append([Double]())
            self.btReceiverHolderTypesArray.append(-1)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        /// check for error
        if let error = error {
            print("ERROR didDiscoverCharacteristicsFor service \(error)")
            return
        }
        
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
                     peripheral.setNotifyValue(true, for: characteristic)
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
                print(emgDataList)
                if isStartClicked {
                    for sessionDataValue in emgDataList {
                        if let preferencePeripherals = BluetoothPreferences.peripherals {
                            for i in 0..<preferencePeripherals.count {
                            
                                if peripheral == preferencePeripherals[i].peripheral {
//                                     self.sessionDataValues[i].append(sessionDataValue)
                                    self.btReceiverHolderTypesArray[i] = preferencePeripherals[i].type!
                                    switch preferencePeripherals[i].type!{
                                    /// append storage array for sensors involved 0 - Medial Gastroc 1 - Posterial Mediall, 2 - Tibilar Anterior  3- Peroneals
                                    case 1:
                                        self.peroneals.append(sessionDataValue)
                                        self.updateProgressBar(emgData: sessionDataValue)
                                        break
                                    case 2:
                                        self.tibAnterior.append(sessionDataValue)
                                        break
                                    case 3:
                                        self.latGastro.append(sessionDataValue)
                                        break
                                    case 4:
                                        self.medGastro.append(sessionDataValue)
                                        break
                                    default:
                                        break
                                
                                    }
                             }
                         }
                     }
                 }
            }
        }
    }
}



