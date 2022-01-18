#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

#if compiler(>=5.5.2)
@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension SQLDatabase {
    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) -> ()) async throws -> Void {
        try await self.execute(sql: query, onRow).get()
    }

    func execute(
        sqlWithPerformanceTracking query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) async throws -> SQLQueryPerformanceRecord {
        try await self.execute(sqlWithPerformanceTracking: query, onRow).get()
    }
}
#else
@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension SQLDatabase {
    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) -> ()) async throws -> Void {
        try await self.execute(sql: query, onRow).get()
    }

    func execute(
        sqlWithPerformanceTracking query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) async throws -> SQLQueryPerformanceRecord {
        try await self.execute(sqlWithPerformanceTracking: query, onRow).get()
    }
}
#endif

#endif
