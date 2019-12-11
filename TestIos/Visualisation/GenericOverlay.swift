
import Foundation
import SpriteKit
import UIKit

public enum OverlayPosition {
    case leftTop
    case rightTop
    case top
    case bottom
    case custom
}

open class OverlayButton {
    let name: String
    var node: SKSpriteNode
    var label: SKLabelNode? = nil
    var scale: CGFloat = 1.0
    var callback: ((SceneOverlay) -> Void)? = nil
    
    public init(name: String, node: SKSpriteNode) {
        self.name = name
        self.node = node
    }
}

open class SceneOverlay: SKScene {
    public let dpi: CGFloat = 160.0
    
    var topButtons: [OverlayButton] = []
    var leftButtons: [OverlayButton] = []
    var rightButtons: [OverlayButton] = []
    var bottomButtons: [OverlayButton] = []
    var customButtons: [OverlayButton] = []
    
    open var buttonSize: CGSize = CGSize(width: 0.3, height: 0.3)
    open var leftPadding: CGFloat = 0.1
    open var topPadding: CGFloat = 0.1
    open var rightPadding: CGFloat = 0.1
    open var bottomPadding: CGFloat = 0.1
    
    open var buttonSpacing: CGFloat = 0.05
    
    
    public override init(size: CGSize) {
        super.init(size: size)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func getButton(_ forName: String) -> OverlayButton? {
        return [topButtons, leftButtons, rightButtons, bottomButtons, customButtons].joined().filter{$0.name == forName}.first
    }
    
    open func addWithImage(_ name: String, position: OverlayPosition, image: UIImage) -> SKSpriteNode {
        let texture = SKTexture(image: image)
        let node = SKSpriteNode(texture: texture)
        node.name = name
        let button = OverlayButton(name: name, node: node)
        switch position {
        case .leftTop:
            leftButtons.append(button)
        case .rightTop:
            rightButtons.append(button)
        case .top:
            topButtons.append(button)
        case .bottom:
            bottomButtons.append(button)
        case .custom:
            break
        }
        self.addChild(node)
        return node
    }
    
    open func addTouchCallback(_ forName: String, callback: @escaping (SceneOverlay) -> Void) {
        if let button = getButton(forName) {
            button.callback = callback
        }
    }
    
    open func createOrGetLabel(_ forName: String) -> SKLabelNode? {
        if let button = getButton(forName) {
            if let label = button.label {
                return label
            } else {
                button.label = SKLabelNode(text: "foobar")
                self.addChild(button.label!)
                return button.label
            }
        }
        return nil
    }
    
    open func resize(_ size: CGSize) {
        let screenHeight: CGFloat = size.height - topPadding * dpi
        var leftPos: CGFloat = leftPadding * dpi
        var topWidth: CGFloat = CGFloat(0.0)
        let topMargin = CGFloat(15.0)
        for button in topButtons {
            let width: CGFloat = buttonSize.width * dpi * button.scale
            let height: CGFloat = buttonSize.height * dpi * button.scale
            button.node.size = CGSize(width: width, height: height)
            let positionX: CGFloat = leftPos + width / 2.0
            let positionY: CGFloat = screenHeight - height / 2.0 - topMargin
            button.node.position = CGPoint(x: positionX, y: positionY)
            leftPos += width + buttonSpacing * dpi
            if let label = button.label {
                let y: CGFloat = button.node.position.y - label.fontSize / 2
                label.position = CGPoint(x: button.node.position.x, y: y)
            }
            if height > topWidth {
                topWidth = height
            }
        }
        
        var topPos: CGFloat = screenHeight - topWidth
        leftPos = leftPadding * dpi
        for button in leftButtons {
            let width: CGFloat = buttonSize.width * dpi * button.scale
            let height: CGFloat = buttonSize.height * dpi * button.scale
            button.node.size = CGSize(width: width, height: height)
            let positionX: CGFloat = leftPos + width / 2.0
            let positionY: CGFloat = topPos - height / 2.0 - topMargin
            button.node.position = CGPoint(x: positionX, y: positionY)
            topPos -= (height + buttonSpacing * dpi)
            if let label = button.label {
                let y: CGFloat = button.node.position.y - label.fontSize / 2
                label.position = CGPoint(x: button.node.position.x, y: y)
                topPos -= label.fontSize
            }
        }
        
        let screenWidth: CGFloat = size.width - rightPadding * dpi
        topPos = screenHeight - topWidth
        for button in rightButtons {
            let width: CGFloat = buttonSize.width * dpi * button.scale
            let height: CGFloat = buttonSize.height * dpi * button.scale
            button.node.size = CGSize(width: width, height: height)
            let positionX: CGFloat = screenWidth - width / 2.0
            let positionY: CGFloat = topPos - height / 2.0 - topMargin
            button.node.position = CGPoint(x: positionX, y: positionY)
            topPos -= (height + buttonSpacing * dpi)
            if let label = button.label {
                let y: CGFloat = button.node.position.y - label.fontSize / 2
                label.position = CGPoint(x: button.node.position.x, y: y)
                topPos -= label.fontSize
            }
        }
        
        leftPos = leftPadding * dpi
        for button in bottomButtons {
            let width: CGFloat = buttonSize.width * dpi * button.scale
            let height: CGFloat = buttonSize.height * dpi * button.scale
            var bottomPos: CGFloat = bottomPadding * dpi + (button.label == nil ? 0 : buttonSpacing)
            button.node.size = CGSize(width: width, height: height)
            let positionX: CGFloat = leftPos + width / 2.0
            let positionY: CGFloat = bottomPos + height / 2.0
            button.node.position = CGPoint(x: positionX, y: positionY)
            leftPos += (width + buttonSpacing * dpi)
            if let label = button.label {
                let y: CGFloat = button.node.position.y - label.fontSize / 2
                label.position = CGPoint(x: button.node.position.x, y: y)
                bottomPos -= label.fontSize
            }
        }
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            if let nodeName = touchedNode.name {
                switch nodeName{
                case "download":
                    print("we are downloading")
                    super.touchesBegan(touches, with: event)
                default:
                     getButton(nodeName)?.callback?(self)
                }
            }
        }
    }
}
