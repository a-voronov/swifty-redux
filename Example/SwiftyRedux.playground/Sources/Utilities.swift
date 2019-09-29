import Foundation
import SwiftyRedux

extension BatchAction: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "BatchAction(actions: [" + actions.map { "\($0)" }.joined(separator: ", ") + "])"
    }
}
