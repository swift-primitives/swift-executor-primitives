public import Clock_Primitives
public import Comparison_Primitives
public import Executor_Primitives_Core
public import Heap_Primitives
public import Index_Primitives

extension Executor.Job {

    public struct Priority: ~Copyable {
        @usableFromInline
        internal var _storage: Heap<Entry>

        @usableFromInline
        internal var _nextSequence: UInt64

        @inlinable
        public init() {
            self._storage = Heap(order: .ascending)
            self._nextSequence = 0
        }
    }
}

extension Executor.Job.Priority {

    @inlinable
    public var count: Index<UnownedJob>.Count { _storage.count.retag(UnownedJob.self) }

    @inlinable
    public var isEmpty: Bool { _storage.isEmpty }

    @inlinable
    public mutating func schedule(_ job: UnownedJob, at deadline: Clock.Continuous.Instant) {
        let sequence = _nextSequence
        _nextSequence &+= 1
        _storage.push(Entry(job: job, deadline: deadline, sequence: sequence))
    }

    @inlinable
    public var peek: Clock.Continuous.Instant? {
        _storage.peek?.deadline
    }

    @inlinable
    public mutating func pop(now: Clock.Continuous.Instant) -> UnownedJob? {
        guard let head = _storage.peek, head.deadline <= now else { return nil }
        return _storage.take?.job
    }

    @inlinable
    public mutating func drain(
        now: Clock.Continuous.Instant,
        _ body: (UnownedJob) -> Void
    ) {
        while let head = _storage.peek, head.deadline <= now {
            guard let popped = _storage.take else { break }
            body(popped.job)
        }
    }
}
