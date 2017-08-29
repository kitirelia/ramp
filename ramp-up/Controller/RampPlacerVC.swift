//
//  ViewController.swift
//  ramp-up
//
//  Created by kitiwat chanluthin on 8/29/17.
//  Copyright © 2017 kitiwat chanluthin. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class RampPlacerVC: UIViewController, ARSCNViewDelegate,UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var control: UIStackView!
    @IBOutlet var sceneView: ARSCNView!
    var selectedRampName:String?
    @IBOutlet weak var rotateBtn: UIButton!
    @IBOutlet weak var downBtn: UIButton!
    @IBOutlet weak var upBtn: UIButton!
    var selectedRamp:SCNNode?
    
    var rampArray = [SCNNode]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/main.scn")!
        sceneView.automaticallyUpdatesLighting = true
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let gesture1 = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressed(gesture:)))
        let gesture2 = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressed(gesture:)))
        let gesture3 = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressed(gesture:)))
        
        gesture1.minimumPressDuration = 0.1
        gesture2.minimumPressDuration = 0.1
        gesture3.minimumPressDuration = 0.1
        
        rotateBtn.addGestureRecognizer(gesture1)
        upBtn.addGestureRecognizer(gesture2)
        downBtn.addGestureRecognizer(gesture3)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}

            //let planAnchor = anchor as! ARPlaneAnchor
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeNode = SCNNode()
            planeNode.position = SCNVector3(x:planeAnchor.center.x,y:0,z:planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)

            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named:"art.scnassets/textures/grid.png")
            plane.materials = [gridMaterial]
            planeNode.geometry = plane
            node.addChildNode(planeNode)


    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    //MARK : - ARSCNViewDelegateMethod
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard  let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: sceneView)
        
        let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
       
        if let hitResult = results.first{
            addSingleRamp(atLocation: hitResult)
        }
        
        // Dev Slopes
//        let results = sceneView.hitTest(touch.location(in: sceneView), types: [.featurePoint])
//
//        guard let hitFeature = results.last else { return }
//
//        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
//        let hitPositon = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
//        placeRamp(position: hitPositon)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    
    @IBAction func rampBtnPressed(_ sender: UIButton) {
        
        let rampPickerVC = RampPickerVC(size: CGSize(width: 250, height: 500))
        rampPickerVC.rampPlacerVC = self
        rampPickerVC.modalPresentationStyle = .popover
        rampPickerVC.popoverPresentationController?.delegate = self
        present(rampPickerVC, animated: true, completion: nil)
        rampPickerVC.popoverPresentationController?.sourceView = sender
        rampPickerVC.popoverPresentationController?.sourceRect = sender.bounds
    }
    
    func onRampSelected(rampName:String){
        selectedRampName = rampName
    }
    
    func placeRamp(position:SCNVector3){
        if let rampName = selectedRampName{
            control.isHidden = false
            let ramp = Ramp.getRampForName(rampName: rampName)
            selectedRamp = ramp
            ramp.position = position
            ramp.scale = SCNVector3Make(0.01, 0.01, 0.01)
            sceneView.scene.rootNode.addChildNode(ramp)
        }
        
    }
    
    @IBAction func removeBtnPressed(_ sender: Any) {
        if let ramp = selectedRamp{
            ramp.removeFromParentNode()
            selectedRamp = nil
        }
    }
   
    
    @objc func onLongPressed(gesture:UILongPressGestureRecognizer){
        if let ramp = selectedRamp{
            if gesture.state == .ended{
                ramp.removeAllActions()
            }else if gesture.state == .began{
                if gesture.view === rotateBtn{
                    let rotate = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat(0.08 * Double.pi), z: 0, duration: 0.1))
                    ramp.runAction(rotate!)
                }else if gesture.view === upBtn{
                    let move = SCNAction.repeatForever(SCNAction.moveBy(x: 0, y: 0.08, z: 0, duration: 0.1))
                    ramp.runAction(move!)
                }else if gesture.view === downBtn{
                    let move = SCNAction.repeatForever(SCNAction.moveBy(x: 0, y: -0.08, z: 0, duration: 0.1))
                    ramp.runAction(move!)
                }
            }
        }
    }
    
    
    func addSingleRamp(atLocation location : ARHitTestResult){
        let ramp = Ramp.getSmallPipe()
        ramp.position = SCNVector3(
            x:location.worldTransform.columns.3.x,
            y:location.worldTransform.columns.3.y,
            z:location.worldTransform.columns.3.z
        )
        rampArray.append(ramp)
        sceneView.scene.rootNode.addChildNode(ramp)
        
    }
    
    @IBAction func clearBtnPressed(_ sender: Any) {
        
        if !rampArray.isEmpty{
            for ramp in rampArray{
                ramp.removeFromParentNode()
            }
        }
        
    }
    
}
