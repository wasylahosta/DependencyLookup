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
        
        assert(try action(), throws: DependencyLookupError.NotFound(type: DOC.self))
    }
    
    func testFetch_WhenHasRegisteredInstanceThenShouldReturnIt() throws {
        let (dependencyLookup, doc) = try makeDependencyLookupWithRegisteredDOCInstance()
        let actualDOC: DOC = try dependencyLookup.fetch()
        XCTAssertTrue(doc === actualDOC)
    }
    
    func testNotFountErrorDescription() {
        let type = DOC.self
        let expectedDescription = "\(DependencyLookup.self): Couldn't find instance of \"\(type)\""
        XCTAssertEqual(expectedDescription, DependencyLookupError.NotFound(type: type).description)
    }
    
    func testShouldInjectDOCRegisteredInDependencyLookup() throws {
        let (dependencyLookup, doc) = try makeDependencyLookupWithRegisteredDOCInstance()
        localDependencyLookup = dependencyLookup
        
        let client = ClientUsingLocalDependencyLookup()
        
        XCTAssertTrue(doc === client.doc)
    }
    
    func testShouldInjectDOCRegisteredInSharedDependencyLookup() throws {
        let (_, doc) = try makeSharedDependencyLookupWithRegisteredDOCInstance()
        
        let client = ClientUsingSharedDependencyLookup()
        
        XCTAssertTrue(doc === client.doc, "Wrong instance")
    }
    
    func testShouldInjectDOCRegisteredByTypeAndKeyInSharedDependencyLookup() throws {
        let (dependencyLookup, _) = try makeSharedDependencyLookupWithRegisteredDOCInstance()
        let docForKey: DOC = DOCImpl()
        try dependencyLookup.register(docForKey, for: someDOCSubKey)
        
        let client = ClientUsingSharedDependencyLookupAndKey()
        
        XCTAssertTrue(docForKey === client.doc, "Wrong instance")
    }
    
    func testShouldBeAbleToResetInjectedDOC() throws {
        let _ = try makeSharedDependencyLookupWithRegisteredDOCInstance()
        
        let client = ClientUsingSharedDependencyLookup()
        let doc = DOCImpl()
        client.doc = doc
        
        XCTAssertTrue(doc === client.doc, "Wrong instance")
    }
    
    func testShouldRegisterBuildingClosureThatCreatesNewInstancesOnFetch() throws {
        let dependencyLookup = makeDependencyLookup()
        
        let builder = { DOCImpl() as DOC }
        try dependencyLookup.register(builder, for: someDOCSubKey)
        
        let firstDOCInstance: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        let secondDOCInstance: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        XCTAssertFalse(firstDOCInstance === secondDOCInstance, "Should create new instance each time")
    }
    
    func testShouldInjectDependencyRegisteredUsingBuildingClosure() throws {
        let dependencyLookup = makeDependencyLookup()
        SharedDependencyLookup.shared = dependencyLookup
        let builder = { DOCImpl() as DOC }
        try dependencyLookup.register(builder)
        _ = ClientUsingSharedDependencyLookup()
    }
    
    func testGiveHasRegisteredDOCWhenCalledRegisterWithDOCOfTheSameTypeAndSubKeyThenThrowImplicitOverwriteError() throws {
        let (dependencyLookup, _) = try makeDependencyLookupWithRegisteredDOCInstance()
        assert(try dependencyLookup.register(DOCImpl() as DOC), throws: DependencyLookupError.ImplicitOverwrite())
    }

    func testGiveHasRegisteredDOCWhenCalledRegisterWithBuilderOfTheSameTypeOfDOCAndSubKeyThenThrowImplicitOverwriteError() throws {
        let (dependencyLookup, _) = try makeDependencyLookupWithRegisteredDOCInstance()
        let builder = { DOCImpl() as DOC }
        assert(try dependencyLookup.register(builder), throws: DependencyLookupError.ImplicitOverwrite())
    }

    func testGivenHasRegisteredDependencyWheCalledReplaceThenShouldSetTheNewInstance() throws {
        let (dependencyLookup, _) = try makeDependencyLookupWithRegisteredDOCInstance(subKey: someDOCSubKey)
        let newDOC: DOC = DOCImpl()
        dependencyLookup.replace(with: newDOC, for: someDOCSubKey)
        try assert(dependencyLookup, contains: newDOC, for: someDOCSubKey)
    }

    func testGivenHasRegisteredDependencyWheCalledReplaceThenShouldSetBuildingClosure() throws {
        let (dependencyLookup, _) = try makeDependencyLookupWithRegisteredDOCInstance(subKey: someDOCSubKey)
        let newDOC: DOC = DOCImpl()
        let builder = { newDOC }
        dependencyLookup.replace(with: builder, for: someDOCSubKey)
        try assert(dependencyLookup, contains: newDOC, for: someDOCSubKey)
    }
    
    func testImplicitOverwriteErrorDescription() {
        let expectedDescription = "To explicitly replace dependency use: replace(with: for:)"
        XCTAssertEqual(expectedDescription, DependencyLookupError.ImplicitOverwrite().description)
    }
}

private extension DependencyLookupTests {
    
    func makeDependencyLookup() -> DependencyLookup {
        DependencyLookup()
    }

    func makeDependencyLookupWithRegisteredDOCInstance(subKey: String? = nil) throws -> (DependencyLookup, DOC) {
        let dependencyLookup = makeDependencyLookup()
        let doc = DOCImpl()
        try dependencyLookup.register(doc as DOC, for: subKey)
        return (dependencyLookup, doc)
    }
    
    func makeSharedDependencyLookupWithRegisteredDOCInstance() throws -> (DependencyLookup, DOC) {
        let (dependencyLookup, doc) = try makeDependencyLookupWithRegisteredDOCInstance()
        SharedDependencyLookup.shared = dependencyLookup
        return (dependencyLookup, doc)
    }
    
    func assert<T>(_ dependencyLookup: DependencyLookup, contains dependency: T, for subKey: String? = nil, line: UInt = #line) throws {
        let actualDependency: T = try dependencyLookup.fetch(for: subKey)
        XCTAssertTrue(dependency as AnyObject === actualDependency as AnyObject, "Doesn't contain expected dependency", line: line)
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
