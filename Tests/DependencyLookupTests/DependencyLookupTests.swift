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
        try assertHasDOCWithSingletonScope(dependencyLookup)
    }
    
    func testRegisterDependencyWithSingletonScopeAndSubKey() throws {
        let dependencyLookup = makeDependencyLookup()
        try dependencyLookup.register(DOCImpl() as DOC, scope: .singleton, forSubKey: someDOCSubKey)
        try assertHasDOCWithSingletonScope(dependencyLookup, forSubKey: someDOCSubKey)
    }
    
    func testRegisterDependencyWithPrototypeScope_ShouldReturnNewInstanceEveryTime() throws {
        let dependencyLookup = makeDependencyLookup()
        
        try dependencyLookup.register(DOCImpl() as DOC, scope: .prototype)
        
        try assertHasDOCWithPrototypeScope(dependencyLookup)
    }
    
    func testGiveHasRegisteredDOCWhenCalledRegisterWithDOCOfTheSameTypeAndSubKeyThenThrowImplicitOverwriteError() throws {
        let (dependencyLookup, _) = try makeDependencyLookupWithRegisteredDOCInstance()
        assert(try dependencyLookup.register(DOCImpl() as DOC, scope: .singleton),
               throws: DependencyLookupError.ImplicitOverwrite())
    }
    
    func testSetDependencyWithSingletonScope_ShouldReturnTheSameInstanceEveryTime() throws {
        let dependencyLookup = makeDependencyLookup()
        dependencyLookup.set(DOCImpl() as DOC, scope: .singleton)
        try assertHasDOCWithSingletonScope(dependencyLookup)
    }
    
    func testSetDependencyWithPrototypeScope_ShouldReturnNewInstanceEveryTime() throws {
        let dependencyLookup = makeDependencyLookup()
        
        dependencyLookup.set(DOCImpl() as DOC, scope: .prototype)
        
        try assertHasDOCWithPrototypeScope(dependencyLookup)
    }
    
    func testSetDependencyWithSingletonScopeAndSubKey() throws {
        let dependencyLookup = makeDependencyLookup()
        dependencyLookup.set(DOCImpl() as DOC, scope: .singleton, forSubKey: someDOCSubKey)
        try assertHasDOCWithSingletonScope(dependencyLookup, forSubKey: someDOCSubKey)
    }
    
    func testGivenHasRegisteredDependencyWhenCalledSetThenShouldReplaceRegistration() throws {
        let (dependencyLookup, _) = try makeDependencyLookupWithRegisteredDOCInstance(subKey: someDOCSubKey)
        let newDOC: DOC = DOCImpl()
        dependencyLookup.set(newDOC, scope: .singleton)
        try assert(dependencyLookup, contains: newDOC)
    }
    
    func testImplicitOverwriteErrorDescription() {
        let expectedDescription = "To explicitly replace dependency use: set(_: for:)"
        XCTAssertEqual(expectedDescription, DependencyLookupError.ImplicitOverwrite().description)
    }
    
    func testSingletonScope_ShouldInstantiateDependencyOnFirstFetch() throws {
        let dependencyLookup = makeDependencyLookup()
        var newInstanceCounter = 0
        try dependencyLookup.register(DOCImpl({
            newInstanceCounter += 1
        }) as DOC, scope: .singleton)
        
        XCTAssertEqual(0, newInstanceCounter, "Should not instantiate dependency before first fetch")
        let _ : DOC = try dependencyLookup.fetch()
        let _ : DOC = try dependencyLookup.fetch()
        XCTAssertEqual(1, newInstanceCounter, "Should instantiate dependency once")
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
        try DependencyLookup.default.register(docForKey, scope: .singleton, forSubKey: someDOCSubKey)
        
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
    
    func testShouldInjectDependencyRegisteredWithPrototypeScope() throws {
        try DependencyLookup.default.register(DOCImpl() as DOC, scope: .prototype)
        let client = ClientUsingDefaultDependencyLookup()
        _ = client.doc
    }
    
    func testInject_ShouldUseLazyFetch() throws {
        let dependencyLookup = makeDependencyLookup()
        DependencyLookup.default = dependencyLookup
        var newInstanceCounter = 0
        try dependencyLookup.register(DOCImpl({
            newInstanceCounter += 1
        }) as DOC, scope: .prototype)
        
        let client = ClientUsingDefaultDependencyLookup()
        
        XCTAssertEqual(0, newInstanceCounter, "Should not call fetch at initialisation phase")
        _ = client.doc
        _ = client.doc
        XCTAssertEqual(1, newInstanceCounter, "Should call fetch only once when accessed doc for the first time")
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
        let actualDependency: T = try dependencyLookup.fetch(forSubKey: subKey)
        XCTAssertTrue(dependency as AnyObject === actualDependency as AnyObject, "Doesn't contain expected dependency", line: line)
    }
    
    func assertHasDOCWithSingletonScope(_ dependencyLookup: DependencyLookup, forSubKey subKey: String? = nil, line: UInt = #line) throws {
        let aDOC: DOC = try dependencyLookup.fetch(forSubKey: subKey)
        let theSameDOC: DOC = try dependencyLookup.fetch(forSubKey: subKey)
        XCTAssertTrue(aDOC === theSameDOC, "DOC should be singleton", line: line)
    }
    
    func assertHasDOCWithPrototypeScope(_ dependencyLookup: DependencyLookup, line: UInt = #line) throws {
        let aDOC: DOC = try dependencyLookup.fetch()
        let anotherDOC: DOC = try dependencyLookup.fetch()
        XCTAssertTrue(aDOC !== anotherDOC, "DOC should be prototype", line: line)
    }
}

protocol DOC: class {
}

final class DOCImpl: DOC {
    
    init(_ callback: () -> Void = {}) {
        callback()
    }
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
