# Executor Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-executor-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-executor-primitives/actions/workflows/ci.yml)

Job-scheduling primitives for building executors. `Executor.Job.Queue` is a thread-safe, unbounded FIFO of jobs; `Executor.Job.Deque` is a Chase-Lev work-stealing deque (Lê et al. 2013) — the owning thread pushes and takes from one end while other threads steal from the other, the standard structure behind work-stealing schedulers. Jobs are Swift's `UnownedJob`, and an `Executor.Shutdown.Flag` coordinates teardown.

These are the building blocks a custom `SerialExecutor` or `TaskExecutor` schedules over — the scheduling data structures, not a full executor. The queue and deque are tuned for the scheduler hot path (lock-free where it counts), so an executor implementation composes them rather than re-deriving them.

---

## Key Features

- **Thread-safe FIFO** — `Executor.Job.Queue`: `enqueue` / `dequeue` / `drain`, unbounded.
- **Work-stealing deque** — `Executor.Job.Deque`: `push` / `take` (owner) and `steal` (thieves), Chase-Lev.
- **`UnownedJob`-based** — schedules Swift concurrency jobs directly.
- **Shutdown coordination** — `Executor.Shutdown.Flag` for teardown.

---

## Quick Start

```swift
import Executor_Primitives

// Thread-safe FIFO job queue:
var queue = Executor.Job.Queue()
queue.enqueue(job)              // job: UnownedJob
let next = queue.dequeue()      // UnownedJob?

// Chase-Lev work-stealing deque:
let deque = Executor.Job.Deque(capacity: 256)
_ = deque.push(job)             // owner thread, one end
let mine = deque.take()         // owner thread (LIFO)
let stolen = deque.steal()      // another thread (FIFO)
```

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-executor-primitives.git", branch: "main")
]
```

Add a product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Executor Primitives", package: "swift-executor-primitives")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Executor Primitives` | Umbrella — the `Executor` namespace and the job structures | Most consumers |
| `Executor Job Queue Primitives` | `Executor.Job.Queue` — thread-safe FIFO | The FIFO queue only |
| `Executor Job Deque Primitives` | `Executor.Job.Deque` — Chase-Lev work-stealing deque | The work-stealing deque only |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Pending (nightly-toolchain follow-up) |

---

## Related Packages

- [`swift-deque-primitives`](https://github.com/swift-primitives/swift-deque-primitives) — the general-purpose double-ended queue (the executor deque is a specialized lock-free work-stealing variant over `UnownedJob`).
- [`swift-clock-primitives`](https://github.com/swift-primitives/swift-clock-primitives) — the clock behind deadline-ordered scheduling.

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
