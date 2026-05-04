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
public import Memory_Primitives_Core
public import Synchronization

extension Executor.Job.Deque {
    /// Chase-Lev work-stealing deque with inline storage (zero heap allocation).
    ///
    /// Same algorithm and API as ``Executor.Job.Deque``, but backed by
    /// `Memory.Inline<UnownedJob, N>` — all storage lives in the struct itself.
    /// Suitable for fixed-size per-worker deques where the capacity is known
    /// at compile time.
    ///
    /// - Parameter N: Capacity. Must be a power of two.
    // WHY: @unchecked Sendable — same reasoning as Executor.Job.Deque.
    // Thread safety is guaranteed by Chase-Lev atomic orderings.
    // TRACKING: Standard concurrency primitive; no removal criteria.
    public struct Static<let N: Int>: ~Copyable, @unchecked Sendable {
        @usableFromInline
        internal let _storage: Memory.Inline<UnownedJob, N>

        @usableFromInline
        internal let _mask: Int

        @usableFromInline
        internal let _top: Atomic<Int>

        @usableFromInline
        internal let _bottom: Atomic<Int>

        /// Creates an inline deque with compile-time capacity `N`.
        ///
        /// - Precondition: `N` must be a positive power of two.
        @inlinable
        public init() {
            precondition(
                N > 0 && (N & (N - 1)) == 0,
                "N must be a power of two"
            )
            self._mask = N - 1
            self._storage = Memory.Inline<UnownedJob, N>()
            self._top = Atomic<Int>(0)
            self._bottom = Atomic<Int>(0)
        }
    }
}

extension Executor.Job.Deque.Static {
    /// Approximate number of pending jobs.
    @inlinable
    public var count: Index<UnownedJob>.Count {
        let b = _bottom.load(ordering: .relaxed)
        let t = _top.load(ordering: .relaxed)
        return try! .init(max(0, b - t))
    }

    /// Whether the deque appears empty.
    @inlinable
    public var isEmpty: Bool {
        _bottom.load(ordering: .relaxed) <= _top.load(ordering: .relaxed)
    }

    /// Owner-side push. Returns `true` on success, `false` if full.
    ///
    /// - Precondition: Called only by the owning thread.
    @inlinable
    public func push(_ job: UnownedJob) -> Bool {
        let b = _bottom.load(ordering: .relaxed)
        let t = _top.load(ordering: .acquiring)
        if b - t >= N { return false }
        unsafe _storage.pointer(at: b & _mask).pointee = job
        _bottom.store(b + 1, ordering: .releasing)
        return true
    }

    /// Owner-side take (LIFO). Returns `nil` if empty.
    ///
    /// - Precondition: Called only by the owning thread.
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

        let value = unsafe _storage.pointer(at: b & _mask).pointee
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

    /// Stealer-side steal (FIFO). Returns `nil` if empty or contention loss.
    ///
    /// May be called from any thread.
    @inlinable
    public func steal() -> UnownedJob? {
        let t = _top.load(ordering: .acquiring)
        let b = _bottom.load(ordering: .acquiring)

        if t >= b { return nil }

        let value = unsafe _storage.pointer(at: t & _mask).pointee
        let (won, _) = _top.compareExchange(
            expected: t,
            desired: t + 1,
            successOrdering: .sequentiallyConsistent,
            failureOrdering: .relaxed
        )
        return won ? value : nil
    }
}
