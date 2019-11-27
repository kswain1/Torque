//
//  PeripheralsViewController.swift
//  TestIos
//
//  Created by kehlin swain on 10/16/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import UIKit
import CoreBluetooth
let emgService = CBUUID(string:"7309203e-349d-4c11-ac6b-baedd1819764")

fileprivate struct Constants {
    
    //allows the peripheral to have a 10 second delay when searching
    struct Peripherals {
        static let searchPeripheralsTimeInterval = 10.0
        static let peripheralStopValue = "stop"
    }
    
    struct SensorPopoverView {
        static let height = 150
        static let width = 200
    }
}

fileprivate enum MeasurementTypes: String {
    case Peroneals = "Peroneals"
    case Tib_Anterior = "Tibilar Anterior"
    case Lat_Gastro = "Lateral Gastro"
    case Med_Gastro = "Medial Gastro"
}

fileprivate enum BLEStatus: String {
    case searching = "Searching for peripherals..."
    case connected = "Connected!"
    case disconnected = "Disconnected"
    case off = "Bluetooth Off!"
}

/// Array holder for peripherals collected in view controller
protocol PeripheralsViewControllerDelegate {
    func didAddPeripherals(array: [Peripheral]?, btmanager: CBCentralManager?)
}

class PeripheralsViewController: UIViewController {
    // MARK: Variables
    
    //Bluetooth peripherals
    fileprivate var btManager: CBCentralManager!
    fileprivate var selectedPeripheral: CBPeripheral!
    fileprivate var currentPeripherals = [Peripheral]()
    fileprivate var selectedPeripherals = [Peripheral]()
    var isSelected = false
    var currentPeripheralUUID = [String]()
    fileprivate var status: BLEStatus = .off {
        didSet {
            statusLabel.text = status.rawValue
            debugPrint(status.rawValue)
        }
    }
    
   fileprivate let measurementTypes = [MeasurementTypes.Peroneals.rawValue : 1, MeasurementTypes.Tib_Anterior.rawValue : 2 , MeasurementTypes.Lat_Gastro.rawValue : 3, MeasurementTypes.Med_Gastro.rawValue: 4]
   fileprivate var availableTypes = [MeasurementTypes.Peroneals.rawValue : 1, MeasurementTypes.Tib_Anterior.rawValue : 2 , MeasurementTypes.Lat_Gastro.rawValue : 3, MeasurementTypes.Med_Gastro.rawValue: 4]
    
    //Timer
    fileprivate var timer = Timer()
    
    //delegate method for peripherals view controller
    var delegateForPeripheralView: PeripheralsViewControllerDelegate?
    
    //MARK: - Outlets and outlet functions
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    @IBOutlet weak var startButton: UIButton!

    
    @IBAction func didTouchConnect(_ sender: Any) {
        print("Select is called")
      //  guard let peripheralArray = BluetoothPreferences.peripherals, let btmanagerValue = BluetoothPreferences.btManager else { return }
        delegateForPeripheralView?.didAddPeripherals(array: selectedPeripherals, btmanager: btManager)
        _ = navigationController?.popViewController(animated: true)
        
    }
    
    
    // MARK: - Functions
    /// Timer func executing on set interval of time in seconds - searchPeripheralsTimeInterval variable
    fileprivate func scheduledTimewithInterval() {
        timer = Timer.scheduledTimer(timeInterval: Constants.Peripherals.searchPeripheralsTimeInterval, target: self, selector: #selector(self.updatePeripherals), userInfo: nil, repeats: true)
    }
    
    @objc fileprivate func updatePeripherals(){
        // 1. Removes gone and out of range peripherals
        currentPeripherals.forEach{ peripheral in
            if !peripheral.isAlive {
                // checking the to see perpheral object is currently in our index
                if let index = currentPeripherals.index(where: { per -> Bool in peripheral.peripheral == per.peripheral }) {
                    // Write "stop" to the peripheral
                    guard let data = Constants.Peripherals.peripheralStopValue.data(using: String.Encoding.utf8) else { return }
                    if let char = currentPeripherals[index].peripheral.services?.first?.characteristics?.first {
                        currentPeripherals[index].peripheral.writeValue(data, for: char, type: .withResponse)
                    }
                    currentPeripherals.remove(at: index)
                    
                    // Cancel the connection
                   btManager.cancelPeripheralConnection(peripheral.peripheral)
                   tableView.beginUpdates()
                   tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                   tableView.endUpdates()
                    
                }
                
            }
            
        }

        // 2. Sets all peripherals' isAlive properties to false so later on when scanned the available ones are marked as alive.
        currentPeripherals.forEach { $0.isAlive = false }
        
        // 3. Retrieve already connected peripherals, because didDiscover doesn't return those peripherals (and set isAlive to true). Only add's specific service for EMG for other ble devices, we have to add services here
        btManager.retrieveConnectedPeripherals(withServices: [BluetoothPreferences.serviceUUID]).forEach { connectedPeripheral in
            if let index = currentPeripherals.index(where: { per -> Bool in per.peripheral.identifier == connectedPeripheral.identifier }) {
                currentPeripherals[index].isAlive = true
            }
        }
        
        // 4. Scans for available peripherals
        //        btManager.scanForPeripherals(withServices: nil, options: nil)
       btManager.scanForPeripherals(withServices: [emgService])
    }
    
    //MARK: PopOver Storyboard
    fileprivate func showPopover(from cell: UITableViewCell, atIndex: Int) {
        //connects to popoview controller
        let popOverView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "muscleTypeViewController") as! SensoryTypeViewController
        
        //sets the style
        popOverView.modalPresentationStyle = .popover
        
        //sets the popover presentation controller
        popOverView.popoverPresentationController?.permittedArrowDirections = .any
        popOverView.popoverPresentationController?.delegate = self
        popOverView.popoverPresentationController?.sourceView = cell
        popOverView.popoverPresentationController?.sourceRect = cell.bounds
        
        popOverView.preferredContentSize = CGSize(width: Constants.SensorPopoverView.width, height: Constants.SensorPopoverView.height)
        
        popOverView.pickerDelegate = self
        popOverView.peripheralNumber = atIndex
        popOverView.typePickerAvailableTypes = availableTypes
        
        //presents the popover
        self.present(popOverView, animated: true, completion:nil)
        
    }
    
    fileprivate func setupBluetoothConnection() {
           btManager = CBCentralManager(delegate: self, queue: nil)
           scheduledTimewithInterval()
           deviceNameLabel.text = "Now discoverable as \(UIDevice.current.name)"
           startButton.isEnabled = false
       }
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBluetoothConnection()
        
        // Tracks user has entered this view
//        Answers.logContentView(withName: "Connecting via Bluetooth Screen", contentType: "bluetooth, ble, sensors", contentId: "5", customAttributes: [:])

        // Do any additional setup after loading the view.
    }
    

    /*

    // In a storyboard-based application, you will often want to do Unknown class PeripheralsViewController in Interface Builder file.a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - UIPopover Delegate
extension PeripheralsViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

//MARK: - Sensor Type Picker Delegate remove selected types from it's row
extension PeripheralsViewController: SensorPickerViewDelegate {
    func didSelect(sensor: Int, of type: String) {
        currentPeripherals[sensor].type = availableTypes[type]
        availableTypes.removeValue(forKey: type)
        tableView.reloadRows(at: [IndexPath(row: sensor, section: 0)], with: .automatic)
    }
}

//MARK: - CBCentralManager Bluetooth Connection
extension PeripheralsViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
                case .unauthorized:
                    status = .off
                case .poweredOff:
                    status = .off
                case .poweredOn:
                    status = .searching
        //            central.scanForPeripherals(withServices: [emgService], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
                    //central.scanForPeripherals(withServices: [emgService])
                    startScan(central: central)
                default: break
                }
    }
    
    func startScan(central: CBCentralManager){
        self.timer.invalidate()
        central.scanForPeripherals(withServices: [emgService])
        print(central.scanForPeripherals(withServices: [emgService]))
        Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(stopScan), userInfo: nil, repeats: false)
    }
    
    @objc func stopScan(){
        self.btManager.stopScan()
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let newPeripheral = Peripheral(name: "HX Sensor" , peripheral: peripheral)
        print(newPeripheral)
        
        //check if peripheral has been selected
        if !isSelected{
            currentPeripherals.append(newPeripheral)
            currentPeripheralUUID.append("\(peripheral.identifier)")
            
        }else if !currentPeripheralUUID.contains("\(peripheral.identifier)"){
            currentPeripherals.append(newPeripheral)
            currentPeripheralUUID.append("\(peripheral.identifier)")
        }
        
        tableView.reloadData()
        // Sets the peripheral's isAlive property to true when discovered (NB: already connected peripherals are not discovered)
        if let index = currentPeripherals.index(where: { per -> Bool in peripheral.identifier == per.peripheral.identifier }) {
            currentPeripherals[index].isAlive = true
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        status = .connected
        startButton.isEnabled = true
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error)
        //consider using alertview
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
           status = .disconnected
           status = .searching

           selectedPeripherals.forEach({ selectedPeripheral in
               if let index = currentPeripherals.index(where: { $0.peripheral == peripheral }), let indexToRemove = selectedPeripherals.index(where: { $0.peripheral == selectedPeripheral.peripheral }) {
                   if selectedPeripheral.peripheral.identifier == currentPeripherals[index].peripheral.identifier {
                       selectedPeripherals.remove(at: indexToRemove)
                       //TODO:
                       updatePeripherals()
                       //BluetoothPreferences.peripherals?.remove(at: indexToRemove)
                   }
               }
           })
           if let index = currentPeripherals.index(where: { per -> Bool in peripheral.identifier == per.peripheral.identifier }) {
               currentPeripherals[index].isSelected = false
               // remove checkmark
               tableView.cellForRow(at: IndexPath(row: index, section: 0))?.accessoryType = .none
           }
           if selectedPeripherals.isEmpty {
               startButton.isEnabled = false
           }
           
           //central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
           central.scanForPeripherals(withServices: [emgService])

       }
}

//MARK: TableView-Delegate Source
extension PeripheralsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "DEVICES"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("table view is being loaded")
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! PeripheralTableViewCell
        cell.peripheral = currentPeripherals[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        isSelected = true
        let cell = tableView.cellForRow(at: indexPath)!
        
        //We are deselecting an already check emg connection
        if cell.accessoryType == .checkmark {
            //Adding available type back in when deselecting a peripheral
            let peripheralToDeselect = selectedPeripherals.filter { $0.peripheral == currentPeripherals[indexPath.row].peripheral }.first
            if let value = peripheralToDeselect?.type {
                availableTypes[measurementTypes.keyFor(value: value)!] = value
            }
            btManager.cancelPeripheralConnection(currentPeripherals[indexPath.row].peripheral)
            cell.accessoryType = .none
            cell.detailTextLabel?.text = "No selected type"
        }else {
            // an emg connection that has not been checked
            cell.accessoryType = .checkmark
            selectedPeripherals.append(currentPeripherals[indexPath.row])
            selectedPeripheral = currentPeripherals[indexPath.row].peripheral
            selectedPeripheral.delegate = self
            btManager.connect(selectedPeripheral, options: nil)
            
            //MARK: Popover View Initated for Muscle Type
            showPopover(from: cell, atIndex: indexPath.row)
        }
        
        if !currentPeripherals.isEmpty {
            currentPeripherals[indexPath.row].isSelected = cell.accessoryType == .checkmark
        }
    }
}

//MARK: CBPeripheral LIGHT Turn On
extension PeripheralsViewController: CBPeripheralDelegate{
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error{
            print("ERROR didDiscoverServices \(error)")
            return
        }
        
        if let peripheralServices = peripheral.services {
            for service in peripheralServices {
                if service.uuid == BluetoothPreferences.serviceUUID {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("ERROR didDiscoverCharacteristicsFor service \(error)")
            return
        }
        
        var turnOn = 1
        let writeValueOn = Data(bytes: &turnOn, count: MemoryLayout.size(ofValue: turnOn))
        if let serviceCharacteristics = service.characteristics {
            for characteristic in serviceCharacteristics {
                if characteristic.uuid == BluetoothPreferences.charUUID {
                    //peripheral.setNotifyValue(true, for: charaacteristic)
                    //startStopSessionRecording(start: true)
                }
                if characteristic.uuid == BluetoothPreferences.lightServiceString {
                    peripheral.writeValue(writeValueOn, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                }
            }
        }
    }
    
    
}
