// [MOD-005] umbrella: re-exports every sub-target so `import Executor_Primitives`
// surfaces the whole package. Root + per-sub-namespace ([MOD-031]) + Job containers.
@_exported public import Executor_Primitive
@_exported public import Executor_Job_Primitives
@_exported public import Executor_Shutdown_Primitives
@_exported public import Executor_Wait_Primitives
@_exported public import Executor_Job_Deque_Primitives
// ⚠️ W5 QUARANTINE (2026-06-11): Job.Priority stores Heap<Entry>;
// swift-heap-primitives is parked for its own template round and its
// umbrella pulls the RED memory-small module. Only external consumers
// are foundations/swift-executors (the deferred L2-tier round).
// Restore with heap's round.
// @_exported public import Executor_Job_Priority_Primitives
@_exported public import Executor_Job_Queue_Primitives
