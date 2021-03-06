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
@testable import ASCIIfy

class TestBlockGrid: XCTestCase {
    var largeChecker: Image!
    override func setUp() {
        super.setUp()
        let bundle = Bundle(for: type(of: self))
        largeChecker = {
            let fileLocation = bundle.path(forResource: "checker-1024", ofType: "png")!
            let image = Image(contentsOfFile: fileLocation)!
            return image
            }()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPixelGridImageConstructor() {
        let result = BlockGrid(image: largeChecker)
        XCTAssertEqual(result.width, Int(largeChecker.size.width))
        XCTAssertEqual(result.height, Int(largeChecker.size.height))
        let black = BlockGrid.Block(r: 0, g: 0, b:0, a: 1)
        let white = BlockGrid.Block(r: 1, g: 1, b:1, a: 1)
        XCTAssertEqual(result.block(atRow: 0, column: 0), white)
        XCTAssertEqual(result.block(atRow:1, column: 0), black)
    }

    func testConstructionFromImagePerformance() {
        measure { 
            let _ = BlockGrid(image: self.largeChecker)
        }
    }
}
