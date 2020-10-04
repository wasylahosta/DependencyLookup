import XCTest
@testable import DependencyLookup

final class DependencyLookupTests: XCTestCase {
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(DependencyLookup().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
