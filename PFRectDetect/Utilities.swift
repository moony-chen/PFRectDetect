/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Core Graphics utility extensions used in the sample code.
*/

import UIKit
import CoreGraphics
import ImageIO

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
    
    func flip(with height: CGFloat) -> CGPoint {
        return CGPoint(x: self.x, y: height - self.y)
    }
    
    func moveX(_ delta: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + delta, y: self.y)
    }
    
    func moveY(_ delta: CGFloat) -> CGPoint {
        return CGPoint(x: self.x, y: self.y + delta)
    }
}
extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImageOrientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

