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
