@propertyWrapper
public struct Injected<T> {
    
    private let register: DependencyRegister
    private let subKey: String?
    private lazy var value: T = try! register.fetch(forSubKey: subKey)
    
    public init(from register: DependencyRegister = .default, forSubKey subKey: String? = nil) {
        self.register = register
        self.subKey = subKey
    }
    
    public var wrappedValue: T {
        mutating get { return value }
        set { value = newValue }
    }
}
