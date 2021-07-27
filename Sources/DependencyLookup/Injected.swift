/// Lazily fetches a dependency from the default `DependencyRegister`
@propertyWrapper public struct Injected<T> {
    
    private let register: DependencyRegister
    private let name: String?
    private lazy var value: T = try! register.fetch(withName: name)
    
    public init(from register: DependencyRegister = .default, name: String? = nil) {
        self.register = register
        self.name = name
    }
    
    public var wrappedValue: T {
        mutating get { return value }
        set { value = newValue }
    }
}
