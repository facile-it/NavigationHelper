import Log

public enum NavigationLogLevel: Int {
    case active = 0
}

extension NavigationLogLevel: Comparable {
    public static func < (lhs: NavigationLogLevel, rhs: NavigationLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public enum NavigationLogSettings: LogSettings {
    public typealias LogLevel = NavigationLogLevel

    public static var currentLogLevel: NavigationLogLevel? = nil
    
    public static var timestampFormat: String? = StandardLogSettings.defaultTimestampFormat
    
    public static var contextSeparator: String? = StandardLogSettings.defaultContextSeparator
    
    public static var lineSeparator: String?
}

public enum NavigationLogContext: String, CustomStringConvertible {
    case global = "NavigationHelper"
    case serialHandler = "SerialHandler"
    case presenter = "Presenter"

    public var description: String {
        return self.rawValue
    }
}

public typealias Log = AdequateLog<NavigationLogSettings, NavigationLogLevel, NavigationLogContext>

extension AdequateLog where Settings == NavigationLogSettings, Context == NavigationLogContext {
    public static func serialHandler(_ text: String) {
        Log.with(level: .active, context: .serialHandler, text: text)
    }

    public static func presenter(_ text: String) {
        Log.with(level: .active, context: .presenter, text: text)
    }
}
