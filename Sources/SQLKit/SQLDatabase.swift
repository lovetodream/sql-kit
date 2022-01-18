import Dispatch
import NIOCore

public protocol SQLDatabase {
    var logger: Logger { get }
    var eventLoop: EventLoop { get }
    var dialect: SQLDialect { get }
    func execute(
        sql query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<Void>
    func execute(
        sqlWithPerformanceTracking query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<SQLQueryPerformanceRecord>
}

extension SQLDatabase {
    public func execute(
        sqlWithPerformanceTracking query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<SQLQueryPerformanceRecord> {
        // By default, when perf tracking is requested of a database that doesn't otherwise support
        // it, at least measure the total execution time as best we can.
        var perfRecord = SQLQueryPerformanceRecord()
        let queryStart = DispatchTime.now()
        
        return self.execute(sql: query, onRow).map {
            perfRecord.record(DispatchTime.secondsElapsed(since: queryStart), for: .fullExecutionDuration)
            perfRecord.record(true, for: .fluentBypassFlag)
            return perfRecord
        }
    }
    
    public func execute<D>(
        sql query: SQLExpression,
        decoding: D.Type,
        _ handler: @escaping (Result<D, Error>) -> ()
    ) -> EventLoopFuture<Void>
        where D: Decodable
    {
        return self.execute(sql: query) { row in handler(.init(catching: { try row.decode(model: D.self) })) }
    }

    public func execute<D>(
        sqlWithPerformanceTracking query: SQLExpression,
        decoding: D.Type,
        _ handler: @escaping (Result<D, Error>) -> ()
    ) -> EventLoopFuture<SQLQueryPerformanceRecord>
        where D: Decodable
    {
        var totalDecodeTime = 0.0
        
        return self.execute(sqlWithPerformanceTracking: query) { row in
            let decodeStart = DispatchTime.now()
            let result = Result<D, Error>(catching: { try row.decode(model: D.self) })
            
            totalDecodeTime += DispatchTime.secondsElapsed(since: decodeStart)
            handler(result)
        }.map { perfRecord in
            var perfRecord = perfRecord
            perfRecord.record(totalDecodeTime, for: .structuredResultDecodingDuration)
            perfRecord.apply(valueFor: .structuredResultDecodingDuration, to: .fullExecutionDuration)
            perfRecord.record(true, for: .fluentBypassFlag)
            return perfRecord
        }
    }

    public func serialize(_ expression: SQLExpression) -> (sql: String, binds: [Encodable]) {
        var serializer = SQLSerializer(database: self)
        expression.serialize(to: &serializer)
        return (serializer.sql, serializer.binds)
    }
 }

extension SQLDatabase {
    public func logging(to logger: Logger) -> SQLDatabase {
        CustomLoggerSQLDatabase(database: self, logger: logger)
    }
}

private struct CustomLoggerSQLDatabase: SQLDatabase {
    let database: SQLDatabase
    let logger: Logger
    var eventLoop: EventLoop {
        return self.database.eventLoop
    }
    
    var dialect: SQLDialect {
        self.database.dialect
    }
    
    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) -> ()) -> EventLoopFuture<Void> {
        self.database.execute(sql: query, onRow)
    }
    
    func execute(
        sqlWithPerformanceTracking query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<SQLQueryPerformanceRecord> {
        self.database.execute(sqlWithPerformanceTracking: query, onRow)
    }
}
