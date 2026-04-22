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

// MARK: - Mock Job Factory

extension UnownedJob {
    /// Creates a distinguishable `UnownedJob` from an integer tag.
    ///
    /// `UnownedJob` is `BitwiseCopyable` and pointer-sized. The job is never
    /// executed — safe for container-semantics testing only.
    ///
    /// Tags are offset by 1 internally: `Optional<UnownedJob>` uses the null
    /// bit pattern as its `.none` representation, so tag 0 must not produce
    /// a zero-valued pointer.
    @unsafe
    @inlinable
    public static func mock(_ tag: Int) -> UnownedJob {
        unsafe unsafeBitCast(tag &+ 1, to: UnownedJob.self)
    }

    /// Recovers the integer tag from a mock job created by ``mock(_:)``.
    @unsafe
    @inlinable
    public var tag: Int {
        unsafe unsafeBitCast(self, to: Int.self) &- 1
    }
}
