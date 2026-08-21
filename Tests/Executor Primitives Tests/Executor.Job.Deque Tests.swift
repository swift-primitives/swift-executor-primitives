import Executor_Primitives_Test_Support
import Synchronization
import Testing

private final class HeapHarness: @unchecked Sendable {
    let deque: Executor.Job.Deque
    let taken = Atomic<Int>(0)
    let stolen = Atomic<Int>(0)
    let pushDone = Atomic<Int>(0)

    init(capacity: Int) {
        self.deque = .init(capacity: capacity)
    }
}

extension Executor.Job.Deque {
    @Suite
    struct Test {

        @Test
        func `empty Deque Reports Is Empty`() {
            let deque = Executor.Job.Deque(capacity: 8)
            let empty = deque.isEmpty
            #expect(empty)
        }

        @Test
        func `take From Empty Returns Nil`() {
            let deque = Executor.Job.Deque(capacity: 8)
            #expect(deque.take() == nil)
        }

        @Test
        func `steal From Empty Returns Nil`() {
            let deque = Executor.Job.Deque(capacity: 8)
            #expect(deque.steal() == nil)
        }

        @Test
        func `push Take Round Trip`() {
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
        func `push Steal Round Trip`() {
            let deque = Executor.Job.Deque(capacity: 8)
            #expect(deque.push(unsafe UnownedJob.mock(99)))
            let job = deque.steal()
            #expect(job != nil)
            #expect(unsafe job!.tag == 99)
            let emptyAfterSteal = deque.isEmpty
            #expect(emptyAfterSteal)
        }

        @Test
        func `push Returns False When Full`() {
            let deque = Executor.Job.Deque(capacity: 4)
            (0..<4).forEach { i in
                #expect(deque.push(unsafe UnownedJob.mock(i)))
            }
            let full = !deque.push(unsafe UnownedJob.mock(999))
            #expect(full)
        }

        @Test
        func `lifo Take Fifo Steal`() {
            let d = Executor.Job.Deque(capacity: 8)

            (0..<5).forEach { i in
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

        @Test
        func `contended Count Reconciliation`() async {
            let h = HeapHarness(capacity: 4096)
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
}
