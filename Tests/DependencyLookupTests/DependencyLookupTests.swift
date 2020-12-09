import XCTest
import DependencyLookup

private var localDependencyLookup: DependencyLookup!
let someDOCSubKey = "some sub-key"

final class DependencyLookupTests: TestCase {
    
    override func setUp() {
        super.setUp()
        DependencyLookup.default = DependencyLookup()
    }
    
    func testNotFoundErrorDescription() {
        let type = DOC.self
        let expectedDescription = "\(DependencyLookup.self): Couldn't find instance of \"\(type)\""
        XCTAssertEqual(expectedDescription, DependencyLookupError.NotFound(type: type).description)
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
    
    func testRegisterDependencyWithSingletonScope_ShouldReturnTheSameInstanceEveryTime() throws {
        let dependencyLookup = makeDependencyLookup()
        
        try dependencyLookup.register(DOCImpl() as DOC, scope: .singleton)
        
        let aDOC: DOC = try dependencyLookup.fetch()
        let theSameDOC: DOC = try dependencyLookup.fetch()
        XCTAssertTrue(aDOC === theSameDOC)
    }
    
    func testRegisterDependencyWithSingletonScopeAndSubKey() throws {
        let dependencyLookup = makeDependencyLookup()
        
        try dependencyLookup.register(DOCImpl() as DOC, scope: .singleton, forSubKey: someDOCSubKey)
        
        let aDOC: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        let theSameDOC: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        XCTAssertTrue(aDOC === theSameDOC)
    }
    
    func testRegisterDependencyWithPrototypeScope_ShouldReturnNewInstanceEveryTime() throws {
        let dependencyLookup = makeDependencyLookup()
        
        try dependencyLookup.register(DOCImpl() as DOC, scope: .prototype)
        
        let aDOC: DOC = try dependencyLookup.fetch()
        let anotherDOC: DOC = try dependencyLookup.fetch()
        XCTAssertTrue(aDOC !== anotherDOC)
    }
    
    func testGiveHasRegisteredDOCWhenCalledRegisterWithDOCOfTheSameTypeAndSubKeyThenThrowImplicitOverwriteError() throws {
        let (dependencyLookup, _) = try makeDependencyLookupWithRegisteredDOCInstance()
        assert(try dependencyLookup.register(DOCImpl() as DOC, scope: .singleton),
               throws: DependencyLookupError.ImplicitOverwrite())
    }
    
    func testSetDependencyWithSingletonScope_ShouldReturnTheSameInstanceEveryTime() throws {
        let dependencyLookup = makeDependencyLookup()
        
        dependencyLookup.set(DOCImpl() as DOC, scope: .singleton)
        
        let aDOC: DOC = try dependencyLookup.fetch()
        let theSameDOC: DOC = try dependencyLookup.fetch()
        XCTAssertTrue(aDOC === theSameDOC)
    }
    
    func testSetDependencyWithPrototypeScope_ShouldReturnNewInstanceEveryTime() throws {
        let dependencyLookup = makeDependencyLookup()
        
        dependencyLookup.set(DOCImpl() as DOC, scope: .prototype)
        
        let aDOC: DOC = try dependencyLookup.fetch()
        let anotherDOC: DOC = try dependencyLookup.fetch()
        XCTAssertTrue(aDOC !== anotherDOC)
    }
    
    func testSetDependencyWithSingletonScopeAndSubKey() throws {
        let dependencyLookup = makeDependencyLookup()
        
        dependencyLookup.set(DOCImpl() as DOC, scope: .singleton, forSubKey: someDOCSubKey)
        
        let aDOC: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        let theSameDOC: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        XCTAssertTrue(aDOC === theSameDOC)
    }
    
    func testGivenHasRegisteredDependencyWhenCalledSetThenShouldReplaceRegistration() throws {
        let (dependencyLookup, _) = try makeDependencyLookupWithRegisteredDOCInstance(subKey: someDOCSubKey)
        let newDOC: DOC = DOCImpl()
        dependencyLookup.set(newDOC, scope: .singleton)
        try assert(dependencyLookup, contains: newDOC)
    }
    
    // Scope+ | Lifecycle- :
    // - singleton (lazy)
    // - prototype
    
    // ----
    
    func testShouldRegisterBuildingClosureThatCreatesNewInstancesOnFetch() throws {
        let dependencyLookup = makeDependencyLookup()
        
        let builder = { DOCImpl() as DOC }
        try dependencyLookup.register(builder, for: someDOCSubKey)
        
        let firstDOCInstance: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        let secondDOCInstance: DOC = try dependencyLookup.fetch(for: someDOCSubKey)
        XCTAssertFalse(firstDOCInstance === secondDOCInstance, "Should create new instance each time")
    }
    
    func testGivenHasRegisteredDependencyWhenCalledSetThenShouldSetBuildingClosure() throws {
        let (dependencyLookup, _) = try makeDependencyLookupWithRegisteredDOCInstance(subKey: someDOCSubKey)
        let newDOC: DOC = DOCImpl()
        let builder = { newDOC }
        dependencyLookup.set(builder, for: someDOCSubKey)
        try assert(dependencyLookup, contains: newDOC, for: someDOCSubKey)
    }
    
    func testImplicitOverwriteErrorDescription() {
        let expectedDescription = "To explicitly replace dependency use: set(_: for:)"
        XCTAssertEqual(expectedDescription, DependencyLookupError.ImplicitOverwrite().description)
    }
    
    // MARK: Inject
    
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
    
    func testShouldInjectDependencyRegisteredUsingBuildingClosure() throws {
        let builder = { DOCImpl() as DOC }
        try DependencyLookup.default.register(builder)
        _ = ClientUsingDefaultDependencyLookup()
    }
    
    func testInject_ShouldUseLazyFetch() throws {
        let dependencyLookup = makeDependencyLookup()
        DependencyLookup.default = dependencyLookup
        var invokeBuilderCounter = 0
        let builder = { () -> DOC in
            invokeBuilderCounter += 1
            return DOCImpl() as DOC
        }
        try dependencyLookup.register(builder)
        
        let client = ClientUsingDefaultDependencyLookup()
        
        XCTAssertEqual(0, invokeBuilderCounter, "Should not call fetch at initialisation phase")
        _ = client.doc
        _ = client.doc
        XCTAssertEqual(1, invokeBuilderCounter, "Should call fetch only once when accessed doc for the first time")
    }
}

private extension DependencyLookupTests {
    
    func makeDependencyLookup() -> DependencyLookup {
        DependencyLookup()
    }

    func makeDependencyLookupWithRegisteredDOCInstance(subKey: String? = nil) throws -> (DependencyLookup, DOC) {
        let dependencyLookup = makeDependencyLookup()
        let doc = DOCImpl()
        try dependencyLookup.register(doc as DOC, scope: .singleton, forSubKey: subKey)
        return (dependencyLookup, doc)
    }
    
    func makeDOCRegisteredInDefaultDependencyLookup() throws -> DOC {
        let doc = DOCImpl()
        try DependencyLookup.default.register(doc as DOC, scope: .singleton)
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
    
    @Inject(from: localDependencyLookup)
    var doc: DOC
}

final class ClientUsingDefaultDependencyLookup {
    
    @Inject
    var doc: DOC
}

final class ClientUsingDefaultDependencyLookupAndKey {
    
    @Inject(forSubKey: someDOCSubKey)
    var doc: DOC
}
