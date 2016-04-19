//
//  Copyright for portions of ASCIIfy are held by Barış Koç, 2014 as part of
//  project BKAsciiImage and Amy Dyer, 2012 as part of project Ascii. All other copyright
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

#if os(OSX)
    public typealias Font = NSFont
    public typealias Image = NSImage
    public typealias Color = NSColor
#elseif os(iOS)
    import UIKit
    public typealias Font = UIFont
    public typealias Image = UIImage
    public typealias Color = UIColor
#endif

public typealias ImageHandler = ((Image) -> Void)?
public typealias StringHandler = ((String) -> Void)?

public class ASCIIConverter {
    var definition = ASCIILookUpTable()
    public var font = Font.systemFontOfSize(defaultFontSize)
    public var backgroundColor = Color.clearColor()
    var columns = 0
    public var reversedLuminance = true
    public var colorMode = ColorMode.Color
    private var gridWidth: CGFloat = 0.0

    static let defaultFontSize: CGFloat = 10.0

    public enum ColorMode {
        case BlackAndWhite,
        GrayScale,
        Color
    }

    public init() {
    }

    public init(luminanceToStringMapping: [Double: String]) {
        definition = ASCIILookUpTable(luminanceToStringMapping: luminanceToStringMapping)
    }

    public init(definition: ASCIILookUpTable) {
        self.definition = definition
    }

    func isTransparent() -> Bool {
        return backgroundColor == Color.clearColor()
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



public extension ASCIIConverter {

    func convertImage(input: Image, completionHandler handler: ImageHandler) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let gridWidth = self.gridWidth(input.size.width)
            let output = self.convertImage(input, withFont: self.font, bgColor: self.backgroundColor, columns: gridWidth, reversed: self.reversedLuminance, colorMode: self.colorMode)
            dispatch_async(dispatch_get_main_queue()) { handler?(output) }
        }
    }

    func convertToString(input: Image, completionHandler handler: StringHandler) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let output = self.convertToString(input)
            dispatch_async(dispatch_get_main_queue(), { handler?(output) })
        })
    }

    func convertImage(input: Image) -> Image {
        let gridWidth = self.gridWidth(input.size.width)
        let output = convertImage(input, withFont: font, bgColor: backgroundColor, columns: gridWidth, reversed: reversedLuminance, colorMode: colorMode)
        return output
    }

    func convertImage(input: Image, withFont font: Font, bgColor: Color, columns: Int, reversed: Bool, colorMode: ColorMode) -> Image {
        let opaque = !isTransparent()
        _ = font.pointSize
        let gridWidth = columns
        let scaledImage = downscaleImage(input, withFactor: gridWidth)
        let pixelGrid = pixelGridForImage(scaledImage)
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

        let blockWidth = input.size.width / CGFloat(pixelGrid.width)
        let blockHeight = input.size.height / CGFloat(pixelGrid.height)
        var attributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: Color.blackColor()]
        for row in 0..<pixelGrid.height {
            for col in 0..<pixelGrid.width {
                let block = pixelGrid.block(atRow: row, column: col)
                let luminance = self.luminance(block)
                let ASCIIResult = definition.stringForLuminance(Double(luminance))!
                let rect = CGRect(x: blockWidth * CGFloat(col), y: blockHeight * CGFloat(row), width: blockWidth, height: blockHeight)

                if colorMode == .Color {
                    let color = Color(red: CGFloat(block.r), green: CGFloat(block.g), blue: CGFloat(block.b), alpha: 1.0)
                     attributes[NSForegroundColorAttributeName] = color
                } else if colorMode == .GrayScale {
                    let color = Color(white: luminance, alpha: 1.0)
                    attributes[NSForegroundColorAttributeName] = color
                }
                ASCIIResult.drawWithRect(rect, options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
            }
        }
        let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return renderedImage
    }

    func convertToString(input: Image) -> String {
        let gridWidth = self.gridWidth(input.size.width)
        let scaledImage = downscaleImage(input, withFactor: gridWidth)
        let pixelGrid = pixelGridForImage(scaledImage)
        let str = NSMutableString(string: "")
        for row in 0..<pixelGrid.height {
            for col in 0..<pixelGrid.width {
                let block = pixelGrid.block(atRow: row, column: col)
                let luminance = self.luminance(block)
                let ASCII = definition.stringForLuminance(Double(luminance))
                str.appendString(ASCII!)
                str.appendString(" ")
            }
            str.appendString("\n")
        }
        return String(str)
    }

    private func pixelGridForImage(image: Image) -> BlockGrid {
        let imageRef = image.CGImage!
        let width = CGImageGetWidth(imageRef)
        let height = CGImageGetHeight(imageRef)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawData = UnsafeMutablePointer<UInt8>(malloc(height * width * 4))
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue)
        let context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue)
        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: width, height: height), imageRef)
        let grid = BlockGrid(width: width, height: height)
        for row in 0..<height {
            for col in 0..<width {
                let byteIndex = (bytesPerRow * row) + col * bytesPerPixel
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

    private func downscaleImage(image: Image, withFactor scaleFactor: Int) -> Image {
        var scaleFactor = CGFloat(scaleFactor)
        if scaleFactor <= 1 {
            return image
        }
        if scaleFactor > min(image.size.height, image.size.width) {
            scaleFactor = min(image.size.height, image.size.width)
        }
        let ratio = scaleFactor / image.size.width
        let newWidth = scaleFactor
        let newHeight = ratio * image.size.height
        let size = CGSize(width: newWidth, height: newHeight)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.drawInRect(CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}
