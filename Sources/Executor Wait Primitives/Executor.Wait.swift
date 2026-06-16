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

extension Executor {
    /// Namespace for wait primitives.
    ///
    /// Concrete types satisfy the conceptual "wait primitive" contract
    /// statically: `Event.Source` (this package) for kernel-event-backed
    /// wait, and condition-variable-backed wait at the compositions layer.
    /// Compositions select their wait type by stored property, not by
    /// protocol. When a third wait mechanism ships, `Wait.Primitive`
    /// becomes a real protocol with retroactive conformances.
    public enum Wait {}
}
