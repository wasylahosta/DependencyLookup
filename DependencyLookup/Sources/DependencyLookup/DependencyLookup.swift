
class DependencyLookup {
    
    private var registry: [String: Any] = [:]
    
    func fetch<T>() throws -> T {
        if let dependency = registry[key(for: T.self)] as? T {
            return dependency
        } else {
            throw DependencyLookupError.notFound(T.self)
        }
    }
    
    func register<T>(_ dependency: T) {
        registry[key(for: T.self)] = dependency
    }
    
    private func key<T>(for type: T.Type) -> String {
        return String(describing: type)
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
