import Foundation

/// Command is a developer friendly wrapper around a closure.
/// It helps to ease debugging by providing callee information.

public final class Command<T> {
    private let id: String
    private let file: StaticString
    private let function: StaticString
    private let line: UInt
    private let closure: (T) -> Void

    public init(
        id: String = "swifty-redux.command",
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        closure: @escaping (T) -> Void
    ) {
        self.id = id
        self.file = file
        self.function = function
        self.line = line
        self.closure = closure
    }

    public func execute(with value: T) {
        closure(value)
    }

    public static func nop() -> Command {
        return Command(id: "swifty-redux.command.nop", closure: { _ in })
    }

    @objc
    func debugQuickLookObject() -> AnyObject? {
        return debugDescription as NSString
    }
}

extension Command where T == Void {
    public func execute() {
        execute(with: ())
    }
}

extension Command {
    public func with(value: T) -> Command<Void> {
        return Command<Void> { self.execute(with: value) }
    }
}

extension Command: Hashable {
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: Command, rhs: Command) -> Bool {
        return lhs === rhs
    }
}

extension Command: CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
        \(String(describing: type(of: self)))(
            id: \(id),
            file: \(file),
            function: \(function),
            line: \(line)
        )
        """
    }
}
