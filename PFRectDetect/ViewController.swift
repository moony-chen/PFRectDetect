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
    private var pointLayer: CAShapeLayer = CAShapeLayer()
    
    func setupVision() {
        let rectRequest = VNDetectRectanglesRequest(completionHandler: self.handleRectangles);
        rectRequest.minimumSize = 0.1
        rectRequest.maximumObservations = 20
        self.rectanglesRequest = [rectRequest]
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let rects = request.results as? [VNRectangleObservation] else {
                print("no rect")
                return
            }
            self.setup(shapeLayer: self.rectLayer, withRects: rects)
//            print("\(r.topLeft), \(r.topRight), \(r.bottomLeft), \(r.bottomRight)")
        }
    }

    
    func setup(shapeLayer: CAShapeLayer, withRects rects: [VNRectangleObservation]) {
        let size = self.view.bounds.size
        
        shapeLayer.frame = self.view.bounds
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = 10
        shapeLayer.strokeEnd = 1
        shapeLayer.strokeColor = UIColor.red.cgColor
        self.view.layer.addSublayer(shapeLayer)
        
        let path = UIBezierPath()
//        let bigrects = rects.filter(self.bigEnough)
        rects
            //.filter(self.bigEnough)
            .forEach { (ro) in
            path.append(drawOne(rect: ro, to: size))
        }

        
        shapeLayer.path = path.cgPath
    }
    
    func bigEnough(rect: VNRectangleObservation) -> Bool {
        let size = rect.boundingBox.size
        return size.width * size.height > 1/3
    }
    
    func drawOne(rect: VNRectangleObservation, to size: CGSize) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: rect.bottomLeft.scaled(to: size).flip(with: size.height)) //
        path.addLine(to: rect.topLeft.scaled(to: size).flip(with: size.height))
        path.addLine(to: rect.topRight.scaled(to: size).flip(with: size.height))
        path.addLine(to: rect.bottomRight.scaled(to: size).flip(with: size.height))
        path.close()
        return path
    }
    
    func setup(shapeLayer: CAShapeLayer, withPoints points: [vector_float3], on camera:ARCamera) {
        let size = self.view.bounds.size
        
        shapeLayer.frame = self.view.bounds
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = 2
        shapeLayer.strokeEnd = 1
        shapeLayer.strokeColor = UIColor.red.cgColor
        self.view.layer.addSublayer(shapeLayer)
        
        let path = UIBezierPath()
        
            for p in points {
                path.append( drawPoint(camera, p))
            }
        
        self.pointLayer.path = path.cgPath
        shapeLayer.path = path.cgPath
    }
    
    func drawPoint(_ ca:ARCamera, _ p: vector_float3) -> UIBezierPath {
        let result = UIBezierPath()
        let p2d = ca.projectPoint(p, orientation: UIInterfaceOrientation.portrait, viewportSize: self.view.bounds.size)
        
        result.addArc(withCenter: p2d, radius: 5, startAngle: 0, endAngle: CGFloat(2*Double.pi), clockwise: true)
        return result
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
        sceneView.debugOptions = [//ARSCNDebugOptions.showWorldOrigin,
                                  ARSCNDebugOptions.showFeaturePoints
        ]
//        sceneView.
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
        
        var requestOptions: [VNImageOption: Any] = [:]
//        if let cameraIntrinsicData = CMGetAttachment(frame.capturedImage, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
//            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
//        }
        
        let ca = frame.camera
        
        let cameraIntrisic = frame.camera.intrinsics
        requestOptions = [.cameraIntrinsics: cameraIntrisic]
//        print(cameraIntrisic)
        

        if let points = frame.rawFeaturePoints?.points {
            self.setup(shapeLayer: self.pointLayer, withPoints: points, on: ca)
        }

        
        
        // Run the rectangle detector, which upon completion runs the ML classifier.
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: CGImagePropertyOrientation.right, options: requestOptions)
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
