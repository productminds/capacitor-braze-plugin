import XCTest
@testable import BrazePlugin

class BrazeTests: XCTestCase {
    func testMethodsThrowWhenNotConfigured() {
        // BrazeBridge.sharedInstance is process-wide state; reset it so this
        // test is independent of whatever other tests in this target run first.
        BrazeBridge.sharedInstance = nil

        let implementation = BrazeBridge()

        XCTAssertThrowsError(try implementation.changeUser(externalId: "user-1")) { error in
            XCTAssertTrue(error is BrazeWrapperError)
        }
    }
}
