/// A builder which can construct - but _not_ execute - a complete `SELECT` query.
/// Useful for building CTEs, `CREATE TABLE ... SELECT` clauses, etc., not to
/// mention actual `SELECT` queries.
///
/// - Important: Despite the use of the term "subquery", this builder does not provide
///   methods for specifying subquery operators (e.g. `ANY`, `SOME`) or CTE clauses (`WITH`),
///   nor does it enclose its result in grouping parenthesis, as all of these formations are
///   context-specific and are the purview of builders that conform to this protocol.
///
/// - Note: The primary motivation for the existence of this protocol is to make it easier
///   to construct `SELECT` queries without specifying a database or providing the
///   `SQLQueryBuilder` and `SQLQueryFetcher` methods in inappropriate contexts.
public protocol SQLSubqueryClauseBuilder: SQLJoinBuilder, SQLPredicateBuilder, SQLSecondaryPredicateBuilder, SQLPartialResultBuilder {
    var select: SQLSelect { get set }
}

extension SQLSubqueryClauseBuilder {
    public var joins: [SQLExpression] {
        get { self.select.joins }
        set { self.select.joins = newValue }
    }
}

extension SQLSubqueryClauseBuilder {
    public var predicate: SQLExpression? {
        get { return self.select.predicate }
        set { self.select.predicate = newValue }
    }
}

extension SQLSubqueryClauseBuilder {
    public var secondaryPredicate: SQLExpression? {
        get { return self.select.having }
        set { self.select.having = newValue }
    }
}

extension SQLSubqueryClauseBuilder {
    public var orderBys: [SQLExpression] {
        get { self.select.orderBy }
        set { self.select.orderBy = newValue }
    }
    
    public var limit: Int? {
        get { self.select.limit }
        set { self.select.limit = newValue }
    }
    
    public var offset: Int? {
        get { self.select.offset }
        set { self.select.offset = newValue }
    }
}

// MARK: - Distinct

extension SQLSubqueryClauseBuilder {
    /// Adds a `DISTINCT` clause to the query.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    public func distinct() -> Self {
        self.select.isDistinct = true
        return self
    }
}

// MARK: - Columns

extension SQLSubqueryClauseBuilder {
    /// Specify a column to be part of the result set of the query. The column is a string
    /// assumed to be a valid SQL identifier and is not qualified.
    ///
    /// The string `*` (a single asterisk) is recognized and replaced with `SQLLiteral.all`.
    ///
    /// - Parameter column: The name of the column to return, or `*` for all.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func column(_ column: String) -> Self {
        if column == "*" {
            return self.column(SQLLiteral.all)
        } else {
            return self.column(SQLColumn(SQLIdentifier(column)))
        }
    }
    
    /// Specify a column to be part of the result set of the query. The column is a string
    /// assumed to be a valid SQL identifier, qualified by a table name, also a string assumed
    /// to be a valid SQL identifier.
    ///
    /// The string `*` (a single asterisk) is recognized and replaced with `SQLLiteral.all`.
    ///
    /// - Parameters:
    ///   - table: The name of a table to qualify the column name.
    ///   - column: The name of the column to return, or `*` for all.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func column(table: String, column: String) -> Self {
        if column == "*" {
            return self.column(SQLColumn(SQLLiteral.all, table: SQLIdentifier(table)))
        } else {
            return self.column(SQLColumn(SQLIdentifier(column), table: SQLIdentifier(table)))
        }
    }

    /// Specify a column to retrieve as a `String`, and an alias for it with another `String`.
    ///
    /// - Parameters:
    ///   - column: The name of the column to return.
    ///   - alias: The label to give the returned column.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func column(_ column: String, as alias: String) -> Self {
        return self.column(SQLIdentifier(column), as: SQLIdentifier(alias))
    }

    /// Specify a column to retrieve as an `SQLExpression`, and an alias for it with a `String`.
    ///
    /// - Parameters:
    ///   - column: An expression identifying the desired data to return.
    ///   - alias: A string specifying the desired label of the identified data.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func column(_ column: SQLExpression, as alias: String) -> Self {
        return self.column(column, as: SQLIdentifier(alias))
    }

    /// Specify a column to retrieve as an `SQLExpression`, and an alias for it with another `SQLExpression`.
    ///
    /// - Parameters:
    ///   - column: An expression identifying the desired data to return.
    ///   - alias: An expression specifying the desired label of the identified data.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func column(_ column: SQLExpression, as alias: SQLExpression) -> Self {
        return self.column(SQLAlias(column, as: alias))
    }

    /// Specify an arbitrary expression as a column to be part of the result set of the query.
    ///
    /// - Parameter expr: An expression identifying the desired data to return.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func column(_ expr: SQLExpression) -> Self {
        self.select.columns.append(expr)
        return self
    }
    
    /// Specify a list of columns to be part of the result set of the query. Each provided name
    /// is a string assumed to be a valid SQL identifier and is not qualified. The string `*` is
    /// recognized and replaced with `SQLLiteral.all`.
    ///
    /// - Parameter columns: The names of the columns to return.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func columns(_ columns: String...) -> Self {
        return self.columns(columns)
    }
    
    /// Specify a list of columns to be part of the result set of the query. Each provided name
    /// is a string assumed to be a valid SQL identifier and is not qualified. The string `*` is
    /// recognized and replaced with `SQLLiteral.all`.
    ///
    /// - Parameter columns: The names of the columns to return.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func columns(_ columns: [String]) -> Self {
        return columns.reduce(self) { $0.column($1) }
    }
    
    /// Specify a list of arbitrary expressions as columns to be part of the result set of the query.
    ///
    /// - Parameter columns: A list of expressions identifying the desired data to return.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func columns(_ columns: SQLExpression...) -> Self {
        return self.columns(columns)
    }
    
    /// Specify a list of arbitrary expressions as columns to be part of the result set of the query.
    ///
    /// - Parameter columns: A list of expressions identifying the desired data to return.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func columns(_ columns: [SQLExpression]) -> Self {
        return columns.reduce(self) { $0.column($1) }
    }
}

// MARK: - From

extension SQLSubqueryClauseBuilder {
    /// Include the given table in the list of those used by the query, without performing an
    /// explicit join. The table specifier is a string assumed to be a valid SQL identifier.
    ///
    /// - Parameter table: The name of the table to use.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func from(_ table: String) -> Self {
        return self.from(SQLIdentifier(table))
    }
    
    /// Include the given table in the list of those used by the query, without performing an
    /// explicit join. The table specifier may be any expression.
    ///
    /// - Parameter table: An expression identifying the table to use.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func from(_ table: SQLExpression) -> Self {
        self.select.tables.append(table)
        return self
    }
    
    /// Include the given table in the list of those used by the query, without performing an
    /// explicit join. An alias for the table may be provided. The table and alias specifiers
    /// are strings assumed to be valid SQL identifiers.
    ///
    /// - Parameters:
    ///   - table: The name of the table to use.
    ///   - alias: The alias to use for the table.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func from(_ table: String, as alias: String) -> Self {
        return self.from(SQLIdentifier(table), as: SQLIdentifier(alias))
    }
    
    /// Include the given table in the list of those used by the query, without performing an
    /// explicit join. The table and alias specifiers may be arbitrary expressions.
    ///
    /// - Parameters:
    ///   - table: An expression identifying the table to use.
    ///   - alias: An expression providing the alias to use for the table.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func from(_ table: SQLExpression, as alias: SQLExpression) -> Self {
        return self.from(SQLAlias(table, as: alias))
    }
}

// MARK: - Group By

extension SQLSubqueryClauseBuilder {
    /// Adds a `GROUP BY` clause to the query with the specified column.
    ///
    /// - Parameter column: Name of column to group results by. Appended to any previously added grouping expressions.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func groupBy(_ column: String) -> Self {
        return self.groupBy(SQLColumn(column))
    }

    /// Adds a `GROUP BY` clause to the query with the specified expression.
    ///
    /// - Parameter expression: Expression to group results by. Appended to any previously added grouping expressions.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func groupBy(_ expression: SQLExpression) -> Self {
        self.select.groupBy.append(expression)
        return self
    }
}

// MARK: - Locking

extension SQLSubqueryClauseBuilder {
    /// Adds a locking clause to this query. If called more than once, the last call wins.
    ///
    /// ```swift
    /// db.select()...for(.update)
    /// db.select()...for(.share)
    /// ```
    ///
    /// Also referred to as locking or "consistent" reads, the locking clause syntax locks
    /// all selected rows for the duration of the current transaction with a type of lock
    /// determined by the specific locking clause and the underlying database's support for
    /// this construct.
    ///
    /// - Warning: If the database in use does not support locking reads, the locking clause
    ///   will be silently ignored regardless of its value.
    ///
    /// - Parameter lockingClause: The type of lock to obtain. See ``SQLLockingClause``.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func `for`(_ lockingClause: SQLLockingClause) -> Self {
        return self.lockingClause(lockingClause)
    }

    /// Adds a locking clause to this query as specified by an arbitrary ``SQLExpression``.
    /// If called more than once, the last call wins.
    ///
    /// ```swift
    /// db.select()...lockingClause(...)
    /// ```
    ///
    /// Also referred to as locking or "consistent" reads, the locking clause syntax locks
    /// all selected rows for the duration of the current transaction with a type of lock
    /// determined by the specific locking clause and the underlying database's support for
    /// this construct.
    ///
    /// - Note: This method allows providing an arbitrary SQL expression as the locking clause.
    ///
    /// - Parameter lockingClause: The locking clause as an SQL expression.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func lockingClause(_ lockingClause: SQLExpression) -> Self {
        self.select.lockingClause = lockingClause
        return self
    }
}
