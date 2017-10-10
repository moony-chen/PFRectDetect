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
    
    func flipNormalized() -> CGPoint {
        return self.flip(with: 1)
    }
    
    func moveX(_ delta: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + delta, y: self.y)
    }
    
    func moveY(_ delta: CGFloat) -> CGPoint {
        return CGPoint(x: self.x, y: self.y + delta)
    }
    
    func toBezierPath() -> UIBezierPath {
        let result = UIBezierPath()
        result.addArc(withCenter: self, radius: 5, startAngle: 0, endAngle: CGFloat(2*Double.pi), clockwise: true)
        return result
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
    
    func flipNormalized() -> CGRect {
        var o = self.origin
        o = o.flipNormalized()
        o.y = o.y - self.size.height
        return CGRect(origin: o, size: self.size)
    }
    
    func toBezierPath() -> UIBezierPath {
        let path = UIBezierPath()
        let box = self
        let p = box.origin
        path.move(to: p) //
        path.addLine(to: p.moveY(box.height))
        path.addLine(to: p.moveY(box.height).moveX(box.width))
        path.addLine(to: p.moveX(box.width))
        path.close()
        return path
    }
    
}

extension CGSize {
    func area() -> CGFloat {
        return self.width * self.height
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

func average(_ input: [Double]) -> Double {
    return input.reduce(0, +) / Double(input.count)
}

func multiply(_ a: [Double], _ b: [Double]) -> [Double] {
    return zip(a, b).map(*)
}

func linearRegression(_ xs: [Double], _ ys: [Double]) -> (Double) -> Double {
    let sum1 = average(multiply(xs, ys)) - average(xs) * average(ys)
    let sum2 = average(multiply(xs, xs)) - pow(average(xs), 2)
    let slope = sum1 / sum2
    let intercept = average(ys) - slope * average(xs)
    return { x in intercept + slope * x }
}

func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage? {
    
    var scaledSize = CGSize(width: maxDimension, height: maxDimension)
    var scaleFactor: CGFloat
    
    if image.size.width > image.size.height {
        scaleFactor = image.size.height / image.size.width
        scaledSize.width = maxDimension
        scaledSize.height = scaledSize.width * scaleFactor
    } else {
        scaleFactor = image.size.width / image.size.height
        scaledSize.height = maxDimension
        scaledSize.width = scaledSize.height * scaleFactor
    }
    
    UIGraphicsBeginImageContext(scaledSize)
    image.draw(in: CGRect(x:0, y:0, width:scaledSize.width, height:scaledSize.height))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return scaledImage
}

