import Foundation
import BrazeKit
import Capacitor

/// Errors surfaced by the ``BrazeBridge`` wrapper when a call can't be satisfied.
enum BrazeWrapperError: LocalizedError {
    case notInitialized
    case unsupportedAttributeValue

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Braze SDK is not configured. Assign BrazeBridge.sharedInstance " +
                "from your AppDelegate before using this plugin."
        case .unsupportedAttributeValue:
            return "Custom user attribute value must be a string, number, or boolean."
        }
    }
}

/// Validation errors for the eCommerce events that have no native BrazeKit
/// class (`order_cancelled`, `order_refunded`). These mirror the same
/// non-blank/255-character, non-negative, and ISO 4217 currency rules that
/// BrazeKit enforces natively in the typed eCommerce event initializers
/// (`Braze.Ecommerce.ValidationError`), so behavior is consistent across all
/// 6 eCommerce methods this plugin exposes.
enum EcommerceValidationError: LocalizedError {
    case invalidString(field: String)
    case invalidNumber(field: String)
    case invalidCurrency(value: String)
    case invalidAction(String)
    case emptyProducts

    var errorDescription: String? {
        switch self {
        case .invalidString(let field):
            return "\"\(field)\" must be non-blank and at most 255 characters."
        case .invalidNumber(let field):
            return "\"\(field)\" must be a non-negative number."
        case .invalidCurrency(let value):
            return "\"currency\" must be a valid ISO 4217 code (3 letters). Received: \"\(value)\""
        case .invalidAction(let value):
            return "\"action\" must be one of: \"add\", \"remove\", \"replace\". Received: \"\(value)\""
        case .emptyProducts:
            return "\"products\" must contain at least one item."
        }
    }
}

/// Validation errors for {@link BrazeBridge.setUserProfile}. BrazeKit's
/// reserved profile field setters accept any string with no format
/// validation of their own client-side (unlike Android's `BrazeUser`, whose
/// setters return a Boolean success flag — see the comment on
/// `BrazeBridge.setUserProfile` for that platform difference), so this
/// plugin enforces "at least one field present, and non-blank/well-formed
/// if present" itself.
enum UserProfileValidationError: LocalizedError {
    case noFieldsProvided
    case invalidString(field: String)
    case invalidGender(value: String)
    case invalidDateOfBirth(value: String)

    var errorDescription: String? {
        switch self {
        case .noFieldsProvided:
            return "At least one of \"email\", \"firstName\", \"lastName\", \"country\", " +
                "\"language\", \"homeCity\", \"phoneNumber\", \"gender\", or \"dateOfBirth\" is required."
        case .invalidString(let field):
            return "\"\(field)\" must be non-blank and at most 255 characters."
        case .invalidGender(let value):
            return "\"gender\" must be one of: \"male\", \"female\", \"other\", \"unknown\", " +
                "\"not_applicable\", \"prefer_not_to_say\". Received: \"\(value)\""
        case .invalidDateOfBirth(let value):
            return "\"dateOfBirth\" must be a valid ISO 8601 date (\"YYYY-MM-DD\"). Received: \"\(value)\""
        }
    }
}

/// Gives `Braze.Ecommerce.ValidationError` (thrown natively by the typed
/// eCommerce event initializers) a readable message, since it doesn't
/// conform to `LocalizedError` itself and `error.localizedDescription`
/// would otherwise fall back to a generic, unhelpful message.
extension Braze.Ecommerce.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .empty(let field):
            return "\"\(field)\" is required."
        case .stringTooLong(let field, let maxLength):
            return "\"\(field)\" must be at most \(maxLength) characters."
        case .invalidCurrencyCode(let value):
            return "\"currency\" must be a valid ISO 4217 code. Received: \"\(value)\""
        case .invalidFloat(let field, let reason):
            switch reason {
            case .notFinite:
                return "\"\(field)\" must be a finite number."
            case .outOfRange:
                return "\"\(field)\" must be a non-negative number."
            @unknown default:
                return "\"\(field)\" is invalid."
            }
        case .invalidInteger(let field, let reason):
            switch reason {
            case .outOfRange:
                return "\"\(field)\" must be a non-negative integer."
            @unknown default:
                return "\"\(field)\" is invalid."
            }
        case .invalidMetadataKey(let key, let path):
            return "metadata key \"\(key)\" at \"\(path)\" is invalid."
        case .metadataTooDeep(let maxDepth):
            return "metadata is nested too deeply (max depth \(maxDepth))."
        case .metadataTooLarge(let maxUTF8Bytes):
            return "metadata is too large (max \(maxUTF8Bytes) UTF-8 bytes)."
        case .metadataNotJSONSerializable:
            return "metadata must be JSON-serializable."
        case .emptyProductsArray:
            return "\"products\" must contain at least one item."
        case .discountEntryNotSerializable(let index):
            return "discounts[\(index)] is not serializable."
        @unknown default:
            return "eCommerce event payload is invalid."
        }
    }
}

/// Thin wrapper around the BrazeKit SDK singleton. Kept separate from
/// `BrazePlugin` so Capacitor bridge concerns (CAPPluginCall parsing,
/// resolve/reject) stay out of the native SDK call sites.
///
/// This plugin never configures BrazeKit itself: the host app must create
/// its own `BrazeKit.Braze` instance (typically in `AppDelegate`, before
/// this plugin is used) and assign it to ``sharedInstance``. See the
/// README's "Native configuration" section for the exact steps.
public final class BrazeBridge {

    /// The `BrazeKit.Braze` instance this plugin delegates to. The host app
    /// is responsible for setting this — this plugin only reads it.
    public static var sharedInstance: BrazeKit.Braze?

    private func requireInstance() throws -> BrazeKit.Braze {
        guard let instance = BrazeBridge.sharedInstance else {
            throw BrazeWrapperError.notInitialized
        }
        return instance
    }

    func changeUser(externalId: String) throws {
        try requireInstance().changeUser(userId: externalId)
    }

    func logCustomEvent(eventName: String, properties: [String: Any]?) throws {
        try requireInstance().logCustomEvent(name: eventName, properties: properties)
    }

    func logPurchase(
        productId: String,
        currency: String,
        price: Double,
        quantity: Int,
        properties: [String: Any]?
    ) throws {
        try requireInstance().logPurchase(
            productId: productId,
            currency: currency,
            price: price,
            quantity: quantity,
            properties: properties
        )
    }

    func setCustomUserAttribute(key: String, value: Any) throws {
        let instance = try requireInstance()

        // `Bool` must be checked before `Int`/`Double`: Foundation bridges
        // JSON booleans to `NSNumber`, and an `NSNumber` wrapping a bool
        // also satisfies `as? Int`/`as? Double` casts, so checking those
        // first would silently misclassify boolean attribute values.
        switch value {
        case let stringValue as String:
            instance.user.setCustomAttribute(key: key, value: stringValue)
        case let boolValue as Bool:
            instance.user.setCustomAttribute(key: key, value: boolValue)
        case let intValue as Int:
            instance.user.setCustomAttribute(key: key, value: intValue)
        case let doubleValue as Double:
            instance.user.setCustomAttribute(key: key, value: doubleValue)
        default:
            throw BrazeWrapperError.unsupportedAttributeValue
        }
    }

    func unsetCustomUserAttribute(key: String) throws {
        try requireInstance().user.unsetCustomAttribute(key: key)
    }

    // BrazeKit's unqualified `addToCustomAttributeArray`/`removeFromCustomAttributeArray`
    // overloads are deprecated (renamed to the `*StringArray` variants below)
    // — using them would emit deprecation warnings on every build.
    func addToCustomUserAttributeArray(key: String, value: String) throws {
        try requireInstance().user.addToCustomAttributeStringArray(key: key, value: value)
    }

    func removeFromCustomUserAttributeArray(key: String, value: String) throws {
        try requireInstance().user.removeFromCustomAttributeStringArray(key: key, value: value)
    }

    /// Validates a `setUserProfile` payload: at least one field must be
    /// present, and any present field must be individually valid (non-blank
    /// strings; `gender` must be a recognized value; `dateOfBirth` must be a
    /// valid ISO 8601 date). Pure (no BrazeKit instance involved) so an
    /// invalid payload is rejected before any native user setter is ever
    /// reached, and so it can be unit tested directly.
    func validateUserProfileFields(
        email: String?,
        firstName: String?,
        lastName: String?,
        country: String?,
        language: String?,
        homeCity: String?,
        phoneNumber: String?,
        gender: String?,
        dateOfBirth: String?
    ) throws {
        if email == nil && firstName == nil && lastName == nil && country == nil
            && language == nil && homeCity == nil && phoneNumber == nil && gender == nil
            && dateOfBirth == nil {
            throw UserProfileValidationError.noFieldsProvided
        }
        if let email { try requireNonBlankProfileField(email, field: "email") }
        if let firstName { try requireNonBlankProfileField(firstName, field: "firstName") }
        if let lastName { try requireNonBlankProfileField(lastName, field: "lastName") }
        if let country { try requireNonBlankProfileField(country, field: "country") }
        if let language { try requireNonBlankProfileField(language, field: "language") }
        if let homeCity { try requireNonBlankProfileField(homeCity, field: "homeCity") }
        if let phoneNumber { try requireNonBlankProfileField(phoneNumber, field: "phoneNumber") }
        if let gender { _ = try parseGender(gender) }
        if let dateOfBirth { _ = try parseDateOfBirth(dateOfBirth) }
    }

    /// Sets one or more reserved profile fields. Unlike Android's
    /// `BrazeUser` (whose reserved-field setters, including
    /// `setPhoneNumber`, return a Boolean success flag reflecting Braze's
    /// own native-side validation), BrazeKit's modern `Braze.User` setters
    /// used here (`set(email:)`, `set(phoneNumber:)`, ...) all return `Void`
    /// — there is no non-deprecated BrazeKit API that reports whether Braze
    /// accepted a value such as a malformed phone number. This method can
    /// therefore only guarantee this plugin's own validation passed, not
    /// that Braze accepted every field natively; see the README for this
    /// documented platform difference.
    func setUserProfile(
        email: String?,
        firstName: String?,
        lastName: String?,
        country: String?,
        language: String?,
        homeCity: String?,
        phoneNumber: String?,
        gender: String?,
        dateOfBirth: String?
    ) throws {
        try validateUserProfileFields(
            email: email,
            firstName: firstName,
            lastName: lastName,
            country: country,
            language: language,
            homeCity: homeCity,
            phoneNumber: phoneNumber,
            gender: gender,
            dateOfBirth: dateOfBirth
        )
        let parsedGender = try gender.map { try parseGender($0) }
        let parsedDateOfBirth = try dateOfBirth.map { try parseDateOfBirth($0) }

        let instance = try requireInstance()
        if let email { instance.user.set(email: email) }
        if let firstName { instance.user.set(firstName: firstName) }
        if let lastName { instance.user.set(lastName: lastName) }
        if let country { instance.user.set(country: country) }
        if let language { instance.user.set(language: language) }
        if let homeCity { instance.user.set(homeCity: homeCity) }
        if let phoneNumber { instance.user.set(phoneNumber: phoneNumber) }
        if let parsedGender { instance.user.set(gender: parsedGender) }
        if let parsedDateOfBirth { instance.user.set(dateOfBirth: parsedDateOfBirth) }
    }

    private func requireNonBlankProfileField(_ value: String, field: String) throws {
        guard !value.isEmpty, value.count <= 255 else {
            throw UserProfileValidationError.invalidString(field: field)
        }
    }

    /// Maps this plugin's own `gender` string values (documented in the
    /// README, shared with the Android implementation) to the real
    /// `Braze.User.Gender` case. Not done via `Gender(rawValue:)` directly:
    /// BrazeKit's raw values for the two multi-word cases are camelCase
    /// (`"notApplicable"`, `"preferNotToSay"`), not this plugin's snake_case
    /// (`"not_applicable"`, `"prefer_not_to_say"`).
    private func parseGender(_ value: String) throws -> Braze.User.Gender {
        switch value {
        case "male": return .male
        case "female": return .female
        case "other": return .other
        case "unknown": return .unknown
        case "not_applicable": return .notApplicable
        case "prefer_not_to_say": return .preferNotToSay
        default:
            throw UserProfileValidationError.invalidGender(value: value)
        }
    }

    /// Parses a `"YYYY-MM-DD"` string into the `Date` `Braze.User.set(dateOfBirth:)`
    /// takes. Unlike `java.util.Calendar` on Android, Swift's `Calendar`/
    /// `DateFormatter` have no leniency flag to reject an out-of-range day —
    /// they silently normalize it instead (e.g. `"2020-02-30"` rolls over to
    /// March 1st and still parses successfully), so the parsed date is
    /// formatted back to a string and compared against the input to catch
    /// that normalization instead of trusting a non-nil parse result.
    private func parseDateOfBirth(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: value), formatter.string(from: date) == value else {
            throw UserProfileValidationError.invalidDateOfBirth(value: value)
        }
        return date
    }

    // --- eCommerce events backed by a native BrazeKit type ---
    //
    // Braze.Ecommerce.ProductViewedEvent / CartUpdated.* / CheckoutStartedEvent
    // / OrderPlacedEvent / ProductLineItem all validate their payload in
    // their own throwing initializer before the event is handed to
    // logEcommerceEvent, so this plugin only needs to parse the incoming
    // JSON and forward it — validation is native.

    func logProductViewed(
        productId: String,
        productName: String,
        variantId: String,
        imageUrl: String?,
        productUrl: String?,
        price: Double,
        currency: String,
        source: String,
        type: [String]?,
        metadata: [String: Any]?
    ) throws {
        let event = try Braze.Ecommerce.ProductViewedEvent(
            productId: productId,
            productName: productName,
            variantId: variantId,
            imageUrl: imageUrl,
            productUrl: productUrl,
            price: price,
            currency: currency,
            source: source,
            metadata: metadata,
            type: type
        )
        try requireInstance().logEcommerceEvent(event)
    }

    func logCartUpdated(
        cartId: String,
        action: String?,
        totalValue: Double?,
        subtotalValue: Double?,
        tax: Double?,
        shipping: Double?,
        currency: String,
        products: [JSObject]?,
        source: String,
        metadata: [String: Any]?
    ) throws {
        let instance = try requireInstance()
        let productLineItems = try parseProducts(products)

        switch action?.lowercased() {
        case "add":
            let event = try Braze.Ecommerce.CartUpdated.Add(
                cartId: cartId,
                totalValue: totalValue,
                currency: currency,
                subtotalValue: subtotalValue,
                tax: tax,
                shipping: shipping,
                products: productLineItems,
                source: source,
                metadata: metadata
            )
            instance.logEcommerceEvent(event)
        case "remove":
            let event = try Braze.Ecommerce.CartUpdated.Remove(
                cartId: cartId,
                totalValue: totalValue,
                currency: currency,
                subtotalValue: subtotalValue,
                tax: tax,
                shipping: shipping,
                products: productLineItems,
                source: source,
                metadata: metadata
            )
            instance.logEcommerceEvent(event)
        case nil, "replace":
            guard let totalValue else {
                throw EcommerceValidationError.invalidNumber(field: "totalValue")
            }
            let event = try Braze.Ecommerce.CartUpdated.Replace(
                cartId: cartId,
                totalValue: totalValue,
                currency: currency,
                subtotalValue: subtotalValue,
                tax: tax,
                shipping: shipping,
                products: productLineItems,
                source: source,
                metadata: metadata
            )
            instance.logEcommerceEvent(event)
        case .some(let value):
            throw EcommerceValidationError.invalidAction(value)
        }
    }

    func logCheckoutStarted(
        checkoutId: String,
        cartId: String?,
        totalValue: Double,
        subtotalValue: Double?,
        tax: Double?,
        shipping: Double?,
        currency: String,
        products: [JSObject]?,
        source: String,
        metadata: [String: Any]?
    ) throws {
        let event = try Braze.Ecommerce.CheckoutStartedEvent(
            checkoutId: checkoutId,
            cartId: cartId,
            totalValue: totalValue,
            currency: currency,
            subtotalValue: subtotalValue,
            tax: tax,
            shipping: shipping,
            products: try parseProducts(products),
            source: source,
            metadata: metadata
        )
        try requireInstance().logEcommerceEvent(event)
    }

    func logOrderPlaced(
        orderId: String,
        cartId: String?,
        totalValue: Double,
        subtotalValue: Double?,
        tax: Double?,
        shipping: Double?,
        currency: String,
        totalDiscounts: Double?,
        discounts: [JSObject]?,
        products: [JSObject]?,
        source: String,
        metadata: [String: Any]?
    ) throws {
        let event = try Braze.Ecommerce.OrderPlacedEvent(
            orderId: orderId,
            cartId: cartId,
            totalValue: totalValue,
            currency: currency,
            subtotalValue: subtotalValue,
            tax: tax,
            shipping: shipping,
            totalDiscounts: totalDiscounts,
            discounts: discounts,
            products: try parseProducts(products),
            source: source,
            metadata: metadata
        )
        try requireInstance().logEcommerceEvent(event)
    }

    // --- eCommerce events with no native BrazeKit type ---
    //
    // Braze does not offer a typed class for order_cancelled/order_refunded
    // on any platform (see https://www.braze.com/docs/developer_guide/analytics/ecommerce/#log-manually
    // ). The `buildOrder*Payload` functions below replicate, field for
    // field, the same validation the native types above enforce in their
    // initializers — including reusing the real `Braze.Ecommerce.ProductLineItem`
    // type for line items, so product validation is identical to the other
    // 4 events. They are pure (no BrazeKit instance involved) so invalid
    // input is rejected before `logCustomEvent` is ever reached, and so
    // they can be unit tested directly.

    func buildOrderCancelledPayload(
        orderId: String?,
        totalValue: Double?,
        subtotalValue: Double?,
        tax: Double?,
        shipping: Double?,
        currency: String?,
        totalDiscounts: Double?,
        discounts: [JSObject]?,
        cancelReason: String?,
        products: [JSObject]?,
        source: String?,
        metadata: [String: Any]?
    ) throws -> [String: Any] {
        let validOrderId = try requireNonBlank(orderId, field: "orderId")
        let validTotalValue = try requireNonNegative(totalValue, field: "totalValue")
        let validCurrency = try requireValidCurrency(currency)
        let validCancelReason = try requireNonBlank(cancelReason, field: "cancelReason")
        let validSource = try requireNonBlank(source, field: "source")
        if let subtotalValue { _ = try requireNonNegative(subtotalValue, field: "subtotalValue") }
        if let tax { _ = try requireNonNegative(tax, field: "tax") }
        if let shipping { _ = try requireNonNegative(shipping, field: "shipping") }
        if let totalDiscounts { _ = try requireNonNegative(totalDiscounts, field: "totalDiscounts") }
        let validProducts = try parseProducts(products)

        var payload: [String: Any] = [
            "order_id": validOrderId,
            "total_value": validTotalValue,
            "currency": validCurrency,
            "cancel_reason": validCancelReason,
            "products": validProducts.map { $0.wireJSON() },
            "source": validSource,
        ]
        if let subtotalValue { payload["subtotal_value"] = subtotalValue }
        if let tax { payload["tax"] = tax }
        if let shipping { payload["shipping"] = shipping }
        if let totalDiscounts { payload["total_discounts"] = totalDiscounts }
        if let discounts { payload["discounts"] = discounts }
        if let metadata { payload["metadata"] = metadata }
        return payload
    }

    func logOrderCancelled(payload: [String: Any]) throws {
        try requireInstance().logCustomEvent(name: "ecommerce.order_cancelled", properties: payload)
    }

    func buildOrderRefundedPayload(
        orderId: String?,
        totalValue: Double?,
        currency: String?,
        totalDiscounts: Double?,
        discounts: [JSObject]?,
        products: [JSObject]?,
        source: String?,
        metadata: [String: Any]?
    ) throws -> [String: Any] {
        let validOrderId = try requireNonBlank(orderId, field: "orderId")
        let validTotalValue = try requireNonNegative(totalValue, field: "totalValue")
        let validCurrency = try requireValidCurrency(currency)
        let validSource = try requireNonBlank(source, field: "source")
        if let totalDiscounts { _ = try requireNonNegative(totalDiscounts, field: "totalDiscounts") }
        let validProducts = try parseProducts(products)

        var payload: [String: Any] = [
            "order_id": validOrderId,
            "total_value": validTotalValue,
            "currency": validCurrency,
            "products": validProducts.map { $0.wireJSON() },
            "source": validSource,
        ]
        if let totalDiscounts { payload["total_discounts"] = totalDiscounts }
        if let discounts { payload["discounts"] = discounts }
        if let metadata { payload["metadata"] = metadata }
        return payload
    }

    func logOrderRefunded(payload: [String: Any]) throws {
        try requireInstance().logCustomEvent(name: "ecommerce.order_refunded", properties: payload)
    }

    // --- shared eCommerce parsing/validation helpers ---

    /// Builds the product line items via the real `Braze.Ecommerce.ProductLineItem`
    /// type, so per-product validation (non-blank/255-char string fields,
    /// non-negative price/quantity) is identical for every eCommerce event,
    /// whether or not that event has its own native type.
    private func parseProducts(_ products: [JSObject]?) throws -> [Braze.Ecommerce.ProductLineItem] {
        guard let products, !products.isEmpty else {
            throw EcommerceValidationError.emptyProducts
        }
        return try products.map { product in
            try Braze.Ecommerce.ProductLineItem(
                productId: product["productId"] as? String ?? "",
                productName: product["productName"] as? String ?? "",
                variantId: product["variantId"] as? String ?? "",
                imageUrl: product["imageUrl"] as? String,
                productUrl: product["productUrl"] as? String,
                quantity: product["quantity"] as? Int ?? -1,
                price: product["price"] as? Double ?? .nan,
                metadata: product["metadata"] as? [String: Any]
            )
        }
    }

    private func requireNonBlank(_ value: String?, field: String) throws -> String {
        guard let value, !value.isEmpty, value.count <= 255 else {
            throw EcommerceValidationError.invalidString(field: field)
        }
        return value
    }

    private func requireNonNegative(_ value: Double?, field: String) throws -> Double {
        guard let value, value >= 0 else {
            throw EcommerceValidationError.invalidNumber(field: field)
        }
        return value
    }

    private func requireValidCurrency(_ value: String?) throws -> String {
        let currency = try requireNonBlank(value, field: "currency")
        guard currency.range(of: "^[A-Za-z]{3}$", options: .regularExpression) != nil else {
            throw EcommerceValidationError.invalidCurrency(value: currency)
        }
        return currency.uppercased()
    }
}

private extension Braze.Ecommerce.ProductLineItem {
    /// Serializes this validated line item to the snake_case wire format
    /// Braze's native eCommerce classes use, for the manually-dispatched
    /// order_cancelled/order_refunded custom events.
    func wireJSON() -> [String: Any] {
        var json: [String: Any] = [
            "product_id": productId,
            "product_name": productName,
            "variant_id": variantId,
            "quantity": quantity,
            "price": price,
        ]
        if let imageUrl { json["image_url"] = imageUrl }
        if let productUrl { json["product_url"] = productUrl }
        if let metadata { json["metadata"] = metadata }
        return json
    }
}
