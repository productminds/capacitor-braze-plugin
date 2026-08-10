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

    // Braze has no native typed class for order_cancelled/order_refunded on
    // any platform, so `buildOrderCancelledPayload`/`buildOrderRefundedPayload`
    // are this plugin's only validation for them. Both are pure — they never
    // touch BrazeBridge.sharedInstance or call logCustomEvent — so a missing
    // required field (e.g. no products) is provably rejected before the event
    // is ever dispatched, independent of whether BrazeKit is configured.
    func testLogOrderCancelledRejectsWhenProductsMissing() {
        let implementation = BrazeBridge()

        XCTAssertThrowsError(
            try implementation.buildOrderCancelledPayload(
                orderId: "order-1",
                totalValue: 10.0,
                subtotalValue: nil,
                tax: nil,
                shipping: nil,
                currency: "USD",
                totalDiscounts: nil,
                discounts: nil,
                cancelReason: "customer_request",
                products: nil,
                source: "test",
                metadata: nil
            )
        ) { error in
            guard case .emptyProducts = error as? EcommerceValidationError else {
                return XCTFail("Expected EcommerceValidationError.emptyProducts, got \(error)")
            }
        }
    }

    func testLogOrderRefundedRejectsWhenProductsMissing() {
        let implementation = BrazeBridge()

        XCTAssertThrowsError(
            try implementation.buildOrderRefundedPayload(
                orderId: "order-1",
                totalValue: 10.0,
                currency: "USD",
                totalDiscounts: nil,
                discounts: nil,
                products: nil,
                source: "test",
                metadata: nil
            )
        ) { error in
            guard case .emptyProducts = error as? EcommerceValidationError else {
                return XCTFail("Expected EcommerceValidationError.emptyProducts, got \(error)")
            }
        }
    }
}
