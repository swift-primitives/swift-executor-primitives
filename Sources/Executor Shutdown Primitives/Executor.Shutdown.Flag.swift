public import Synchronization

extension Executor.Shutdown {

    public struct Flag: ~Copyable, Sendable {
        @usableFromInline
        internal let _atomic: Atomic<Bool>

        @inlinable
        public init() {
            self._atomic = .init(false)
        }
    }
}

extension Executor.Shutdown.Flag {

    @inlinable
    public var isSet: Bool {
        _atomic.load(ordering: .relaxed)
    }

    @inlinable
    public func set() {
        _atomic.store(true, ordering: .releasing)
    }
}
