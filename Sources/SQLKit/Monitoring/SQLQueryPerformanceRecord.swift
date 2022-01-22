import Collections
import Dispatch
import Foundation
import NIOPosix

public struct SQLQueryPerformanceRecord: Codable {
    private var metrics: OrderedDictionary<Metric, Value> = [:]
    
    public init() {}
    
    /// Check whether there is a recorded value for a particular metric.
    public func hasValue(for metric: Metric) -> Bool {
        return self.metrics.keys.contains(metric)
    }
    
    /// Look up a metric's recorded value, if there is one.
    public subscript(metric metric: Metric) -> Value? {
        get {
            return self.metrics[metric]
        }
    }
    
    /// Record a generic value for a metric. If the specified metric already has a recorded
    /// value, it is overwritten.
    ///
    /// The order in which metrics are recorded is considered significant and is preserved.
    ///
    /// This method is not intended for general use; a performance record is not intended to
    /// be a data bag any more than the tracing library's baggage type is. It is public so that
    /// the various Fluent subsystems and drivers can use it.
    public mutating func record(value: Value, for metric: Metric) {
        self.metrics[metric] = value
    }
    
    /// Return an ordered list of all recorded metrics and their values.
    public func allMetrics() -> [(Metric, Value)] {
        Array(self.metrics.elements)
    }
}

extension SQLQueryPerformanceRecord {
    public struct Metric: RawRepresentable, Hashable, Codable {
        public let rawValue: String
        
        public init(string: String) {
            self.rawValue = string
        }
        
        public init?(rawValue: String) {
            self.init(string: rawValue)
        }
    }
    
    public enum Value: Hashable, Codable {
        case duration(Double)
        case count(Int)
        case flag(Bool)
        case note(String)
    }
}

// MARK: - Predefined metrics

extension SQLQueryPerformanceRecord.Metric {
    /// The overall amount of real time spent executing a query from start to finish,
    /// to the nearest possible approximation, expressed as a floating-point number of
    /// seconds with millisecond or better precision.
    ///
    /// - Important: Not only is it allowed for the sum of all other recorded metrics
    ///   not to add up to this metric's value, it is not even guaranteed that this
    ///   metric will measure as much elapsed time as any other metric or combination
    ///   of metrics. It probably should, most of the time, but measuring elapsed time
    ///   across the callbacks of futures can not always be done accurately.
    public static var fullExecutionDuration: Self { .init(string: "codes.vapor.sqlkit.metric.fullExecution") }

    /// The amount of real time spent converting the `SQLExpression`(s) representing
    /// a query to the actual query text, expressed as a floating-point number of
    /// seconds with millisecond or better precision.
    public static var serializationDuration: Self { .init(string: "codes.vapor.sqlkit.metric.serialization") }

    /// The amount of real time spent encoding the bound query parameters (if any) of
    /// a query to a format suitable for sending to the database, expressed as a floating-
    /// point number of seconds with millisecond or better precision.
    public static var parameterEncodingDuration: Self { .init(string: "codes.vapor.sqlkit.metric.parameterEncoding") }
    
    /// The amount of real time elapsed between sending a query to the database and
    /// the initial receipt of a reply (successful or otherwise), _not_ counting any time
    /// spent receiving any actual result, expressed as a floating-point number of seconds
    /// with millisecond or better precision.
    public static var processingDuration: Self { .init(string: "codes.vapor.sqlkit.metric.processing") }
    
    /// The amount of real time spent decoding a query result set, or database error
    /// message, into the ``SQLRow`` abstaction, _not_ counting any additional time
    /// spent performing further decoding into model structures, expressed as a floating-
    /// point number of seconds with millisecond or better precision.
    public static var outputRowsDecodingDuration: Self { .init(string: "codes.vapor.sqlkit.metric.outputRowsDecoding") }
    
    /// The amount of real time spent futher decoding a series of ``SQLRow``s received
    /// as a result into a sequence of the specified structure or model type, such as via
    /// ``SQLQueryFetcher``'s ``.all(decoding:)`` or ``.first(decoding:)`` methods,
    /// expressed as a floating-point number of seconds with millisecond or better precision.
    public static var structuredResultDecodingDuration: Self { .init(string: "codes.vapor.sqlkit.metric.structuredResultDecoding") }

    /// A length-limited record of the serialized text of a database query. In particular,
    /// excess palceholders are collapsed, so as not to use excessive resources in the case
    /// of queries which insert or select thousands of values.
    public static var serializedQueryText: Self { .init(string: "codes.vapor.sqlkit.metric.serializedQuery") }
    
    /// The number of bound parameters, if any, for a query.
    public static var boundParameterCount: Self { .init(string: "codes.vapor.sqlkit.metric.paramsCount") }
    
    /// The number of result rows, if any, returned from a query. This metric has a value, even
    /// if it is zero, if any attempt to retrieve results - including `RETURNING` clauses - was
    /// made. If it has no value at all, the query did not check for or return any results.
    public static var returnedResultRowCount: Self { .init(string: "codes.vapor.sqlkit.metric.resultCount") }
    
    /// A flag indicating whether a database query was processed via SQLKit (versus FluentKit).
    public static var fluentBypassFlag: Self { .init(string: "codes.vapor.sqlkit.metric.sqlkit-is-best-kit")}
}

// MARK: - Conveniences for drivers
extension SQLQueryPerformanceRecord {
    /// Measure the duration of a closure's execution and record it as a duration metric. The closure must be synchronous.
    /// See ``record(value:for:)``.
    public mutating func measure<R>(metric: Metric, closure: () throws -> R) rethrows -> R {
        let beginTime = DispatchTime.now()
        defer { self.record(DispatchTime.secondsElapsed(since: beginTime), for: metric) }
        return try closure()
    }
    
    /// Record a duration value for a metric. See ``record(value:for:)``.
    public mutating func record(_ value: Double, for metric: Metric) { self.record(value: .duration(value), for: metric) }

    /// Record a count value for a metric. See ``record(value:for:)``.
    public mutating func record(_ value: Int, for metric: Metric) { self.record(value: .count(value), for: metric) }
    
    /// Record a flag value for a metric. See ``record(value:for:)``.
    public mutating func record(_ value: Bool, for metric: Metric) { self.record(value: .flag(value), for: metric) }
    
    /// Record a notation value for a metric. See ``record(value:for:)``.
    public mutating func record(_ value: String, for metric: Metric) { self.record(value: .note(value), for: metric) }
    
    /// Add additional time to a duration metric. Non-duration values are treated as zero. See ``record(value:for:)``.
    public mutating func record(additional: Double, for metric: Metric) { self.record(self.metrics[metric].typed() + additional, for: metric) }

    /// Add additional count to a counter metric. Non-counter values are treated as zero. See ``record(value:for:)``.
    public mutating func record(additional: Int, for metric: Metric) { self.record(self.metrics[metric].typed() + additional, for: metric) }
    
    /// Append additional info to a notation metric. Non-notation values are treated as empty. See ``record(value:for:)``.
    public mutating func record(additional: String, for metric: Metric) { self.record(self.metrics[metric].typed() + additional, for: metric) }
    
    /// Apply a given metric's value to another metric of the same type. Non-matching types cause a fatal error.
    public mutating func apply(valueFor metric1: Metric, to metric2: Metric) {
        guard let val1 = self[metric: metric1], let val2 = self[metric: metric2] else { return }
        if case let .duration(v) = val1, case .duration(_) = val2 { self.record(additional: v, for: metric2) }
        else if case let .count(v) = val1, case .count(_) = val2 { self.record(additional: v, for: metric2) }
        else if case let .note(v) = val1, case .note(_) = val2 { self.record(additional: v, for: metric2) }
        else { fatalError("Mismatching apply metrics") }
    }
    
    /// _Reverse_ the application of a given duration or counter metric's value to another metric. Non-matching metrics cause a fatal error.
    public mutating func deduct(valueFor metric1: Metric, from metric2: Metric) {
        guard let val1 = self[metric: metric1], let val2 = self[metric: metric2] else { return }
        if case let .duration(v) = val1, case .duration(_) = val2 { self.record(additional: -v, for: metric2) }
        else if case let .count(v) = val1, case .count(_) = val2 { self.record(additional: -v, for: metric2) }
        else { fatalError("Can't deduct non-numeric metrics") }
    }

    /// Apply an entire performance record's metrics to all existing metrics. Metrics with values in both records
    /// have their values summed if they are durations or counts; such metrics that exist only in one or the other
    /// are treated as if the missing value is zero. Flag and note metrics are ignored in the "incoming" record,
    /// and deleted if they exist in the current record.
    public mutating func aggregate(record: Self) {
        self.metrics.removeAll(where: { !$1.isNumeric })
        self.metrics.merge(record.metrics.filter { $1.isNumeric }) {
            switch ($0, $1) {
                case let (.duration(l), .duration(r)): return .duration(l + r)
                case let (.count(l), .count(r)): return .count(l + r)
                default: fatalError("mismatched metrics in merge")
            }
        }
    }
}

// MARK: - Base representation

extension SQLQueryPerformanceRecord.Value:
    ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral, ExpressibleByStringLiteral
{
    public init(floatLiteral value: Double) {
        self = .duration(value)
    }
    
    public init(integerLiteral value: Int) {
        self = .count(value)
    }
    
    public init(booleanLiteral value: Bool) {
        self = .flag(value)
    }
    
    public init(stringLiteral value: String) {
        self = .note(value)
    }
}

extension SQLQueryPerformanceRecord.Value: CustomStringConvertible {
    private static var _durationFormatter: ThreadSpecificVariable<NumberFormatter> = .init()
    private static var durationFormatter: NumberFormatter {
        return self._durationFormatter.currentValue ?? {
            let formatter = NumberFormatter()
            
            formatter.allowsFloats = true
            formatter.alwaysShowsDecimalSeparator = true
            formatter.maximumFractionDigits = 4
            formatter.minimumFractionDigits = 4
            formatter.roundingMode = .halfUp
            self._durationFormatter.currentValue = formatter
            return formatter
        }()
    }
    
    public var description: String {
        switch self {
        case .duration(let value):
            // N.B.: NumberFormatter's crud, but MeasurementFormatter is still unimplemented on Linux.
            return "\(Self.durationFormatter.string(from: .init(value: value)) ?? "???")s"
        case .count(let value):
            return String(value, radix: 10)
        case .flag(let value):
            return value ? "true" : "false"
        case .note(let value):
            return value
        }
    }
}

extension SQLQueryPerformanceRecord: CustomStringConvertible {
    public var description: String {
        return "Query metrics:\n  \(self.allMetrics().map { "\($0.rawValue): \($1.description)" }.joined(separator: "\n  "))"
    }
}

// MARK: - Utility
extension DispatchTime {
    /// Subtract `self` from `other` and express the result as a count of seconds with fractional
    /// precision equivalent to the resolution of `DispatchTime.uptimeNanoseconds`, or the maximum
    /// precision of `Double`, whichever is smaller.
    public func secondsDistance(to other: DispatchTime) -> Double {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        switch self.distance(to: other) {
            case .seconds(let secs): return Double(secs)
            case .milliseconds(let millis): return Double(millis) / 1_000.0
            case .microseconds(let micros): return Double(micros) / 1_000_000.0
            case .nanoseconds(let nanos): return Double(nanos) / 1_000_000_000.0
            case .never: return .infinity
            @unknown default: return .nan
        }
#else
        return Double(other.uptimeNanoseconds - self.uptimeNanoseconds) / 1_000_000_000.0
#endif
    }
    
    /// Return the monotonic time elapsed since the given `DispatchTime` as a count of seconds with
    /// fractional precision equivalent to the resolution of `DispatchTime.uptimeNanoseconds`, or
    /// the maximum precision of `Double`, whichever is smaller.
    public static func secondsElapsed(since start: DispatchTime) -> Double {
        return start.secondsDistance(to: .now())
    }
}

extension Optional where Wrapped == SQLQueryPerformanceRecord.Value {
    /// This whole rigamarole only works as long as no two kinds of values have confusable
    /// underlying representations according to the type system. The idea here is, "if self
    /// has the right case for the type T, return the value, else return the default value
    /// for T's case."
    fileprivate func typed<T>(_: T.Type = T.self) -> T {
        switch (self, 0.0, 0, false, "") {
            case let (.duration(val), _, _, _, _) where val is T, let (_, val, _, _, _) where val is T: return val as! T
            case let (.count(val),    _, _, _, _) where val is T, let (_, _, val, _, _) where val is T: return val as! T
            case let (.flag(val),     _, _, _, _) where val is T, let (_, _, _, val, _) where val is T: return val as! T
            case let (.note(val),     _, _, _, _) where val is T, let (_, _, _, _, val) where val is T: return val as! T
            default: fatalError("Invalid type \(T.self)")
        }
    }
}

extension SQLQueryPerformanceRecord.Value {
    fileprivate var isNumeric: Bool {
        switch self {
            case .duration(_), .count(_): return true
            default: return false
        }
    }
}

// MARK: - Concurrency

#if canImport(_Concurrency) && compiler(>=5.5.2)
@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension SQLQueryPerformanceRecord: Sendable {}
extension SQLQueryPerformanceRecord.Metric: Sendable {}

// TODO: TEMPORARY, NEEDS TO BE REVISED!
// FIXME: REMOVE THIS CONFORMANCE ASAP!
extension OrderedDictionary: @unchecked Sendable {}
#endif
