# Audit: swift-executor-primitives

## Supervisor Review Findings — 2026-04-15

| # | Finding | Location | Status |
|---|---------|----------|--------|
| 7 | `drain(into:)` precondition undocumented | Executor.Job.Queue.swift:55–64 | RESOLVED — documented in doc comment (line 61); not enforced at runtime |
| 8 | Wait namespace references Condvar | Executor.Wait.Event.Source.swift:24–29 | RESOLVED 2026-04-15 — L1 doc replaced with layer-agnostic description in commit `678d5aa`. |
| 9 | No Event.Source test | Executor.Wait.Event.Source Tests.swift | RESOLVED — compile-validation test exists (L1 cannot construct the type without L2/L3) |
| 10 | Entry still public | Executor.Job.Priority.Entry.swift:22 | RESOLVED — now `@usableFromInline package` |

---

## Code Surface — 2026-04-15

### Scope

- **Target**: swift-executor-primitives (all source targets)
- **Skill**: code-surface — [API-NAME-*], [API-ERR-*], [API-IMPL-*]
- **Files**: 12 source files

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| 1 | MEDIUM | [API-NAME-002] | Executor.Job.Priority.swift:57 | `popReady(now:)` is compound public method (verb+adjective). Nested accessor alternative: `.ready.pop(now:)`. | RESOLVED 2026-04-15 — renamed to `pop(now:)` (flat rename; `now:` label carries "ready" semantics, Property accessor was over-engineering). |
| 2 | MEDIUM | [API-NAME-002] | Executor.Job.Priority.swift:64 | `drainReady(now:_:)` is compound public method (verb+adjective). Nested accessor alternative: `.ready.drain(now:_:)`. | RESOLVED 2026-04-15 — renamed to `drain(now:_:)`. |

### Summary

2 findings: 0 critical, 0 high, 2 medium, 0 low. **All resolved 2026-04-15.**

All types follow Nest.Name ([API-NAME-001]). One type per file ([API-IMPL-005]) throughout. Minimal type bodies ([API-IMPL-008]). File naming matches nested type paths ([API-IMPL-006]). Single throwing function uses typed throws ([API-ERR-001]).

---

## Implementation — 2026-04-15

### Scope

- **Target**: swift-executor-primitives (all source targets)
- **Skill**: implementation — [IMPL-*], [COPY-FIX-*], [PATTERN-*]
- **Files**: 12 source files

### Findings

No findings.

### Summary

0 findings. Types default to `~Copyable` where appropriate ([IMPL-064]). Copyable `Entry` justified by `Heap` storage. Typed arithmetic used throughout — `Index<UnownedJob>.Count`, `.retag()` ([IMPL-002]). No `.rawValue` chains. Expressions read as intent ([IMPL-INTENT]). `unsafe` placement correct ([IMPL-034]). `Sendable` applied minimally ([IMPL-068]).

---

## Platform — 2026-04-15

### Scope

- **Target**: swift-executor-primitives (all source targets + Package.swift)
- **Skill**: platform — [PLAT-ARCH-*], [PATTERN-*]
- **Files**: 12 source files + Package.swift

### Findings

No findings.

### Summary

0 findings. No Foundation imports ([PRIM-FOUND-001]). No `import Darwin`/`Glibc`/`Dispatch` ([PLAT-ARCH-008a]). Swift 6 + `.strictMemorySafety()` + `Lifetimes` correctly configured ([PATTERN-005], [PATTERN-006], [PATTERN-007]). The `#if KERNEL_AVAILABLE` custom define is deterministic (maps to explicit platform list in Package.swift) — not a `#if canImport()` misuse.

---

## Modularization — 2026-04-15

### Scope

- **Target**: swift-executor-primitives (Package.swift + target structure)
- **Skill**: modularization — [MOD-*]
- **Files**: Package.swift, 6 targets

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| 1 | HIGH | [MOD-001] | Package.swift:19–21 | `Executor Primitives Core` published as library product. Core MUST be an internal target only — not a published product. One-line fix: remove the product declaration. | RESOLVED 2026-04-15 — Core removed from products array. |
| 2 | HIGH | [MOD-002] | Package.swift:52–93 | Core has zero external dependencies. All 4 variants depend on external packages directly (`swift-queue-primitives`, `swift-index-primitives`, `swift-heap-primitives`, `swift-comparison-primitives`, `swift-kernel-primitives`). Core re-exports nothing and has no `exports.swift`. The centralization principle is inoperative. Exception partially applicable: variants need different concrete types (`Deque`, `Heap`, `Kernel.Event.Source`), not shared protocols. | DEFERRED 2026-04-15 — exception applies (variants require different concrete types, not shared protocols); `exports.swift` added as centralization point for future shared deps. |
| 3 | MEDIUM | [MOD-002] | Sources/Executor Primitives Core/ | Core target has no `exports.swift`. Even with zero external deps currently, the file should exist as the centralization point for future dependencies. | RESOLVED 2026-04-15 — `exports.swift` added to Core. |
| 4 | LOW | [MOD-011] | Package.swift | No `Executor Primitives Test Support` library product. Multi-product package (6 products) requires one per [MOD-011]. | DEFERRED — no downstream consumers need test fixtures yet |

### Summary

4 findings: 0 critical, 2 high, 1 medium, 1 low. **2026-04-15 update: 2 RESOLVED, 2 DEFERRED.** Finding #1 (Core published) resolved by removing from products. Finding #3 (no exports.swift) resolved by adding the file. Finding #2 (decentralized external deps) deferred — the exception applies (variants need different concrete types). Finding #4 (no test support) remains deferred pending downstream need.
