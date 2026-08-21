public import Executor_Job_Primitives
public import Index_Primitives
public import Synchronization

extension Executor.Job {

    @safe
    public struct Deque: ~Copyable, @unchecked Sendable {
        @usableFromInline
        internal let _storage: ManagedBuffer<Int, UnownedJob>

        @usableFromInline
        internal let _elements: UnsafeMutablePointer<UnownedJob>

        @usableFromInline
        internal let _mask: Int

        @usableFromInline
        internal let _top: Atomic<Int>

        @usableFromInline
        internal let _bottom: Atomic<Int>

        @inlinable
        public init(capacity: Int) {
            precondition(
                capacity > 0 && (capacity & (capacity - 1)) == 0,
                "capacity must be a power of two"
            )
            self._mask = capacity - 1
            self._storage = ManagedBuffer<Int, UnownedJob>.create(
                minimumCapacity: capacity,
                makingHeaderWith: { _ in capacity }
            )
            unsafe self._elements = _storage.withUnsafeMutablePointerToElements { unsafe $0 }
            self._top = Atomic<Int>(0)
            self._bottom = Atomic<Int>(0)
        }
    }
}

extension Executor.Job.Deque {

    @inlinable
    public var count: Index<UnownedJob>.Count {
        let b = _bottom.load(ordering: .relaxed)
        let t = _top.load(ordering: .relaxed)

        return try! .init(max(0, b - t))
    }

    @inlinable
    public var isEmpty: Bool {
        _bottom.load(ordering: .relaxed) <= _top.load(ordering: .relaxed)
    }

    @inlinable
    public func push(_ job: UnownedJob) -> Bool {
        let b = _bottom.load(ordering: .relaxed)
        let t = _top.load(ordering: .acquiring)
        if b - t >= _storage.header { return false }

        unsafe _elements.advanced(by: b & _mask).pointee = job
        _bottom.store(b + 1, ordering: .releasing)
        return true
    }

    @inlinable
    public func take() -> UnownedJob? {
        let oldB = _bottom.load(ordering: .relaxed)
        let b = oldB - 1
        _bottom.store(b, ordering: .sequentiallyConsistent)
        let t = _top.load(ordering: .sequentiallyConsistent)

        if t > b {
            _bottom.store(oldB, ordering: .relaxed)
            return nil
        }

        let value = unsafe _elements.advanced(by: b & _mask).pointee
        if t < b { return value }

        let (won, _) = _top.compareExchange(
            expected: t,
            desired: t + 1,
            successOrdering: .sequentiallyConsistent,
            failureOrdering: .relaxed
        )
        _bottom.store(oldB, ordering: .relaxed)
        return won ? value : nil
    }

    @inlinable
    public func steal() -> UnownedJob? {
        let t = _top.load(ordering: .acquiring)
        let b = _bottom.load(ordering: .acquiring)

        if t >= b { return nil }

        let value = unsafe _elements.advanced(by: t & _mask).pointee
        let (won, _) = _top.compareExchange(
            expected: t,
            desired: t + 1,
            successOrdering: .sequentiallyConsistent,
            failureOrdering: .relaxed
        )
        return won ? value : nil
    }
}
