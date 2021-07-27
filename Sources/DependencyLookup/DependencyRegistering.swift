public protocol DependencyRegistering {
    
    func register(in reg: DependencyRegister) throws
}

open class CompositeDependencyRegistrar: DependencyRegistering {
    
    private let registrars: [DependencyRegistering]
    
    public init(_ registrars: DependencyRegistering...) {
        self.registrars = registrars
    }
    
    open func register(in reg: DependencyRegister) throws {
        try registrars.forEach { try $0.register(in: reg) }
    }
}
