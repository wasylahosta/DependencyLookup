
@propertyWrapper
struct Injected<T> {
    
    private let dependencyLookup: DependencyLookup
    private var value: T
    
    init(_ dependencyLookup: DependencyLookup = SharedDependencyLookup.shared, for subKey: String? = nil) {
        self.dependencyLookup = dependencyLookup
        value = try! dependencyLookup.fetch(for: subKey)
    }
    
    var wrappedValue: T {
        get { return value }
        set { value = newValue }
    }
}
