//
//  ViewController.swift
//  TutorialApp
//
//  Created by Elekes Tamas on 7/28/17.
//  Copyright © 2017 Notch Interfaces. All rights reserved.
//

import UIKit
import WearnotchSDK
import CoreBluetooth
import MessageUI
import Accelerate



//Mark: lifeCycle
class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    private let LICENSE_CODE = "x7XURbDfbQWKYOQE7kr3"
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var deviceListLabel: UILabel!
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var realtimeSwitch: UISwitch!
    @IBOutlet weak var dockAnimationImageView: UIImageView!
    @IBOutlet weak var selectedConfigurationLabel: UILabel!
    
    // MARK: - capture buttons
    @IBOutlet weak var steadyInitButton: UIButton!
    @IBOutlet weak var captureInitButton: UIButton!
    @IBOutlet weak var configureCaptureButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    // Mark: EMG Variables
    var btReceiverHolderTypesArray = [Int]()
    var sessionDataValues = [[Double]]()
    var isStartClicked = false
    var sessionDictionary = [String:[Double]]()
    var emgData = EMGStruct()
    //var emgData.medGastroc = [Double]()  //Medial Gastro
   // var emgData.latGastroc = [Double]()  // 1 - Posterial Medial
    //var emgData.tibAnterior = [Double]()  // 2 - Tibilar Anterior
    //var emgData.peroneals = [Double]()  // 3- Peroneals
    var emgDataArray = [0.0,0.0,0.0,0.0]
    var imuDictionary: [[String : Float]]? = []
    var blueToothPeripheralsDelegate: BluetoothControllerDelegate?
    var MVCDict: [String:Double] = [:]
    var captureTimeConfiguration = 30
    
    var htmlString = ""

    
    private var selectedConfiguration: ConfigurationType = ConfigurationType.chest1 {
        didSet {
            selectedConfigurationLabel.text = selectedConfiguration.name
            steadyInitButton.setTitle("\(selectedConfiguration.notchCount) notch init", for: .normal)
            captureInitButton.setTitle("\(selectedConfiguration.notchCount) notch init", for: .normal)
        }
    }
    
    var currentCancellable: NotchCancellable? = nil
    var currentMeasurement: NotchMeasurement? = nil
    var measurementURL: URL?
    
    // Mark: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set your license code here. in a real app it would be asked from the backend and saved
        AppDelegate.service.license = LICENSE_CODE
        
        scrollView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: -20)
        
        reloadNotchList()
        
        statusLabel.isHidden = true
        initDockAnimation()
        selectedConfiguration = ConfigurationType.chest1
        
        realtimeSwitch.addTarget(self, action: #selector(realtimeSwitchChanged(_ :)), for: .valueChanged)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view will appear")
        setupPeripherals()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "MVCAnteriorSegue" {
            let mvcVC = segue.destination as? MVCAnteriorViewController
            mvcVC?.mvcDelegate = self
            blueToothPeripheralsDelegate?.didAddPeripherals(array: BluetoothPreferences.peripherals, btmanager: BluetoothPreferences.btManager)
        }else if segue.identifier == "MVCPosterioSegue" {
            let mvcVC = segue.destination as? MVCPosterioViewController
            mvcVC?.mvcDelegate = self
            blueToothPeripheralsDelegate?.didAddPeripherals(array: BluetoothPreferences.peripherals, btmanager: BluetoothPreferences.btManager)
        }else if segue.identifier == "MVCLateralSegue" {
            let mvcVC = segue.destination as?  MVCLateralViewController
            mvcVC?.mvcDelegate = self
            blueToothPeripheralsDelegate?.didAddPeripherals(array: BluetoothPreferences.peripherals, btmanager: BluetoothPreferences.btManager)
        }else if segue.identifier == "SensorBodyAttachment"{
            let sensorBodyVC = segue.destination as? SensorBodyAttachmentViewController
            // pass the configuration object here
            sensorBodyVC?.sensorConfiguration = selectedConfiguration
            
        }else if segue.identifier == "Visualizer"{
            let visualizerVC = segue.destination as? VisualiserViewController
            // pass the configuration object here
            visualizerVC?.sensorConfiguration = selectedConfiguration
            print("selected configuration, ", selectedConfiguration)
        }
        let nav = segue.destination as? PeripheralsViewController
       // let vc = nav?.topViewController as? PeripheralsViewController
        nav?.delegateForPeripheralView = self
    }
    @IBAction func startEmg(_ sender: Any) {
        
        // use let
        
        if BluetoothPreferences.btManager != nil {
            blueToothPeripheralsDelegate?.didAddPeripherals(array: BluetoothPreferences.peripherals, btmanager: BluetoothPreferences.btManager) // == nil (let's see why??)
            EMGPeripheral.shared.startOrStopCollection(startClicked: true)
        }else {
            showFailedBleConnection()
        }
        
        isStartClicked = true
        var progressSeconds = 0.0
        var maxTimeElapse = captureTimeConfiguration
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (Timer) in
            progressSeconds += 1.0
            if Int(progressSeconds) >= maxTimeElapse {
                self.isStartClicked = false
                print("It has been 3 seconds")
                Timer.invalidate()
                EMGPeripheral.shared.startOrStopCollection(startClicked: false)
                self.emgData = EMGPeripheral.shared.getEmgData()
            }
            
        }
    }
    
    
    @IBAction func stopEMG(_ sender: Any) {
        isStartClicked = false
        EMGPeripheral.shared.startOrStopCollection(startClicked: false)
    }
    
    @IBAction func downloadCSV(_ sender: Any) {
        let fileName = "emgDownload.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Medial Gastroc, Posteriolateral Gastroc, Tibilar Anterior,Peroneals\n"
        let count = self.emgData.medGastroc.count
        
        if count > 0 {
            for emgArray in emgData.medGastroc {
                let newline = "\(emgData.medGastroc[0]),\(emgData.medGastroc[1]),\(emgData.medGastroc[2]),\(emgData.medGastroc[3])\n"
//                let newline = currentMeasurement!
                csvText.append(contentsOf: newline)
            }
            
            do {
                //TODO check path is true
                try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
                let vcExportCSV = UIActivityViewController(activityItems: [path], applicationActivities: [])
                vcExportCSV.excludedActivityTypes = [
                    UIActivity.ActivityType.assignToContact,
                    UIActivity.ActivityType.saveToCameraRoll,
                    UIActivity.ActivityType.postToFlickr,
                    UIActivity.ActivityType.postToVimeo,
                    UIActivity.ActivityType.postToTencentWeibo,
                    UIActivity.ActivityType.postToTwitter,
                    UIActivity.ActivityType.postToFacebook,
                    UIActivity.ActivityType.openInIBooks
                ]
                present(vcExportCSV, animated: true, completion: nil)
            }
            catch {
                print("Failed to create file")
                print("Error")
            }
        }
    }
    
    /// EXPORT IMU DATA
    @IBAction func exportIMU(_ sender: Any) {
        let fileName = "imuDownload.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "ankleAngleX, ankleAngleY, ankleAngleZ, lowLegAngleMag,lowLegAngleX, lowLegAngleY, lowLegAngleZ, lowLegAngleVeloMag, lowLegAngleVeloX, lowLegAngleVeloY, lowLegAngleVeloZ, lowLegAngleAccelX, lowLegAngleAccelY, lowLegAngleAccelZ, footAngleMag, footAngleX, footAngleY, footAngleZ, footAngleVeloMag, footAngleVeloX, footAngleVeloY,  footAngleVeloZ, footAngleAccelMag, footAngleAccelX, footAngleAccelY, footAngleAccelZ, footPosMag, footPosX, footPosY, footPosZ,footSpeedMag, footSpeedX, footSpeedY, footSpeedZ, footAccelMag, footAccelX, footAccelY, footAccelZ, lowLegPosMag, lowLegPosX, lowLegPosY, lowLegPosZ, lowLegSpeedMag, lowLegSpeedX, lowLegSpeedY, lowLegSpeedZ, lowLegAccelMag, lowLegAccelX, lowLegAccelY, lowLegAccelZ, medGastro, tibAnterior,\n"
        let count = self.imuDictionary?.count
        var angleX, angleY, angleZ: Float
        var i = 0
        
        //Linear Inteprolation Medial Gastro and Tibilar Anterior
        //let imuSampleTime = 40 * captureTimeConfiguration
        var imuSampleTime = 0
        if imuDictionary?.count != 0 {
            imuSampleTime = imuDictionary!.count
        } else {
            imuSampleTime = captureTimeConfiguration * 50
        }
        
        var emgMedGastro : [Double] = []
        
        
        //linear intperplation activated
        if emgData.medGastroc.count != 0 {

            

            let controlVector: [Float] = vDSP.ramp(in: 0 ... Float(emgData.medGastroc.count) - 1,
            count: imuSampleTime)
            var values = emgData.medGastroc.map { Float($0)}
            values = vDSP.linearInterpolate(elementsOf: values,
            using: controlVector)
            emgData.medGastroc = values.map {Double($0)}
            


        }
        
        if emgData.latGastroc.count != 0 {
              let controlVector: [Float] = vDSP.ramp(in: 0 ... Float(emgData.latGastroc.count) - 1,
                      count: imuSampleTime)
                      var values = emgData.latGastroc.map { Float($0)}
                      values = vDSP.linearInterpolate(elementsOf: values,
                      using: controlVector)
                      emgData.latGastroc = values.map {Double($0)}
        }
        if emgData.tibAnterior.count != 0 {
              let controlVector: [Float] = vDSP.ramp(in: 0 ... Float(emgData.tibAnterior.count) - 1,
                      count: imuSampleTime)
                      var values = emgData.tibAnterior.map { Float($0)}
                      values = vDSP.linearInterpolate(elementsOf: values,
                      using: controlVector)
                      emgData.tibAnterior = values.map {Double($0)}
        }
        if emgData.peroneals.count != 0 {
              let controlVector: [Float] = vDSP.ramp(in: 0 ... Float(emgData.peroneals.count) - 1,
                      count: imuSampleTime)
                      var values = emgData.peroneals.map { Float($0)}
                      values = vDSP.linearInterpolate(elementsOf: values,
                      using: controlVector)
                      emgData.peroneals = values.map {Double($0)}
        }
        
        ///Save emg Data to IMUDictionary
        if imuDictionary != nil {
            let imulength = imuDictionary!.count
            for i in 0..<imulength {
                if emgData.medGastroc.count != 0{
                    if let MedGastroc = self.MVCDict["medialGastroc"] {
                        var normalize = self.emgData.medGastroc[i]/MedGastroc
                        normalize *= 100
                        imuDictionary![i]["medGastro"] = Float(normalize)
                    }
                    else {
                        imuDictionary![i]["medGastro"] = Float(emgData.medGastroc[i])
                    }
                }
                
                if emgData.latGastroc.count != 0{
                    // check for MVC value storage
                    if let LatGastroc = self.MVCDict["lateralGastroc"]{
                        var normalize = self.emgData.latGastroc[i]/LatGastroc
                        normalize *= 100
                        imuDictionary![i]["latGastro"] = Float(normalize)
                    }else {
                        imuDictionary![i]["latGastro"] = Float(emgData.latGastroc[i])
                    }
                }
                
                if emgData.tibAnterior.count != 0{
                    //check for MVC value storage
                    if let TibAnterior = self.MVCDict["Anterior"]{
                        var normalize = self.emgData.tibAnterior[i]/TibAnterior
                        normalize *= 100
                        imuDictionary![i]["tibAnt"] = Float(normalize)
                    }else{
                        imuDictionary![i]["tibAnt"] = Float(emgData.tibAnterior[i])
                    }
                    
                }
                
                if emgData.peroneals.count != 0{
                    //check for MVC value storage
                    if let Peroneals = self.MVCDict["Peroneals"]{
                        var normalize = self.emgData.peroneals[i]/Peroneals
                        normalize *= 100
                        imuDictionary![i]["peroneals"] = Float(normalize)
                    }
                    imuDictionary![i]["peroneals"] = Float(emgData.peroneals[i])
                }
            }
            
            //clear emg data
            emgData.medGastroc = []
            emgData.latGastroc = []
            emgData.tibAnterior = []
            emgData.peroneals = []
            
        }
        
        if imuDictionary != nil{
            var imuMotionList = "\(i),"
            for item in imuDictionary!{
                if (item["angleX"] != nil){
                angleX = item["angleX"] ?? 0.00
                angleY = item["angleY"] ?? 0.00
                angleZ = item["angleZ"] ?? 0.00
                    csvText.append(contentsOf: "\(angleX), \(angleY), \(angleZ),")
                    
                }else {
                    csvText.append(contentsOf: ",,,")
                }
                
                if (item["lowerLegAngleX"] != nil){
                    let lowLegAngleX = item["lowerLegAngleX"] ?? 0.00
                    let lowLegAngleY = item["lowerLegAngleY"] ?? 0.00
                    let lowLegAngleZ = item["lowerLegAngleZ"] ?? 0.00
                    let lowerLegAngleMag = item["lowerLegAngleMag"] ?? 0.00
                    csvText.append(contentsOf: "\(lowerLegAngleMag), \(lowLegAngleX), \(lowLegAngleY), \(lowLegAngleZ),")
                }else{
                    csvText.append(contentsOf: ",,,,")
                }
                
                if (item["lowerLegAngleVeloX"] != nil){
                    let angleVeloX = item["lowerLegAngleVeloX"] ?? 0.00
                    let angleVeloY = item["lowerLegAngleVeloY"] ?? 0.00
                    let angleVeloZ = item["lowerLegAngleVeloZ"] ?? 0.00
                    let lowerLegAngleVeloMag = item["lowerLegAngleVeloMag"] ?? 0.00
                    csvText.append(contentsOf: "\(lowerLegAngleVeloMag), \(angleVeloX), \(angleVeloY), \(angleVeloZ),")
                }else{
                    csvText.append(contentsOf: ",,,,")
                }
                
                if (item["angleAccelX"] != nil){
                    let angleAccelX = item["angleAccelX"] ?? 0.00
                    let angleAccelY = item["angleAccelY"] ?? 0.00
                    let angleAccelZ = item["angleAccelZ"] ?? 0.00
                    csvText.append(contentsOf: "\(angleAccelX), \(angleAccelY), \(angleAccelZ),")
                }else {
                    csvText.append(contentsOf: ",,,")
                }
                if (item["footAngleX"] != nil){
                    let footAngleX = item["footAngleX"]!
                    let footAngleY = item["footAngleY"]!
                    let footAngleZ = item["footAngleZ"]!
                    let footAngleMag = item["footAngleMag"]!
                    csvText.append(contentsOf: "\(footAngleMag),\(footAngleX), \(footAngleY), \(footAngleZ),")
                }else {
                    csvText.append(contentsOf: ",,,,")
                }
                if (item["footAngleVeloX"] != nil){
                    let footAngleVeloX = item["footAngleVeloX"]!
                    let footAngleVeloY = item["footAngleVeloY"]!
                    let footAngleVeloZ = item["footAngleVeloZ"]!
                    let footAngleVeloMag = item["footAngleVeloMag"]!
                    csvText.append(contentsOf: "\(footAngleVeloMag),\(footAngleVeloX), \(footAngleVeloY), \(footAngleVeloZ),")
                }else {
                    csvText.append(contentsOf: ",,,,")
                }
                if (item["footAngleAccelX"] != nil){
                    let footAngleAccelX = item["footAngleAccelX"]!
                    let footAngleAccelY = item["footAngleAccelY"]!
                    let footAngleAccelZ = item["footAngleAccelZ"]!
                    let footAngleAccelMag = item["footAngleAccelMag"]!
                    csvText.append(contentsOf: "\(footAngleAccelMag),\(footAngleAccelX), \(footAngleAccelY), \(footAngleAccelZ),")
                }else {
                    csvText.append(contentsOf: ",,,,")
                }
                
                if (item["posX"] != nil){
                    let posX = item["posX"]!
                    let posY = item["posY"]!
                    let posZ = item["posZ"]!
                    let posMag = item["posMag"]!
                    csvText.append(contentsOf: "\(posMag), \(posX), \(posY), \(posZ),")
                }else {
                    csvText.append(contentsOf: ",,,,")
                }
                
                if (item["footSpeedX"] != nil){
                    let footSpeedX = item["footSpeedX"]!
                    let footSpeedY = item["footSpeedY"]!
                    let footSpeedZ = item["footSpeedZ"]!
                    let footSpeedMag = item["footSpeedMag"]!
                    csvText.append(contentsOf: "\(footSpeedMag), \(footSpeedX), \(footSpeedY), \(footSpeedZ),")
                }else {
                    csvText.append(contentsOf: ",,,,")
                }
                
                if (item["footAccelX"] != nil){
                    let footAccelX = item["footAccelX"]!
                    let footAccelY = item["footAccelY"]!
                    let footAccelZ = item["footAccelZ"]!
                    let footAccelMag = item["footAccelMag"]!
                    csvText.append(contentsOf: "\(footAccelMag), \(footAccelX), \(footAccelY), \(footAccelZ),")
                }else {
                    csvText.append(contentsOf: ",,,,")
                }
                
                if (item["lowerLegPosX"] != nil){
                    let lowerLegPosX = item["lowerLegPosX"]!
                    let lowerLegPosY = item["lowerLegPosY"]!
                    let lowerLegPosZ = item["lowerLegPosZ"]!
                    let lowerLegPosMag = item["lowerLegPosMag"]!
                    csvText.append(contentsOf: "\(lowerLegPosMag), \(lowerLegPosX), \(lowerLegPosY), \(lowerLegPosZ),")
                }else {
                    csvText.append(contentsOf: ",,,,")
                }
                
                if (item["lowerLegSpeedX"] != nil){
                    let lowerLegSpeedX = item["lowerLegSpeedX"]!
                    let lowerLegSpeedY = item["lowerLegSpeedY"]!
                    let lowerLegSpeedZ = item["lowerLegSpeedZ"]!
                    let lowerLegSpeedMag = item["lowerLegSpeedMag"]!
                    csvText.append(contentsOf: "\(lowerLegSpeedMag), \(lowerLegSpeedX), \(lowerLegSpeedY), \(lowerLegSpeedZ),")
                }else {
                    csvText.append(contentsOf: ",,,,")
                }
                
                if (item["lowerLegAccelX"] != nil){
                    let lowLegAccelX = item["lowerLegAccelX"]!
                    let lowerLegAccelY = item["lowerLegAccelY"]!
                    let lowerLegAccelZ = item["lowerLegAccelZ"]!
                    let lowerLegAccelMag = item["lowerLegAccelMag"]!
                    csvText.append(contentsOf: "\(lowerLegAccelMag), \(lowLegAccelX), \(lowerLegAccelY), \(lowerLegAccelZ),")
                }else {
                    csvText.append(contentsOf: ",,,,")
                }
                
                if (item["medGastro"] != nil){
                    let medGastro = item["medGastro"]!
                    csvText.append(contentsOf: "\(medGastro),")
                }else {
                    csvText.append(contentsOf: ",")
                }
                
                if (item["tibAnt"] != nil){
                    let tibAnterior = item["tibAnt"]!
                    csvText.append(contentsOf: "\(tibAnterior)\n")
                }else {
                    csvText.append(contentsOf: "\n")
                }
            }
            // clear IMU data
            imuDictionary = [[String:Float]]()
            
            do {
                try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
                let vcExportCSV = UIActivityViewController(activityItems: [path], applicationActivities: [])
                vcExportCSV.excludedActivityTypes = [
                    UIActivity.ActivityType.assignToContact,
                    UIActivity.ActivityType.saveToCameraRoll,
                    UIActivity.ActivityType.postToFlickr,
                    UIActivity.ActivityType.postToVimeo,
                    UIActivity.ActivityType.postToTencentWeibo,
                    UIActivity.ActivityType.postToTwitter,
                    UIActivity.ActivityType.postToFacebook,
                    UIActivity.ActivityType.openInIBooks
                ]
                present(vcExportCSV, animated: true, completion: nil)
                
            }catch {
                print("Failed to create file")
                showFailedActionAlert(message: "Failed to Create CSV File")
            }
            
        } else {
            print("no loaded imu data")
            showFailedActionAlert(message: "No Loaded IMU Data")
        }
        
    }
    
    @IBAction func emailReport(_ sender: Any) {
        self.sendEmailAlert()
        
        print("email alert")
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Device Management
extension ViewController {

    @IBAction func actionPairDevice() {
        self.showStatusLabel()
        
        self.currentCancellable = AppDelegate.service.pair(
            success: { _ in
                //self.showToast()
                self.actionShutdown()
                self.hideStatusLabel()
        }, failure: defaultFailureCallback,
           progress: { _ in },
           cancelled: { })
        
    }
    
    @IBAction func actionSyncPairing() {
        self.showStatusLabel()
        
        _ = AppDelegate.service.syncPairedDevices(
            success: {
                self.showToast()
                self.reloadNotchList()
                self.hideStatusLabel()
        }, failure: defaultFailureCallback,
           progress: { _ in },
           cancelled: { })
    }
    
    @IBAction func actionRemoveAllDevices() {
        self.showStatusLabel()
        _ = AppDelegate.service.deletePairedDevices(
            success: {
                self.reloadNotchList()
                self.hideStatusLabel()
        }, failure: defaultFailureCallback,
           progress: { _ in },
           cancelled: {})
    }
    
    @IBAction func actionShutdown() {
        self.showStatusLabel()
        
        if AppDelegate.service.connected {
            self.showStatusLabel()
            
            _ = AppDelegate.service.shutDown(
                success: {
                    self.showToast()
                    self.updateNetwork()
                    self.reloadNotchList()
                    self.hideStatusLabel()
            }, failure: defaultFailureCallback,
               progress: { _ in },
               cancelled: {})
        } else {
            self.showFailedActionAlert(message: "First connect to a network")
        }
    }
    
    @IBAction func actionEraseDevices() {
        self.showStatusLabel()
        _ = AppDelegate.service.erase(
            success: defaultSuccessCallback,
            failure: defaultFailureCallback,
            progress: { _ in },
            cancelled: {})
    }
}

//MARK: - EMG Device Management
extension ViewController {
    /// Setup selected Peripherals
       fileprivate func setupPeripherals() {
         sessionDataValues.removeAll()
         btReceiverHolderTypesArray.removeAll()
           BluetoothPreferences.peripherals?.forEach { peripheral in
               //print("we have peripherals")
               //peripheral.peripheral.delegate = self
//               peripheral.peripheral.discoverServices([BluetoothPreferences.serviceUUID])
//               self.sessionDataValues.append([Double]())
//               self.btReceiverHolderTypesArray.append(-1)
           }
       }
    
    @IBAction func disconnectEMG() {
        //stop collection of emg data
        BluetoothPreferences.peripherals?.forEach {
            peripheral in
            BluetoothPreferences.btManager?.cancelPeripheralConnection( peripheral.peripheral)
        }
    }
    func disconnectAllEMG() {
        // while (start time counter != 0)
        //     start collection
        
        //stop collection of emg data
        BluetoothPreferences.peripherals?.forEach {
            peripheral in
            BluetoothPreferences.btManager?.cancelPeripheralConnection( peripheral.peripheral)
        }
    
    }
    
}

//MARK: EMG PeripheralsViewController Delegate
extension ViewController: PeripheralsViewControllerDelegate {
   
    func didAddPeripherals(array: [Peripheral]?, btmanager: CBCentralManager?) {
        print("we have ran the peripheral view delegate")
        BluetoothPreferences.btManager = btmanager
        BluetoothPreferences.peripherals = array
    }
    
}

extension ViewController: CBPeripheralDelegate {

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
            print(emgDataList, "main view controller")
            if isStartClicked {
                for sessionDataValue in emgDataList {
                    if let preferencePeripherals = BluetoothPreferences.peripherals {
                        for i in 0..<preferencePeripherals.count {

                            if peripheral == preferencePeripherals[i].peripheral {
                                 self.sessionDataValues[i].append(sessionDataValue)
                                self.btReceiverHolderTypesArray[i] = preferencePeripherals[i].type!
                                switch preferencePeripherals[i].type!{
                                /// append storage array for sensors involved 0 - Medial Gastroc 1 - Posterial Mediall, 2 - Tibilar Anterior  3- Peroneals
                                case 1:
                                    self.emgData.peroneals.append(sessionDataValue)
                                    break
                                case 2:

                                    self.emgData.tibAnterior.append(sessionDataValue)
                                    break
                                case 3:
                                    self.emgData.latGastroc.append(sessionDataValue)
                                    break
                                case 4:
                                    self.emgData.medGastroc.append(sessionDataValue)
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

// MARK: - Firmware
extension ViewController {
    @IBAction func pairEmgTest(_ sender: Any) {
        print("EmgDevice clicked.")
        performSegue(withIdentifier: "sensor", sender: self)
    }
    
    @IBAction func actionDiagnosticInit() {
        self.showStatusLabel()
        
        _ = AppDelegate.service.diagnosticInit(
            firmwareCheck: false,
            success: { result in
                self.showToast()
                self.hideStatusLabel()
        }, failure: defaultFailureCallback,
           progress: { _ in },
           cancelled: {})
    }
    
    @IBAction func actionFirmwareUpdate() {
        self.showStatusLabel()
        
        _ = AppDelegate.service.scan(
            success: { result in
                var filtered = [NotchBluetoothDevice]()
                for device in result {
                    if (device.name.contains("NOTCHR") || device.name.contains("NOTCH2R")) {
                        filtered.append(device)
                    }
                }
                self.updateDevices(currentItem: 0, devices: filtered)
        }, failure: defaultFailureCallback,
           progress: { _ in },
           cancelled: {})
    }
    
    func updateDevices(currentItem: Int, devices: [NotchBluetoothDevice]) {
        if currentItem >= devices.count {
            return
        }
        var p = 0
        _ = AppDelegate.service.firmwareUpdate(
            device: devices[currentItem],
            success: {
                self.hideStatusLabel()
                self.showToast()
        }, failure: defaultFailureCallback,
           progress: { progress in
            if (progress.progress != nil) {
                p = (Int)(progress.progress! * 100)
            }
            self.showStatusLabel(message: "Progess: \(p)%")
            
            if (progress.status?.contains("PAUSED"))! {
                self.showStatusLabel(message: "FW update paused")
            }
        }, cancelled: {})
    }
    
    @IBAction func resumeFirmwareUpdate() {
        _ = AppDelegate.service.resumeFirmwareUpdate()
    }
}

// MARK: - Workout selection
extension ViewController {
    @IBAction func actionShowWorkouts() {
        let selectionController = UIAlertController(title: "Choose workout", message: nil, preferredStyle: .actionSheet)
        
        ConfigurationType.allItems.forEach { (type) in
            selectionController.addAction(
                UIAlertAction(
                    title: type.name,
                    style: .default,
                    handler: { (_) in
                        self.selectedConfiguration = type
                }))
        }
        
        selectionController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(selectionController, animated: true, completion: nil)
    }
    
}

// MARK: - Calibration
extension ViewController {
    @IBAction func actionUncheckedInit() {
        self.showStatusLabel(message: "Connecting...")
        
        _ = AppDelegate.service.uncheckedInit(
            success: { _ in
                self.hideStatusLabel()
                self.updateNetwork()
        }, failure: defaultFailureCallback,
           progress: { _ in  },
           cancelled: { })
    }
    
    @IBAction func actionConfigureCalibration() {
        self.showStatusLabel()
        
        _ = AppDelegate.service.configureCalibration(
            isShowingColors: false,
            success: defaultSuccessCallback,
            failure: defaultFailureCallback,
            progress: {_ in },
            cancelled: {})
    }
    
    @IBAction func actionStartCalibration() {
        DispatchQueue.main.async {
            self.dockAnimationImageView.isHidden = false
            self.dockAnimationImageView.startAnimating()
        }
        
        currentCancellable = AppDelegate.service.calibration(
            success: { result in
                DispatchQueue.main.async {
                    self.dockAnimationImageView.isHidden = true
                    self.dockAnimationImageView.stopAnimating()
                }
        }, failure: { result in
            DispatchQueue.main.async {
                self.dockAnimationImageView.isHidden = true
                self.dockAnimationImageView.stopAnimating()
            }
            self.showFailure(notchError: result)
        }, progress: { _ in },
           cancelled: {})
    }
    
    @IBAction func actionGetCalibrationData() {
        self.showStatusLabel(message: "Connecting...")
        
        self.currentCancellable = AppDelegate.service.getCalibrationData(
            success: { result in
                if result == false {
                    print("WARNING: Calibration may be wrong. Its advised to try again.")
                }
                self.hideStatusLabel()
        }, failure: defaultFailureCallback,
           progress: { _ in },
           cancelled: {})
    }
    
    private func lastCalibrationTime() -> Int64 {
        var lastTime = Int64(Date().timeIntervalSince1970 * 1000)
        let actionDeviceSet = AppDelegate.service.getNetwork()?.deviceSet
        let notchDevices: [ NotchDevice ]? = AppDelegate.service.findAllDevices()
        for actionDevice in actionDeviceSet! {
            let networkId = actionDevice.networkIdNum
            for device in notchDevices! {
                if device.notchActionDevice.networkIdNum == networkId {
                    if device.lastCalibration <= lastTime {
                        lastTime = device.lastCalibration
                    }
                }
            }
        }
        
        return lastTime
    }
}

// MARK: - Steady
extension ViewController {
    @IBAction func actionConfigureSteady() {
        self.showStatusLabel()
        
        _ = AppDelegate.service.configureSteady(
            measurementType: NotchMeasurementType.steadySimple, isShowingColors: true,
            success: defaultSuccessCallback,
            failure:  defaultFailureCallback,
            progress: { _ in
                // present second view controller on screen
                // use base picture initially then add logic for dynamic view
                // 
            },
            cancelled: { })
    }
    
    @IBAction func actionStartSteady() {
        self.showStatusLabel()
        
        _ = AppDelegate.service.steady(
            success: { _ in
                self.hideStatusLabel()
        }, failure: defaultFailureCallback,
           progress: { progress in
            self.showStatusLabel(message: "Steady progress: \(String(describing: progress.progress))")
        }, cancelled: {})
        
    }
    
    @IBAction func actionGetSteadyData() {
        self.showStatusLabel()
        
        _ = AppDelegate.service.getSteadyData(
            success: defaultSuccessCallback,
            failure: defaultFailureCallback,
            progress: { _ in },
            cancelled: {})
    }
}

// MARK: - Capture
extension ViewController {
    
    
    @IBAction func actionWorkoutInit() {
        self.showStatusLabel()
        
        guard let workoutUrl = selectedConfiguration.configurationFile else {
            assertionFailure("Configuration file not found")
            return
        }
        
        do {
            let skeleton = try loadSkeleton()
            var workout = try NotchWorkout.from(
                name: selectedConfiguration.name,
                skeleton: skeleton,
                configFilePath: workoutUrl.path)
            
            if realtimeSwitch.isOn {
                workout = workout.withRealTime(realtime: true)
            }
            
            _ = AppDelegate.service.initWithWorkout(
                workout: workout,
                success: { result in
                    let lastCalibration = self.lastCalibrationTime()
                    
                    if (lastCalibration <= 0) {
                        print("Never calibrated. This will raise an error at capture")
                    } else if (Int64(Date().timeIntervalSince1970 * 1000) - lastCalibration > 8 * 3600 * 1000) {
                        print("Calibration was more than 8 hours ago. This can lead to inaccurate measurements")
                    }
                    
                    self.showToast()
                    self.hideStatusLabel()
                    self.updateNetwork()
            }, failure: defaultFailureCallback,
               progress: { _ in },
               cancelled: {})
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    @objc func realtimeSwitchChanged(_ rtSwitch: UISwitch) {
        if rtSwitch.isOn {
            self.configureCaptureButton.setTitle("Configure real time capture", for: .normal)
            self.downloadButton.setTitle("Stop real time", for: .normal)
            self.captureButton.setTitle("Real time capture", for: .normal)
        } else {
            self.configureCaptureButton.setTitle("Configure \(self.captureTimeConfiguration) sec capture", for: .normal)
            self.downloadButton.setTitle("Download", for: .normal)
            self.captureButton.setTitle("Capture \(self.captureTimeConfiguration) sec", for: .normal)
        }
    }
    
    @objc func remoteCaptureSwitchChanged(_ remoteSwitch: UISwitch) {
        if remoteSwitch.isOn {
            DispatchQueue.main.async {
                if self.realtimeSwitch.isOn {
                    self.realtimeSwitch.isOn = false
                }
                
                self.steadyInitButton.setTitle("init 3 notches", for: .normal)
                self.captureInitButton.setTitle("init 3 notches", for: .normal)
                self.configureCaptureButton.setTitle("Configure 3 sec capture", for: .normal)
                self.downloadButton.setTitle("Download", for: .normal)
                self.captureButton.setTitle("Capture 3 sec", for: .normal)
            }
        }
    }
    
    @IBAction func actionConfigureCapture() {
        self.showStatusLabel()
        
        if realtimeSwitch.isOn {
            _ = AppDelegate.service.configureCapture(
                isShowingColors: true,
                success: defaultSuccessCallback,
                failure: defaultFailureCallback,
                progress: { _ in },
                cancelled: { })
            
        } else {
            let configurationTime = Int64(self.captureTimeConfiguration * 1000)
            _ = AppDelegate.service.configureTimedCapture(
                timerMillis: configurationTime, isShowingColors: false,
                success: defaultSuccessCallback,
                failure: defaultFailureCallback,
                progress: { _ in },
                cancelled: { })
            
        }
    }
    
    @IBAction func actionCapture() {
        self.showStatusLabel()
        
        if realtimeSwitch.isOn {
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let viewController = storyboard.instantiateViewController(withIdentifier: "visualizerScreenId") as! VisualiserViewController
                viewController.visualizerDelegate = self
                self.navigationController?.pushViewController(viewController, animated: true)
                
            }
        } else {
            
            }
            _ = AppDelegate.service.timedCapture(
                success: { result in
                    self.currentMeasurement = result
                    self.hideStatusLabel()
                    self.showStatusLabel(message: "imu capture complete")
            }, failure: defaultFailureCallback,
               progress: { _ in },
               cancelled: { })
        if BluetoothPreferences.btManager != nil {
            blueToothPeripheralsDelegate?.didAddPeripherals(array: BluetoothPreferences.peripherals, btmanager: BluetoothPreferences.btManager) // == nil (let's see why??)
            EMGPeripheral.shared.startOrStopCollection(startClicked: true)
        }else {
            print("no bluetooth connection")
            showFailedBleConnection()
        }
        //start emg sensor capture
        var progressSeconds = 0.0
        let elapsedTime = captureTimeConfiguration
        self.isStartClicked = true
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (Timer) in
            progressSeconds += 1
            if Int(progressSeconds) >= elapsedTime {
                print("emg has started")
                self.isStartClicked = false
                Timer.invalidate()
                self.showStatusLabel(message: "Saved EMG, Click Download Button")
                EMGPeripheral.shared.startOrStopCollection(startClicked: false)
                self.emgData = EMGPeripheral.shared.getEmgData()
                
            }
            
            
        }
    }
    
    @IBAction func actionDownload() {
        self.showStatusLabel()
        
        if currentMeasurement == nil {
            self.showToast("No recorded measurement")
            return
        }
        
        if realtimeSwitch.isOn {
            if currentCancellable != nil {
                currentCancellable?.cancel()
            }
            self.hideStatusLabel()
        } else {
            _ = AppDelegate.service.download(
                outputFilePath: createFile(), measurement: currentMeasurement!,
                success: { result in
                 self.hideStatusLabel()
            }, failure: { result in
                self.showFailure(notchError: result)
            }, progress: { progress in
                self.showStatusLabel(message: "Download progress: \(String(describing: progress.progress))")
            }, cancelled: { })
            
            
        }
    }
    
    @IBAction func actionVisualize() {
        if measurementURL == nil {
            self.showToast("No downloaded measurement")
        } else {
            openMeasurement()
        }
    }
    
    
}

// MARK: - Example
extension ViewController {
    @IBAction func actionShowExample() {
        openMeasurement(isShowingExample: true)
    }
}

// MARK: - Notch helpers
extension ViewController {
    func loadSkeleton() throws -> NotchSkeleton {
        let skeletonJson = NSDataAsset(name: "skeleton")
        return try NotchSkeleton.from(configJsonString: String(data: (skeletonJson?.data)!, encoding: String.Encoding.utf8)!)
        
    }
    
    private func openMeasurement(isShowingExample: Bool = false) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "visualizerScreenId") as! VisualiserViewController
        
        if isShowingExample {
            viewController.isExampleMeasurement = true
            viewController.visualizerDelegate = self
            viewController.sensorConfiguration = selectedConfiguration

        } else {
            viewController.measurementURL = measurementURL
            viewController.visualizerDelegate = self
            viewController.sensorConfiguration = selectedConfiguration
        }
        DispatchQueue.main.async(){
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func updateNetwork() {
        var networkString = ""
        if let network = AppDelegate.service.getNetwork()  {
            for device in network.deviceSet {
                networkString.append("\(device.networkId)\n")
            }
        }
        DispatchQueue.main.async {
            self.networkLabel.text = networkString
        }
    }
    
    private func reloadNotchList() {
        var notchDevices = AppDelegate.service.findAllDevices()
        notchDevices.sort() { $0.notchActionDevice.networkIdNum < $1.notchActionDevice.networkIdNum }
        var deviceListText = ""
        for device in notchDevices {
            deviceListText.append("Notch \(device.notchActionDevice.networkIdNum) CH:\(device.channel) \(device.notchActionDevice.deviceMac ?? "")\n")
        }
        
        DispatchQueue.main.async {
            self.deviceListLabel.text = deviceListText
        }
    }
}

// MARK: - App Utils
extension ViewController {
    func defaultSuccessCallback() {
        self.showToast()
        self.hideStatusLabel()
    }
    
    func defaultFailureCallback(_ notchError: NotchError) {
        self.showFailure(notchError: notchError)
        self.hideStatusLabel()
    }
    
    private func hideStatusLabel() {
        DispatchQueue.main.async {
            self.statusLabel.isHidden = true
        }
    }
    
    private func showStatusLabel(message: String = "Progress...") {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            self.statusLabel.isHidden = false
        }
    }
    
    private func createFile() -> String {
        let dateString = createCurrentDateString()
        let fileName = "\(dateString).zip"
        
        let captureDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        measurementURL = URL(fileURLWithPath: "\(captureDirectory)/\(fileName)")
        
        return measurementURL!.path
    }
    
    private func createCurrentDateString() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        dateFormatter.locale = Locale.init(identifier: "en_US")
        return dateFormatter.string(from: Date())
    }
    
    private func initDockAnimation() {
        var imgListArray = [UIImage]()
        
        for countValue in 0...132 {
            let strImageName : String = "c\(String(format: "%04d", countValue)).png"
            let image  = UIImage(named:strImageName)
            imgListArray.append(image!)
        }
        dockAnimationImageView.animationImages = imgListArray;
        dockAnimationImageView.animationRepeatCount = 1
        dockAnimationImageView.animationDuration = 7.0
        
        dockAnimationImageView.isHidden = true
        dockAnimationImageView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
    }
}

// MARK: Download Delegate from 3D Rendering
extension ViewController: VisualizerDownloadDelegate {
    
    func getImuData(data: [[String : Float]]) {
        imuDictionary?.append(contentsOf: data)
    }
}

extension ViewController: MVCDelegate, PosteriorMVCDelegate {
    func addMVC(MVC: (String, Double)) {
        print("We are in the MVC view controller")
        self.MVCDict[MVC.0] = MVC.1
        
        self.showToast("\(MVC.0) MVC: \(MVC.1)")
    }
    
    func addPostMVC(MVC: (String, Double, String, Double)) {
        self.MVCDict[MVC.0] = MVC.1
        self.MVCDict[MVC.2] = MVC.3
        if MVC.3 != 0.0 {
            self.showToast("\(MVC.0) MVC: \(MVC.1) & \(MVC.2) MVC: \(MVC.3) ")
        }else {
            self.showToast("\(MVC.0) MVC: \(MVC.1)")
        }
        
    }
    
}


// MARK: Email Report
extension ViewController {
    func sendEmailAlert() {
        let sendEmail = UIAlertController(title: "Email address", message: "Please enter your email address.", preferredStyle: .alert)
        
        sendEmail.addTextField { (text) in
            text.placeholder = "Enter Your Email"
        }
        
        sendEmail.textFields?[0].keyboardType = .emailAddress
        sendEmail.addAction(UIAlertAction(title: "Send", style: .default, handler:  {(action) in
            if let email = sendEmail.textFields?.first?.text {
                //  self.yBalScore = Int(name)!
                self.sendMail(email)
                //self.postDataYBal()
            }
            else {
                print("no email saved")
            }
            
            })
        )
        
        sendEmail.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(sendEmail, animated: true)
    }
    
    func sendMail(_ email: String) {
        let mailComposeViewController = configureMailComposer(email)
        if MFMailComposeViewController.canSendMail(){
            self.present(mailComposeViewController, animated: true, completion: nil)
        }else{
            print("Can't send email")
        }
    }
    
    func configureMailComposer(_ email: String) -> MFMailComposeViewController{
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self
        mailComposeVC.setToRecipients([email])
        mailComposeVC.setSubject("Torque Demo")
        self.prepareHTMLFromPlayerData()
        mailComposeVC.setMessageBody(self.htmlString, isHTML: true)
        return mailComposeVC
    }
    
    func prepareHTMLFromPlayerData(){
        var externalTorqueSum:Float = 0.00
        var angularVelocitySum:Float = 0.00
        var effeciencyScoreAverage:[String:Float] = [:]
        var externalTorquelAvg: Float = 0.00
        var angularVeloAverage:Float = 0.00
        
        // save medial gastro information
        //Save emg Data to IMUDictionary
        if imuDictionary != nil {
            let imulength = imuDictionary!.count
            for i in 0..<imulength {
                if emgData.medGastroc.count != 0{
                    
                    if let MedGastroc = self.MVCDict["medialGastroc"] {
                        var normalize = self.emgData.medGastroc[i]/MedGastroc
                        normalize *= 100
                        imuDictionary![i]["medGastro"] = Float(normalize)
                    }
                    else {
                        imuDictionary![i]["medGastroc"] = Float(emgData.medGastroc[i])
                    }
                }
                
                if emgData.latGastroc.count != 0{
                    // check for MVC value storage
                    if let LatGastroc = self.MVCDict["lateralGastroc"]{
                        var normalize = self.emgData.latGastroc[i]/LatGastroc
                        normalize *= 100
                        imuDictionary![i]["latGastro"] = Float(normalize)
                    }else {
                        imuDictionary![i]["latGastroc"] = Float(emgData.latGastroc[i])
                    }
                }
                
                if emgData.tibAnterior.count != 0{
                    //check for MVC value storage
                    if let TibAnterior = self.MVCDict["Anterior"]{
                        var normalize = self.emgData.tibAnterior[i]/TibAnterior
                        normalize *= 100
                        imuDictionary![i]["tibAnt"] = Float(normalize)
                    }else{
                        imuDictionary![i]["tibAnt"] = Float(emgData.tibAnterior[i])
                    }
                    
                }
                
                if emgData.peroneals.count != 0{
                    //check for MVC value storage
                    if let Peroneals = self.MVCDict["Peroneals"]{
                        var normalize = self.emgData.peroneals[i]/Peroneals
                        normalize *= 100
                        imuDictionary![i]["peroneals"] = Float(normalize)
                    }
                    imuDictionary![i]["peroneals"] = Float(emgData.peroneals[i])
                }
            }
            
        }
        
        if imuDictionary != nil {
            for item in self.imuDictionary!{
                var angleVeloMag: Float = 0.00
                externalTorqueSum += item["torqueMag"]!
                
                //calculate the angleVelocity Magnitude
                angleVeloMag = externalWorkMagnitude(x: item["angleVeloX"]!, y: item["angleVeloY"]!, z: item["angleVeloZ"]!)
                angularVelocitySum += angleVeloMag
                
                //calculate the sum effeciency scores
                if let tibilarAnterior = item["tibAnt"]{
                    if effeciencyScoreAverage["tibAnt"] == nil {
                        effeciencyScoreAverage["tibAnt"] = tibilarAnterior
                    }else {
                        effeciencyScoreAverage["tibAnt"]! += tibilarAnterior
                    }
                    
                }
                
                if let medialGastroc = item["medGastro"]{
                    if effeciencyScoreAverage["medGastroc"] == nil {
                        effeciencyScoreAverage["medGastroc"] = medialGastroc
                    }else {
                        effeciencyScoreAverage["medGastroc"]! += medialGastroc
                    }
                }
                
            }
            
            externalTorquelAvg = externalTorqueSum/Float(imuDictionary!.count)
            angularVeloAverage = angularVelocitySum/Float(imuDictionary!.count)
            if let tibAnterior = effeciencyScoreAverage["tibAnt"] {
                effeciencyScoreAverage["tibAnt"] = tibAnterior/Float(imuDictionary!.count)
                
            }
            
            if let medGastro = effeciencyScoreAverage["medGastroc"] {
                effeciencyScoreAverage["medGastroc"] = medGastro/Float(imuDictionary!.count)
                
            }
            
        }
        
        //clear emg data
        emgData.medGastroc = []
        emgData.latGastroc = []
        emgData.tibAnterior = []
        emgData.peroneals = []
        // clear IMU data
        imuDictionary = [[String:Float]]()
        
        
        self.htmlString = String(format: """
             <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
             <html>
                <h1> Torque Snap Shot </h1>
                <h4> External Torque Average</h4>
                <b>%2.2f</b>
                <h4> Average Angular Velocity </h4>
                <b>%2.3f</b>
                <h4> Average Tibilar Anterior Effeciency Score <h4>
                <b>%2.2f</b>
                <h4> Average MedGastro Anterior Effeciency Score <h4>
                <b>%2.2f</b>
             </html>
            """, externalTorquelAvg, angularVeloAverage, effeciencyScoreAverage["tibAnt"] ?? 0.0, effeciencyScoreAverage["medGastroc"] ?? 0.0)
    }
    
}


