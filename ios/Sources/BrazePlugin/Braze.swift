import Foundation
import BrazeKit

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
}
