
@propertyWrapper
struct Injected<T> {
    
    private let dependencyLookup: DependencyLookup
    
    init(_ dependencyLookup: DependencyLookup = SharedDependencyLookup.shared) {
        self.dependencyLookup = dependencyLookup
    }
    
    var wrappedValue: T {
        get {
            try! dependencyLookup.fetch()
        }
    }
}
