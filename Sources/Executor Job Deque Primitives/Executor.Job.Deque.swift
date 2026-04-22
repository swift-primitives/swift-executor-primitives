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
public import Synchronization
public import Index_Primitives

extension Executor.Job {
    /// Chase-Lev work-stealing deque for executor jobs (Lê et al. 2013).
    ///
    /// Single-owner, multi-stealer bounded deque backed by a heap-allocated
    /// ring buffer. The owner calls ``push(_:)`` and ``take()``; any thread
    /// may call ``steal()``. Thread safety is guaranteed by the Chase-Lev
    /// algorithm's atomic orderings — no external lock required.
    ///
    /// - Important: `UnownedJob` is `BitwiseCopyable`. The Chase-Lev protocol
    ///   relies on element loads and stores being atomic at the word level;
    ///   no per-slot lifecycle management is needed.
    // WHY: @unchecked Sendable — thread safety is guaranteed by the Chase-Lev
    // algorithm's atomic orderings (acquire/release on push/steal,
    // sequentially-consistent on take's last-element CAS), not by Swift's
    // Sendable checking. Single-owner (push/take), multi-stealer protocol
    // ensures no data races.
    // TRACKING: Standard concurrency primitive; no removal criteria.
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

        /// Creates a bounded deque with the given capacity.
        ///
        /// - Parameter capacity: Maximum number of jobs. Must be a power of two.
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
            self._elements = unsafe _storage.withUnsafeMutablePointerToElements { $0 }
            self._top = Atomic<Int>(0)
            self._bottom = Atomic<Int>(0)
        }
    }
}

extension Executor.Job.Deque {
    /// Approximate number of pending jobs.
    ///
    /// Because `top` and `bottom` are read independently, the count may be
    /// transiently stale. The result is clamped to zero.
    @inlinable
    public var count: Index<UnownedJob>.Count {
        let b = _bottom.load(ordering: .relaxed)
        let t = _top.load(ordering: .relaxed)
        return try! .init(max(0, b - t))
    }

    /// Whether the deque appears empty.
    ///
    /// Approximate: a concurrent ``push(_:)`` or ``steal()`` may change the
    /// answer between the check and the caller's next operation.
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
        if b - t >= _storage.header { return false }
        unsafe _elements.advanced(by: b & _mask).pointee = job
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

        let value = unsafe _elements.advanced(by: b & _mask).pointee
        if t < b { return value }

        // Last element — race with stealers via CAS on top.
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
