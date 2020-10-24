import XCTest

class TestCase: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }
    
    func assert<E: Error>(_ expression: @autoclosure () throws -> Void, `throws` error: E, file: StaticString = #file, line: UInt = #line) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            XCTAssertTrue(error is E, "Caught unexpected error: \(error)", file: file, line: line)
        }
    }
}

