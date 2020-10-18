import XCTest
@testable import DependencyLookup

private var localDependencyLookup: DependencyLookup!
private let someDOCSubKey = "some sub-key"

final class DependencyLookupTests: TestCase {
    
    func testFetch_WhenDoesNotContainInstanceThenShouldReturnNotFoundError() {
        let dependencyLookup = makeDependencyLookup()

        let action = { () throws -> Void in
            let _ : DOC = try dependencyLookup.fetch()
        }
        
        let expectedError = DependencyLookupError.notFound(DOC.self)
        XCTAssertThrowsError(try action(), "Should throw \(expectedError)") { error in
            XCTAssertEqual("\(expectedError)", "\(error)")
        }
    }
    
    func testFetch_WhenHasRegisteredInstanceThenShouldReturnIt() throws {
        let (dependencyLookup, doc) = makeDependencyLookupWithRegisteredDOCInstance()
        let actualDOC: DOC = try dependencyLookup.fetch()
        XCTAssertTrue(doc === actualDOC)
    }
    
    func testNotFountErrorDescription() {
        let type = DOC.self
        let expectedDescription = "\(DependencyLookup.self): Couldn't find instance of \"\(type)\""
        XCTAssertEqual(expectedDescription, DependencyLookupError.notFound(type).description)
    }
    
    func testShouldInjectDOCRegisteredInDependencyLookup() {
        let (dependencyLookup, doc) = makeDependencyLookupWithRegisteredDOCInstance()
        localDependencyLookup = dependencyLookup
        
        let client = ClientUsingLocalDependencyLookup()
        
        XCTAssertTrue(doc === client.doc)
    }
    
    func testShouldInjectDOCRegisteredInSharedDependencyLookup() {
        let (_, doc) = makeSharedDependencyLookupWithRegisteredDOCInstance()
        
        let client = ClientUsingSharedDependencyLookup()
        
        XCTAssertTrue(doc === client.doc, "Wrong instance")
    }
    
    func testShouldInjectDOCRegisteredByTypeAndKeyInSharedDependencyLookup() {
        let (dependencyLookup, _) = makeSharedDependencyLookupWithRegisteredDOCInstance()
        let docForKey: DOC = DOCImpl()
        dependencyLookup.register(docForKey, for: someDOCSubKey)
        
        let client = ClientUsingSharedDependencyLookupAndKey()
        
        XCTAssertTrue(docForKey === client.doc, "Wrong instance")
    }
    
    func testShouldBeAbleToResetInjectedDOC() {
        let _ = makeSharedDependencyLookupWithRegisteredDOCInstance()
        
        let client = ClientUsingSharedDependencyLookup()
        let doc = DOCImpl()
        client.doc = doc
        
        XCTAssertTrue(doc === client.doc, "Wrong instance")
    }
    
    func testShouldRegisterBuildingClosureThatCreatesNewInstancesOnFetch() throws {
        let dependencyLookup = makeDependencyLookup()
        
        let builder = { DOCImpl() as DOC }
        dependencyLookup.register(builder, for: someDOCSubKey)
        
        let firstDOCInstance: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        let secondDOCInstance: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        XCTAssertFalse(firstDOCInstance === secondDOCInstance, "Should create new instance each time")
    }
    
    func testShouldInjectDependencyRegisteredUsingBuildingClosure() {
        let dependencyLookup = makeDependencyLookup()
        SharedDependencyLookup.shared = dependencyLookup
        let builder = { DOCImpl() as DOC }
        dependencyLookup.register(builder)
        _ = ClientUsingSharedDependencyLookup()
    }
}

private extension DependencyLookupTests {
    
    func makeDependencyLookup() -> DependencyLookup {
        DependencyLookup()
    }

    func makeDependencyLookupWithRegisteredDOCInstance() -> (DependencyLookup, DOC) {
        let dependencyLookup = makeDependencyLookup()
        let doc = DOCImpl()
        dependencyLookup.register(doc as DOC)
        return (dependencyLookup, doc)
    }
    
    func makeSharedDependencyLookupWithRegisteredDOCInstance() -> (DependencyLookup, DOC) {
        let (dependencyLookup, doc) = makeDependencyLookupWithRegisteredDOCInstance()
        SharedDependencyLookup.shared = dependencyLookup
        return (dependencyLookup, doc)
    }
}

protocol DOC: class {
}

final class DOCImpl: DOC {
}

final class ClientUsingLocalDependencyLookup {
    
    @Injected(localDependencyLookup)
    var doc: DOC
}

final class ClientUsingSharedDependencyLookup {
    
    @Injected
    var doc: DOC
}

final class ClientUsingSharedDependencyLookupAndKey {
    
    @Injected(for: someDOCSubKey)
    var doc: DOC
}
