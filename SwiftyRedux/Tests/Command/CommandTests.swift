import XCTest
@testable import SwiftyRedux

class CommandTests: XCTestCase {
    func testCommand() {
        let cmd = Command<Int>(id: "redux.command.test", closure: { x in x * 2 })
        print(cmd)
    }
}
