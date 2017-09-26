//
//  ViewController.swift
//  PFRectDetect
//
//  Created by Moony Chen on 26/09/2017.
//  Copyright © 2017 Moony Chen. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private var rectanglesRequest = [VNRequest]()
    
    private var rectLayer: CAShapeLayer = CAShapeLayer()
    
    func setupVision() {
        let rectRequest = VNDetectRectanglesRequest(completionHandler: self.handleRectangles);
        rectRequest.minimumSize = 0.1
        rectRequest.maximumObservations = 20
        self.rectanglesRequest = [rectRequest]
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let rects = request.results as? [VNRectangleObservation], let r = rects.first else {
                print("no rect")
                return
            }
            self.setup(shapeLayer: self.rectLayer, with: r)
            print("\(r.topLeft), \(r.topRight), \(r.bottomLeft), \(r.bottomRight)")
        }
    }
    
    func setup(shapeLayer: CAShapeLayer, with rect: VNRectangleObservation) {
        let size = self.view.bounds.size
        
        shapeLayer.frame = self.view.bounds
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = 10
        shapeLayer.strokeEnd = 1
        shapeLayer.strokeColor = UIColor.red.cgColor
        self.view.layer.addSublayer(shapeLayer)
        
        
        
        let path = UIBezierPath()
        path.move(to: rect.bottomLeft.scaled(to: size).flip(with: size.height))
        path.addLine(to: rect.topLeft.scaled(to: size).flip(with: size.height))
        path.addLine(to: rect.topRight.scaled(to: size).flip(with: size.height))
        path.addLine(to: rect.bottomRight.scaled(to: size).flip(with: size.height))

        path.close()
        shapeLayer.path = path.cgPath
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        
        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//
//        // Set the scene to the view
//        sceneView.scene = scene
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        sceneView.session.delegate = self
        // Run the view's session
        sceneView.session.run(configuration)
        
        
        setupVision()
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
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        //frame.camera.ori
        print("didUpdate frame")
        
        // Run the rectangle detector, which upon completion runs the ML classifier.
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: CGImagePropertyOrientation.up, options: [:])
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform(self.rectanglesRequest)
            } catch {
                print(error)
            }
        }
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
    
    
}
