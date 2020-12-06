
@propertyWrapper
public struct Inject<T> {
    
    private let dependencyLookup: DependencyLookup
    private var value: T
    
    public init(from dependencyLookup: DependencyLookup = .default, forSubKey subKey: String? = nil) {
        self.dependencyLookup = dependencyLookup
        value = try! dependencyLookup.fetch(for: subKey)
    }
    
    public var wrappedValue: T {
        get { return value }
        set { value = newValue }
    }
}
