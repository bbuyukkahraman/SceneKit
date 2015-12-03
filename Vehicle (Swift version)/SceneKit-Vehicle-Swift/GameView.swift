import SpriteKit
import UIKit
import SceneKit

class GameView : SCNView {
    
    var touchCount  : Int = 0
    var inCarView   : Bool!
    
    func changePointOfView() {
        
        // retrieve the list of point of views
        let pointOfViews : NSArray = (scene?.rootNode.childNodesPassingTest({ (child, stop) -> Bool in
            return child.name != nil
        }))!
        
        let currentPointOfView = pointOfViews
        
        // select the next one
        var index:Int = pointOfViews.indexOfObject(currentPointOfView)
        index++
        if index >= pointOfViews.count { index = 0 }
        
        self.inCarView = (index == 0)
        
        // set it with an implicit transaction
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(0.75)
        pointOfView = pointOfViews.objectAtIndex(index) as? SCNNode
        SCNTransaction.commit()
    }    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touch = touches.first
        
        //test if we hit the camera button
        let scene = self.overlaySKScene
        var p = touch!.locationInView(self)
        
        p = scene!.convertPointFromView(p)
        let node = scene!.nodeAtPoint(p)
        
        if node.name == "camera" {
            //play a sound
            node.runAction(SKAction.playSoundFileNamed("click.caf", waitForCompletion: false))
            
            //change the point of view
            changePointOfView()
            return
        }
        
        //update the total number of touches on screen
        let allTouches = event!.allTouches()
        touchCount = allTouches!.count
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touchCount = 0
    }
}