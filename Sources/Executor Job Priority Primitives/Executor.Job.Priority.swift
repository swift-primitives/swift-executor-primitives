// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives
// project authors. Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Executor_Primitives_Core
public import Heap_Primitives_Core
public import Index_Primitives
public import Comparison_Primitives
public import Clock_Primitives

extension Executor.Job {
    /// Deadline-ordered priority queue of executor jobs.
    ///
    /// Min-heap keyed by absolute deadline; ties within a deadline break
    /// FIFO via a monotonic insertion sequence. `peek` returns the
    /// next-to-fire deadline without removal; `pop(now:)` removes the head
    /// job if its deadline is ≤ `now`.
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
    /// The number of scheduled jobs.
    @inlinable
    public var count: Index<UnownedJob>.Count { _storage.count.retag(UnownedJob.self) }

    /// Whether there are no scheduled jobs.
    @inlinable
    public var isEmpty: Bool { _storage.isEmpty }

    /// Schedule a job for execution at the given deadline.
    ///
    /// The caller's serialization (mutex, condvar, actor isolation) governs
    /// ordering between concurrent `schedule` calls; the queue relies on
    /// that serialization for sequence-number monotonicity.
    @inlinable
    public mutating func schedule(_ job: UnownedJob, at deadline: Clock.Continuous.Instant) {
        let sequence = _nextSequence
        _nextSequence &+= 1
        _storage.push(Entry(job: job, deadline: deadline, sequence: sequence))
    }

    /// The earliest deadline without removal. `nil` if empty.
    @inlinable
    public var peek: Clock.Continuous.Instant? {
        _storage.peek?.deadline
    }

    /// Pop the head job if its deadline has elapsed; otherwise `nil`.
    @inlinable
    public mutating func pop(now: Clock.Continuous.Instant) -> UnownedJob? {
        guard let head = _storage.peek, head.deadline <= now else { return nil }
        return _storage.take?.job
    }

    /// Drain all jobs whose deadline is ≤ `now`, passing each to `body`.
    @inlinable
    public mutating func drain(
        now: Clock.Continuous.Instant,
        _ body: (UnownedJob) -> Void
    ) {
        while let head = _storage.peek, head.deadline <= now {
            body(_storage.take!.job)
        }
    }
}
