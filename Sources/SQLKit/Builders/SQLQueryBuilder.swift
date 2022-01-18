import NIO

/// Builds queries and executes them on a connection.
///
///     builder.run()
///
public protocol SQLQueryBuilder: AnyObject {
    /// Query being built.
    var query: SQLExpression { get }
    
    /// Connection to execute query on.
    var database: SQLDatabase { get }

    func run() -> EventLoopFuture<Void>
    
    func runRecordingPerformance() -> EventLoopFuture<SQLQueryPerformanceRecord>
}

extension SQLQueryBuilder {
    /// Runs the query.
    ///
    ///     builder.run()
    ///
    /// - returns: A future signaling completion.
    public func run() -> EventLoopFuture<Void> {
        return self.database.execute(sql: self.query) { _ in }
    }
    
    /// Runs the query, keeping track performance metrics when supported by the database driver.
    ///
    ///     builder.runRecordingPerformance().map {
    ///         builder.database.logger.info("Query performance: \($0.description)")
    ///     }
    ///
    /// - returns: A future signaling completion and containing any perforamnce metrics which\
    ///   were successfully measured.
    public func runRecordingPerformance() -> EventLoopFuture<SQLQueryPerformanceRecord> {
        return self.database.execute(sqlWithPerformanceTracking: self.query) { _ in }
    }
}
