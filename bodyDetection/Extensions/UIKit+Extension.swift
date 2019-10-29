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

extension UIImage {
    func resizedImage(newSize: CGSize) -> UIImage? {
        guard self.size != newSize else { return self }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func resizedImageWithinRect(rectSize: CGSize) -> UIImage? {
        let widthFactor = size.width / rectSize.width
        let heightFactor = size.height / rectSize.height
        
        var resizeFactor = widthFactor
        if size.height > size.width {
            resizeFactor = heightFactor
        }
        
        let newSize = CGSize(width: size.width/resizeFactor, height: size.height/resizeFactor)
        let resized = resizedImage(newSize: newSize)
        return resized
    }
    
    func resizedImageWithAspectFill(for rectSize: CGSize) -> UIImage? {
        let newWidth: CGFloat = rectSize.width / size.width
        let newHeight: CGFloat = rectSize.height / size.height
        var aspectFillSize = CGSize(width: rectSize.width, height: rectSize.height)

        if newHeight > newWidth {
            aspectFillSize.width = newHeight * size.width
        } else if newWidth > newHeight {
            aspectFillSize.height = newWidth * size.height
        }
        return resizedImage(newSize: aspectFillSize)
    }
}

extension UIImageView {
    var aspectFitSize: CGSize {
        guard let image = image else { return CGSize.zero }

        var aspectFitSize = CGSize(width: frame.size.width, height: frame.size.height)
        let newWidth: CGFloat = frame.size.width / image.size.width
        let newHeight: CGFloat = frame.size.height / image.size.height

        if newHeight < newWidth {
            aspectFitSize.width = newHeight * image.size.width
        } else if newWidth < newHeight {
            aspectFitSize.height = newWidth * image.size.height
        }

        return aspectFitSize
    }
    
    var aspectFillSize: CGSize {
         guard let image = image else { return CGSize.zero }

         var aspectFillSize = CGSize(width: frame.size.width, height: frame.size.height)
         let newWidth: CGFloat = frame.size.width / image.size.width
         let newHeight: CGFloat = frame.size.height / image.size.height

         if newHeight > newWidth {
             aspectFillSize.width = newHeight * image.size.width
         } else if newWidth > newHeight {
             aspectFillSize.height = newWidth * image.size.height
         }

         return aspectFillSize
     }
}
