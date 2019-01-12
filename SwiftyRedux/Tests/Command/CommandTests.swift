import XCTest
@testable import SwiftyRedux

class CommandTests: XCTestCase {
    func testCommandExecutesCorrectly() {
        var result: Int = 0
        let cmd = Command { x in result = x * 2 }

        cmd.execute(with: 21)

        XCTAssertEqual(result, 42)
    }

    func testCommandWithValueExecutesCorrectly() {
        var result: Int = 0
        let cmd = Command { x in result = x * 2 }

        cmd.with(value: 21).execute()

        XCTAssertEqual(result, 42)
    }

    func testCommandsEquality() {
        let cmd1 = Command<Void>.nop()
        let cmd2 = cmd1
        let cmd3 = Command<Void>.nop()

        XCTAssertEqual(cmd1, cmd2)
        XCTAssertNotEqual(cmd2, cmd3)
    }

    func testCommandsHashValues() {
        let cmd1 = Command<Void>.nop()
        let cmd2 = cmd1
        let cmd3 = Command<Void>.nop()

        XCTAssertEqual(cmd1.hashValue, cmd2.hashValue)
        XCTAssertNotEqual(cmd2.hashValue, cmd3.hashValue)
    }

    func testDebugQuickLook() {
        let cmd = Command<Void>.nop()

        XCTAssertEqual(cmd.debugDescription, cmd.debugQuickLookObject() as? String)
    }
}
