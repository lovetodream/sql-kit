import NIO
import Dispatch

/// A `SQLQueryBuilder` that supports decoding results.
///
///     builder.all(decoding: Planet.self)
///
public protocol SQLQueryFetcher: SQLQueryBuilder { }

extension SQLQueryFetcher {
    // MARK: First

    public func first<D>(decoding: D.Type) -> EventLoopFuture<D?>
        where D: Decodable
    {
        self.all(decoding: D.self).map { $0.first }
    }
    
    public func firstRecordingPerformance<D>(
        decoding: D.Type
    ) -> EventLoopFuture<(D?, SQLQueryPerformanceRecord)>
        where D: Decodable
    {
        self.allRecordingPerformance(decoding: D.self).map { ($0.first, $1) }
    }
    
    /// Collects the first raw output and returns it.
    ///
    ///     builder.first()
    ///
    public func first() -> EventLoopFuture<SQLRow?> {
        return self.all().map { $0.first }
    }
    
    public func firstRecordingPerformance() -> EventLoopFuture<(SQLRow?, SQLQueryPerformanceRecord)> {
        return self.allRecordingPerformance().map { ($0.first, $1) }
    }
    
    
    // MARK: All

    // These are implemented this way specifically to ensure everything funnels through
    // the "run()" methods.

    public func all<D>(decoding: D.Type) -> EventLoopFuture<[D]>
        where D: Decodable
    {
        var models: [D] = []
        let promise = self.database.eventLoop.makePromise(of: [D].self)
        
        return self.run(decoding: D.self) { switch $0 {
            case .success(let model): models.append(model)
            case .failure(let error): promise.fail(error)
        } }.flatMap {
            promise.succeed(models)
            return promise.futureResult
        }
    }

    public func allRecordingPerformance<D>(
        decoding: D.Type
    ) -> EventLoopFuture<([D], SQLQueryPerformanceRecord)>
        where D: Decodable
    {
        var models: [D] = []
        let promise = self.database.eventLoop.makePromise(of: ([D], SQLQueryPerformanceRecord).self)
        
        return self.runRecordingPerformance(decoding: D.self) { switch $0 {
            case .success(let model): models.append(model)
            case .failure(let error): promise.fail(error)
        } }.flatMap {
            promise.succeed((models, $0))
            return promise.futureResult
        }
    }

    /// Collects all raw output into an array and returns it.
    ///
    ///     builder.all()
    ///
    public func all() -> EventLoopFuture<[SQLRow]> {
        var all: [SQLRow] = []
        return self.run { all.append($0) }.map { all }
    }
    
    public func allRecordingPerformance() -> EventLoopFuture<([SQLRow], SQLQueryPerformanceRecord)> {
        var all: [SQLRow] = []
        return self.runRecordingPerformance { all.append($0) }.map { (all, $0) }
    }

    // MARK: Run


    public func run<D>(decoding: D.Type, _ handler: @escaping (Result<D, Error>) -> ()) -> EventLoopFuture<Void>
        where D: Decodable
    {
        return self.database.execute(sql: self.query, decoding: D.self, handler)
    }
    
    public func runRecordingPerformance<D>(
        decoding: D.Type,
        _ handler: @escaping (Result<D, Error>) -> ()
    ) -> EventLoopFuture<SQLQueryPerformanceRecord>
        where D: Decodable
    {
        return self.database.execute(sqlWithPerformanceTracking: self.query, decoding: D.self, handler)
    }
    
    /// Runs the query, passing output to the supplied closure as it is recieved.
    ///
    ///     builder.run { print($0) }
    ///
    /// The returned future will signal completion of the query.
    public func run(_ handler: @escaping (SQLRow) -> ()) -> EventLoopFuture<Void> {
        return self.database.execute(sql: self.query, handler)
    }

    public func runRecordingPerformance(
        _ handler: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<SQLQueryPerformanceRecord> {
        return self.database.execute(sqlWithPerformanceTracking: self.query, handler)
    }
}
