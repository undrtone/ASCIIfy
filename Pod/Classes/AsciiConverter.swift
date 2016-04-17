//
//  Copyright for portions of ASCIIfy are held by Barış Koç, 2014 as part of
//  project BKAsciiImage and Amy Dyer, 2012 as part of project ASCII. All other copyright
//  for ASCIIfy are held by Nick Walker, 2016.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
import Foundation
import UIKit

let defaultFontSize: CGFloat = 10.0

public class AsciiConverter {
    var definition = AsciiDefinition()
    var font = UIFont.systemFontOfSize(defaultFontSize)
    var backgroundColor: UIColor = .clearColor()
    var columns: Int = 0
    var reversedLuminance: Bool = true
    var grayscale: Bool = false
    private var gridWidth: CGFloat = 0.0


    public init() {
        
    }

    public init(luminanceToStringMapping: [Double: String]) {
        definition = AsciiDefinition(luminanceToStringMapping: luminanceToStringMapping)
    }

    public init(definition: AsciiDefinition) {
        self.definition = definition
    }

    func isTransparent() -> Bool {
        return backgroundColor == UIColor.clearColor()
    }

    private func gridWidth(width: CGFloat) -> Int {
        if self.columns == 0 {
            return Int(width / font.pointSize)
        } else {
            return columns
        }
    }

    private func luminance(block: BlockGrid.Block) -> CGFloat {
        var result = 0.2126 * block.r + 0.7152 * block.g + 0.0722 * block.b
        if reversedLuminance {
            result = (1.0 - result)
        }
        return CGFloat(result)
    }
}

#if os(iOS)
public extension AsciiConverter {
    func convertImage(input: UIImage) -> UIImage {
        var asciiGridWidth = gridWidth(input.size.width)
        var output = convertImage(input, withFont: font, bgColor: backgroundColor, columns: asciiGridWidth, reversed: reversedLuminance, grayscale: grayscale)
        return output
    }

    func convertImage(input: UIImage, completionHandler handler: (UIImage) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var asciiGridWidth = self.gridWidth(input.size.width)
            var output = self.convertImage(input, withFont: self.font, bgColor: self.backgroundColor, columns: asciiGridWidth, reversed: self.reversedLuminance, grayscale: self.grayscale)
            dispatch_async(dispatch_get_main_queue()) { handler(output) }
        }
    }

    func convertImage(input: UIImage, withFont font: UIFont, bgColor: UIColor, columns: Int, reversed: Bool, grayscale: Bool) -> UIImage {

        let opaque = !isTransparent()
        let fontSize = font.pointSize
        var asciiGridWidth = columns
        var scaledImage = downscaleImage(input, withFactor: asciiGridWidth)
        var pixelGrid = pixelGridForImage(scaledImage)
        UIGraphicsBeginImageContextWithOptions(input.size, false, 0.0)

        // Setup background
        let ctx = UIGraphicsGetCurrentContext()
        let ctxRect = CGRect(x: 0, y: 0, width: input.size.width, height: input.size.height)
        if opaque {
            CGContextSetFillColorWithColor(ctx, bgColor.CGColor)
            CGContextFillRect(ctx, ctxRect)
        } else {
            CGContextClearRect(ctx, ctxRect)
        }

        var blockWidth = input.size.width / CGFloat(pixelGrid.width)
        var blockHeight = input.size.height / CGFloat(pixelGrid.height)
        let attributes = [NSFontAttributeName: font]
        for row in 0..<pixelGrid.height {
            for col in 0..<pixelGrid.width {
                var block = pixelGrid.block(atRow: row, column: col)
                var luminance = self.luminance(block)
                var asciiResult = definition.stringForLuminance(Double(luminance))!
                var rect = CGRect(x: blockWidth * CGFloat(col), y: blockHeight * CGFloat(row), width: blockWidth, height: blockHeight)
                if !grayscale || true {
                    let color = UIColor(red: CGFloat(block.r), green: CGFloat(block.g), blue: CGFloat(block.b), alpha: 1.0)
                     CGContextSetFillColorWithColor(ctx, color.CGColor)
                } else {
                    let color = UIColor(white: luminance, alpha: 1.0)
                    CGContextSetFillColorWithColor(ctx, color.CGColor)
                }


                asciiResult.drawWithRect(rect, options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)

            }
        }
        let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return renderedImage
    }


    func convertToString(input: UIImage) -> String {
        var asciiGridWidth = gridWidth(input.size.width)
        var scaledImage = downscaleImage(input, withFactor: asciiGridWidth)
        var pixelGrid = pixelGridForImage(scaledImage)
        var str = NSMutableString(string: "")
        for var y = 0; y < pixelGrid.height; y++ {
            for var x = 0; x < pixelGrid.width; x++ {
                var col = x
                var row = y
                var block = pixelGrid.block(atRow: row, column: col)
                var luminance = self.luminance(block)
                var ascii = definition.stringForLuminance(Double(luminance))
                str.appendString(ascii!)
                str.appendString(" ")
            }
            str.appendString("\n")
        }
        return String(str)
    }


    func convertToString(input: UIImage, completionHandler handler: (String) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var output = self.convertToString(input)
            dispatch_async(dispatch_get_main_queue(), { handler(output) })
        })
    }

    private func pixelGridForImage(image: UIImage) -> BlockGrid {
        var imageRef = image.CGImage!
        var width = CGImageGetWidth(imageRef)
        var height = CGImageGetHeight(imageRef)
        var colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = UnsafeMutablePointer<UInt8>(malloc(height * width * 4))
        var bytesPerPixel = 4
        var bytesPerRow = bytesPerPixel * width
        var bitsPerComponent = 8

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue)
        var context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue)
        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: width, height: height), imageRef)
        var grid = BlockGrid(width: width, height: height)
        var block: BlockGrid.Block
        for var row = 0; row < height; row++ {
            for var col = 0; col < width; col++ {
                var byteIndex = (bytesPerRow * col) + row * bytesPerPixel
                let r = Double(rawData[byteIndex]) / 255.0
                let g = Double(rawData[byteIndex + 1]) / 255.0
                let b = Double(rawData[byteIndex + 2]) / 255.0
                let a = Double(rawData[byteIndex + 3]) / 255.0
                grid.copy(BlockGrid.Block(r: r, g: g, b: b, a: a), toRow: row, column: col)
            }
        }
        free(rawData)
        return grid
    }

    private func downscaleImage(image: UIImage, withFactor scaleFactor: Int) -> UIImage {
        var scaleFactor = CGFloat(scaleFactor)
        if scaleFactor <= 1 {
            return image
        }
        if scaleFactor > min(image.size.height, image.size.width) {
            scaleFactor = min(image.size.height, image.size.width)
        }
        var ratio = scaleFactor / image.size.width
        var newWidth = scaleFactor
        var newHeight = ratio * image.size.height
        var size = CGSize(width: newWidth, height: newHeight)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.drawInRect(CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        var scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}
    #endif
