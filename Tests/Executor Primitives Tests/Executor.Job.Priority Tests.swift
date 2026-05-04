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

import Clock_Primitives
import Executor_Primitives
import Executor_Primitives_Test_Support
import Testing

@Suite
struct JobPriorityTests {

    @Test
    func `empty priority queue reports isEmpty`() {
        let pq = Executor.Job.Priority()
        let empty = pq.isEmpty
        #expect(empty)
    }

    @Test
    func `peek on empty returns nil`() {
        let pq = Executor.Job.Priority()
        let deadline = pq.peek
        #expect(deadline == nil)
    }

    @Test
    func `pop on empty returns nil`() {
        var pq = Executor.Job.Priority()
        let now = Clock.Continuous.Instant(nanoseconds: 0)
        let result = pq.pop(now: now)
        #expect(result == nil)
    }

    @Test
    func `same-deadline jobs drain in FIFO insertion order`() {
        var pq = Executor.Job.Priority()
        let deadline = Clock.Continuous.Instant(nanoseconds: 0)

        for tag in 0..<5 {
            pq.schedule(unsafe UnownedJob.mock(tag), at: deadline)
        }

        let fireTime = deadline.advanced(by: .seconds(1))
        var observed: [Int] = []
        pq.drain(now: fireTime) { unsafe observed.append($0.tag) }

        #expect(observed == [0, 1, 2, 3, 4])
    }

    @Test
    func `earlier deadline fires before later deadline regardless of insertion order`() {
        var pq = Executor.Job.Priority()
        let now = Clock.Continuous.Instant(nanoseconds: 0)
        let later = now.advanced(by: .milliseconds(100))
        let earlier = now.advanced(by: .milliseconds(10))

        pq.schedule(unsafe UnownedJob.mock(42), at: later)
        pq.schedule(unsafe UnownedJob.mock(7), at: earlier)

        let fireTime = now.advanced(by: .seconds(1))
        var observed: [Int] = []
        pq.drain(now: fireTime) { unsafe observed.append($0.tag) }

        #expect(observed == [7, 42])
    }

    @Test
    func `deadline dominates FIFO sequence across mixed insertions`() {
        var pq = Executor.Job.Priority()
        let now = Clock.Continuous.Instant(nanoseconds: 0)
        let early = now.advanced(by: .milliseconds(10))
        let mid = now.advanced(by: .milliseconds(50))

        pq.schedule(unsafe UnownedJob.mock(100), at: mid)
        pq.schedule(unsafe UnownedJob.mock(0), at: early)
        pq.schedule(unsafe UnownedJob.mock(101), at: mid)
        pq.schedule(unsafe UnownedJob.mock(1), at: early)
        pq.schedule(unsafe UnownedJob.mock(2), at: early)

        let fireTime = now.advanced(by: .seconds(1))
        var observed: [Int] = []
        pq.drain(now: fireTime) { unsafe observed.append($0.tag) }

        #expect(observed == [0, 1, 2, 100, 101])
    }
}
