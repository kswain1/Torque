
import UIKit
import QuartzCore
import SceneKit
import SpriteKit
import GLKit
import WearnotchSDK
//importt WearnotchSDK


open class WorkoutAnimationViewController: UIViewController, CameraController {
    let renderer: NotchRenderer = NotchRenderer()
    
    var innerScene: SCNScene?
    
    var panGestureRecognizer: UIPanGestureRecognizer?
    var pinchGestureRecognizer: UIPinchGestureRecognizer?
    var scnView: SCNView?
    
    open var cameraNode: SCNNode = SCNNode()
    open var cameraCenter: GLKVector3 = GLKVector3Make(0.0, 1.0, 0.0)
    open var cameraPanSpeed: Float = 64.0
    open var cameraMaxElevationAngle: Float = Float(Double.pi / 4)
    open var cameraMinElevationAngle: Float = Float(-Double.pi / 4)
    open var cameraTopYAngle: Float = 0.0
    
    open var defaultLighting: Bool = true
    
    open var scene: SCNScene? {
        get {
            return innerScene
        }
    }
    
    open func addWorkoutAnimation(_ animation: NotchAnimation) {
        renderer.addAnimation(animation)
    }
    
    open func removeWorkoutAnimation(_ animation: NotchAnimation) {
        renderer.removeAnimation(animation)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // 3D scene
        innerScene = SCNScene()
        let backgroundColor: UIColor = UIColor(red: 217/255.0, green: 217/255.0, blue: 217/255.0, alpha: 1.0)
        innerScene!.background.contents = UIImage.fromColor(color: backgroundColor)
        setupInitialCamera(innerScene!)
        if defaultLighting {
            setupLighting(innerScene!)
        }
        
        // retrieve the SCNView
        scnView = self.view as! SCNView?
        
        // set the scene to the view
        scnView?.scene = innerScene!
        
        // view properties
        scnView?.delegate = renderer
        if (defaultLighting) {
            scnView?.autoenablesDefaultLighting = true
        }
        moveCamera(GLKVector3Make(0.0, 1.0, 3.0))
        
        // add a gesture recogniser
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(WorkoutAnimationViewController.handlePanGesture(_:)))
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(WorkoutAnimationViewController.handlePinchGesture(_:)))
        
        isGestureRecogniserEnabled(true)
        
        //download Button
        
    }
    
    public func isGestureRecogniserEnabled(_ isEnabled: Bool) {
        if isEnabled {
            scnView?.addGestureRecognizer(panGestureRecognizer!)
            scnView?.addGestureRecognizer(pinchGestureRecognizer!)
        } else {
            scnView?.removeGestureRecognizer(panGestureRecognizer!)
            scnView?.removeGestureRecognizer(pinchGestureRecognizer!)
        }
    }
    
    
    open func moveCamera(_ position: GLKVector3) {
        // set/reset camera properties:
        cameraNode.orientation = SCNVector4Make(0.0, 0.0, 0.0, 1.0)
        cameraNode.position = SCNVector3FromGLKVector3(position)
        cameraNode.rotation = SCNVector4Make(0.0, 0.0, 0.0, 0.0)
        
        // calculate camera orientaion
        // vector from position to center:
        let centerToPosition = GLKVector3Subtract(cameraCenter, position)
        
        // angle around X axis:
        let distanceFromCenter = GLKVector3Length(centerToPosition)
        if distanceFromCenter <= 0.0001 {
            return  // makes no sense to turn the camera
        }
        let sinX = centerToPosition.y / distanceFromCenter
        cameraNode.eulerAngles.x = asin(sinX)
        
        // angle around Y axis:
        let distanceFromY = GLKVector2Length(GLKVector2Make(centerToPosition.z, centerToPosition.x))
        if distanceFromY <= 0.0001 {
            cameraNode.eulerAngles.y = cameraTopYAngle
        } else {
            let cosY = -centerToPosition.z / distanceFromY
            var angY = acos(cosY)
            if centerToPosition.x >= 0 {
                angY = Float(2.0 * Double.pi) - angY
            }
            cameraNode.eulerAngles.y = angY
        }
    }
    
    fileprivate var cameraPosition = GLKVector3Make(0.0, 0.0, 0.0)
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        // we're gonna rotate around cameraCenter on a sphere
        let translation = sender.translation(in: sender.view!)
        let transVect = GLKVector2Make(
            cameraPanSpeed * Float(translation.x / sender.view!.frame.size.width),
            cameraPanSpeed * Float(translation.y / sender.view!.frame.size.height))
        
        // init movement
        if sender.state == .began {
            cameraPosition = SCNVector3ToGLKVector3(cameraNode.position)
        }
        
        // sphere's radius:
        let vect2Center = GLKVector3Subtract(cameraCenter, cameraPosition)
        let radius = GLKVector3Length(vect2Center)
        
        // distanse on the sphere
        let transLength = GLKVector2Length(transVect)  // actual length on the sphere
        let transAngle = transLength / (2.0 * Float(Double.pi) * radius) // move in radians
        
        // avoid division by 0
        if transLength <= 0.00001 {
            return
        }
        if radius <= 0.00001 {
            return
        }
        
        // constraint - actual elevation
        let elevation = asin(vect2Center.y / radius)
        
        // rotate around Y
        let angY = -transAngle * transVect.x / transLength
        let mat4RotY = GLKMatrix4MakeYRotation(angY)
        var rotVect2Center = GLKMatrix4MultiplyVector3(mat4RotY, GLKVector3MultiplyScalar(vect2Center, -1.0))
        
        // rotate verticaly
        var angDelta = -transAngle * transVect.y / transLength
        angDelta = (angDelta + elevation < -cameraMaxElevationAngle) ? (-cameraMaxElevationAngle - elevation) : angDelta
        angDelta = (angDelta + elevation > -cameraMinElevationAngle) ? (-cameraMinElevationAngle - elevation) : angDelta
        var vect2CenterXZ = GLKVector3Make(vect2Center.x, 0.0, vect2Center.z)
        if GLKVector3Length(vect2CenterXZ) <= 0.001 {
            vect2CenterXZ = GLKVector3Make(0.0, 0.0, 1.0)
        }
        // rotate by 90 degree to vect2CenterXZ
        let mat4RotAxis = GLKMatrix4MakeRotation(angDelta, -vect2CenterXZ.z, 0.0, vect2CenterXZ.x)
        rotVect2Center = GLKMatrix4MultiplyVector3(mat4RotAxis, rotVect2Center)
        
        // move
        moveCamera(GLKVector3Add(cameraCenter, rotVect2Center))
    }
    
    @objc func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        // we're gonna change the camera distance
        var velocity = Float(sender.velocity)
        if abs(velocity) > 7.0 {
            velocity = sign(velocity) * 7.0
        }
        
        cameraPosition = SCNVector3ToGLKVector3(cameraNode.position)
        
        var zoomVector = GLKVector3Subtract(cameraCenter, cameraPosition)
        
        zoomVector = GLKVector3Normalize(zoomVector)
        zoomVector = GLKVector3MultiplyScalar(zoomVector, velocity * 0.2)
        cameraPosition = GLKVector3Add(cameraPosition, zoomVector)
        
        // if it would be too clo
        let distance = GLKVector3Distance(cameraCenter, cameraPosition)
        if (distance < 2.0 && velocity > 0) || (distance > 20.0 && velocity < 0)  {
            return
        }
        
        cameraNode.position = SCNVector3FromGLKVector3(cameraPosition)
    }
    
    override open var shouldAutorotate : Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupInitialCamera(_ targetScene: SCNScene) {
        cameraNode.position = SCNVector3(x: 0.0, y: 1.0, z: 2.5)
        cameraNode.camera = SCNCamera()
        targetScene.rootNode.addChildNode(cameraNode)
    }
    
    func setupLighting(_ targetScene: SCNScene) {
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor.lightGray
        targetScene.rootNode.addChildNode(ambientLightNode)
    }
    
}

extension UIImage {
    static func fromColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
