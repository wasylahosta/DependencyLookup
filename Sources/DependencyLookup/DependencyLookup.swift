
open class DependencyLookup {
    
    public static var `default`: DependencyLookup = DependencyLookup()
    
    public typealias Builder<T> = () -> T
    
    private var registry: [String: Any] = [:]
    
    public init() {
    }
    
    open func fetch<T>(for subKey: String? = nil) throws -> T {
        let key = makeKey(for: T.self, subKey)
        switch registry[key] {
        case let dependency as T: return dependency
        case let builder as Builder<T>: return builder()
        default: throw DependencyLookupError.NotFound(type: T.self)
        }
    }
    
    open func register<T>(_ dependency: T, for subKey: String? = nil) throws {
        let key = makeKey(for: T.self, subKey)
        try verifyDoesNotHaveRegistration(for: key)
        registry[key] = dependency
    }
    
    open func register<T>(_ builder: @escaping Builder<T>, for subKey: String? = nil) throws {
        let key = makeKey(for: T.self, subKey)
        try verifyDoesNotHaveRegistration(for: key)
        registry[key] = builder
    }

    private func verifyDoesNotHaveRegistration(for key: String) throws {
        guard registry[key] == nil else {
            throw DependencyLookupError.ImplicitOverwrite()
        }
    }

    open func replace<T>(with dependency: T, for subKey: String? = nil) {
        registry[makeKey(for: T.self, subKey)] = dependency
    }

    open func replace<T>(with builder: @escaping Builder<T>, for subKey: String? = nil) {
        registry[makeKey(for: T.self, subKey)] = builder
    }
    
    private func makeKey<T>(for type: T.Type, _ subKey: String? = nil) -> String {
        let typeKey = String(describing: type)
        if let key = subKey {
            return typeKey + key
        }
        return typeKey
    }
}

public enum DependencyLookupError {
    
    public struct NotFound: Error, CustomStringConvertible {

        let type: Any
        
        public init(type: Any) {
            self.type = type
        }

        public var description: String {
            return "\(DependencyLookup.self): Couldn't find instance of \"\(type)\""
        }
    }

    public struct ImplicitOverwrite: Error, CustomStringConvertible {
        
        public init() {
        }

        public var description: String {
            return "To explicitly replace dependency use: replace(with: for:)"
        }
    }
}
