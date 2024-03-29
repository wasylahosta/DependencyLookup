import XCTest
import DependencyLookup

private var localDependencyRegister: DependencyRegister!
let someDOCName = "some name"

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
        try dependencyRegister.register(scope: .singleton) { DOCImpl() as DOC }
        try assertHasDOCWithSingletonScope(dependencyRegister)
    }
    
    func testRegisterDependencyWithSingletonScopeAndName() throws {
        let dependencyRegister = makeDependencyRegister()
        try dependencyRegister.register(scope: .singleton, name: someDOCName) { DOCImpl() as DOC }
        try assertHasDOCWithSingletonScope(dependencyRegister, name: someDOCName)
    }
    
    func testRegisterDependencyWithPrototypeScope_ShouldReturnNewInstanceEveryTime() throws {
        let dependencyRegister = makeDependencyRegister()
        
        try dependencyRegister.register(scope: .prototype) { DOCImpl() as DOC }
        
        try assertHasDOCWithPrototypeScope(dependencyRegister)
    }
    
    func testGiveHasRegisteredDOCWhenCalledRegisterWithDOCOfTheSameTypeAndNameThenThrowImplicitOverwriteError() throws {
        let (dependencyRegister, _) = try makeDependencyRegisterWithRegisteredDOCInstance()
        assert(try dependencyRegister.register(scope: .singleton, { DOCImpl() as DOC }),
               throws: DependencyLookupError.ImplicitOverwrite())
    }
    
    func testSetDependencyWithSingletonScope_ShouldReturnTheSameInstanceEveryTime() throws {
        let dependencyRegister = makeDependencyRegister()
        dependencyRegister.set(scope: .singleton) { DOCImpl() as DOC }
        try assertHasDOCWithSingletonScope(dependencyRegister)
    }
    
    func testSetDependencyWithPrototypeScope_ShouldReturnNewInstanceEveryTime() throws {
        let dependencyRegister = makeDependencyRegister()
        
        dependencyRegister.set(scope: .prototype) { DOCImpl() as DOC }
        
        try assertHasDOCWithPrototypeScope(dependencyRegister)
    }
    
    func testSetDependencyWithSingletonScopeAndName() throws {
        let dependencyRegister = makeDependencyRegister()
        dependencyRegister.set(scope: .singleton, name: someDOCName) { DOCImpl() as DOC }
        try assertHasDOCWithSingletonScope(dependencyRegister, name: someDOCName)
    }
    
    func testGivenHasRegisteredDependencyWhenCalledSetThenShouldReplaceRegistration() throws {
        let (dependencyRegister, _) = try makeDependencyRegisterWithRegisteredDOCInstance(name: someDOCName)
        let newDOC: DOC = DOCImpl()
        
        dependencyRegister.set(scope: .singleton) { newDOC }
        
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
        try dependencyRegister.register(scope: .singleton) {
            DOCImpl({ newInstanceCounter += 1}) as DOC
        }
        
        XCTAssertEqual(0, newInstanceCounter, "Should not instantiate dependency before first fetch")
        let _ : DOC = try dependencyRegister.fetch()
        let _ : DOC = try dependencyRegister.fetch()
        XCTAssertEqual(1, newInstanceCounter, "Should instantiate dependency once")
    }
    
    func testReferenceScope_ShouldReturnTheSameInstanceTillItHasStrongReference() throws {
        let dependencyRegister = makeDependencyRegister()
        
        try dependencyRegister.register(scope: .reference) { DOCImpl() as DOC }
        
        let aDOC: DOC = try dependencyRegister.fetch()
        let theSameDOC: DOC = try dependencyRegister.fetch()
        XCTAssertTrue(aDOC === theSameDOC, "Should return the same instance of DOC")
    }
    
    func testReferenceScope_ShouldReturnNewInstanceWhenOldOneDied() throws {
        let dependencyRegister = makeDependencyRegister()
        
        var newInstanceCounter = 0
        try dependencyRegister.register(scope: .reference) {
            DOCImpl({ newInstanceCounter += 1 }) as DOC
        }
        
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
        
        try dependencyRegister.register(scope: .reference) {
            ValueDOCImpl(value: .random(in: 0...1000000)) as ValueDOC
        }
        
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
        try DependencyRegister.default.register(scope: .singleton, name: someDOCName) { docForKey }
        
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
        try DependencyRegister.default.register(scope: .prototype) { DOCImpl() as DOC }
        let client = ClientUsingDefaultDependencyRegister()
        _ = client.doc
    }
    
    func testInject_ShouldUseLazyFetch() throws {
        let dependencyRegister = makeDependencyRegister()
        DependencyRegister.default = dependencyRegister
        var newInstanceCounter = 0
        try dependencyRegister.register(scope: .prototype) {
            DOCImpl({ newInstanceCounter += 1 }) as DOC
        }
        
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

    func makeDependencyRegisterWithRegisteredDOCInstance(name: String? = nil) throws -> (DependencyRegister, DOC) {
        let dependencyRegister = makeDependencyRegister()
        let doc = DOCImpl()
        try dependencyRegister.register(scope: .singleton, name: name) { doc as DOC }
        return (dependencyRegister, doc)
    }
    
    func makeDOCRegisteredInDefaultDependencyRegister() throws -> DOC {
        let doc = DOCImpl()
        try DependencyRegister.default.register(scope: .singleton) { doc as DOC }
        return doc
    }
    
    func assertCanFetchDependency<T>(ofType type: T.Type, from dependencyRegister: DependencyRegister, line: UInt = #line) {
        XCTAssertNoThrow(try dependencyRegister.fetch() as T, "Doesn't contain expected dependency", line: line)
    }
    
    func assertHasDOCWithSingletonScope(_ dependencyRegister: DependencyRegister, name: String? = nil, line: UInt = #line) throws {
        let aDOC: DOC = try dependencyRegister.fetch(withName: name)
        let theSameDOC: DOC = try dependencyRegister.fetch(withName: name)
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
    
    @Injected(name: someDOCName)
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
        try reg.register(scope: .reference) { DOCImpl() as DOC }
    }
}

final class ValueDOCRegistrar: DependencyRegistering {
    
    func register(in reg: DependencyRegister) throws {
        try reg.register(scope: .prototype) { ValueDOCImpl(value: 1) as ValueDOC }
    }
}

struct StructClient {
    
    @Injected var doc: DOC
    
    func foo() {
        print(doc)
    }
}
