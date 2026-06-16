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

public import Synchronization

extension Executor.Shutdown {
    /// Atomic boolean coordinating run-loop shutdown.
    ///
    /// Relaxed load on the hot path (run-loop predicate check), release
    /// store on shutdown (publishes any preceding writes to the observing
    /// run-loop thread).
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
    /// Whether the shutdown signal has been set.
    ///
    /// Relaxed ordering: run-loops poll this — they see the update
    /// within one iteration. Consumers needing acquire semantics
    /// on the read side handle that themselves.
    @inlinable
    public var isSet: Bool {
        _atomic.load(ordering: .relaxed)
    }

    /// Signal shutdown. Release ordering publishes preceding writes
    /// to the observing run-loop thread.
    @inlinable
    public func set() {
        _atomic.store(true, ordering: .releasing)
    }
}
