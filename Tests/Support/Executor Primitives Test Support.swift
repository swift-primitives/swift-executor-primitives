extension UnownedJob {

    @unsafe
    @inlinable
    public static func mock(_ tag: Int) -> UnownedJob {
        unsafe unsafeBitCast(tag &+ 1, to: UnownedJob.self)
    }

    @unsafe
    @inlinable
    public var tag: Int {
        unsafe unsafeBitCast(self, to: Int.self) &- 1
    }
}
