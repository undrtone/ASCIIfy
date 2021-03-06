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

import XCTest
import ASCIIfy

class TestASCIIConverter: XCTestCase {
    var basicChecker: Image!
    var largeChecker: Image!
    var asymmetricChecker: Image!
    override func setUp() {
        super.setUp()
        let bundle = Bundle(for: type(of: self))

        basicChecker = {
            let fileLocation = bundle.path(forResource: "checker-2", ofType: "png")!
            let image = Image(contentsOfFile: fileLocation)!
            return image
        }()
        largeChecker = {
            let fileLocation = bundle.path(forResource: "checker-1024", ofType: "png")!
            let image = Image(contentsOfFile: fileLocation)!
            return image
        }()
        asymmetricChecker = {
            let fileLocation = bundle.path(forResource: "asymmetric-checker-2", ofType: "png")!
            let image = Image(contentsOfFile: fileLocation)!
            return image
            }()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasicChecker() {
        let lut = LuminanceLookupTable()
        lut.invertLuminance = true
        let converter = ASCIIConverter(lut: lut)
        let result = converter.convertToString(basicChecker)
        XCTAssertEqual(result, "@   \n  @ \n")
    }

    func testBasicCheckerInverse() {
        let lut = LuminanceLookupTable()
        lut.invertLuminance = false
        let converter = ASCIIConverter(lut: lut)
        let result = converter.convertToString(basicChecker)
        XCTAssertEqual(result, "  @ \n@   \n")
    }

    func testThatImageOrientationIsNotChanged() {
        let lut = LuminanceLookupTable()
        lut.invertLuminance = false
        let converter = ASCIIConverter(lut: lut)
        let result = converter.convertToString(asymmetricChecker)
        XCTAssertEqual(result, "  @ \n<   \n")
    }

    func testThatImageSizeIsCorrect() {
        let result = largeChecker.fy_asciiImage()
        XCTAssertEqual(result.size, largeChecker.size)
    }

    func testSurvivesLargeFontSize() {
        _ = largeChecker.fy_asciiImage(ASCIIConverter.defaultFont.withSize(500.0))
    }

    func testImageConversionPerformance() {
        let converter = ASCIIConverter()
        measure {
            let result = converter.convertImage(self.largeChecker)
            XCTAssertEqual(result.size, self.largeChecker.size)
        }

    }

    func testStringConversionPerformance() {
        let converter = ASCIIConverter()
        measure {
            let _ = converter.convertToString(self.largeChecker)
        }

    }

    
}
