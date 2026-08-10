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
        CAPPluginMethod(name: "setCustomUserAttribute", returnType: CAPPluginReturnPromise)
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
}
