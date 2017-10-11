//
//  OCRService.swift
//  PFRectDetect
//
//  Created by Moony Chen on 10/10/2017.
//  Copyright © 2017 Moony Chen. All rights reserved.
//

import Foundation
import TesseractOCR

class OCRService : NSObject {
    
    static let sharedInstance = OCRService()
    
    
//    let queue = OperationQueue()
    
    func ocr(image: UIImage) -> String? {
        
//        let ciImage = CIImage(cgImage: image.cgImage!)
        
//        let orientation = CGImagePropertyOrientation(image.imageOrientation)
//        print("orientation=\(orientation.rawValue)")
//        let inputImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))

        
        let tesseract:G8Tesseract = G8Tesseract(language:"eng");
        tesseract.engineMode = .tesseractCubeCombined
        // 4
        tesseract.pageSegmentationMode = .auto
        // 5
        tesseract.maximumRecognitionTime = 2
        //tesseract.language = "eng+ita";
        tesseract.charWhitelist = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUWXYZ0123456789";
        tesseract.image = image.g8_blackAndWhite();
        if tesseract.recognize() {
            return tesseract.recognizedText
        }
        return nil
    }
}
