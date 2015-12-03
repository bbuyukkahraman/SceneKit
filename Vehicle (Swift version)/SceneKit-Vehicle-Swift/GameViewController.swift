import CoreMotion
import SpriteKit
import UIKit
import QuartzCore
import SceneKit
import GameController

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    
    private var myCameraNode : SCNNode!
    private var myVehicleNode :SCNNode!
    private var myReactor : SCNParticleSystem!
    private var myReactorDefaultBirthRate: CGFloat = 0
    private var myVehicle : SCNPhysicsVehicle!
    private var mySpotLightNode :SCNNode!
    private var myMotionManager : CMMotionManager!
    private var myOrientation   : CGFloat = 0
    private var myVehicleSteering : CGFloat!
    private var maxSpeed : CGFloat = 250
    var accelerometer = [UIAccelerationValue](count: 3, repeatedValue: 0.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scnView = self.view as! SCNView
        
        //set the background to back
        scnView.backgroundColor = SKColor.blackColor()
        
        //setup the scene
        let scene = setupScene()
        
        //present it
        scnView.scene = scene
        
        //tweak physics
        scnView.scene!.physicsWorld.speed = 4.0
        
        //initial point of view
        scnView.pointOfView = myCameraNode
        

        //plug game logic
        scnView.delegate = self
        
        //setup overlays
        scnView.overlaySKScene = OverlayScene(size: scnView.bounds.size)
        
        //setup accelerometer
       setupAccelerometer()
        
        // Add Gesture
        let doubleTap = UITapGestureRecognizer(target: self, action: "handleDoubleTap:")
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 2
        scnView.gestureRecognizers = [doubleTap]
    }
    func setupScene() -> SCNScene {
        
        // create a new scene
        let scene = SCNScene()
        
        //global environment
        setupEnvironment(scene)
        
        //add elements
        setupSceneElements(scene)
        
        //setup vehicle
        myVehicleNode = setupVehicle(scene)
        
        //create a main camera
        myCameraNode = SCNNode()
        myCameraNode.camera = SCNCamera()
        myCameraNode.camera!.zFar = 500
        myCameraNode.position = SCNVector3Make(0, 60, 50)
        myCameraNode.rotation  = SCNVector4Make(1, 0, 0, -Float(M_PI_4)*0.75)
        scene.rootNode.addChildNode(myCameraNode)
        
        
        //add a secondary camera to the car
        let frontCameraNode = SCNNode()
        frontCameraNode.position = SCNVector3Make(0, 3.5, 2.5)
        frontCameraNode.rotation = SCNVector4Make(0, 1, 0, Float(M_PI))
        frontCameraNode.camera = SCNCamera()
        frontCameraNode.camera!.xFov = 75
        frontCameraNode.camera!.zFar = 500
        
        myVehicleNode.addChildNode(frontCameraNode)
        
        return scene
    }
    func setupEnvironment(scene : SCNScene) {
        
        // add an ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = SCNLightTypeAmbient
        ambientLight.light!.color = UIColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        //add a key light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeSpot
        
        lightNode.light!.castsShadow = true
        lightNode.light!.color = UIColor(white: 0.8, alpha: 1.0)
        lightNode.position = SCNVector3Make(0, 80, 30)
        lightNode.rotation = SCNVector4Make(1,0,0,Float(-M_PI)/2.8)
        lightNode.light!.spotInnerAngle = 0
        lightNode.light!.spotOuterAngle = 50
        lightNode.light!.shadowColor = SKColor.blackColor()
        lightNode.light!.zFar = 500
        lightNode.light!.zNear = 50
        scene.rootNode.addChildNode(lightNode)
        
        //keep an ivar for later manipulation
        mySpotLightNode = lightNode
        
        
        let floor = SCNNode()
        floor.geometry = SCNFloor()
        floor.geometry!.firstMaterial!.diffuse.contents = "wood.png"
        floor.geometry!.firstMaterial!.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1)
        floor.geometry!.firstMaterial!.locksAmbientWithDiffuse = true
        ((floor.geometry) as! SCNFloor).reflectionFalloffEnd = 10
        
        let staticBody = SCNPhysicsBody.staticBody()
        floor.physicsBody = staticBody
        scene.rootNode.addChildNode(floor)
    }
    func setupSceneElements(scene: SCNScene) {
        
          // add walls
        var wall = SCNNode(geometry: SCNBox(width: 400, height: 100, length: 4, chamferRadius: 0))
        wall.geometry!.firstMaterial!.diffuse.contents = "wall.jpg"
        wall.geometry!.firstMaterial!.diffuse.contentsTransform = SCNMatrix4Mult(SCNMatrix4MakeScale(24, 2, 1), SCNMatrix4MakeTranslation(0, 1, 0))
        wall.geometry!.firstMaterial!.diffuse.wrapS = .Repeat
        wall.geometry!.firstMaterial!.diffuse.wrapT = .Mirror
        wall.geometry!.firstMaterial!.doubleSided = false
        wall.castsShadow = false
        wall.geometry!.firstMaterial!.locksAmbientWithDiffuse = false
        
        wall.position = SCNVector3Make(0, 50, -92)
        wall.physicsBody = SCNPhysicsBody.staticBody()
        scene.rootNode.addChildNode(wall)

        wall = wall.clone()
        wall.position = SCNVector3Make(-202, 50, 0)
        wall.rotation = SCNVector4Make(0, 1, 0, Float(M_PI_2))
        scene.rootNode.addChildNode(wall)
        
        wall = wall.clone()
        wall.position = SCNVector3Make(202, 50, 0)
        wall.rotation = SCNVector4Make(0, 1, 0, Float(-M_PI_2))
        scene.rootNode.addChildNode(wall)
        
        let backWall = SCNNode(geometry: SCNPlane(width: 400, height: 100))
        backWall.geometry!.firstMaterial = wall.geometry!.firstMaterial
        backWall.position = SCNVector3Make(0, 50, 200)
        backWall.rotation = SCNVector4Make(0, 1, 0, Float(M_PI))
        backWall.castsShadow = false
        backWall.physicsBody = SCNPhysicsBody.staticBody()
        scene.rootNode.addChildNode(backWall)
        
        // add ceil
        let ceilNode = SCNNode(geometry: SCNPlane(width: 400, height: 400))
        ceilNode.position = SCNVector3Make(0, 100, 0)
        ceilNode.rotation = SCNVector4Make(1, 0, 0, Float(M_PI_2))
        ceilNode.geometry!.firstMaterial!.doubleSided = false
        ceilNode.castsShadow = false
        ceilNode.geometry!.firstMaterial!.locksAmbientWithDiffuse = false
        scene.rootNode.addChildNode(ceilNode)

        
        // add a train
        addTrainToScene(scene, pos: SCNVector3Make(-5, 20, -40))
        
        // add wooden blocks
        addWoodenBlockToScene(scene, imageName: "WoodCubeA.jpg", position: SCNVector3Make(-10, 15, 10))
        addWoodenBlockToScene(scene, imageName: "WoodCubeB.jpg", position: SCNVector3Make(-9, 10, 10))
        addWoodenBlockToScene(scene, imageName: "WoodCubeC.jpg", position: SCNVector3Make(20, 15, -11))
        addWoodenBlockToScene(scene, imageName: "WoodCubeA.jpg", position: SCNVector3Make(25, 5, -20))

        //add more block
        for _ in 0...4 {
            addWoodenBlockToScene(scene, imageName: "WoodCubeA.jpg", position: SCNVector3Make(Float(rand()%60) - 30, 20, Float(rand()%40) - 20))
            addWoodenBlockToScene(scene, imageName: "WoodCubeB.jpg", position: SCNVector3Make(Float(rand()%60) - 30, 20, Float(rand()%40 - 20)))
            addWoodenBlockToScene(scene, imageName: "WoodCubeC.jpg", position: SCNVector3Make(Float(rand()%60) - 30, 20, Float(rand()%40 - 20)))
        }
        
        // add cartoon book
        let block = SCNNode()
        block.position = SCNVector3Make(20, 10, -16)
        block.rotation = SCNVector4Make(0, 1, 0, Float(-M_PI_4))
        block.geometry = SCNBox(width: 22, height: 0.2, length: 34, chamferRadius: 0)
        let frontMat = SCNMaterial()
        frontMat.locksAmbientWithDiffuse = true
        frontMat.diffuse.contents = "book_front.jpg"
        frontMat.diffuse.mipFilter = .Linear
        let backMat = SCNMaterial()
        backMat.locksAmbientWithDiffuse = true
        backMat.diffuse.contents = "book_back.jpg"
        backMat.diffuse.mipFilter = .Linear
        block.geometry!.materials = [frontMat, backMat]
        block.physicsBody = SCNPhysicsBody.dynamicBody()
        scene.rootNode.addChildNode(block)
        
        // add carpet
        let rug = SCNNode()
        rug.position = SCNVector3Make(0, 0.01, 0)
        rug.rotation = SCNVector4Make(1, 0, 0, Float(M_PI_2))
        let path = UIBezierPath(roundedRect: CGRectMake(-50, -30, 100, 50), cornerRadius: 2.5)
        path.flatness = 0.1
        rug.geometry = SCNShape(path: path, extrusionDepth: 0.05)
        rug.geometry!.firstMaterial!.locksAmbientWithDiffuse = true
        rug.geometry!.firstMaterial!.diffuse.contents = "carpet.jpg"
        scene.rootNode.addChildNode(rug)
        
        // add ball
        let ball = SCNNode()
        ball.position = SCNVector3Make(-5, 5, -18)
        ball.geometry = SCNSphere(radius: 5)
        ball.geometry!.firstMaterial!.locksAmbientWithDiffuse = true
        ball.geometry!.firstMaterial!.diffuse.contents = "ball.jpg"
        ball.geometry!.firstMaterial!.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 1, 1)
        ball.geometry!.firstMaterial!.diffuse.wrapS = .Mirror
        ball.physicsBody = SCNPhysicsBody.dynamicBody()
        ball.physicsBody!.restitution = 0.9
        scene.rootNode.addChildNode(ball)
        
    }
    func addWoodenBlockToScene(scene:SCNScene, imageName: String , position: SCNVector3) {
        
        //create a new node
        let block = SCNNode()
        
        //place it
        block.position = position
        
        //attach a box of 5x5x5
        block.geometry = SCNBox(width: 5, height: 5, length: 5, chamferRadius: 0)
        
        //use the specified images named as the texture
        block.geometry!.firstMaterial!.diffuse.contents = imageName
        
        //turn on mipmapping
        block.geometry!.firstMaterial!.diffuse.mipFilter = .Linear
        
        //make it physically based
        block.physicsBody = SCNPhysicsBody.dynamicBody()
        
        //add to the scene
        scene.rootNode.addChildNode(block)
    }
    func addTrainToScene(scene: SCNScene, pos:SCNVector3) {
        let trainScene = SCNScene(named: "train_flat")
        
        //physicalize the train with simple boxes
        trainScene?.rootNode.enumerateChildNodesUsingBlock({ child, stop in
            let node = child as SCNNode
            if node.geometry != nil {
                node.position = SCNVector3Make(node.position.x + pos.x, node.position.y + pos.y, node.position.z + pos.z);
                
                var min = SCNVector3Zero
                var max = SCNVector3Zero

                node.getBoundingBoxMin(&min, max: &max)
                
               let body = SCNPhysicsBody.dynamicBody()
               let boxShape = SCNBox(width: CGFloat(max.x - min.x), height: CGFloat(max.y - min.y), length: CGFloat(max.z - min.z), chamferRadius: 0.0)
                
               body.physicsShape = SCNPhysicsShape(geometry: boxShape, options: nil)
                
                node.pivot = SCNMatrix4MakeTranslation(0, -min.y, 0)
                node.physicsBody = body
                scene.rootNode.addChildNode(node)
            }
        })
        
        //add smoke
        let smokeHandle = scene.rootNode.childNodeWithName("Smoke", recursively: true)
        smokeHandle?.addParticleSystem(SCNParticleSystem(named: "smoke", inDirectory: nil)!)
        
        //add physics constraints between engine and wagons
        let engineCar = scene.rootNode.childNodeWithName("EngineCar", recursively: false)
        let wagon1 = scene.rootNode.childNodeWithName("Wagon1", recursively:false)
        let wagon2 = scene.rootNode.childNodeWithName("Wagon2", recursively:false)
        
        
        var min = SCNVector3Zero
        var max = SCNVector3Zero
        engineCar!.getBoundingBoxMin(&min, max: &max )
        
        var wmin = SCNVector3Zero
        var wmax = SCNVector3Zero
        wagon1!.getBoundingBoxMin(&wmin, max:&wmax)
        
        // Tie EngineCar & Wagon1
        var joint = SCNPhysicsBallSocketJoint(bodyA: engineCar!.physicsBody!, anchorA: SCNVector3Make(max.x, min.y, 0), bodyB: wagon1!.physicsBody!, anchorB: SCNVector3Make(wmin.x, wmin.y, 0))
        scene.physicsWorld.addBehavior(joint)
        
        // Wagon1 & Wagon2
        joint = SCNPhysicsBallSocketJoint(bodyA: wagon1!.physicsBody!, anchorA: SCNVector3Make(wmax.x + 0.1, wmin.y, 0), bodyB: wagon2!.physicsBody!, anchorB: SCNVector3Make(wmin.x - 0.1, wmin.y, 0))
        scene.physicsWorld.addBehavior(joint)
    }
    func setupVehicle(scene:SCNScene) -> SCNNode {
        
        let carScene = SCNScene(named: "rc_car")
        let chassisNode = carScene!.rootNode.childNodeWithName("rccarBody", recursively: false)
        
        // setup the chassis
        chassisNode!.position = SCNVector3Make(0, 10, 30)
        chassisNode!.rotation = SCNVector4Make(0, 1, 0, Float(M_PI))
        
        let body = SCNPhysicsBody.dynamicBody()
        body.allowsResting = false
        body.mass = 80
        body.restitution = 0.1
        body.friction = 0.5
        body.rollingFriction = 0
        
        chassisNode!.physicsBody = body
        scene.rootNode.addChildNode(chassisNode!)
        
        let pipeNode = chassisNode!.childNodeWithName("pipe", recursively:true)
        myReactor = SCNParticleSystem(named: "reactor", inDirectory: nil)
        
        myReactorDefaultBirthRate = myReactor.birthRate
        myReactor.birthRate = 0
        pipeNode!.addParticleSystem(myReactor)
        
        //add wheels
        let wheel0Node = chassisNode?.childNodeWithName("wheelLocator_FL", recursively: true)
        let wheel1Node = chassisNode?.childNodeWithName("wheelLocator_FR", recursively: true)
        let wheel2Node = chassisNode?.childNodeWithName("wheelLocator_RL", recursively: true)
        let wheel3Node = chassisNode?.childNodeWithName("wheelLocator_RR", recursively: true)

        let wheel0 = SCNPhysicsVehicleWheel(node: wheel0Node!)
        let wheel1 = SCNPhysicsVehicleWheel(node: wheel1Node!)
        let wheel2 = SCNPhysicsVehicleWheel(node: wheel2Node!)
        let wheel3 = SCNPhysicsVehicleWheel(node: wheel3Node!)

        var min = SCNVector3Zero
        var max = SCNVector3Zero
        
        wheel0Node!.getBoundingBoxMin(&min, max: &max)
       
        let wheelHalfWidth:CGFloat = 0.5 * CGFloat(max.x - min.x)
        
        wheel0.connectionPosition = SCNVector3FromFloat3(SCNVector3ToFloat3(wheel0Node!.convertPosition(SCNVector3Zero, toNode: chassisNode)) + vector_float3([Float(wheelHalfWidth), 0.0, 0.0]) )
        
        wheel1.connectionPosition = SCNVector3FromFloat3(SCNVector3ToFloat3(wheel1Node!.convertPosition(SCNVector3Zero, toNode: chassisNode)) - vector_float3([Float(wheelHalfWidth), 0.0, 0.0]) )
        wheel2.connectionPosition = SCNVector3FromFloat3(SCNVector3ToFloat3(wheel2Node!.convertPosition(SCNVector3Zero, toNode: chassisNode)) + vector_float3([Float(wheelHalfWidth), 0.0, 0.0]) )
        wheel3.connectionPosition = SCNVector3FromFloat3(SCNVector3ToFloat3(wheel3Node!.convertPosition(SCNVector3Zero, toNode: chassisNode)) - vector_float3([Float(wheelHalfWidth), 0.0, 0.0]) )
        
        // create the physics vehicle
        let vehicle = SCNPhysicsVehicle(chassisBody: chassisNode!.physicsBody!, wheels: [wheel0, wheel1, wheel2, wheel3])
        scene.physicsWorld.addBehavior(vehicle)
        
        myVehicle = vehicle
        return chassisNode!
    }
    func setupAccelerometer()  {

        let motionManager = CMMotionManager()
        
        let weakSelf = self
        
        if GCController.controllers().count == 0 && motionManager.accelerometerAvailable == true {
            motionManager.accelerometerUpdateInterval = 1/60.0
            motionManager.startAccelerometerUpdatesToQueue( NSOperationQueue.mainQueue(), withHandler: { (accelerometerData, error) in
                weakSelf.accelerometerDidChange(accelerometerData!.acceleration)
            })
        }
    }
    func accelerometerDidChange(acceleration: CMAcceleration) {

        let kFilteringFactor = 0.5
        
        //Use a basic low-pass filter to only keep the gravity in the accelerometer values
        accelerometer[0] = acceleration.x * kFilteringFactor + accelerometer[0] * (1.0 - kFilteringFactor);
        accelerometer[1] = acceleration.y * kFilteringFactor + accelerometer[1] * (1.0 - kFilteringFactor);
        accelerometer[2] = acceleration.z * kFilteringFactor + accelerometer[2] * (1.0 - kFilteringFactor);
        
        if accelerometer[0] > 0 { myOrientation = CGFloat(accelerometer[1]) * 1.3 }
        else { myOrientation = CGFloat(-accelerometer[1]) * 1.3 }
    }
    func handleDoubleTap(gesture:UITapGestureRecognizer) {
        
        let scene = setupScene()
        
        let scnView = self.view as! SCNView
        
        //present it
        scnView.scene = scene
        
        //tweak physics
        scnView.scene!.physicsWorld.speed = 4.0
        
        //initial point of view
        scnView.pointOfView = myCameraNode
        
        (scnView as! GameView).touchCount = 0
    }
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        
        let defaultEngineForce  :Float  = 300.0
        let defaultBrakingForce :Float  = 3.0
        let steeringClamp       :Float  = 0.6
        let cameraDamping       :Float  = 0.3
    
        let scnView: GameView = self.view as! GameView

        var engineForce     :CGFloat = 0
        var brakingForce    :CGFloat = 0
        
        let orientation     :Float = Float(myOrientation)
        
        //drive: 1 touch = accelerate, 2 touches = backward, 3 touches = brake
        if scnView.touchCount == 1 { engineForce = CGFloat(defaultEngineForce)
            myReactor.birthRate = myReactorDefaultBirthRate }
        else if scnView.touchCount == 2 { engineForce = CGFloat(-defaultEngineForce)
            myReactor.birthRate = 0  }
        else if scnView.touchCount == 3 { brakingForce = 100
            myReactor.birthRate = 0 }
        else {
            brakingForce = CGFloat(defaultBrakingForce)
            myReactor.birthRate = 0
        }

        myVehicleSteering = CGFloat(-orientation)
        if orientation == 0 { myVehicleSteering = myVehicleSteering * 0.9 }
        if myVehicleSteering < CGFloat(-steeringClamp) { myVehicleSteering = CGFloat(-steeringClamp) }
        if myVehicleSteering > CGFloat(steeringClamp) { myVehicleSteering = CGFloat(steeringClamp)}
        
        //update the vehicle steering and acceleration
        myVehicle.setSteeringAngle(myVehicleSteering, forWheelAtIndex: 0)
        myVehicle.setSteeringAngle(myVehicleSteering, forWheelAtIndex: 1)

        myVehicle.applyEngineForce(engineForce, forWheelAtIndex: 2)
        myVehicle.applyEngineForce(engineForce, forWheelAtIndex: 3)

        myVehicle.applyBrakingForce(brakingForce, forWheelAtIndex: 2)
        myVehicle.applyBrakingForce(brakingForce, forWheelAtIndex: 3)
        
        
        // make camera follow the car node
        let car = myVehicleNode.presentationNode
        let carPos = car.position

        let targetPos = vector_float3(carPos.x, 30.0, carPos.z + 25.0)
        var cameraPos = SCNVector3ToFloat3(myCameraNode.position)

        
        cameraPos = vector_mix(cameraPos, targetPos, (vector_float3)(cameraDamping))
        myCameraNode.position = SCNVector3FromFloat3(cameraPos)
        
        if (scnView.inCarView != nil) {
            //move spot light in front of the camera
            
            let frontPosition = scnView.pointOfView!.presentationNode.convertPosition(SCNVector3Make(0, 0, -30), toNode: nil)
            mySpotLightNode.position = SCNVector3Make(frontPosition.x, 80.0, frontPosition.z)
            mySpotLightNode.rotation = SCNVector4Make(1,0,0, Float(-M_PI/2))
        }
        else {
            //move spot light on top of the car
            mySpotLightNode.position = SCNVector3Make(carPos.x, 80.0, carPos.z + 30.0);
            mySpotLightNode.rotation = SCNVector4Make(1,0,0,Float(-M_PI/2.8))
        }
        
        //speed gauge
       let overlayScene = scnView.overlaySKScene as! OverlayScene
       overlayScene.mySpeedNeedle.zRotation = -(myVehicle.speedInKilometersPerHour * CGFloat(M_PI) / maxSpeed)
    }
}

