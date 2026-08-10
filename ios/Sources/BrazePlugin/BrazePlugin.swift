import Foundation
import Capacitor

/**
 * Capacitor plugin that wraps the core analytics and user identity APIs of
 * the Braze iOS SDK (BrazeKit). See the Capacitor iOS Plugin Development
 * Guide: https://capacitorjs.com/docs/plugins/ios
 */
@objc(BrazePlugin)
public class BrazePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "BrazePlugin"
    public let jsName = "Braze"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "changeUser", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logCustomEvent", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logPurchase", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setCustomUserAttribute", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logProductViewed", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logCartUpdated", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logCheckoutStarted", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logOrderPlaced", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logOrderCancelled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logOrderRefunded", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = BrazeBridge()

    @objc func changeUser(_ call: CAPPluginCall) {
        guard let externalId = call.getString("externalId"), !externalId.isEmpty else {
            call.reject("\"externalId\" is required")
            return
        }

        do {
            try implementation.changeUser(externalId: externalId)
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }

    @objc func logCustomEvent(_ call: CAPPluginCall) {
        guard let eventName = call.getString("eventName"), !eventName.isEmpty else {
            call.reject("\"eventName\" is required")
            return
        }

        do {
            try implementation.logCustomEvent(eventName: eventName, properties: call.getObject("properties"))
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }

    @objc func logPurchase(_ call: CAPPluginCall) {
        guard let productId = call.getString("productId"), !productId.isEmpty else {
            call.reject("\"productId\" is required")
            return
        }
        guard let currency = call.getString("currency"), !currency.isEmpty else {
            call.reject("\"currency\" is required")
            return
        }
        guard let price = call.getDouble("price"), price >= 0 else {
            call.reject("\"price\" must be a non-negative number")
            return
        }
        guard let quantity = call.getInt("quantity"), quantity >= 0 else {
            call.reject("\"quantity\" must be a non-negative integer")
            return
        }

        do {
            try implementation.logPurchase(
                productId: productId,
                currency: currency,
                price: price,
                quantity: quantity,
                properties: call.getObject("properties")
            )
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }

    @objc func setCustomUserAttribute(_ call: CAPPluginCall) {
        guard let key = call.getString("key"), !key.isEmpty else {
            call.reject("\"key\" is required")
            return
        }
        guard let value = call.getValue("value") else {
            call.reject("\"value\" is required")
            return
        }

        do {
            try implementation.setCustomUserAttribute(key: key, value: value)
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }

    @objc func logProductViewed(_ call: CAPPluginCall) {
        guard let productId = call.getString("productId"), !productId.isEmpty else {
            call.reject("\"productId\" is required")
            return
        }
        guard let productName = call.getString("productName"), !productName.isEmpty else {
            call.reject("\"productName\" is required")
            return
        }
        guard let variantId = call.getString("variantId"), !variantId.isEmpty else {
            call.reject("\"variantId\" is required")
            return
        }
        guard let price = call.getDouble("price") else {
            call.reject("\"price\" is required")
            return
        }
        guard let currency = call.getString("currency"), !currency.isEmpty else {
            call.reject("\"currency\" is required")
            return
        }
        guard let source = call.getString("source"), !source.isEmpty else {
            call.reject("\"source\" is required")
            return
        }

        do {
            try implementation.logProductViewed(
                productId: productId,
                productName: productName,
                variantId: variantId,
                imageUrl: call.getString("imageUrl"),
                productUrl: call.getString("productUrl"),
                price: price,
                currency: currency,
                source: source,
                type: call.getArray("type", String.self),
                metadata: call.getObject("metadata")
            )
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }

    @objc func logCartUpdated(_ call: CAPPluginCall) {
        guard let cartId = call.getString("cartId"), !cartId.isEmpty else {
            call.reject("\"cartId\" is required")
            return
        }
        guard let currency = call.getString("currency"), !currency.isEmpty else {
            call.reject("\"currency\" is required")
            return
        }
        guard let source = call.getString("source"), !source.isEmpty else {
            call.reject("\"source\" is required")
            return
        }
        guard let products = call.getArray("products", JSObject.self), !products.isEmpty else {
            call.reject("\"products\" must contain at least one item")
            return
        }

        do {
            try implementation.logCartUpdated(
                cartId: cartId,
                action: call.getString("action"),
                totalValue: call.getDouble("totalValue"),
                subtotalValue: call.getDouble("subtotalValue"),
                tax: call.getDouble("tax"),
                shipping: call.getDouble("shipping"),
                currency: currency,
                products: products,
                source: source,
                metadata: call.getObject("metadata")
            )
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }

    @objc func logCheckoutStarted(_ call: CAPPluginCall) {
        guard let checkoutId = call.getString("checkoutId"), !checkoutId.isEmpty else {
            call.reject("\"checkoutId\" is required")
            return
        }
        guard let totalValue = call.getDouble("totalValue") else {
            call.reject("\"totalValue\" is required")
            return
        }
        guard let currency = call.getString("currency"), !currency.isEmpty else {
            call.reject("\"currency\" is required")
            return
        }
        guard let source = call.getString("source"), !source.isEmpty else {
            call.reject("\"source\" is required")
            return
        }
        guard let products = call.getArray("products", JSObject.self), !products.isEmpty else {
            call.reject("\"products\" must contain at least one item")
            return
        }

        do {
            try implementation.logCheckoutStarted(
                checkoutId: checkoutId,
                cartId: call.getString("cartId"),
                totalValue: totalValue,
                subtotalValue: call.getDouble("subtotalValue"),
                tax: call.getDouble("tax"),
                shipping: call.getDouble("shipping"),
                currency: currency,
                products: products,
                source: source,
                metadata: call.getObject("metadata")
            )
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }

    @objc func logOrderPlaced(_ call: CAPPluginCall) {
        guard let orderId = call.getString("orderId"), !orderId.isEmpty else {
            call.reject("\"orderId\" is required")
            return
        }
        guard let totalValue = call.getDouble("totalValue") else {
            call.reject("\"totalValue\" is required")
            return
        }
        guard let currency = call.getString("currency"), !currency.isEmpty else {
            call.reject("\"currency\" is required")
            return
        }
        guard let source = call.getString("source"), !source.isEmpty else {
            call.reject("\"source\" is required")
            return
        }
        guard let products = call.getArray("products", JSObject.self), !products.isEmpty else {
            call.reject("\"products\" must contain at least one item")
            return
        }

        do {
            try implementation.logOrderPlaced(
                orderId: orderId,
                cartId: call.getString("cartId"),
                totalValue: totalValue,
                subtotalValue: call.getDouble("subtotalValue"),
                tax: call.getDouble("tax"),
                shipping: call.getDouble("shipping"),
                currency: currency,
                totalDiscounts: call.getDouble("totalDiscounts"),
                discounts: call.getArray("discounts", JSObject.self),
                products: products,
                source: source,
                metadata: call.getObject("metadata")
            )
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }

    @objc func logOrderCancelled(_ call: CAPPluginCall) {
        do {
            let payload = try implementation.buildOrderCancelledPayload(
                orderId: call.getString("orderId"),
                totalValue: call.getDouble("totalValue"),
                subtotalValue: call.getDouble("subtotalValue"),
                tax: call.getDouble("tax"),
                shipping: call.getDouble("shipping"),
                currency: call.getString("currency"),
                totalDiscounts: call.getDouble("totalDiscounts"),
                discounts: call.getArray("discounts", JSObject.self),
                cancelReason: call.getString("cancelReason"),
                products: call.getArray("products", JSObject.self),
                source: call.getString("source"),
                metadata: call.getObject("metadata")
            )
            try implementation.logOrderCancelled(payload: payload)
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }

    @objc func logOrderRefunded(_ call: CAPPluginCall) {
        do {
            let payload = try implementation.buildOrderRefundedPayload(
                orderId: call.getString("orderId"),
                totalValue: call.getDouble("totalValue"),
                currency: call.getString("currency"),
                totalDiscounts: call.getDouble("totalDiscounts"),
                discounts: call.getArray("discounts", JSObject.self),
                products: call.getArray("products", JSObject.self),
                source: call.getString("source"),
                metadata: call.getObject("metadata")
            )
            try implementation.logOrderRefunded(payload: payload)
            call.resolve()
        } catch {
            call.reject(error.localizedDescription, nil, error)
        }
    }
}
