
@propertyWrapper
public struct Inject<T> {
    
    private let dependencyLookup: DependencyLookup
    private let subKey: String?
    private lazy var value: T = try! dependencyLookup.fetch(for: subKey)
    
    public init(from dependencyLookup: DependencyLookup = .default, forSubKey subKey: String? = nil) {
        self.dependencyLookup = dependencyLookup
        self.subKey = subKey
    }
    
    public var wrappedValue: T {
        mutating get { return value }
        set { value = newValue }
    }
}
