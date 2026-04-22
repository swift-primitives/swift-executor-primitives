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

import Testing
import Synchronization
import Executor_Primitives_Test_Support

// MARK: - Contended Test Harness
// Wraps ~Copyable deque + atomics in a Sendable class for closure capture.
// Atomic<Int> and Executor.Job.Deque are both ~Copyable — cannot be captured
// directly in @Sendable @escaping closures.

private final class HeapHarness: @unchecked Sendable {
    let deque: Executor.Job.Deque
    let taken = Atomic<Int>(0)
    let stolen = Atomic<Int>(0)
    let pushDone = Atomic<Int>(0)

    init(capacity: Int) {
        self.deque = .init(capacity: capacity)
    }
}

private final class StaticHarness: @unchecked Sendable {
    let deque: Executor.Job.Deque.Static<256>
    let taken = Atomic<Int>(0)
    let stolen = Atomic<Int>(0)
    let pushDone = Atomic<Int>(0)

    init() {
        self.deque = .init()
    }
}

// MARK: - Heap Variant

@Suite
struct JobDequeTests {

    @Test
    func emptyDequeReportsIsEmpty() {
        let deque = Executor.Job.Deque(capacity: 8)
        let empty = deque.isEmpty
        #expect(empty)
    }

    @Test
    func takeFromEmptyReturnsNil() {
        let deque = Executor.Job.Deque(capacity: 8)
        #expect(deque.take() == nil)
    }

    @Test
    func stealFromEmptyReturnsNil() {
        let deque = Executor.Job.Deque(capacity: 8)
        #expect(deque.steal() == nil)
    }

    @Test
    func pushTakeRoundTrip() {
        let deque = Executor.Job.Deque(capacity: 8)
        #expect(deque.push(unsafe UnownedJob.mock(42)))
        let notEmpty = !deque.isEmpty
        #expect(notEmpty)
        let job = deque.take()
        #expect(job != nil)
        #expect(unsafe job!.tag == 42)
        let emptyAfterTake = deque.isEmpty
        #expect(emptyAfterTake)
    }

    @Test
    func pushStealRoundTrip() {
        let deque = Executor.Job.Deque(capacity: 8)
        #expect(deque.push(unsafe UnownedJob.mock(99)))
        let job = deque.steal()
        #expect(job != nil)
        #expect(unsafe job!.tag == 99)
        let emptyAfterSteal = deque.isEmpty
        #expect(emptyAfterSteal)
    }

    @Test
    func pushReturnsFalseWhenFull() {
        let deque = Executor.Job.Deque(capacity: 4)
        for i in 0..<4 {
            #expect(deque.push(unsafe UnownedJob.mock(i)))
        }
        let full = !deque.push(unsafe UnownedJob.mock(999))
        #expect(full)
    }

    // V1: Single-threaded LIFO/FIFO discipline (port of spike V1).
    @Test
    func lifoTakeFifoSteal() {
        let d = Executor.Job.Deque(capacity: 8)

        for i in 0..<5 {
            #expect(d.push(unsafe UnownedJob.mock(i)))
        }

        // Owner takes LIFO: 4, 3
        #expect(unsafe d.take()!.tag == 4)
        #expect(unsafe d.take()!.tag == 3)

        // Stealer takes FIFO: 0
        #expect(unsafe d.steal()!.tag == 0)

        // Owner takes remaining LIFO: 2, 1
        #expect(unsafe d.take()!.tag == 2)
        #expect(unsafe d.take()!.tag == 1)

        // Empty
        #expect(d.take() == nil)
        #expect(d.steal() == nil)
    }

    // V2: Contended push/take/steal with count reconciliation
    // (port of spike V2). Verifies pushed == taken + stolen.
    @Test
    func contendedCountReconciliation() async {
        let h = HeapHarness(capacity: 4096)
        let totalPush = 100_000
        let stealerCount = 4

        await withTaskGroup(of: Void.self) { group in
            // Owner
            group.addTask {
                var pushed = 0
                var localTaken = 0
                while pushed < totalPush {
                    if h.deque.push(unsafe UnownedJob.mock(pushed)) {
                        pushed += 1
                        if pushed % 10 == 0, h.deque.take() != nil {
                            localTaken += 1
                        }
                    } else {
                        await Task.yield()
                    }
                }
                while h.deque.take() != nil {
                    localTaken += 1
                }
                h.taken.wrappingAdd(localTaken, ordering: .releasing)
                h.pushDone.store(1, ordering: .releasing)
            }

            // Stealers
            for _ in 0..<stealerCount {
                group.addTask {
                    var localStolen = 0
                    while h.pushDone.load(ordering: .acquiring) == 0 {
                        if h.deque.steal() != nil {
                            localStolen += 1
                        } else {
                            await Task.yield()
                        }
                    }
                    while h.deque.steal() != nil {
                        localStolen += 1
                    }
                    h.stolen.wrappingAdd(localStolen, ordering: .releasing)
                }
            }
        }

        let t = h.taken.load(ordering: .acquiring)
        let s = h.stolen.load(ordering: .acquiring)
        #expect(t + s == totalPush)
    }
}

// MARK: - Static Variant

@Suite
struct JobDequeStaticTests {

    @Test
    func emptyStaticDequeReportsIsEmpty() {
        let deque = Executor.Job.Deque.Static<8>()
        let empty = deque.isEmpty
        #expect(empty)
    }

    @Test
    func takeFromEmptyStaticReturnsNil() {
        let deque = Executor.Job.Deque.Static<8>()
        #expect(deque.take() == nil)
    }

    @Test
    func stealFromEmptyStaticReturnsNil() {
        let deque = Executor.Job.Deque.Static<8>()
        #expect(deque.steal() == nil)
    }

    @Test
    func staticPushTakeRoundTrip() {
        let deque = Executor.Job.Deque.Static<8>()
        #expect(deque.push(unsafe UnownedJob.mock(42)))
        let job = deque.take()
        #expect(job != nil)
        #expect(unsafe job!.tag == 42)
        let emptyAfterTake = deque.isEmpty
        #expect(emptyAfterTake)
    }

    @Test
    func staticPushReturnsFalseWhenFull() {
        let deque = Executor.Job.Deque.Static<4>()
        for i in 0..<4 {
            #expect(deque.push(unsafe UnownedJob.mock(i)))
        }
        let full = !deque.push(unsafe UnownedJob.mock(999))
        #expect(full)
    }

    @Test
    func staticLifoTakeFifoSteal() {
        let d = Executor.Job.Deque.Static<8>()

        for i in 0..<5 {
            #expect(d.push(unsafe UnownedJob.mock(i)))
        }

        #expect(unsafe d.take()!.tag == 4)
        #expect(unsafe d.take()!.tag == 3)
        #expect(unsafe d.steal()!.tag == 0)
        #expect(unsafe d.take()!.tag == 2)
        #expect(unsafe d.take()!.tag == 1)

        #expect(d.take() == nil)
        #expect(d.steal() == nil)
    }

    // Contended test uses concrete StaticHarness<256> class
    // to avoid ~Copyable capture issues in @escaping closures.
    @Test
    func staticContendedCountReconciliation() async {
        let h = StaticHarness()
        let totalPush = 100_000
        let stealerCount = 4

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                var pushed = 0
                var localTaken = 0
                while pushed < totalPush {
                    if h.deque.push(unsafe UnownedJob.mock(pushed)) {
                        pushed += 1
                        if pushed % 10 == 0, h.deque.take() != nil {
                            localTaken += 1
                        }
                    } else {
                        await Task.yield()
                    }
                }
                while h.deque.take() != nil {
                    localTaken += 1
                }
                h.taken.wrappingAdd(localTaken, ordering: .releasing)
                h.pushDone.store(1, ordering: .releasing)
            }

            for _ in 0..<stealerCount {
                group.addTask {
                    var localStolen = 0
                    while h.pushDone.load(ordering: .acquiring) == 0 {
                        if h.deque.steal() != nil {
                            localStolen += 1
                        } else {
                            await Task.yield()
                        }
                    }
                    while h.deque.steal() != nil {
                        localStolen += 1
                    }
                    h.stolen.wrappingAdd(localStolen, ordering: .releasing)
                }
            }
        }

        let t = h.taken.load(ordering: .acquiring)
        let s = h.stolen.load(ordering: .acquiring)
        #expect(t + s == totalPush)
    }
}
