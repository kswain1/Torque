
import UIKit
import QuartzCore
import SceneKit
import SpriteKit
import WearnotchSDK

protocol ControlsOverlayDelegate: class {
    func goBack(data: [[String: Float]])
}

protocol VisualizerDownloadDelegate: class {
    func getImuData(data: [[String:Float]])
}

class VisualiserViewController: WorkoutAnimationViewController, AnimationProgressDelegate {
    

    var measurementURL: URL?
    var isExampleMeasurement: Bool = false
    var currentCancellable: NotchCancellable? = nil
    
    var sceneProvider: NotchSceneProvider!
    
    var visualiserData: NotchVisualiserData!
    var droidAvatarSource: AvatarVisualizationSource!
    var avatarAnimation: AvatarAnimation!
    var notchAnimation: NotchAnimation!
    
    var sceneOverlay: AnimationControlsOverlay!
    
    var imuData = [0]
    
    var progress: Float = 0.0
    
    weak var visualizerDelegate: VisualizerDownloadDelegate?
    var sensorConfiguration: ConfigurationType?
    
    override func viewDidLoad() {
        // set up scene
        super.viewDidLoad()
        
        self.title = "HX Visualizer"
        
        // add static elements to scene:
        addFloor()
        
        if let workout = AppDelegate.service.getNetwork()?.workout {
            self.sceneProvider = workout
            if workout.isRealTime {
                self.startRealTimeCapture()
            } else {
                configureReplayMeasurement()
            }
        } else if self.isExampleMeasurement {
            configureReplayMeasurement()
        }
        
        //add download observer
        self.addObserver(self.sceneOverlay, forKeyPath: "download", options: .new, context: nil)
    }
    
    private func createFile() -> String {
        let dateString = createCurrentDateString()
        let fileName = "\(dateString).zip"
        
        let captureDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        let measurementURL = URL(fileURLWithPath: "\(captureDirectory)/\(fileName)")
        
        return measurementURL.path
    }
    
    private func createCurrentDateString() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        dateFormatter.locale = Locale.init(identifier: "en_US")
        return dateFormatter.string(from: Date())
    }
    
    private func startRealTimeCapture() {
        self.currentCancellable = AppDelegate.service.capture(
            outputFilePath: createFile(),
            success: { },
            failure: { result in
                self.showFailure(notchError: result)
                self.currentCancellable = nil
        },
            progress: { progress in
                
                if self.notchAnimation == nil {
                    
                    self.notchAnimation = NotchAnimation()
                    self.notchAnimation!.delegate = NotchRealTimeAnimationDelegate()
                    self.notchAnimation!.offset  = GLKVector3Make(0.0, 0.9585, 0.0)  // app-dependant (where the floor is)
                    self.addAvatarAnimations()
                    
                    self.addWorkoutAnimation(self.notchAnimation!)
                    
                    (self.view as! SCNView).isPlaying = true
                }
                
                (self.notchAnimation!.delegate as! NotchRealTimeAnimationDelegate).visualiserData = progress.realtimeData
                
        },
            cancelled: { })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            print("we are touching in visualizer")
            let location = touch.location(in: self.sceneOverlay)
            let touchedNode = self.sceneOverlay.atPoint(location)
            if let nodeName = touchedNode.name {
                switch nodeName {
                 case "download":
                    print("touch began two")
                default:
                    print("nill")
                }
            }
        }
            
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentCancellable?.cancel()
    }
    
    private func configureReplayMeasurement() {
        
        var imuData: [[String: Float]] = []
        // imuData:[String:
        if (self.isExampleMeasurement) {
            do {
                let measurementAsset = NSDataAsset(name: "cartwheel_11notches", bundle: Bundle.main)
                self.visualiserData = try NotchVisualiserData.fromData(data: measurementAsset!.data)
                let skeleton = self.visualiserData.skeleton
                
                
                /// Downloading skeleton data example
                let rightLowerLeg = skeleton.bone("RightLowerLeg")
                let rightFoot = skeleton.bone("RightFootTop")
                let rightFootFront = skeleton.bone("RightFootFront")
                let bones = skeleton.boneOrder
                if (rightLowerLeg != nil ) && (rightFoot != nil) && (rightFootFront != nil){
                    var previousVeloX:Float = 0.00
                    var previousVeloY:Float = 0.00
                    var previousVeloZ:Float = 0.00
                    var torqueX: Float = 0.0
                    var torqueY: Float = 0.0
                    var torqueZ: Float = 0.0
                    var angleX:Float = 0.00
                    var angleY:Float = 0.00
                    var angleZ: Float = 0.00
                    
                    
                    //count through all of the samples
                    for i in 1..<self.visualiserData.frameCount {
                        
                        
                        if let vector = self.visualiserData.calculateAngularVelocity(bone: rightLowerLeg!, frameIndex: i) {
                            
                            print("angular Velocity: \(vector.x) \(vector.y) \(vector.z)")
                            if i > 1 {
                                let accelerationX = angularAcceleration(angleVelocityPrevious: Float(previousVeloX), angleVelocityCurrent: vector.x, samplesPerSecond: 40)
                                let accelerationY = angularAcceleration(angleVelocityPrevious: Float(previousVeloY), angleVelocityCurrent: vector.x, samplesPerSecond: 40)
                                let accelerationZ = angularAcceleration(angleVelocityPrevious: Float(previousVeloZ), angleVelocityCurrent: vector.x, samplesPerSecond: 40)

                                // Calculating Torque
                                // Step 1 collect angles
                                if let angles = self.visualiserData.calculateRelativeAngleForReferenceBone(bone: rightLowerLeg!, referenceBone: rightFoot!, frameIndex: i){
                                    angleX = angles.x
                                    angleY = angles.y
                                    angleZ = angles.z
                                }
                                
                                torqueX = jointTorque(angularAcceleration: accelerationX, angle: angleX)
                                torqueY = jointTorque(angularAcceleration: accelerationY, angle: angleY)
                                torqueZ = jointTorque(angularAcceleration: accelerationZ, angle: angleZ)
                                let torqueMag = externalWorkMagnitude(x:torqueX,y:torqueY,z:torqueZ )
                                
                                let data: [String: Float] = ["angleX":angleX,"angleY":angleY,"angleZ":angleZ ,"angleVeloX":vector.x, "angleVeloY": vector.y, "angleVeloZ": vector.z, "angleAccelX": accelerationX, "angleAccelY": accelerationY, "angleAccelZ": accelerationZ, "torqueMag":torqueMag, "torqueX":torqueX, "torqueY":torqueY, "torqueZ":torqueZ]
                                imuData.append(data)
                                
                                // swap values acceleration calculation
                                previousVeloX = Float(vector.x)
                                previousVeloY = Float(vector.y)
                                previousVeloZ = Float(vector.z)
                            } else {
                                // for zero case
                                // Step 1 collect angles
                                if let angles = self.visualiserData.calculateRelativeAngleForReferenceBone(bone: rightLowerLeg!, referenceBone: rightFoot!, frameIndex: i){
                                    angleX = angles.x
                                    angleY = angles.y
                                    angleZ = angles.z
                                }
                                
                                let data: [String: Float] = ["angleX":angleX,"angleY":angleY, "angleZ":angleZ, "angleVeloX":vector.x, "angleVeloY": vector.y, "angleVeloZ": vector.z, "angleAccelX": 0.0, "angleAccelY": 0.0, "angleAccelZ": 0.0,"torqueMag":0.0 ,"torqueX":torqueX, "torqueY":torqueY, "torqueZ":torqueZ]
                               imuData.append(data)
                            }
                            
                        }
                        
                        if let vector = self.visualiserData.getPosition(bone: rightFoot!, frameIndex: i) {
                            let data: [String: Float] = ["posX":vector.x, "posY": vector.y, "posZ": vector.z]
                            imuData.append(data)
                        }
                        
                    }
                }
                
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } else {
            
            //file creation for saving file (potentially delete in the future)
            let fileName = "imuDownload.csv"
            let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            var posText = "posX, posY, posZ, posMag\n"
            var imuText = "sample, angleX, angleY, angleZ, angleVeloX, angleVeloY, angleVeloZ, posX, posY, posZ\n"
            do {
                self.visualiserData = try NotchVisualiserData.fromURL(url: (self.measurementURL)!)
                var s = VisualizerImuDictionary()
                
                
                let skeleton = self.visualiserData.skeleton
                
//                let rightFoot = skeleton.bone("RightFootTop")
//                let leftFoot = skeleton.bone("LeftFootTop")
//                let rightLowerLeg = skeleton.bone("RightLowerLeg")
//                let chest = skeleton.bone("Chest")
                
                let sensorConfigDic =  ["Left Ankle & Right Thigh (5)":"Left", "Right Ankle & Left Thigh (5)":"Right", "Chest (1)":"chest"]
                //check for right foot
                let selectLeg = sensorConfiguration?.name
                let leg = sensorConfigDic[selectLeg!]
                imuData = s.computeImuDict(leg: leg!, visualizerData: self.visualiserData, measurementUrl: self.measurementURL!)
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
            
            
        }
        
        self.sceneProvider = self.visualiserData.config
        self.notchAnimation = NotchAnimation(visualiserData)
        self.notchAnimation!.offset  = GLKVector3Make(0.0, 0.9585, 0.0)  // app-dependant (where the floor is)
        (self.notchAnimation!.delegate as! NotchWorkoutAnimationDelegate).progress.delegate = self
        
        addAvatarAnimations()
        
        // add overlay:
        sceneOverlay = AnimationControlsOverlay(size: self.view.bounds.size)
        sceneOverlay.controlDelegate = self
        sceneOverlay.topPadding = 64.0 / sceneOverlay.dpi // navigation bar + status bar
        sceneOverlay.cameraController = self
        sceneOverlay.animationController = self
        
        sceneOverlay.scnView = (self.view as! SCNView)
        (self.view as! SCNView).overlaySKScene = sceneOverlay
        
        sceneOverlay.resize(self.view.bounds.size)
        
        
        if notchAnimation.delegate is NotchWorkoutAnimationDelegate {
            sceneOverlay.animationProgress = (notchAnimation.delegate as! NotchWorkoutAnimationDelegate).progress
        }
        
        // add animation & start it
        addWorkoutAnimation(self.notchAnimation!)
        
        /// CONTROLLER DEMO - custom top view angle
        self.cameraTopYAngle = Float(Double.pi)
        
        (notchAnimation.delegate as! NotchWorkoutAnimationDelegate).progress.rewindAtEnd = true
        (notchAnimation.delegate as! NotchWorkoutAnimationDelegate).progress.isLooping = true
        
        (notchAnimation.delegate as! NotchWorkoutAnimationDelegate).progress.play()
        
        /// IMU data holder
        sceneOverlay.imuData?.append(contentsOf: imuData)
    }
    
    func addAvatarAnimations() {
        // add avatar visualization
        let avatarModelRoot = VisualizationSourceLoadDefaultDroidRoot(modelName: "notch_male")  // default model (as SCNNode)
        let avatarNodesPivoter = AvatarNodesPivoterCreateDefault(modelName: "notch_male")  // use built-in model's sizes
        let avatarBoneNodes = avatarNodesPivoter.getScaledBones(avatarModelRoot, sceneProvider: self.sceneProvider) // pivot & scale bones
        droidAvatarSource = AvatarVisualizationSource(targetScene: self.scene!, nodes: avatarBoneNodes)  // source
        
        self.avatarAnimation = AvatarAnimation(skeleton: sceneProvider.skeleton, source: droidAvatarSource)
        
        if visualiserData?.config.disabledBones != nil {
            for bone in visualiserData.config.disabledBones {
                self.avatarAnimation.disableBone(bone.boneName)
            }
        }
        
        self.notchAnimation!.addVisualisation(avatarAnimation)
    }
    
    func addSaveMotionButton() {
        let saveButton = SKSpriteNode(imageNamed: "download")
        saveButton.name = "saveButton"
        saveButton.position = CGPoint.zero
        
    }
    
    func addFloor() {
        // add floor color
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = UIColor(red: 140/255.0, green: 142/255.0, blue: 145/255.0, alpha: 1.0)
        let floor = SCNPlane(width: 37, height: 37)
        let floorNode = SCNNode()
        floorNode.geometry = floor
        floorNode.geometry?.materials = [floorMaterial]
        floorNode.transform = SCNMatrix4Mult(floorNode.transform, SCNMatrix4MakeRotation(Float(Double.pi / -2.0), 1, 0, 0))
        floorNode.position = SCNVector3Make(0.0, -0.02, 0.0)
        self.scene?.rootNode.addChildNode(floorNode)
    }
    
    func animationProgressDidUpdate(_ animationProgress: AnimationProgress) {
        let frameIndex = Int32(animationProgress.progress*Float(visualiserData.frameCount))
        let rootbone = (sceneProvider.skeleton.bone("Root"))
        var centerpos = GLKVector3.init(v: (0.0, 0.0, 0.0))
        if (rootbone != nil) {
            centerpos = visualiserData.getPosition(bone: rootbone!, frameIndex: frameIndex)!
        }
        self.cameraCenter = centerpos
    }
    
    
    func animationProgressDidStartPlaying(_ animationProgress: AnimationProgress) {
        (self.view as! SCNView).isPlaying = true
        sceneOverlay.animationPaused = false
    }
    
    func animationProgressDidPause(_ animationProgress: AnimationProgress) {
        (self.view as! SCNView).isPlaying = false
        sceneOverlay.animationPaused = true
        
    }
    
    func animationProgressDidStartSeeking(_ animationProgress: AnimationProgress) {
        (self.view as! SCNView).isPlaying = true
    }
    
    func animationProgressDidStopSeeking(_ animationProgress: AnimationProgress) {
    }
    
    func animationProgressDidStop(_ animationProgress: AnimationProgress) {
        (self.view as! SCNView).isPlaying = false
        sceneOverlay.animationPaused = true
    }
}

extension VisualiserViewController: ControlsOverlayDelegate {
    func goBack(data: [[String: Float]]) {
        //sends to main view controller
        visualizerDelegate?.getImuData(data: data)
        self.navigationController?.popViewController(animated: true)
    }
}
