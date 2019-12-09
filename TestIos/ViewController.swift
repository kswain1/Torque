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
    var medGastroc = [Double]()  //Medial Gastro
    var latGastroc = [Double]()  // 1 - Posterial Medial
    var tibAnterior = [Double]()  // 2 - Tibilar Anterior
    var peroneals = [Double]()  // 3- Peroneals
    var emgDataArray = [0.0,0.0,0.0,0.0]
    var imuDictionary: [[String : Float]]? = []
    var blueToothPeripheralsDelegate: BluetoothControllerDelegate?
    var MVCDict: [String:Double] = [:]
    
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
            
        }
        let nav = segue.destination as? PeripheralsViewController
       // let vc = nav?.topViewController as? PeripheralsViewController
        nav?.delegateForPeripheralView = self
    }
    @IBAction func startEmg(_ sender: Any) {
        isStartClicked = true
        var progressSeconds = 0.0
        var maxTimeElapse = 3.0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (Timer) in
            progressSeconds += 1.0
            if progressSeconds >= maxTimeElapse {
                self.isStartClicked = false
                print("It has been 3 seconds")
                Timer.invalidate()
            }
            
        }
    }
    
    
    @IBAction func stopEMG(_ sender: Any) {
        isStartClicked = false
    }
    
    @IBAction func downloadCSV(_ sender: Any) {
        let fileName = "emgDownload.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Medial Gastroc, Posteriolateral Gastroc, Tibilar Anterior,Peroneals\n"
        let count = self.medGastroc.count
        
        if count > 0 {
            for emgArray in medGastroc {
                let newline = "\(medGastroc[0]),\(medGastroc[1]),\(medGastroc[2]),\(medGastroc[3])\n"
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
        var csvText = "angleX, angleY, angleZ,torqueMag, torqueX, torqueY, torqueZ, posMag, posX, posY, posZ, medGastro, tibAnterior, latGastro, Peroneals\n"
        let count = self.imuDictionary?.count
        var angleX, angleY, angleZ: Float
        var i = 0
        
        
        ///Save emg Data to IMUDictionary
        if imuDictionary != nil {
            let imulength = imuDictionary!.count
            for i in 0..<imulength {
                if medGastroc.count != 0{
                    
                    if let MedGastroc = self.MVCDict["medialGastroc"] {
                        var normalize = self.medGastroc[i]/MedGastroc
                        normalize *= 100
                        imuDictionary![i]["medGastro"] = Float(normalize)
                    }
                    else {
                        imuDictionary![i]["medGastroc"] = Float(medGastroc[i])
                    }
                }
                
                if latGastroc.count != 0{
                    // check for MVC value storage
                    if let LatGastroc = self.MVCDict["lateralGastroc"]{
                        var normalize = self.latGastroc[i]/LatGastroc
                        normalize *= 100
                        imuDictionary![i]["latGastro"] = Float(normalize)
                    }else {
                        imuDictionary![i]["latGastroc"] = Float(latGastroc[i])
                    }
                }
                
                if tibAnterior.count != 0{
                    //check for MVC value storage
                    if let TibAnterior = self.MVCDict["Anterior"]{
                        var normalize = self.tibAnterior[i]/TibAnterior
                        normalize *= 100
                        imuDictionary![i]["tibAnt"] = Float(normalize)
                    }else{
                        imuDictionary![i]["tibAnt"] = Float(tibAnterior[i])
                    }
                    
                }
                
                if peroneals.count != 0{
                    //check for MVC value storage
                    if let Peroneals = self.MVCDict["Peroneals"]{
                        var normalize = self.peroneals[i]/Peroneals
                        normalize *= 100
                        imuDictionary![i]["peroneals"] = Float(normalize)
                    }
                    imuDictionary![i]["peroneals"] = Float(peroneals[i])
                }
            }
            
            //clear emg data
            medGastroc = []
            latGastroc = []
            tibAnterior = []
            peroneals = []
            
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
                
                if (item["torqueX"] != nil){
                    let torqueX = item["torqueX"]!
                    let torqueY = item["torqueY"]!
                    let torqueZ = item["torqueZ"]!
                    let torqueMag = item["torqueMag"]!
                    csvText.append(contentsOf: "\(torqueMag),\(torqueX), \(torqueY), \(torqueZ),")
                }else {
                    csvText.append(contentsOf: ",,,")
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
                    csvText.append(contentsOf: ",")
                }
                
                if (item["latGastro"] != nil){
                    let tibAnterior = item["latGastro"]!
                    csvText.append(contentsOf: "\(tibAnterior)\n")
                }else {
                    csvText.append(contentsOf: ",")
                }
                if (item["peroneals"] != nil){
                    let tibAnterior = item["peroneals"]!
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
               print("we have peripherals")
               peripheral.peripheral.delegate = self
               peripheral.peripheral.discoverServices([BluetoothPreferences.serviceUUID])
               self.sessionDataValues.append([Double]())
               self.btReceiverHolderTypesArray.append(-1)
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
            print(emgDataList)
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
                                    self.peroneals.append(sessionDataValue)
                                    break
                                case 2:
                                    
                                    self.tibAnterior.append(sessionDataValue)
                                    break
                                case 3:
                                    self.latGastroc.append(sessionDataValue)
                                    break
                                case 4:                                    self.medGastroc.append(sessionDataValue)
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
            self.configureCaptureButton.setTitle("Configure 30 sec capture", for: .normal)
            self.downloadButton.setTitle("Download", for: .normal)
            self.captureButton.setTitle("Capture 30 sec", for: .normal)
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
                self.configureCaptureButton.setTitle("Configure 30 sec capture", for: .normal)
                self.downloadButton.setTitle("Download", for: .normal)
                self.captureButton.setTitle("Capture 30 sec", for: .normal)
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
        
            _ = AppDelegate.service.configureTimedCapture(
                timerMillis: 30000, isShowingColors: false,
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
                    self.showStatusLabel(message: "succesfully saved imu")
            }, failure: defaultFailureCallback,
               progress: { _ in },
               cancelled: { })
            
        //start emg sensor capture
        var progressSeconds = 1.0
        let elapsedTime = 30.0
        self.isStartClicked = true
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (Timer) in
            progressSeconds += 1
            if progressSeconds >= elapsedTime {
                self.isStartClicked = false
                Timer.invalidate()
                self.showStatusLabel(message: "Saved EMG, Click Download Button")
                
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

        } else {
            viewController.measurementURL = measurementURL
            viewController.visualizerDelegate = self
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
                if medGastroc.count != 0{
                    
                    if let MedGastroc = self.MVCDict["medialGastroc"] {
                        var normalize = self.medGastroc[i]/MedGastroc
                        normalize *= 100
                        imuDictionary![i]["medGastro"] = Float(normalize)
                    }
                    else {
                        imuDictionary![i]["medGastroc"] = Float(medGastroc[i])
                    }
                }
                
                if latGastroc.count != 0{
                    // check for MVC value storage
                    if let LatGastroc = self.MVCDict["lateralGastroc"]{
                        var normalize = self.latGastroc[i]/LatGastroc
                        normalize *= 100
                        imuDictionary![i]["latGastro"] = Float(normalize)
                    }else {
                        imuDictionary![i]["latGastroc"] = Float(latGastroc[i])
                    }
                }
                
                if tibAnterior.count != 0{
                    //check for MVC value storage
                    if let TibAnterior = self.MVCDict["Anterior"]{
                        var normalize = self.tibAnterior[i]/TibAnterior
                        normalize *= 100
                        imuDictionary![i]["tibAnt"] = Float(normalize)
                    }else{
                        imuDictionary![i]["tibAnt"] = Float(tibAnterior[i])
                    }
                    
                }
                
                if peroneals.count != 0{
                    //check for MVC value storage
                    if let Peroneals = self.MVCDict["Peroneals"]{
                        var normalize = self.peroneals[i]/Peroneals
                        normalize *= 100
                        imuDictionary![i]["peroneals"] = Float(normalize)
                    }
                    imuDictionary![i]["peroneals"] = Float(peroneals[i])
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
        medGastroc = []
        latGastroc = []
        tibAnterior = []
        peroneals = []
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


