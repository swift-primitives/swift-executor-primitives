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
import Executor_Primitives

@Suite
struct ShutdownFlagTests {

    @Test
    func `initial state is not set`() {
        let flag = Executor.Shutdown.Flag()
        let value = flag.isSet
        #expect(!value)
    }

    @Test
    func `set transitions to true`() {
        let flag = Executor.Shutdown.Flag()
        flag.set()
        let value = flag.isSet
        #expect(value)
    }

    @Test
    func `multiple set calls are idempotent`() {
        let flag = Executor.Shutdown.Flag()
        flag.set()
        flag.set()
        let value = flag.isSet
        #expect(value)
    }
}
