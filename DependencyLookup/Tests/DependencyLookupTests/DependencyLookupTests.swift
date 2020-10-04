import XCTest
@testable import DependencyLookup

final class DependencyLookupTests: TestCase {
    
    func testFetch_WhenDoesNotContainInstanceThenShouldReturnNotFoundError() {
        let sut = makeDependencyLookup()

        let action = { () throws -> Void in
            let _ : DOC = try sut.fetch()
        }
        
        let expectedError = DependencyLookupError.notFound(DOC.self)
        XCTAssertThrowsError(try action(), "Should throw \(expectedError)") { error in
            XCTAssertEqual("\(expectedError)", "\(error)")
        }
    }
    
    func testFetch_WhenHasRegisteredInstanceThenShouldReturnIt() throws {
        let sut = makeDependencyLookup()
        let doc = DOCImpl()
        sut.register(doc as DOC)
        let actualDOC: DOC = try sut.fetch()
        XCTAssertTrue(doc === actualDOC)
    }
    
    func testNotFountErrorDescription() {
        let type = DOC.self
        let expectedDescription = "\(DependencyLookup.self): Couldn't find instance of \"\(type)\""
        XCTAssertEqual(expectedDescription, DependencyLookupError.notFound(type).description)
    }
}

private extension DependencyLookupTests {
    
    func makeDependencyLookup() -> DependencyLookup {
        DependencyLookup()
    }
}

extension DependencyLookupTests {

    static var allTests = [
        ("testExample", testFetch_WhenDoesNotContainInstanceThenShouldReturnNotFoundError),
    ]
}

protocol DOC: class {
}

final class DOCImpl: DOC {
}
