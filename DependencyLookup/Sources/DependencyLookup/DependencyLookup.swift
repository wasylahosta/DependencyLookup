
class DependencyLookup {
    
    typealias Builder<T> = () -> T
    
    private var registry: [String: Any] = [:]
    
    func fetch<T>(for subKey: String? = nil) throws -> T {
        let key = makeKey(for: T.self, subKey)
        switch registry[key] {
        case let dependency as T: return dependency
        case let builder as Builder<T>: return builder()
        default: throw DependencyLookupError.notFound(T.self)
        }
    }
    
    func register<T>(_ dependency: T, for subKey: String? = nil) {
        registry[makeKey(for: T.self, subKey)] = dependency
    }
    
    func register<T>(_ builder: @escaping Builder<T>, for subKey: String? = nil) {
        registry[makeKey(for: T.self, subKey)] = builder
    }
    
    private func makeKey<T>(for type: T.Type, _ subKey: String? = nil) -> String {
        let typeKey = String(describing: type)
        if let key = subKey {
            return typeKey + key
        } else {
            return typeKey
        }
    }
}

enum DependencyLookupError: Error, CustomStringConvertible {
    
    case notFound(Any)

    var description: String {
        switch self {
        case .notFound(let type):
            return "\(DependencyLookup.self): Couldn't find instance of \"\(type)\""
        }
    }
}
