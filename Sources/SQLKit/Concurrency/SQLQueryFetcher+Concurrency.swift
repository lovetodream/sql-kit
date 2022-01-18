#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

#if compiler(>=5.5.2)
@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension SQLQueryFetcher {
    func first<D>(decoding: D.Type) async throws -> D? where D: Decodable {
        return try await self.first(decoding: D.self).get()
    }
    
    func firstRecordingPerformance<D>(decoding: D.Type) async throws -> (D?, SQLQueryPerformanceRecord)
        where D: Decodable
    {
        return try await self.firstRecordingPerformance(decoding: D.self).get()
    }

    func first() async throws -> SQLRow? {
        return try await self.first().get()
    }
    
    func firstRecordingPerformance() async throws -> (SQLRow?, SQLQueryPerformanceRecord) {
        return try await self.firstRecordingPerformance().get()
    }

    func all<D>(decoding: D.Type) async throws -> [D] where D: Decodable {
        return try await self.all(decoding: D.self).get()
    }
    
    func allRecordingPerformance<D>(decoding: D.Type) async throws -> ([D], SQLQueryPerformanceRecord)
        where D: Decodable
    {
        return try await self.allRecordingPerformance(decoding: D.self).get()
    }

    func all() async throws -> [SQLRow] {
        return try await self.all().get()
    }
    
    func allRecordingPerformance() async throws -> ([SQLRow], SQLQueryPerformanceRecord) {
        return try await self.allRecordingPerformance().get()
    }

    func run<D>(decoding: D.Type, _ handler: @escaping (Result<D, Error>) -> ()) async throws -> Void where D: Decodable {
        return try await self.run(decoding: D.self, handler).get()
    }
    
    func runRecordingPerformance<D>(
        decoding: D.Type,
        _ handler: @escaping (Result<D, Error>) -> ()
    ) async throws -> SQLQueryPerformanceRecord
        where D: Decodable
    {
        try await self.runRecordingPerformance(decoding: D.self, handler).get()
    }

    func run(_ handler: @escaping (SQLRow) -> ()) async throws -> Void {
        return try await self.run(handler).get()
    }

    func runRecordingPerformance(
        _ handler: @escaping (SQLRow) -> ()
    ) async throws -> SQLQueryPerformanceRecord {
        try await self.runRecordingPerformance(handler).get()
    }
}
#else
@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension SQLQueryFetcher {
    func first<D>(decoding: D.Type) async throws -> D? where D: Decodable {
        return try await self.first(decoding: D.self).get()
    }
    
    func firstRecordingPerformance<D>(decoding: D.Type) async throws -> (D?, SQLQueryPerformanceRecord)
        where D: Decodable
    {
        return try await self.firstRecordingPerformance(decoding: D.self).get()
    }

    func first() async throws -> SQLRow? {
        return try await self.first().get()
    }
    
    func firstRecordingPerformance() async throws -> (SQLRow?, SQLQueryPerformanceRecord) {
        return try await self.firstRecordingPerformance().get()
    }

    func all<D>(decoding: D.Type) async throws -> [D] where D: Decodable {
        return try await self.all(decoding: D.self).get()
    }
    
    func allRecordingPerformance<D>(decoding: D.Type) async throws -> ([D], SQLQueryPerformanceRecord)
        where D: Decodable
    {
        return try await self.allRecordingPerformance(decoding: D.self).get()
    }

    func all() async throws -> [SQLRow] {
        return try await self.all().get()
    }
    
    func allRecordingPerformance() async throws -> ([SQLRow], SQLQueryPerformanceRecord) {
        return try await self.allRecordingPerformance().get()
    }

    func run<D>(decoding: D.Type, _ handler: @escaping (Result<D, Error>) -> ()) async throws -> Void where D: Decodable {
        return try await self.run(decoding: D.self, handler).get()
    }
    
    func runRecordingPerformance<D>(
        decoding: D.Type,
        _ handler: @escaping (Result<D, Error>) -> ()
    ) async throws -> SQLQueryPerformanceRecord
        where D: Decodable
    {
        try await self.runRecordingPerformance(decoding: D.self, handler).get()
    }

    func run(_ handler: @escaping (SQLRow) -> ()) async throws -> Void {
        return try await self.run(handler).get()
    }

    func runRecordingPerformance(
        _ handler: @escaping (SQLRow) -> ()
    ) async throws -> SQLQueryPerformanceRecord {
        try await self.runRecordingPerformance(handler).get()
    }
}
#endif

#endif
