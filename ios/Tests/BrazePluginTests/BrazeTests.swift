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

    // `validateUserProfileFields` is `setUserProfile`'s only validation —
    // BrazeKit's reserved-field setters (`set(email:)`, `set(firstName:)`,
    // `set(lastName:)`, etc.) accept any string, so this plugin must reject
    // an empty payload itself. It's pure (never touches BrazeBridge.sharedInstance)
    // so a payload with no fields is provably rejected before any native
    // setter is ever reached, independent of whether BrazeKit is configured.
    func testSetUserProfileRejectsWhenNoFieldsPresent() {
        let implementation = BrazeBridge()

        XCTAssertThrowsError(
            try implementation.validateUserProfileFields(
                email: nil,
                firstName: nil,
                lastName: nil,
                country: nil,
                language: nil,
                homeCity: nil,
                phoneNumber: nil,
                gender: nil,
                dateOfBirth: nil
            )
        ) { error in
            guard case .noFieldsProvided = error as? UserProfileValidationError else {
                return XCTFail("Expected UserProfileValidationError.noFieldsProvided, got \(error)")
            }
        }
    }

    // `dateOfBirth` must be parsed by this plugin (BrazeKit's `set(dateOfBirth:)`
    // takes a `Date`, not a string), so a malformed ISO 8601 date must be
    // rejected here, before BrazeKit ever sees it.
    func testSetUserProfileRejectsInvalidDateOfBirthFormat() {
        let implementation = BrazeBridge()

        XCTAssertThrowsError(
            try implementation.validateUserProfileFields(
                email: nil,
                firstName: nil,
                lastName: nil,
                country: nil,
                language: nil,
                homeCity: nil,
                phoneNumber: nil,
                gender: nil,
                dateOfBirth: "13/45/2020"
            )
        ) { error in
            guard case .invalidDateOfBirth(let value) = error as? UserProfileValidationError else {
                return XCTFail("Expected UserProfileValidationError.invalidDateOfBirth, got \(error)")
            }
            XCTAssertEqual(value, "13/45/2020")
        }
    }

    // `gender` must map to a real `Braze.User.Gender` case; an unrecognized
    // value must be rejected with a message listing the accepted values,
    // not silently dropped or passed through to BrazeKit.
    func testSetUserProfileRejectsUnrecognizedGender() {
        let implementation = BrazeBridge()

        XCTAssertThrowsError(
            try implementation.validateUserProfileFields(
                email: nil,
                firstName: nil,
                lastName: nil,
                country: nil,
                language: nil,
                homeCity: nil,
                phoneNumber: nil,
                gender: "nonbinary",
                dateOfBirth: nil
            )
        ) { error in
            guard case .invalidGender(let value) = error as? UserProfileValidationError else {
                return XCTFail("Expected UserProfileValidationError.invalidGender, got \(error)")
            }
            XCTAssertEqual(value, "nonbinary")
            XCTAssertTrue(error.localizedDescription.contains("prefer_not_to_say"))
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
