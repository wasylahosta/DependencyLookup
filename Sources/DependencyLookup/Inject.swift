
@propertyWrapper
public struct Inject<T> {
    
    private let dependencyLookup: DependencyLookup
    private let subKey: String?
    private var value: T!
    
    public init(from dependencyLookup: DependencyLookup = .default, forSubKey subKey: String? = nil) {
        self.dependencyLookup = dependencyLookup
        self.subKey = subKey
    }
    
    public var wrappedValue: T {
        mutating get {
            if value == nil {
                value = try! dependencyLookup.fetch(for: subKey) as T
            }
            return value
        }
        set { value = newValue }
    }
}
