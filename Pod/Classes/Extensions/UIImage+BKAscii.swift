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

#if os(iOS)
import UIKit

public typealias ImageHandler = ((UIImage) -> Void)?
public typealias StringHandler = ((String) -> Void)?

public extension UIImage {
    func bk_asciiImage() -> UIImage {
        let converter = AsciiConverter()
        return converter.convertImage(self)
    }

    func bk_asciiImageWithFont(font: UIFont) -> UIImage {
        let converter = AsciiConverter()
        converter.font = font
        return converter.convertImage(self)
    }

    func bk_asciiString() -> String {
        let converter = AsciiConverter()
        return converter.convertToString(self)
    }

    func bk_asciiImageCompletionHandler(handler: ImageHandler) {
        let converter = AsciiConverter()
        converter.convertImage(self) { handler?($0)}
    }

    func bk_asciiImageWithFont(font: UIFont, completionHandler handler: ImageHandler) {
        let converter = AsciiConverter()
        converter.font = font
        converter.convertImage(self) { handler?($0)}
    }

    func bk_asciiImage(bgColor: UIColor, grayscale: Bool) -> UIImage {
        let converter = AsciiConverter()
        converter.backgroundColor = bgColor
        converter.grayscale = grayscale
        return converter.convertImage(self)
    }

    func bk_asciiImageWithFont(font: UIFont, bgColor: UIColor, columns: Int, reversed: Bool, grayscale: Bool, completionHandler handler: ImageHandler) {
        let converter = AsciiConverter()
        converter.backgroundColor = bgColor
        converter.columns = columns
        converter.reversedLuminance = reversed
        converter.grayscale = grayscale
        converter.convertImage(self) { handler?($0) }
    }

    func bk_asciiStringCompletionHandler(handler: StringHandler) {
        let converter = AsciiConverter()
        converter.convertToString(self) { handler?($0) }
    }
}
#endif
