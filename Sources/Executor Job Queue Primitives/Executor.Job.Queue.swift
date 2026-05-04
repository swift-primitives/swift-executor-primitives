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
public import Index_Primitives
public import Queue_DoubleEnded_Primitives
public import Queue_Primitives_Core

extension Executor.Job {
    /// Thread-safe unbounded FIFO of executor jobs.
    ///
    /// O(1) enqueue + dequeue. Caller supplies the lock / synchronization.
    /// This type is the storage primitive only — not itself locked.
    public struct Queue: ~Copyable {
        @usableFromInline
        internal var _storage: Deque<UnownedJob>

        @inlinable
        public init() {
            self._storage = Deque()
            self._storage.reserve(try! .init(64))
        }
    }
}

extension Executor.Job.Queue {
    /// The number of pending jobs.
    @inlinable
    public var count: Index<UnownedJob>.Count { _storage.count }

    /// Whether the queue has no pending jobs.
    @inlinable
    public var isEmpty: Bool { _storage.isEmpty }

    /// Enqueue a job at the back.
    @inlinable
    public mutating func enqueue(_ job: UnownedJob) {
        _storage.push(job, to: .back)
    }

    /// Dequeue the front job, or `nil` if empty.
    @inlinable
    public mutating func dequeue() -> UnownedJob? {
        _storage.take(from: .front)
    }

    /// Move every pending job into `other`, leaving `self` empty. O(1) via swap.
    ///
    /// Used by the batch-drain pattern in `Kernel.Thread.Executor.Polling`:
    /// lock → drain into local → unlock → execute local jobs.
    ///
    /// - Precondition: `other` is empty.
    @inlinable
    public mutating func drain(into other: inout Executor.Job.Queue) {
        swap(&self._storage, &other._storage)
    }
}
