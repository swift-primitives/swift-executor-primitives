public import Clock_Primitives
public import Comparison_Primitives
public import Executor_Primitives_Core

extension Executor.Job.Priority {

    @usableFromInline
    package struct Entry: Sendable {

        @usableFromInline
        package let job: UnownedJob

        @usableFromInline
        package let deadline: Clock.Continuous.Instant

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

extension Executor.Job.Priority.Entry: Equation.`Protocol` {

    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        (lhs.deadline, lhs.sequence) == (rhs.deadline, rhs.sequence)
    }
}

extension Executor.Job.Priority.Entry: Comparison.`Protocol` {

    @inlinable
    public static func < (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        (lhs.deadline, lhs.sequence) < (rhs.deadline, rhs.sequence)
    }
}
