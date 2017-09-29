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
#if !RX_NO_MODULE
    import RxSwift
#endif

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private var rectanglesRequest = [VNRequest]()
    
    private var rectLayer: CAShapeLayer = CAShapeLayer()
    private var pointLayer: CAShapeLayer = CAShapeLayer()
    
    private var pointsInRectLayer: CAShapeLayer = CAShapeLayer()
    
    private var obsFeaturePoints: Variable<[CGPoint]> = Variable<[CGPoint]>([])
    private var obsTextRect: Variable<CGRect> = Variable<CGRect>(CGRect.zero)
    
    func setupVision() {
        
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.handleRectangles);
        textRequest.reportCharacterBoxes = true
        self.rectanglesRequest = [textRequest]
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }
        
        let result = observations.map({$0 as? VNTextObservation})
            

        
        DispatchQueue.main.async {
            
            self.obsTextRect.value = result.flatMap({ o -> [CGRect] in
                if let rect = o?.boundingBox {
                    return [rect]
                } else {
                    return []
                }
            }).reduce(CGRect.zero, { (result, rect) -> CGRect in
                return result.size.area() >= rect.size.area() ? result : rect
            }).flipNormalized().scaled(to: self.view.bounds.size)
 
            self.setup(shapeLayer: self.rectLayer, withRects: result)
//            print("\(r.topLeft), \(r.topRight), \(r.bottomLeft), \(r.bottomRight)")
        }
    }

    
    func setup(shapeLayer: CAShapeLayer, withRects rects: [VNTextObservation?]) {
        let size = self.view.bounds.size
        

        
        let path = UIBezierPath()
//        let bigrects = rects.filter(self.bigEnough)
        rects
            //.filter(self.bigEnough)
            .forEach { (ro) in
                if let to = ro {
                    path.append(drawOne(rect: to, to: size))
                }
            
        }

        
        shapeLayer.path = path.cgPath
    }
    
    func bigEnough(rect: VNRectangleObservation) -> Bool {
        let size = rect.boundingBox.size
        return size.width * size.height > 1/3
    }
    
    func drawOne(rect: VNTextObservation, to size: CGSize) -> UIBezierPath {
        
        return rect.boundingBox.flipNormalized().scaled(to: size).toBezierPath()
        
    }
    
    func setup(shapeLayer: CAShapeLayer, withPoints points: [vector_float3], on camera:ARCamera) {


        
        let path = UIBezierPath()
        
        let p2d = points.map { p in
            camera.projectPoint(p, orientation: UIInterfaceOrientation.portrait, viewportSize: self.view.bounds.size)
        }
        
        obsFeaturePoints.value = p2d
        
        for p in points {
            path.append( drawPoint(camera, p))
        }
        
        self.pointLayer.path = path.cgPath
        shapeLayer.path = path.cgPath
    }

    
    func drawPoint(_ ca:ARCamera, _ p: vector_float3) -> UIBezierPath {
        let p2d = ca.projectPoint(p, orientation: UIInterfaceOrientation.portrait, viewportSize: self.view.bounds.size)
        return p2d.toBezierPath()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        
        rectLayer.frame = self.view.bounds
        rectLayer.fillColor = nil
        rectLayer.lineWidth = 10
        rectLayer.strokeEnd = 1
        rectLayer.strokeColor = UIColor.red.cgColor
        self.view.layer.addSublayer(rectLayer)
        
        pointLayer.frame = self.view.bounds
        pointLayer.fillColor = nil
        pointLayer.lineWidth = 2
        pointLayer.strokeEnd = 1
        pointLayer.strokeColor = UIColor.red.cgColor
        self.view.layer.addSublayer(pointLayer)
        
        pointsInRectLayer.frame = self.view.bounds
        pointsInRectLayer.fillColor = nil
        pointsInRectLayer.lineWidth = 1
        pointsInRectLayer.strokeEnd = 1
        pointsInRectLayer.strokeColor = UIColor.green.cgColor
        self.view.layer.addSublayer(pointsInRectLayer)
        
        
        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//
//        // Set the scene to the view
//        sceneView.scene = scene
        
        let obs = Observable.combineLatest(self.obsFeaturePoints.asObservable(), self.obsTextRect.asObservable()){ ($0, $1) }
        let dis = obs.subscribe(onNext: { (points, rect) in
            let inpoints = points.filter({rect.contains($0)})
            self.drawPoints(inpoints, onRect: rect)
//            print("rect: \(rect) - inpoint1: \(inpoints)")
        })
    
    }
    
    func drawPoints(_ points: [CGPoint], onRect rect: CGRect) {
        
        let result = UIBezierPath()
        points.forEach { (p) in
            result.append(p.toBezierPath())
        }
        result.append(rect.toBezierPath())
        
        self.pointsInRectLayer.path = result.cgPath
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        sceneView.session.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin,
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
