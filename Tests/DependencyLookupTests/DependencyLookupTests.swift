import XCTest
import DependencyLookup

private var localDependencyLookup: DependencyLookup!
let someDOCSubKey = "some sub-key"

final class DependencyLookupTests: TestCase {
    
    override func setUp() {
        super.setUp()
        DependencyLookup.default = DependencyLookup()
    }
    
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
    
    func testShouldInjectDOCRegisteredInDefaultDependencyLookup() throws {
        let doc = try makeDOCRegisteredInDefaultDependencyLookup()
        
        let client = ClientUsingDefaultDependencyLookup()
        
        XCTAssertTrue(doc === client.doc, "Wrong instance")
    }
    
    func testShouldInjectDOCRegisteredByTypeAndKeyInSharedDependencyLookup() throws {
        let _ = try makeDOCRegisteredInDefaultDependencyLookup()
        let docForKey: DOC = DOCImpl()
        try DependencyLookup.default.register(docForKey, for: someDOCSubKey)
        
        let client = ClientUsingDefaultDependencyLookupAndKey()
        
        XCTAssertTrue(docForKey === client.doc, "Wrong instance")
    }
    
    func testShouldBeAbleToResetInjectedDOC() throws {
        let _ = try makeDOCRegisteredInDefaultDependencyLookup()
        
        let client = ClientUsingDefaultDependencyLookup()
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
        let builder = { DOCImpl() as DOC }
        try DependencyLookup.default.register(builder)
        _ = ClientUsingDefaultDependencyLookup()
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
    
    func makeDOCRegisteredInDefaultDependencyLookup() throws -> DOC {
        let doc = DOCImpl()
        try DependencyLookup.default.register(doc as DOC)
        return doc
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

final class ClientUsingDefaultDependencyLookup {
    
    @Injected
    var doc: DOC
}

final class ClientUsingDefaultDependencyLookupAndKey {
    
    @Injected(for: someDOCSubKey)
    var doc: DOC
}
