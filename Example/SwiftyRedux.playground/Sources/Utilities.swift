import Foundation
import SwiftyRedux

public func updating<T>(_ value: T, _ transform: (inout T) -> Void) -> T {
    var newValue = value
    transform(&newValue)
    return newValue
}

extension BatchAction: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "BatchAction(actions: [" + actions.map { "\($0)" }.joined(separator: ", ") + "])"
    }
}
