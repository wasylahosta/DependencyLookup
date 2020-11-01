
@propertyWrapper
public struct Injected<T> {
    
    private let dependencyLookup: DependencyLookup
    private var value: T
    
    public init(_ dependencyLookup: DependencyLookup = .default, for subKey: String? = nil) {
        self.dependencyLookup = dependencyLookup
        value = try! dependencyLookup.fetch(for: subKey)
    }
    
    public var wrappedValue: T {
        get { return value }
        set { value = newValue }
    }
}
