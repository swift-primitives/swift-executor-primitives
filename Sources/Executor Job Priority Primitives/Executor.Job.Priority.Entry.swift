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

public import Clock_Primitives
public import Comparison_Primitives
public import Executor_Primitives_Core

extension Executor.Job.Priority {
    /// A job paired with its scheduled deadline and insertion sequence.
    ///
    /// Internal to the priority queue — consumers interact via
    /// `schedule(_:at:)` and `pop(now:)`, never Entry directly.
    @usableFromInline
    package struct Entry: Sendable {
        /// The executor job to run.
        @usableFromInline
        package let job: UnownedJob

        /// The absolute deadline at which the job should fire.
        @usableFromInline
        package let deadline: Clock.Continuous.Instant

        /// Monotonic insertion sequence assigned by `Priority.schedule(_:at:)`.
        ///
        /// Breaks ties between entries sharing a deadline so that earlier
        /// `schedule` calls fire first (FIFO within a deadline). Matches the
        /// Java `ScheduledThreadPoolExecutor` ordering discipline.
        @usableFromInline
        package let sequence: UInt64

        @usableFromInline
        package init(job: UnownedJob, deadline: Clock.Continuous.Instant, sequence: UInt64) {
            self.job = job
            self.deadline = deadline
            self.sequence = sequence
        }
    }
}

// MARK: - Equation.Protocol

extension Executor.Job.Priority.Entry: Equation.`Protocol` {
    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        (lhs.deadline, lhs.sequence) == (rhs.deadline, rhs.sequence)
    }
}

// MARK: - Comparison.Protocol (for Heap ordering)

extension Executor.Job.Priority.Entry: Comparison.`Protocol` {
    /// Entries compare by deadline first, then by monotonic insertion
    /// sequence — earlier deadlines fire first, and same-deadline entries
    /// fire in FIFO order of their `schedule(_:at:)` calls.
    @inlinable
    public static func < (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        (lhs.deadline, lhs.sequence) < (rhs.deadline, rhs.sequence)
    }
}
