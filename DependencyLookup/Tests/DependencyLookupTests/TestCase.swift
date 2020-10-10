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
}

