#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

#if compiler(>=5.5.2)
@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension SQLQueryBuilder {
    func run() async throws -> Void {
        return try await self.run().get()
    }
    
    func runRecordingPerformance() async throws -> SQLQueryPerformanceRecord {
        return try await self.runRecordingPerformance().get()
    }
}
#else
@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension SQLQueryBuilder {
    func run() async throws -> Void {
        return try await self.run().get()
    }

    func runRecordingPerformance() async throws -> SQLQueryPerformanceRecord {
        return try await self.runRecordingPerformance().get()
    }
}
#endif

#endif
