import Executor_Primitives
import Testing

extension Executor.Shutdown.Flag {
    @Suite
    struct Test {

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
}
