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



//Mark: lifeCycle
class ViewController: UIViewController {
    
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
    /// Line Chart Data
    var btReceiverHolderTypesArray = [Int]()
    var sessionDataValues = [[Double]]()
    var isStartClicked = false
    var sessionDictionary = [String:[Double]]()
    var customArray = [Double]()
    var customArray1 = [Double]()
    var customArray2 = [Double]()
    var customArray3 = [Double]()
    var emgDataArray = [0.0,0.0,0.0,0.0]
    var imuDictionary: [[String : Float]]? = []

    
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
        let nav = segue.destination as? PeripheralsViewController
       // let vc = nav?.topViewController as? PeripheralsViewController
        nav?.delegateForPeripheralView = self
    }
    @IBAction func startEmg(_ sender: Any) {
        isStartClicked = true
    }
    
    
    @IBAction func stopEMG(_ sender: Any) {
        isStartClicked = false
    }
    
    @IBAction func downloadCSV(_ sender: Any) {
        let fileName = "emgDownload.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Medial Gastroc, Posteriolateral Gastroc, Tibilar Anterior,Peroneals\n"
        let count = self.customArray.count
        
        if count > 0 {
            for emgArray in customArray {
                let newline = "\(customArray[0]),\(customArray[1]),\(customArray[2]),\(customArray[3])\n"
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
        var csvText = "angleX, angleY, angleZ, externalWorkX, externalWorkY, externalWorkZ\n"
        let count = self.imuDictionary?.count
        var angleX, angleY, angleZ: Float
        var i = 0
        
        if imuDictionary != nil{
            var imuMotionList = "\(i),"
            for item in imuDictionary!{
                if (item["angleX"] != nil){
                angleX = item["angleX"] ?? 0.00
                angleY = item["angleY"] ?? 0.00
                angleZ = item["angleZ"] ?? 0.00
                    csvText.append(contentsOf: "\(angleX), \(angleY), \(angleZ)")
                    
                }else {
                    csvText.append(contentsOf: ",,,")
                }
                
                if (item["torqueX"] != nil){
                    let externalWorkX = item["torqueX"]!
                    let externalWorkY = item["torqueY"]!
                    let externalWorkZ = item["torqueZ"]!
                    csvText.append(contentsOf: "\(externalWorkX), \(externalWorkY), \(externalWorkZ)")
                }else {
                    csvText.append(contentsOf: ",,,")
                }
                
                if (item["posX"] != nil){
                    let posX = item["posX"]!
                    let posY = item["posY"]!
                    let posZ = item["posZ"]!
                    csvText.append(contentsOf: "\(posX), \(posY), \(posZ)")
                }else {
                    csvText.append(contentsOf: ",,,\n")
                }
            }
            
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
    
    func timePeripheals(time: NSNumber) {
        // while (start time counter != 0)
        //     start collection
        
        //stop collection of emg data
        BluetoothPreferences.peripherals?.forEach {
            peripheral in
            
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
                                switch i{
                                /// append storage array for sensors involved 0 - Medial Gastroc 1 - Posterial Mediall, 2 - Tibilar Anterior  3- Peroneals
                                case 0:
                                    self.customArray.append(sessionDataValue)
                                    break
                                case 1:
                                    self.customArray1.append(sessionDataValue)
                                    break
                                case 2:
                                    self.customArray2.append(sessionDataValue)
                                    break
                                case 3:
                                    self.customArray3.append(sessionDataValue)
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
            progress: { _ in },
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
            _ = AppDelegate.service.timedCapture(
                success: { result in
                    self.currentMeasurement = result
                    self.hideStatusLabel()
            }, failure: defaultFailureCallback,
               progress: { _ in },
               cancelled: { })
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
        var i = 1
        for item in data {
            
            print("potential data value for angle X", data[i]["angleX"])
            
            if (item["angleX"]  != nil) {
            print("Item angleX... ", item["angleX"])
            print("Item angleY... ", item["angleY"])
            print("Item workx...", item["torqueX"])
            print("item worky...", item["torqueY"])
            }
        }
    }
}

