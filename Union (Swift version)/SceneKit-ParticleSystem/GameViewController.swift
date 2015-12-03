/*
    Abstract:
    Game View Controller declaration.

    Created by Apple and converted to Swift by Bulent Buyukkahraman on 11/26/15.
*/


import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {
    
    
    //MARK:- Properties
    private var mySceneView             : SCNView!
    private var myScene                 : SCNScene!
    private var myCameraNode            : SCNNode!
    private var myAmbientLightNode      : SCNNode!
    private var mySpotLightParentNode   : SCNNode!
    private var mySpotLightNode         : SCNNode!
    private var myOriginalSpotTransform : SCNMatrix4!
    private var myFloorNode             : SCNNode!
    private var myMainWall              : SCNNode!
    private var myInvisibleWall         : SCNNode!
    private var myCameraHandle          : SCNNode!
    private var myCameraOrientation     : SCNNode!
    private var mySceneKitLogo          : SCNNode!
    private var myShipNode              : SCNNode!
    private var myShipPivot             : SCNNode!
    private var myShipHandle            : SCNNode!
    private var myIntroNodeGroup        : SCNNode!
    private var myEmitter               : SCNNode!
    private var myPosition              : SCNVector3!
    private var myShipXTranslate        : SCNNode!
    
    private let slideCount = 10
    private let textScale = 0.75
    
    //MARK:- Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewSetup()
    }
    
    func viewSetup()            {
        
        self.mySceneView               = self.view as! SCNView     // retrieve the SCNView
        mySceneView.playing            = true
        mySceneView.loops              = true                      //redraw forever
        mySceneView.showsStatistics    = true
        mySceneView.backgroundColor    = UIColor.blackColor()
        
        sceneSetup()
    }
    func sceneSetup()           {

        self.myScene                    = SCNScene()        // create a new scene
        self.mySceneView.scene          = myScene           //present SCScene
        self.mySceneView.pointOfView    = myCameraNode      //initial point of view

        cameraSetup()
        lightSetup()
        floorSetup()
        wallSetup()
        introSetup()
    }
    func cameraSetup()          {
        
        //create a main camera
        self.myCameraNode           = SCNNode()
        myCameraNode.position       = SCNVector3Make(0, 0, 120)

        
        //create a node to manipulate the camera orientation
        self.myCameraHandle         = SCNNode()
        myCameraHandle.position     = SCNVector3Make(0, 60, 0)

        self.myCameraOrientation    = SCNNode()
        
        
        self.myScene.rootNode.addChildNode(myCameraHandle)
        myCameraHandle.addChildNode(myCameraOrientation)
        myCameraOrientation.addChildNode(myCameraNode)
        
    
        let myCamera        = SCNCamera()
        myCameraNode.camera = myCamera
        myCamera.zFar       = 800
        myCamera.xFov       = 75
    }
    func lightSetup()           {

        // add an ambient light
        self.myAmbientLightNode         = SCNNode()
        myAmbientLightNode.light        = SCNLight()
        myAmbientLightNode.light!.type  = SCNLightTypeAmbient
        myAmbientLightNode.light!.color = UIColor(white: 0.3, alpha: 1.0)
        self.myScene.rootNode.addChildNode(myAmbientLightNode)
        
        //add a key light to the scene
        self.mySpotLightParentNode      = SCNNode()
        mySpotLightParentNode.position  = SCNVector3Make(0, 90, 20)
        
        self.mySpotLightNode                    = SCNNode()
        mySpotLightNode.rotation                = SCNVector4Make(1,0,0, Float(-M_PI_4))
        mySpotLightNode.light                   = SCNLight()
        mySpotLightNode.light!.type             = SCNLightTypeSpot
        mySpotLightNode.light!.color            = UIColor(white: 1.0, alpha: 1.0)
        mySpotLightNode.light!.castsShadow      = true
        mySpotLightNode.light!.shadowColor      = UIColor(white: 0, alpha: 0.5)
        mySpotLightNode.light!.zNear            = 30
        mySpotLightNode.light!.zFar             = 800
        mySpotLightNode.light!.shadowRadius     = 1.0
        mySpotLightNode.light!.spotInnerAngle   = 15
        mySpotLightNode.light!.spotOuterAngle   = 70
        
        self.myCameraNode.addChildNode(mySpotLightParentNode)
        mySpotLightParentNode.addChildNode(mySpotLightNode)
        
        //save spotlight transform
        self.myOriginalSpotTransform = mySpotLightNode.transform
    }
    func floorSetup()           {
        
        //floor
        self.myFloorNode                = SCNNode()
        myFloorNode.physicsBody         = SCNPhysicsBody()
        myFloorNode.physicsBody!.type   = .Static
        myFloorNode.physicsBody!.restitution = 1.0
        
        let myFloor                     = SCNFloor()
        myFloorNode.geometry            =  myFloor
        myFloor.reflectionFalloffEnd    = 0
        myFloor.reflectivity            = 0
        myFloor.firstMaterial!.diffuse.contents         = "wood.png"
        myFloor.firstMaterial!.locksAmbientWithDiffuse  = true
        myFloor.firstMaterial!.diffuse.wrapS            = .Repeat
        myFloor.firstMaterial!.diffuse.wrapT            = .Repeat
        myFloor.firstMaterial!.diffuse.mipFilter        = .Nearest
        myFloor.firstMaterial!.doubleSided              = false
        
        self.myScene.rootNode.addChildNode(myFloorNode)
    }
    func wallSetup()            {
        
        // create the wall geometry
        let wallGeometry        = SCNPlane(width: 800, height: 200)
        wallGeometry.firstMaterial!.diffuse.contents            = "wallPaper.png"
        wallGeometry.firstMaterial!.diffuse.contentsTransform   = SCNMatrix4Mult(SCNMatrix4MakeScale(8, 2, 1), SCNMatrix4MakeRotation(Float(M_PI_4), 0, 0, 1))
        wallGeometry.firstMaterial!.diffuse.wrapS               = .Repeat
        wallGeometry.firstMaterial!.diffuse.wrapT               = .Repeat
        wallGeometry.firstMaterial!.doubleSided                 = false
        wallGeometry.firstMaterial!.locksAmbientWithDiffuse     = true
        
        let wallWithBaseboardNode                       = SCNNode(geometry: wallGeometry)
        wallWithBaseboardNode.position                  = SCNVector3Make(200, 100, -20)
        wallWithBaseboardNode.physicsBody               = SCNPhysicsBody()
        wallWithBaseboardNode.physicsBody!.type         = .Static
        wallWithBaseboardNode.physicsBody!.restitution  = 1.0
        wallWithBaseboardNode.castsShadow               = false
        
        
        let baseboardGeomety                                = SCNBox(width: 800, height: 8, length: 0.5, chamferRadius: 0)
        baseboardGeomety.firstMaterial!.diffuse.contents    = "baseboard.jpg"
        baseboardGeomety.firstMaterial!.diffuse.wrapS       = .Repeat
        baseboardGeomety.firstMaterial!.doubleSided         = false
        baseboardGeomety.firstMaterial!.locksAmbientWithDiffuse = true
        
        let baseboardNode               = SCNNode(geometry: baseboardGeomety)
        baseboardNode.position          = SCNVector3Make(0, -wallWithBaseboardNode.position.y + 4, 0.5)
        baseboardNode.castsShadow       = false
        baseboardNode.renderingOrder    = -3; //render before others
        
        wallWithBaseboardNode.addChildNode(baseboardNode)
        
        
        //front walls
        self.myMainWall = wallWithBaseboardNode.clone()
        self.myScene.rootNode.addChildNode(wallWithBaseboardNode)
        myMainWall.renderingOrder   = -3  //render before others
        
        //back
        var wallNode = wallWithBaseboardNode.clone()
        wallNode.opacity                    = 0
        wallNode.physicsBody                = SCNPhysicsBody()
        wallNode.physicsBody!.type          = .Static
        wallNode.physicsBody!.restitution   = 1.0
        wallNode.physicsBody!.categoryBitMask = 1 << 2
        wallNode.castsShadow                = false
        wallNode.position                   = SCNVector3Make(0, 100, 40)
        wallNode.rotation                   = SCNVector4Make(0, 1, 0, Float(M_PI))
        self.myScene.rootNode.addChildNode(wallNode)
        
        //left
        wallNode            = wallWithBaseboardNode.clone()
        wallNode.position   = SCNVector3Make(-120, 100, 40)
        wallNode.rotation   = SCNVector4Make(0, 1, 0, Float(M_PI_2))
        self.myScene.rootNode.addChildNode(wallNode)
        
        //right (an invisible wall to keep the bodies in the visible area when zooming in the Physics slide)
        wallNode = wallNode.clone()
        wallNode.opacity        = 0
        wallNode.position       = SCNVector3Make(120, 100, 40)
        wallNode.rotation       = SCNVector4Make(0, 1, 0, Float(-M_PI_2))

        self.myInvisibleWall = wallNode
        
        //right (the actual wall on the right)
        wallNode = wallWithBaseboardNode.clone()
        wallNode.physicsBody    = nil
        wallNode.position       = SCNVector3Make(600, 100, 40)
        wallNode.rotation       = SCNVector4Make(0, 1, 0, Float(-M_PI_2))
        self.myScene.rootNode.addChildNode(wallNode)

        //top
        wallNode            = wallWithBaseboardNode.copy() as! SCNNode
        wallNode.geometry   = (wallNode.geometry!.copy() as! SCNGeometry)
        wallNode.geometry!.firstMaterial = SCNMaterial()
        wallNode.opacity    = 1
        wallNode.position   = SCNVector3Make(200, 200, 0)
        wallNode.scale      = SCNVector3Make(1, 10, 1)
        wallNode.rotation   = SCNVector4Make(1, 0, 0, Float(M_PI_2))
        self.myScene.rootNode.addChildNode(wallNode)

       myMainWall.hidden = true //hide at first (save some milliseconds)
    }
    func introSetup()           {
        
        // configure the lighting for the introduction (dark lighting)
        self.myAmbientLightNode.light!.color    = UIColor.blackColor()
        self.mySpotLightNode.light!.color       = UIColor.blackColor()
        self.mySpotLightNode.position           = SCNVector3Make(50, 90, -50)
        self.mySpotLightNode.eulerAngles        = SCNVector3Make(Float(-M_PI_2)*0.75, Float(M_PI_4)*0.5, 0)
        
        self.myPosition                         = SCNVector3Make(200, 0, 200)
        self.myCameraNode.position              = SCNVector3Make(200, -20, myPosition.z+150)
        self.myCameraNode.eulerAngles           = SCNVector3Make(Float(-M_PI_2)*0.06, 0, 0)
        
        sceneKitLogoSetup()
        shipSetup()
    }
    func sceneKitLogoSetup()    {

        //put all texts under this node to remove all at once later
        self.myIntroNodeGroup   = SCNNode()
        
        let logoSize : CGFloat  = 70
        let myLogo              = SCNPlane(width: logoSize, height: logoSize)
        myLogo.firstMaterial!.doubleSided       = true
        myLogo.firstMaterial!.diffuse.contents  = "SceneKit.png"
        myLogo.firstMaterial!.emission.contents = "SceneKit.png"
        
        self.mySceneKitLogo = SCNNode(geometry: myLogo)
        mySceneKitLogo.renderingOrder       = -1
        self.myFloorNode.renderingOrder     = -2
        
        self.myIntroNodeGroup.addChildNode(mySceneKitLogo)
        self.mySceneKitLogo.position         = SCNVector3Make(200, Float(logoSize) * 0.5, 200)
        
    }
    func shipSetup()            {
        
        // hierarchy
        let myModelScene    = SCNScene(named: "ship.dae", inDirectory: "assets.scnassets/models", options: nil)
        self.myShipNode     = SCNNode()
        myShipNode          = (myModelScene?.rootNode.childNodeWithName("Aircraft", recursively: true))!
        
        let myShipMesh      = myShipNode.childNodes[0]
        myShipMesh.geometry?.firstMaterial?.fresnelExponent     = 1.0
        myShipMesh.geometry?.firstMaterial?.emission.intensity  = 0.5
        myShipMesh.renderingOrder = -3
        
        self.myShipPivot            = SCNNode()
        self.myShipXTranslate       = SCNNode()
        self.myShipHandle           = SCNNode()
        myShipHandle.position       = SCNVector3Make(200 - 500, 0, self.myPosition.z + 30)
        myShipNode.position         = SCNVector3Make(50, 30, 0)
        
        myShipPivot.addChildNode(myShipNode)
        myShipXTranslate.addChildNode(myShipPivot)
        myShipHandle.addChildNode(myShipXTranslate)
        self.myIntroNodeGroup.addChildNode(myShipHandle)
        
        shipAnimationSetup()
    }
    func shipAnimationSetup()   {
        
        //animate ship
        self.myShipNode.removeAllActions()
        self.myShipNode.rotation     = SCNVector4Make(0, 0, 1, Float(M_PI_4) * 0.5)
        
        //make spotlight relative to the ship
        let myNewPosition               = SCNVector3Make(50, 100, 0)
        let myOldTransform              = myShipPivot.convertTransform(SCNMatrix4Identity, fromNode: self.mySpotLightNode)
        self.mySpotLightNode.transform  = myOldTransform
        self.myShipPivot.addChildNode(mySpotLightNode)
        
        self.mySpotLightNode.position               = myNewPosition // will animate implicitly
        self.mySpotLightNode.eulerAngles            = SCNVector3Make(Float(-M_PI_2), 0, 0)
        self.mySpotLightNode.light!.spotOuterAngle  = 120
        
        self.myShipPivot.eulerAngles = SCNVector3Make(0,Float(M_PI_2), 0)
        let myAction = SCNAction.sequence([SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: CGFloat(M_PI), z: 0, duration: 2))])
        myShipPivot.runAction(myAction)
        
        let myAnimation             = CABasicAnimation(keyPath: "position.x")
        myAnimation.fromValue       = -50
        myAnimation.toValue         = 50
        myAnimation.timingFunction  = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        myAnimation.autoreverses    = true
        myAnimation.duration        = 2
        myAnimation.repeatCount     = Float.infinity
        myAnimation.timeOffset      = -myAnimation.duration*0.5
        myShipXTranslate.addAnimation(myAnimation, forKey: nil)
        
        self.myEmitter          = SCNNode()
        myEmitter               = myShipNode.childNodeWithName("emitter", recursively: true)!
        let myParticleSystem    = SCNParticleSystem(named: "reactor.scnp", inDirectory: "assets.scnassets/particles")
        
        myEmitter.addParticleSystem(myParticleSystem!)
        self.myShipHandle.position = SCNVector3Make(myShipHandle.position.x, myShipHandle.position.y, myShipHandle.position.z-50)
        
        self.myScene.rootNode.addChildNode(myIntroNodeGroup)
        
        //wait, then fade in light
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(1.0)
        
        SCNTransaction.setCompletionBlock { () -> Void in
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(2.5)
            self.myShipHandle.position          = SCNVector3Make(self.myShipHandle.position.x+500, self.myShipHandle.position.y, self.myShipHandle.position.z)
            self.mySpotLightNode.light!.color   = UIColor(white: 1, alpha: 1)
            self.mySceneKitLogo.geometry!.firstMaterial!.emission.intensity = 0.80
            SCNTransaction.commit()
        }
        self.mySpotLightNode.light!.color       = UIColor(white: 0.001, alpha: 1)
        SCNTransaction.commit()
    }
}