import XCTest
import DependencyLookup

private var localDependencyRegister: DependencyRegister!
let someDOCSubKey = "some sub-key"

final class DependencyLookupTests: TestCase {
    
    override func setUp() {
        super.setUp()
        DependencyRegister.default = DependencyRegister()
    }
    
    func testNotFoundErrorDescription() {
        let type = DOC.self
        let expectedDescription = "\(DependencyRegister.self): Couldn't find instance of \"\(type)\""
        XCTAssertEqual(expectedDescription, DependencyLookupError.NotFound(type: type).description)
    }
    
    func testFetch_WhenDoesNotContainInstanceThenShouldReturnNotFoundError() {
        let dependencyRegister = makeDependencyRegister()

        let action = { () throws -> Void in
            let _ : DOC = try dependencyRegister.fetch()
        }
        
        assert(try action(), throws: DependencyLookupError.NotFound(type: DOC.self))
    }
    
    func testFetch_WhenHasRegisteredInstanceThenShouldReturnIt() throws {
        let (dependencyRegister, doc) = try makeDependencyRegisterWithRegisteredDOCInstance()
        let actualDOC: DOC = try dependencyRegister.fetch()
        XCTAssertTrue(doc === actualDOC)
    }
    
    func testRegisterDependencyWithSingletonScope_ShouldReturnTheSameInstanceEveryTime() throws {
        let dependencyRegister = makeDependencyRegister()
        try dependencyRegister.register(DOCImpl() as DOC, scope: .singleton)
        try assertHasDOCWithSingletonScope(dependencyRegister)
    }
    
    func testRegisterDependencyWithSingletonScopeAndSubKey() throws {
        let dependencyRegister = makeDependencyRegister()
        try dependencyRegister.register(DOCImpl() as DOC, scope: .singleton, forSubKey: someDOCSubKey)
        try assertHasDOCWithSingletonScope(dependencyRegister, forSubKey: someDOCSubKey)
    }
    
    func testRegisterDependencyWithPrototypeScope_ShouldReturnNewInstanceEveryTime() throws {
        let dependencyRegister = makeDependencyRegister()
        
        try dependencyRegister.register(DOCImpl() as DOC, scope: .prototype)
        
        try assertHasDOCWithPrototypeScope(dependencyRegister)
    }
    
    func testGiveHasRegisteredDOCWhenCalledRegisterWithDOCOfTheSameTypeAndSubKeyThenThrowImplicitOverwriteError() throws {
        let (dependencyRegister, _) = try makeDependencyRegisterWithRegisteredDOCInstance()
        assert(try dependencyRegister.register(DOCImpl() as DOC, scope: .singleton),
               throws: DependencyLookupError.ImplicitOverwrite())
    }
    
    func testSetDependencyWithSingletonScope_ShouldReturnTheSameInstanceEveryTime() throws {
        let dependencyRegister = makeDependencyRegister()
        dependencyRegister.set(DOCImpl() as DOC, scope: .singleton)
        try assertHasDOCWithSingletonScope(dependencyRegister)
    }
    
    func testSetDependencyWithPrototypeScope_ShouldReturnNewInstanceEveryTime() throws {
        let dependencyRegister = makeDependencyRegister()
        
        dependencyRegister.set(DOCImpl() as DOC, scope: .prototype)
        
        try assertHasDOCWithPrototypeScope(dependencyRegister)
    }
    
    func testSetDependencyWithSingletonScopeAndSubKey() throws {
        let dependencyRegister = makeDependencyRegister()
        dependencyRegister.set(DOCImpl() as DOC, scope: .singleton, forSubKey: someDOCSubKey)
        try assertHasDOCWithSingletonScope(dependencyRegister, forSubKey: someDOCSubKey)
    }
    
    func testGivenHasRegisteredDependencyWhenCalledSetThenShouldReplaceRegistration() throws {
        let (dependencyRegister, _) = try makeDependencyRegisterWithRegisteredDOCInstance(subKey: someDOCSubKey)
        let newDOC: DOC = DOCImpl()
        
        dependencyRegister.set(newDOC, scope: .singleton)
        
        let actualDependency: DOC = try dependencyRegister.fetch()
        XCTAssertTrue(actualDependency as! DOCImpl === newDOC, "Doesn't contain expected dependency")
    }
    
    func testImplicitOverwriteErrorDescription() {
        let expectedDescription = "To explicitly replace dependency use: set(_: for:)"
        XCTAssertEqual(expectedDescription, DependencyLookupError.ImplicitOverwrite().description)
    }
    
    func testSingletonScope_ShouldInstantiateDependencyOnFirstFetch() throws {
        let dependencyRegister = makeDependencyRegister()
        var newInstanceCounter = 0
        try dependencyRegister.register(DOCImpl({
            newInstanceCounter += 1
        }) as DOC, scope: .singleton)
        
        XCTAssertEqual(0, newInstanceCounter, "Should not instantiate dependency before first fetch")
        let _ : DOC = try dependencyRegister.fetch()
        let _ : DOC = try dependencyRegister.fetch()
        XCTAssertEqual(1, newInstanceCounter, "Should instantiate dependency once")
    }
    
    func testReferenceScope_ShouldReturnTheSameInstanceTillItHasStrongReference() throws {
        let dependencyRegister = makeDependencyRegister()
        
        try dependencyRegister.register(DOCImpl() as DOC, scope: .reference)
        
        let aDOC: DOC = try dependencyRegister.fetch()
        let theSameDOC: DOC = try dependencyRegister.fetch()
        XCTAssertTrue(aDOC === theSameDOC, "Should return the same instance of DOC")
    }
    
    func testReferenceScope_ShouldReturnNewInstanceWhenOldOneDied() throws {
        let dependencyRegister = makeDependencyRegister()
        
        var newInstanceCounter = 0
        try dependencyRegister.register(DOCImpl({
            newInstanceCounter += 1
        }) as DOC, scope: .reference)
        
        do {
            let aDOC: DOC = try dependencyRegister.fetch()
            print(aDOC)
        }
        let newDOC: DOC = try dependencyRegister.fetch()
        print(newDOC)
        XCTAssertEqual(2, newInstanceCounter, "Should have created a new instance")
    }
    
    func testReferenceScope_ShouldBehaveAsPrototypeForValueTypes() throws {
        let dependencyRegister = makeDependencyRegister()
        
        try dependencyRegister.register(ValueDOCImpl(value: .random(in: 0...1000000)) as ValueDOC, scope: .reference)
        
        let aDOC: ValueDOC = try dependencyRegister.fetch()
        let anotherDOC: ValueDOC = try dependencyRegister.fetch()
        XCTAssertTrue(aDOC as! ValueDOCImpl != anotherDOC as! ValueDOCImpl, "Should return new instance of ValueDOC")
    }
    
    // MARK: Inject
    
    func testShouldInjectDOCRegisteredInDependencyLookup() throws {
        let (dependencyRegister, doc) = try makeDependencyRegisterWithRegisteredDOCInstance()
        localDependencyRegister = dependencyRegister
        
        let client = ClientUsingLocalDependencyRegister()
        
        XCTAssertTrue(doc === client.doc)
    }
    
    func testShouldInjectDOCRegisteredInDefaultDependencyLookup() throws {
        let doc = try makeDOCRegisteredInDefaultDependencyRegister()
        
        let client = ClientUsingDefaultDependencyRegister()
        
        XCTAssertTrue(doc === client.doc, "Wrong instance")
    }
    
    func testShouldInjectDOCRegisteredByTypeAndKeyInSharedDependencyLookup() throws {
        let _ = try makeDOCRegisteredInDefaultDependencyRegister()
        let docForKey: DOC = DOCImpl()
        try DependencyRegister.default.register(docForKey, scope: .singleton, forSubKey: someDOCSubKey)
        
        let client = ClientUsingDefaultDependencyRegisterAndKey()
        
        XCTAssertTrue(docForKey === client.doc, "Wrong instance")
    }
    
    func testShouldBeAbleToResetInjectedDOC() throws {
        let _ = try makeDOCRegisteredInDefaultDependencyRegister()
        
        let client = ClientUsingDefaultDependencyRegister()
        let doc = DOCImpl()
        client.doc = doc
        
        XCTAssertTrue(doc === client.doc, "Wrong instance")
    }
    
    func testShouldInjectDependencyRegisteredWithPrototypeScope() throws {
        try DependencyRegister.default.register(DOCImpl() as DOC, scope: .prototype)
        let client = ClientUsingDefaultDependencyRegister()
        _ = client.doc
    }
    
    func testInject_ShouldUseLazyFetch() throws {
        let dependencyRegister = makeDependencyRegister()
        DependencyRegister.default = dependencyRegister
        var newInstanceCounter = 0
        try dependencyRegister.register(DOCImpl({
            newInstanceCounter += 1
        }) as DOC, scope: .prototype)
        
        let client = ClientUsingDefaultDependencyRegister()
        
        XCTAssertEqual(0, newInstanceCounter, "Should not call fetch at initialisation phase")
        _ = client.doc
        _ = client.doc
        XCTAssertEqual(1, newInstanceCounter, "Should call fetch only once when accessed doc for the first time")
    }
    
    // MARK: Registering
    
    func testDependencyRegistering() throws {
        let dependencyRegister = makeDependencyRegister()
        let compositeRegistrar: DependencyRegistering = CompositeDependencyRegistrar(
            DOCRegistrar(),
            ValueDOCRegistrar()
        )
        
        try compositeRegistrar.register(in: dependencyRegister)
        
        assertCanFetchDependency(ofType: DOC.self, from: dependencyRegister)
        assertCanFetchDependency(ofType: ValueDOC.self, from: dependencyRegister)
    }
}

private extension DependencyLookupTests {
    
    func makeDependencyRegister() -> DependencyRegister {
        DependencyRegister()
    }

    func makeDependencyRegisterWithRegisteredDOCInstance(subKey: String? = nil) throws -> (DependencyRegister, DOC) {
        let dependencyRegister = makeDependencyRegister()
        let doc = DOCImpl()
        try dependencyRegister.register(doc as DOC, scope: .singleton, forSubKey: subKey)
        return (dependencyRegister, doc)
    }
    
    func makeDOCRegisteredInDefaultDependencyRegister() throws -> DOC {
        let doc = DOCImpl()
        try DependencyRegister.default.register(doc as DOC, scope: .singleton)
        return doc
    }
    
    func assertCanFetchDependency<T>(ofType type: T.Type, from dependencyRegister: DependencyRegister, line: UInt = #line) {
        XCTAssertNoThrow(try dependencyRegister.fetch() as T, "Doesn't contain expected dependency", line: line)
    }
    
    func assertHasDOCWithSingletonScope(_ dependencyRegister: DependencyRegister, forSubKey subKey: String? = nil, line: UInt = #line) throws {
        let aDOC: DOC = try dependencyRegister.fetch(forSubKey: subKey)
        let theSameDOC: DOC = try dependencyRegister.fetch(forSubKey: subKey)
        XCTAssertTrue(aDOC === theSameDOC, "DOC should be singleton", line: line)
    }
    
    func assertHasDOCWithPrototypeScope(_ dependencyRegister: DependencyRegister, line: UInt = #line) throws {
        let aDOC: DOC = try dependencyRegister.fetch()
        let anotherDOC: DOC = try dependencyRegister.fetch()
        XCTAssertTrue(aDOC !== anotherDOC, "DOC should be prototype", line: line)
    }
}

protocol DOC: AnyObject {
}

final class DOCImpl: DOC {
    
    init(_ callback: () -> Void = {}) {
        callback()
    }
}

final class ClientUsingLocalDependencyRegister {
    
    @Injected(from: localDependencyRegister)
    var doc: DOC
}

final class ClientUsingDefaultDependencyRegister {
    
    @Injected
    var doc: DOC
}

final class ClientUsingDefaultDependencyRegisterAndKey {
    
    @Injected(forSubKey: someDOCSubKey)
    var doc: DOC
}

protocol ValueDOC {
    
    var value: Int { get }
}

struct ValueDOCImpl: ValueDOC, Equatable {
    
    var value: Int
}

final class DOCRegistrar: DependencyRegistering {
    
    func register(in reg: DependencyRegister) throws {
        try reg.register(DOCImpl() as DOC, scope: .reference)
    }
}

final class ValueDOCRegistrar: DependencyRegistering {
    
    func register(in reg: DependencyRegister) throws {
        try reg.register(ValueDOCImpl(value: 1) as ValueDOC, scope: .prototype)
    }
}
