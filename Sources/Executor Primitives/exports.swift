@_exported public import Executor_Job_Deque_Primitives
// ⚠️ W5 QUARANTINE (2026-06-11): Job.Priority stores Heap<Entry>;
// swift-heap-primitives is parked for its own template round and its
// umbrella pulls the RED memory-small module. Only external consumers
// are foundations/swift-executors (the deferred L2-tier round).
// Restore with heap's round.
// @_exported public import Executor_Job_Priority_Primitives
@_exported public import Executor_Job_Queue_Primitives
@_exported public import Executor_Primitives_Core
