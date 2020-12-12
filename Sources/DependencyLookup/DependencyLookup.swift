
open class DependencyLookup {
    
    public enum Scope {
        case singleton
        case prototype
    }
    
    public static var `default`: DependencyLookup = DependencyLookup()
    
    public typealias Builder<T> = () -> T
    
    private var registry: [String: Any] = [:]
    
    public init() {
    }
    
    open func fetch<T>(forSubKey subKey: String? = nil) throws -> T {
        let key = makeKey(for: T.self, subKey)
        switch registry[key] {
        case let singleton as LazySingletonHolder<T>: return singleton.instance
        case let prototype as Builder<T>: return prototype()
        default: throw DependencyLookupError.NotFound(type: T.self)
        }
    }
    
    open func register<T>(_ dependencyBuilder: @autoclosure @escaping Builder<T>, scope: Scope, forSubKey subKey: String? = nil) throws {
        let key = makeKey(for: T.self, subKey)
        try verifyDoesNotHaveAnyRegistration(for: key)
        set(dependencyBuilder, scope: scope, for: key)
    }
    
    open func set<T>(_ dependencyBuilder: @autoclosure @escaping Builder<T>, scope: Scope, forSubKey subKey: String? = nil) {
        let key = makeKey(for: T.self, subKey)
        set(dependencyBuilder, scope: scope, for: key)
    }
    
    private func set<T>(_ dependencyBuilder: @escaping Builder<T>, scope: Scope, for key: String) {
        switch scope {
        case .singleton:
            registry[key] = LazySingletonHolder(dependencyBuilder)
        case .prototype:
            registry[key] = dependencyBuilder
        }
    }

    private func verifyDoesNotHaveAnyRegistration(for key: String) throws {
        guard registry[key] == nil else {
            throw DependencyLookupError.ImplicitOverwrite()
        }
    }
    
    private func makeKey<T>(for type: T.Type, _ subKey: String? = nil) -> String {
        let typeKey = String(describing: type)
        if let key = subKey {
            return typeKey + key
        }
        return typeKey
    }
    
    private final class LazySingletonHolder<T> {
        
        private(set) lazy var instance: T = builder()
        private let builder: Builder<T>
        
        init(_ builder: @escaping Builder<T>) {
            self.builder = builder
        }
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
            return "To explicitly replace dependency use: set(_: for:)"
        }
    }
}
