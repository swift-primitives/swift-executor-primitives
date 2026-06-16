# Executor Primitives Scope

The identity surface of `swift-executor-primitives`, and what is deliberately out of it.

## Identity

`swift-executor-primitives` provides **the policy-free storage and coordination primitives an
executor run-loop is built from** — a layer below an actual executor. It owns the job
containers an executor drains (an unbounded thread-safe FIFO, a Chase-Lev work-stealing deque,
a deadline-ordered priority queue) and the run-loop coordination primitives that drive them
(an atomic shutdown flag, the wait-primitive namespace). Every type is a policy-free building
block: the containers carry executor jobs without owning the scheduling policy, the thread
management, or the run-loop itself. The executor that composes these — its loop, its threads,
its policy — is built above this layer, not here.

## Core targets

Per [MOD-017]/[MOD-031], the root namespace + foundational declarations live in the singular
`Executor Primitive`, and each sub-namespace `Executor.{X}` is its own target:

- `Executor Primitive` — the `Executor` namespace root and foundational, stdlib-only
  declarations (zero external dependencies per [MOD-017]).
- `Executor Job Primitives` — `Executor.Job`, the namespace for executor job containers.
- `Executor Shutdown Primitives` — `Executor.Shutdown` and `Executor.Shutdown.Flag`, the
  atomic boolean coordinating run-loop shutdown (relaxed-load hot path, releasing-store signal).
- `Executor Wait Primitives` — `Executor.Wait` and `Executor.Wait.Event`, the wait-primitive
  namespace (concrete kernel-event-backed wait is satisfied statically, not by protocol).
- `Executor Job Queue Primitives` — `Executor.Job.Queue`, a thread-safe unbounded FIFO storage
  primitive (caller supplies the lock).
- `Executor Job Deque Primitives` — `Executor.Job.Deque`, a single-owner/multi-stealer Chase-Lev
  work-stealing deque (thread safety from the algorithm's atomic orderings, no external lock).

The deadline-ordered priority queue `Executor.Job.Priority` (`Executor Job Priority Primitives`)
is part of this identity surface but is currently PARKED under the W5 quarantine — it stores
`Heap<Entry>`, and `swift-heap-primitives` is parked for its own template round. It is restored
with heap's round.

## Out of scope

These compose with the package but lie OUTSIDE its identity surface:

- **The executor itself** — the run-loop, OS-thread management, and scheduling policy that drain
  these containers: → foundations (`swift-executors`, `Kernel.Thread.Executor.Polling`). This
  package provides the containers an executor is built from, not the executor.
- **Underlying data structures** (deque, ring buffer, column, heap, index): → their own
  primitive packages — consumed here, never owned.
- **Clocks, deadlines, durations** (`Clock.Continuous.Instant`): → `swift-clock-primitives` /
  `swift-time-primitives` — consumed by `Executor.Job.Priority`, never owned.
- **Condition-variable-backed wait**: → a composing layer above. `Executor.Wait` owns only the
  namespace and the event-source-backed form; the second wait mechanism becomes a real
  `Wait.Primitive` protocol with retroactive conformances when it ships.

## Evaluation rule

Sub-target additions are evaluated against this scope. If a proposed addition is OUT of scope,
it extracts to a sibling package, not into this one.
