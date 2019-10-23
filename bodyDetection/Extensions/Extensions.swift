//
//  Extensions.swift
//  bodyDetection
//
//  Created by Andressa Valengo on 22/10/19.
//  Copyright © 2019 Andressa Valengo. All rights reserved.
//

import Foundation
import UIKit
import VideoToolbox

extension CGImage {
    func colors(at: [CGPoint]) -> [UIColor]? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
            let ptr = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return nil
        }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return at.map { p in
            let i = bytesPerRow * Int(p.y) + bytesPerPixel * Int(p.x)

            let a = CGFloat(ptr[i + 3]) / 255.0
            let r = (CGFloat(ptr[i]) / a) / 255.0
            let g = (CGFloat(ptr[i + 1]) / a) / 255.0
            let b = (CGFloat(ptr[i + 2]) / a) / 255.0

            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
    }
}

extension UIImage {
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }

        return self
    }
}

extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        if let cgImage = cgImage {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
}

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
}
