//
//  PFRectDetectTests.swift
//  PFRectDetectTests
//
//  Created by Moony Chen on 26/09/2017.
//  Copyright © 2017 Moony Chen. All rights reserved.
//

import XCTest
@testable import PFRectDetect

class PFRectDetectTests: XCTestCase {
    
    var ocrService: OCRService?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        ocrService = OCRService()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOCR() {
        let image = UIImage(named:"Lenore", in: Bundle(for: PFRectDetectTests.self), compatibleWith: nil)
        let text = ocrService?.ocr(image: scaleImage(image: image!, maxDimension: 640)!)
        XCTAssert((text?.starts(with: "Lenore"))!)
    }
    
    func testStickyNote() {
        let image = UIImage(named:"3", in: Bundle(for: PFRectDetectTests.self), compatibleWith: nil)
        let text = ocrService?.ocr(image: image!)
        XCTAssertEqual("3", text)
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
