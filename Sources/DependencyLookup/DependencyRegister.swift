/// Container for dependency registrations
open class DependencyRegister {
    
    /// Lifecycle scope of a registered dependency
    public enum Scope {
        
        /// Provide single shared instance
        case singleton
        
        /// Provide new instance each time
        case prototype
        
        /// Provide the same instance till it has strong references
        case reference
    }
    
    /// Default shared instance used by `Injected`
    public static var `default`: DependencyRegister = DependencyRegister()
    
    /// A closure that provides an instance of a dependency.
    public typealias Builder<T> = () -> T
    
    @Atomic var storage: [String: Any] = [:]
    
    public init() {
    }
    
    /// Resolves a dependency based on the return type and the `name`.
    /// - Parameters:
    ///   - name: Helps to differentiate registrations for the same dependency type. The default value is `nil`.
    /// - Throws: `DependencyLookupError.NotFound` if couldn't resolve the dependency.
    /// - Returns: An instance of the dependency of type `T`.
    open func fetch<T>(withName name: String? = nil) throws -> T {
        let key = makeKey(for: T.self, name)
        switch storage[key] {
        case let singleton as LazySingletonHolder<T>: return singleton.instance
        case let prototype as Builder<T>: return prototype()
        case let reference as ReferenceHolder<T>: return reference.instance
        default: throw DependencyLookupError.NotFound(type: T.self)
        }
    }
    
    /// Registers a new dependency based on its type and `name`.
    /// - Parameters:
    ///   - scope: Lifecycle scope used by the `fetch` method to resolve a dependency
    ///   - name: Helps to differentiate registrations for the same dependency type. The default value is `nil`.
    ///   - dependencyBuilder: A closure that provides an instance of a dependency.
    /// - Throws: `DependencyLookupError.ImplicitOverwrite` if registration with the same dependency type and  name already exists.
    open func register<T>(scope: Scope, name: String? = nil, _ dependencyBuilder: @escaping Builder<T>) throws {
        let key = makeKey(for: T.self, name)
        try verifyDoesNotHaveAnyRegistration(for: key)
        set(dependencyBuilder, scope: scope, for: key)
    }
    
    /// Registers a dependency based on its type and `name`. Replaces the registration if there is one with the same dependency type and name.
    /// - Parameters:
    ///   - dependencyBuilder: A closure that provides an instance of a dependency.
    ///   - scope: Lifecycle scope used by the `fetch` method to resolve a dependency
    ///   - name: Helps to differentiate registrations for the same dependency type. The default value is `nil`.
    open func set<T>(_ dependencyBuilder: @autoclosure @escaping Builder<T>, scope: Scope, name: String? = nil) {
        let key = makeKey(for: T.self, name)
        set(dependencyBuilder, scope: scope, for: key)
    }
    
    private func set<T>(_ dependencyBuilder: @escaping Builder<T>, scope: Scope, for key: String) {
        switch scope {
        case .singleton:
            storage[key] = LazySingletonHolder(dependencyBuilder)
        case .prototype:
            storage[key] = dependencyBuilder
        case .reference:
            storage[key] = ReferenceHolder(dependencyBuilder)
        }
    }

    private func verifyDoesNotHaveAnyRegistration(for key: String) throws {
        guard storage[key] == nil else {
            throw DependencyLookupError.ImplicitOverwrite()
        }
    }
    
    private func makeKey<T>(for type: T.Type, _ name: String? = nil) -> String {
        let typeKey = String(describing: type)
        if let name = name {
            return typeKey + name
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
    
    private final class ReferenceHolder<T> {
        
        private weak var weakInstance: AnyObject?
        
        var instance: T {
            if let weakInstance = weakInstance {
                return weakInstance as! T
            }
            let anInstance = builder()
            weakInstance = anInstance as AnyObject
            return anInstance
        }
        
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
            return "\(DependencyRegister.self): Couldn't find instance of \"\(type)\""
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
