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
    
    private var obsFeaturePoints = Variable<[vector_float3]>([])
    private var obsARFrame = PublishSubject<ARFrame>()
    private var obsTap = PublishSubject<UITapGestureRecognizer>()
    private var obsTextRect = Variable<CGRect>(CGRect.zero)
    
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
//                o?.characterBoxes
                if let rect = o?.boundingBox {
                    return [rect]
                } else {
                    return []
                }
            }).reduce(CGRect.zero, { (result, rect) -> CGRect in
                return result.size.area() >= rect.size.area() ? result : rect
            }).flipNormalized()//.scaled(to: self.view.bounds.size)
 
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
        
        
        
        obsFeaturePoints.value = points
        
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
        
        let bounds = self.view.bounds
        let size = bounds.size
        let center = self.view.center
        
        let obs =
            Observable.combineLatest(
                Observable.zip(self.obsARFrame, self.obsTextRect.asObservable()){ ($0, $1) }
            , obsTap) {(ab, c) in (ab.0, ab.1, c)}
        .take(1)
//            .filter { (_, rect) -> Bool in
//                return bounds.contains(rect)
//            }.filter { (_, rect) -> Bool in
//                rect.contains(center)
//        }
        

        
        //        planeNode.rotation = SCNVector4(1, 0, 0, Float.pi/2)

        let dis = obs.subscribe(onNext: { (frame, rectN, tap) in
            let rect = rectN.scaled(to: size)
            
            
            let ciImage = CIImage(cvPixelBuffer:  frame.capturedImage)
//            let uiImage = UIImage(ciImage: ciImage, scale: 1, orientation: UIImageOrientation.right)
            
//            let snapshot = self.sceneView.snapshot()
//            let ciImage = CIImage(image: snapshot)!
            let snapRect = rectN.flipNormalized().scaled(to: ciImage.extent.size)
            let imageForOcr = self.prepareImageForOCR(image: ciImage, rect: snapRect, orientation: UIImageOrientation.right)
//
            let roomName = OCRService.sharedInstance.ocr(image: imageForOcr)
            print("roomName=\(String(describing: roomName))")
//
            
            if let points3d = frame.rawFeaturePoints?.points {
                let points2d = points3d.map({ p in
                    return (p, frame.camera.projectPoint(p, orientation: UIInterfaceOrientation.portrait, viewportSize: size))
                })
                
                let inpoints = points2d.filter({rect.contains($1)})
                
                self.drawPoints(inpoints.map({$1}), onRect: rect)
                
                let sv = self.sceneView!
                
                let imagePlane = SCNPlane(width: sv.bounds.width/6000, height: sv.bounds.height/6000)
                imagePlane.firstMaterial?.diffuse.contents = UIImage(named: "poster")
                imagePlane.firstMaterial?.isDoubleSided = true
                imagePlane.firstMaterial?.lightingModel = .constant
                
                let planeNode = SCNNode(geometry: imagePlane)
                sv.scene.rootNode.addChildNode(planeNode)
                
                inpoints.map({ (p3d, _) in
                    let ball = SCNSphere(radius: 0.001)
                    ball.firstMaterial?.diffuse.contents = UIColor(red: 0, green: 1, blue: 0, alpha: 0.9)
                    ball.firstMaterial?.lightingModel = .constant
                    let ballNode = SCNNode(geometry: ball)
                    ballNode.position = SCNVector3(p3d)
                    return ballNode
                }).forEach({ (node) in
                    sv.scene.rootNode.addChildNode(node)
                })
                
//                planeNode.position = SCNVector3(x: 0.0, y:0.1, z:0)
                
                
                
                
//                if  inpoints.count > 1 {
//                    let p1 = inpoints[0].0, p2 = inpoints[1].0
//                    planeNode.position = SCNVector3(p1)
//
//                    let theta = atan( (p2.z - p1.z)/(p2.x - p1.x))
//
//                    planeNode.rotation = SCNVector4(0, 1, 0, theta)
//                }
                if inpoints.count > 1 {
                    let p0 = inpoints.first?.0.y
                    let xs = inpoints.map({$0.0}).map({Double($0.x)})
                    let zs = inpoints.map({$0.0}).map({Double($0.z)})
                    let lineReg = linearRegression(xs, zs)
                    let avgx = average(xs)
                    planeNode.position = SCNVector3(x:Float(avgx), y: p0!-0.1, z: Float(lineReg(avgx)))
                    
                    let theta = atan( lineReg(1) - lineReg(0))
                    planeNode.rotation = SCNVector4(0, 1, 0, -theta)
                    
                }
                
                
//                print("rect: \(rect) - inpoint1: \(inpoints.count)")
            }
            
            
        })
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
    
    }
    

    
    @objc
    func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        
        obsTap.onNext(gestureRecognizer)
        
    }
    
    func prepareImage(image: UIImage) -> UIImage {
        var orientation: UIImageOrientation = .up
        orientation = image.imageOrientation
        let ciImage = CIImage(image: image)
        let updatedImage = ciImage?
            .applyingFilter("CIExposureAdjust", parameters: ["inputEV": 2])
            .applyingFilter("CIColorControls", parameters: ["inputContrast": 2])
            .applyingFilter("CIHighlightShadowAdjust", parameters: ["inputShadowAmount": 0])
        
        return UIImage(ciImage: updatedImage!, scale: 1, orientation: orientation)
    }

    func prepareImageForOCR(image: CIImage, rect: CGRect, orientation: UIImageOrientation) -> UIImage {
//        guard let ciImage = CIImage(image: image)
//            else { fatalError("can't create CIImage from UIImage") }
//        print("uiImage.imageOrientation=\(image.imageOrientation.rawValue)")
        let orientation = CGImagePropertyOrientation(orientation)
        print("orientation=\(orientation.rawValue)")
        let rect2 = rect.bigger()
        let inputImage = image.oriented(forExifOrientation: Int32(orientation.rawValue))

        // Rectify the detected image and reduce it to inverted grayscale for applying model.
//        let topLeft = detectedRectangle.topLeft.scaled(to: imageSize)
//        let topRight = detectedRectangle.topRight.scaled(to: imageSize)
//        let bottomLeft = detectedRectangle.bottomLeft.scaled(to: imageSize)
//        let bottomRight = detectedRectangle.bottomRight.scaled(to: imageSize)
        let correctedImage = inputImage
            .cropped(to: rect2)
//            .applyingFilter("CIPerspectiveCorrection", parameters: [
//                "inputTopLeft": CIVector(cgPoint: topLeft),
//                "inputTopRight": CIVector(cgPoint: topRight),
//                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
//                "inputBottomRight": CIVector(cgPoint: bottomRight)
//                ])
            .applyingFilter("CIExposureAdjust", parameters: ["inputEV": 2])
            .applyingFilter("CIColorControls", parameters: ["inputContrast": 2])
            .applyingFilter("CIHighlightShadowAdjust", parameters: ["inputShadowAmount": 0])
//            .applyingFilter("CIColorInvert", parameters: [:])
        
        let context = CIContext(options:nil)
        let cgimg = context.createCGImage(correctedImage, from: correctedImage.extent)

        return UIImage(cgImage: cgimg!)


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
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin
//            ,ARSCNDebugOptions.showFeaturePoints
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
        
        obsARFrame.onNext(frame)

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
