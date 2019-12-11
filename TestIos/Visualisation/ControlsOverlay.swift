
import Foundation
import SceneKit
import SpriteKit
import UIKit
import WearnotchSDK


@objc public protocol CameraController {
    func moveCamera(_ position: GLKVector3)
}


open class CameraViewOverlay: SceneOverlay {
    open var cameraController: CameraController? = nil
    
    let bundle = Bundle(for: CameraViewOverlay.self)
    
    var ic_droid_front_view: UIImage
    var ic_droid_side_view: UIImage
    var ic_droid_top_view: UIImage
    
    var droidView = DroidView.Front
    
    public override init(size: CGSize) {
        
        self.ic_droid_front_view = UIImage(named: "ic_droid_front", in: bundle, compatibleWith: nil)!
        self.ic_droid_side_view = UIImage(named: "ic_droid_side", in: bundle, compatibleWith: nil)!
        self.ic_droid_top_view = UIImage(named: "ic_droid_top", in: bundle, compatibleWith: nil)!
        
        super.init(size: size)
        
        self.scaleMode = .resizeFill
        
        _ = self.addWithImage("droid_view", position: OverlayPosition.rightTop, image: ic_droid_front_view)
        self.addTouchCallback("droid_view", callback: changeViewTapped)
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeViewTapped(_ sender: SceneOverlay) {
        let button = getButton("droid_view")
        var texture = SKTexture(image: ic_droid_side_view)
        
        switch droidView {
        case .Front:
            droidView = .Side
            texture = SKTexture(image: ic_droid_side_view)
            sideView()
            break
        case .Side:
            droidView = .Top
            texture = SKTexture(image: ic_droid_top_view)
            topView()
            break
        case .Top:
            droidView = .Front
            texture = SKTexture(image: ic_droid_front_view)
            frontView()
            break
        }
        button?.node.texture = texture
    }
    
    func sideView() {
        cameraController?.moveCamera(GLKVector3Make(-2.5, 1.0, 0.0))
    }
    
    func topView() {
        cameraController?.moveCamera(GLKVector3Make(0.0, 3.5, 0.0))
    }
    
    func frontView() {
        cameraController?.moveCamera(GLKVector3Make(0.0, 1.0, 2.5))
    }
}

enum DroidView {
    case Front
    case Side
    case Top
}

open class AnimationControlsOverlay: CameraViewOverlay {
    open var downloadTrue = false
    open var imuData:[[String:Float]]? = []
    public var animationController: WorkoutAnimationViewController? = nil
    
    weak var controlDelegate: ControlsOverlayDelegate?
    
    var progressBackground: SKShapeNode!
    var progressFull: SKShapeNode!
    var progressDone: SKShapeNode!
    var progressButton: SKSpriteNode!
    
    var pauseImage: UIImage!
    var playImage: UIImage!
    var downloadImage: UIImage!
    
    var progressWidth: CGFloat = 0.0
    var progressBegin: CGFloat = 0.0
    var progressHeight: CGFloat = 0.0
    var ypos: CGFloat = 0.0
    
    var isMovingProgressValue = false
    
    open weak var animationProgress: AnimationProgress?
    
    open weak var scnView: SCNView? = nil
    
    open var progressLinePercent: Float {
        get {
            return animationProgress?.progress ?? 0.0
        }
        set(aNewValue) {
            if let animation = animationProgress {
                animation.progress = aNewValue
                applyAction(SKAction.run() {
                    self.moveProgressBar(aNewValue)
                })
            }
        }
    }
    
    open var animationPaused: Bool {
        get {
            return animationProgress?.isPlaying ?? true
        }
        set(aNewValue) {
            if animationProgress != nil {
                let image = aNewValue ? playImage : pauseImage
                let button = self.getButton("playpause")!.node
                applyAction(SKAction.run() {
                    button.texture = SKTexture(image: image!)
                })
            }
        }
    }
    
    open var playbackSpeed: PlaybackSpeed {
        get {
            if let animation = animationProgress {
                return animation.playbackSpeed
            } else {
                return .normal
            }
        }
        set(aNewValue) {
            if let animation = animationProgress {
                let button = self.getButton("slomo")!
                var labelText: String!
                switch aNewValue {
                case .normal:
                    labelText = "1x"
                case .half:
                    labelText = "1/2x"
                case .quarter:
                    labelText = "1/4x"
                case .eighth:
                    labelText = "1/8x"
                }
                animation.playbackSpeed = aNewValue
                applyAction(SKAction.run() {
                    button.label?.text = labelText
                })
            }
        }
    }
    
    public override init(size: CGSize) {
        super.init(size: size)
        
        let bundle = Bundle(for: CameraViewOverlay.self)
        
        ///Button for rewind
        let im_rewind = UIImage(named: "ic_backward", in: bundle, compatibleWith: nil)
        _ = self.addWithImage("rewind", position: OverlayPosition.bottom, image: im_rewind!)
        self.getButton("rewind")!.scale = 0.85
        
        ///Button for pause and play
        pauseImage = UIImage(named: "ic_pause", in: bundle, compatibleWith: nil)
        playImage = UIImage(named: "ic_play", in: bundle, compatibleWith: nil)
        _ = self.addWithImage("playpause", position: OverlayPosition.bottom, image: pauseImage)
        _ = self.getButton("playpause")!.scale = 0.85
        
        ///Button for slow mo
        let im_clock = UIImage(named: "ic_clock", in: bundle, compatibleWith: nil)
        _ = self.addWithImage("slomo", position: OverlayPosition.bottom, image: im_clock!)
        let slomoLabel = self.createOrGetLabel("slomo")!
        slomoLabel.text = "1x"
        slomoLabel.fontName = "DINAlternate-Bold"
        slomoLabel.fontColor = UIColor.white
        slomoLabel.fontSize = 15
        self.getButton("slomo")!.scale = 0.85
        
        ///Button for downlaod
        downloadImage = UIImage(named: "download", in: bundle, compatibleWith: nil)
        _ = self.addWithImage("download", position: OverlayPosition.leftTop, image: downloadImage)
        _ = self.getButton("download")
        
        
        self.progressBackground = SKShapeNode(rectOf: CGSize(width: 10, height: 10), cornerRadius: 0.0)
        self.progressBackground.name = "progressBackground"
        self.progressBackground.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        self.progressBackground.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        self.progressBackground.glowWidth = 0.0
        
        self.progressFull = SKShapeNode(rectOf: CGSize(width: 10000, height: 10), cornerRadius: 0.0)
        self.progressFull.name = "progressFull"
        self.progressFull.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.progressFull.strokeColor = UIColor(red: 0.6, green: 0.6, blue: 0.5, alpha: 1.0)
        self.progressFull.glowWidth = 0.0
        
        self.progressDone = SKShapeNode(rectOf: CGSize(width: 10000, height: 10), cornerRadius: 0.0)
        self.progressDone.name = "progressDone"
        self.progressDone.fillColor = UIColor(red: 0.0, green: 171/255.0, blue: 209/255.0, alpha: 0.85)
        self.progressDone.strokeColor = UIColor(red: 0.0, green: 171/255.0, blue: 209/255.0, alpha: 0.85)
        self.progressDone.glowWidth = 0.0
        
        let im_progress = UIImage(named: "ic_progress", in: bundle, compatibleWith: nil)
        let tx_progress = SKTexture(image: im_progress!)
        self.progressButton = SKSpriteNode(texture: tx_progress)
        self.progressButton.name = "progressButton"
        
        self.addChild(self.progressBackground)
        self.addChild(self.progressFull)
        self.addChild(self.progressDone)
        self.addChild(self.progressButton)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func resize(_ size: CGSize) {
        super.resize(size)
        // TODO commentd out, because of slow compilation time (http://irace.me/swift-profiling)
        // 1766.3ms /notch-ios-visualiser/visualizer/ControlsOverlay.swift:193:24    @objc open override func resize(_ size: CGSize)
        
        self.progressButton.size = CGSize(width: buttonSize.width * dpi * 0.4, height: buttonSize.height * dpi * 0.4)
        self.ypos = bottomPadding * dpi + buttonSize.height * dpi * 0.3
        
        self.progressHeight = buttonSize.height * dpi
        self.progressBegin = getButton("slomo")!.node.position.x + buttonSize.width * dpi * 0.7 / 2.0 + buttonSpacing * dpi
        self.progressWidth = size.width - rightPadding * dpi - self.progressBegin
        
        let progressCenter = self.progressBegin + self.progressWidth/2
        self.progressFull.position = CGPoint(x: progressCenter, y: ypos)
        self.progressFull.yScale = 0.02 * dpi / 10.0
        self.progressFull.xScale = self.progressWidth/10000.0
        self.progressDone.yScale = 0.02 * dpi / 10.0
        
        self.progressBackground.position = CGPoint(x: progressCenter, y: ypos)
        self.progressBackground.xScale = progressWidth/10.0
        self.progressBackground.yScale = buttonSize.height * dpi * 0.6 / 10.0
        
        self.moveProgressBar(self.progressLinePercent)
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)

            if let nodeName = touchedNode.name {
                switch nodeName {
                case "rewind":
                    progressLinePercent = 0.0
                case "playpause":
                    if let animation = animationProgress {
                        if animation.isPlaying {
                            animation.pause()
                        } else {
                            animation.play()
                        }
                    }
                case "download":
                    self.controlDelegate?.goBack(data:imuData ?? [])


                case "slomo":
                    if animationProgress != nil {
                        switch playbackSpeed {
                        case .normal:
                            playbackSpeed = .eighth
                        case .half:
                            playbackSpeed = .normal
                        case .quarter:
                            playbackSpeed = .half
                        case .eighth:
                            playbackSpeed = .quarter
                        }
                    }
                case "progressBackground", "progressFull", "progressDone":
                    setProgressPercentByScreenXPosition(screenPosition: location.x)
                case "progressButton":
                    isMovingProgressValue = true
                    setProgressPercentByScreenXPosition(screenPosition: location.x)
                    animationController?.isGestureRecogniserEnabled(false)
                default:
                    super.touchesBegan(touches, with: event)
                }
            }
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            
            if(isMovingProgressValue) {
                setProgressPercentByScreenXPosition(screenPosition: location.x)
            }
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMovingProgressValue = false
        animationController?.isGestureRecogniserEnabled(true)
    }
    
    private func setProgressPercentByScreenXPosition(screenPosition: CGFloat) {
        var progress = Float((screenPosition - progressBegin) / progressWidth)
        if progress < 0.0 {
            progress = 0.0
        }
        if progress > 1.0 {
            progress = 1.0
        }
        progressLinePercent = progress
    }
    
    override open func update(_ currentTime: TimeInterval) {
        moveProgressBar(animationProgress!.progress)
        if animationProgress!.progress >= 1.0 {
            animationPaused = true
        }
    }
    
    fileprivate func applyAction(_ action: SKAction) {
        let playing = scnView!.isPlaying
        run(action, completion: { self.scnView!.isPlaying = playing })
        scnView!.isPlaying = true
    }
    
    fileprivate func moveProgressBar(_ progress: Float) {
        let progressDoneWidth = self.progressWidth * CGFloat(progress)
        let progressDoneCenter = self.progressBegin + progressDoneWidth/2
        self.progressDone.position = CGPoint(x: progressDoneCenter, y: self.ypos)
        self.progressDone.xScale = self.progressWidth * CGFloat(progress) / 10000.0
        self.progressButton.position = CGPoint(x: self.progressBegin + progressDoneWidth, y: self.ypos)
    }
}

