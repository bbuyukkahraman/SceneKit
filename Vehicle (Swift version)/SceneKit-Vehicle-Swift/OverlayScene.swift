import SpriteKit

class OverlayScene : SKScene {
    
    
    var mySpeedNeedle : SKNode!
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder) is not used in this app") }
    override init(size: CGSize) {
        super.init(size: size)
        
        //setup the overlay scene
        self.anchorPoint = CGPointMake(0.5, 0.5)
        
        //automatically resize to fill the viewport
        self.scaleMode = .ResizeFill
        
        let scale :Float = 1.5
        
        //add the speed gauge
        let myImage = SKSpriteNode(imageNamed: "speedGauge.png")
        myImage.anchorPoint = CGPointMake(0.5, 0)
        myImage.position = CGPointMake(size.width*0.33, -size.height*0.5)
        myImage.xScale = 0.8 * CGFloat(scale)
        myImage.yScale = 0.8 * CGFloat(scale)
        addChild(myImage)
        
        //add the needed
        let needleHandle = SKNode()
        let needle = SKSpriteNode(imageNamed: "needle.png")
        needleHandle.position = CGPointMake(0, 16)
        needle.anchorPoint = CGPointMake(0.5, 0)
        needle.xScale = 0.7
        needle.yScale = 0.7
        needle.zRotation = CGFloat(M_PI_2)
        needleHandle.addChild(needle)
        myImage.addChild(needleHandle)
        
        mySpeedNeedle = needleHandle
        
        //add the camera button
        
        let cameraImage = SKSpriteNode(imageNamed: "video_camera.png")
        cameraImage.position = CGPointMake(-size.width * 0.4, -size.height*0.4)
        cameraImage.name = "camera"
        cameraImage.xScale = 0.6 * CGFloat(scale)
        cameraImage.yScale = 0.6 * CGFloat(scale)
        addChild(cameraImage)
    }
}