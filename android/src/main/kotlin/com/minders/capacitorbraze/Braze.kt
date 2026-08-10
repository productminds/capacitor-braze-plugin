package com.minders.capacitorbraze

import android.content.Context
import com.braze.Braze as BrazeSdk
import com.braze.models.outgoing.BrazeProperties
import com.braze.models.recommended.ecommerce.CartUpdatedAction
import com.braze.models.recommended.ecommerce.CartUpdatedEvent
import com.braze.models.recommended.ecommerce.CheckoutStartedEvent
import com.braze.models.recommended.ecommerce.EcommerceProduct
import com.braze.models.recommended.ecommerce.OrderPlacedEvent
import com.braze.models.recommended.ecommerce.ProductViewedEvent
import org.json.JSONArray
import org.json.JSONObject
import java.math.BigDecimal

/**
 * Thin wrapper around the Braze Android SDK singleton. Kept separate from
 * [BrazePlugin] so the Capacitor bridge concerns (PluginCall parsing,
 * resolve/reject) stay out of the native SDK call sites.
 *
 * This plugin never configures the Braze SDK itself — the host app must
 * declare `com_braze_api_key` / `com_braze_custom_endpoint` string
 * resources (see the README) before any method here is called.
 */
class Braze {

    /**
     * [BrazeSdk.getInstance] never throws, even if the SDK was never
     * configured — it lazily builds a singleton either way. [BrazeSdk.isDisabled]
     * is the SDK's own public signal that no valid API key was found (or
     * the SDK was remotely disabled), so we check it explicitly instead of
     * silently forwarding calls that would otherwise no-op.
     */
    private fun requireConfiguredInstance(context: Context): BrazeSdk {
        val instance = BrazeSdk.getInstance(context)
        check(!BrazeSdk.isDisabled) {
            "Braze SDK is not configured. Declare \"com_braze_api_key\" and " +
                "\"com_braze_custom_endpoint\" string resources (e.g. in " +
                "res/values/braze.xml) before using this plugin."
        }
        return instance
    }

    fun changeUser(context: Context, externalId: String) {
        requireConfiguredInstance(context).changeUser(externalId)
    }

    fun logCustomEvent(context: Context, eventName: String, properties: JSONObject?) {
        requireConfiguredInstance(context).logCustomEvent(eventName, properties?.let { BrazeProperties(it) })
    }

    fun logPurchase(
        context: Context,
        productId: String,
        currency: String,
        price: BigDecimal,
        quantity: Int,
        properties: JSONObject?,
    ) {
        requireConfiguredInstance(context)
            .logPurchase(productId, currency, price, quantity, properties?.let { BrazeProperties(it) })
    }

    fun setCustomUserAttribute(context: Context, key: String, value: Any, onComplete: (Boolean) -> Unit) {
        requireConfiguredInstance(context).getCurrentUser { user ->
            val success = when (value) {
                is String -> user.setCustomUserAttribute(key, value)
                is Int -> user.setCustomUserAttribute(key, value)
                is Double -> user.setCustomUserAttribute(key, value)
                is Boolean -> user.setCustomUserAttribute(key, value)
                else -> false
            }
            onComplete(success)
        }
    }

    // --- eCommerce events backed by native Braze SDK classes ---
    //
    // ProductViewedEvent / CartUpdatedEvent / CheckoutStartedEvent /
    // OrderPlacedEvent all validate their payload in their own constructor
    // (throwing IllegalArgumentException on invalid input) before the event
    // is handed to Braze.logEcommerceEvent, so this plugin only needs to
    // parse the incoming JSON and forward it — validation is native.

    fun logProductViewed(
        context: Context,
        productId: String,
        productName: String,
        variantId: String,
        price: Double,
        currency: String,
        source: String,
        imageUrl: String?,
        productUrl: String?,
        type: List<String>?,
        metadata: JSONObject?,
    ) {
        val event = ProductViewedEvent(
            productId = productId,
            productName = productName,
            variantId = variantId,
            price = price,
            currency = currency,
            source = source,
            imageUrl = imageUrl,
            productUrl = productUrl,
            metadata = metadata?.let { BrazeProperties(it) },
            type = type,
        )
        requireConfiguredInstance(context).logEcommerceEvent(event)
    }

    fun logCartUpdated(
        context: Context,
        cartId: String,
        action: String?,
        totalValue: Double?,
        subtotalValue: Double?,
        tax: Double?,
        shipping: Double?,
        currency: String,
        products: JSONArray?,
        source: String,
        metadata: JSONObject?,
    ) {
        val event = CartUpdatedEvent(
            cartId = cartId,
            currency = currency,
            source = source,
            totalValue = totalValue,
            products = parseProducts(products),
            metadata = metadata?.let { BrazeProperties(it) },
            action = parseCartUpdatedAction(action),
            subtotalValue = subtotalValue,
            tax = tax,
            shipping = shipping,
        )
        requireConfiguredInstance(context).logEcommerceEvent(event)
    }

    fun logCheckoutStarted(
        context: Context,
        checkoutId: String,
        cartId: String?,
        totalValue: Double,
        subtotalValue: Double?,
        tax: Double?,
        shipping: Double?,
        currency: String,
        products: JSONArray?,
        source: String,
        metadata: JSONObject?,
    ) {
        val event = CheckoutStartedEvent(
            checkoutId = checkoutId,
            cartId = cartId,
            currency = currency,
            source = source,
            totalValue = totalValue,
            products = parseProducts(products),
            metadata = metadata?.let { BrazeProperties(it) },
            subtotalValue = subtotalValue,
            tax = tax,
            shipping = shipping,
        )
        requireConfiguredInstance(context).logEcommerceEvent(event)
    }

    fun logOrderPlaced(
        context: Context,
        orderId: String,
        cartId: String?,
        totalValue: Double,
        subtotalValue: Double?,
        tax: Double?,
        shipping: Double?,
        currency: String,
        totalDiscounts: Double?,
        discounts: JSONArray?,
        products: JSONArray?,
        source: String,
        metadata: JSONObject?,
    ) {
        val event = OrderPlacedEvent(
            orderId = orderId,
            cartId = cartId,
            currency = currency,
            source = source,
            totalValue = totalValue,
            products = parseProducts(products),
            totalDiscounts = totalDiscounts,
            discounts = parseDiscounts(discounts),
            metadata = metadata?.let { BrazeProperties(it) },
            subtotalValue = subtotalValue,
            tax = tax,
            shipping = shipping,
        )
        requireConfiguredInstance(context).logEcommerceEvent(event)
    }

    // --- eCommerce events with no native Braze SDK class ---
    //
    // Braze does not offer a typed class for order_cancelled/order_refunded
    // on any platform (see https://www.braze.com/docs/developer_guide/analytics/ecommerce/#log-manually
    // ). The `buildOrder*Payload` functions below replicate, field for
    // field, the same validation the native classes above enforce in their
    // constructors — including reusing the real [EcommerceProduct] class
    // for line items, so product validation is identical to the other 4
    // events. They are pure (no [Context], no SDK calls) so invalid input
    // is rejected before `logCustomEvent` is ever reached, and so they can
    // be unit tested directly.

    fun buildOrderCancelledPayload(
        orderId: String?,
        totalValue: Double?,
        subtotalValue: Double?,
        tax: Double?,
        shipping: Double?,
        currency: String?,
        totalDiscounts: Double?,
        discounts: JSONArray?,
        cancelReason: String?,
        products: JSONArray?,
        source: String?,
        metadata: JSONObject?,
    ): JSONObject {
        val validOrderId = requireNonBlank(orderId, "orderId")
        val validTotalValue = requireNonNegative(totalValue, "totalValue")
        val validCurrency = requireValidCurrency(currency)
        val validCancelReason = requireNonBlank(cancelReason, "cancelReason")
        val validSource = requireNonBlank(source, "source")
        subtotalValue?.let { requireNonNegative(it, "subtotalValue") }
        tax?.let { requireNonNegative(it, "tax") }
        shipping?.let { requireNonNegative(it, "shipping") }
        totalDiscounts?.let { requireNonNegative(it, "totalDiscounts") }
        val validProducts = parseProducts(products)

        return JSONObject().apply {
            put("order_id", validOrderId)
            put("total_value", validTotalValue)
            subtotalValue?.let { put("subtotal_value", it) }
            tax?.let { put("tax", it) }
            shipping?.let { put("shipping", it) }
            put("currency", validCurrency)
            totalDiscounts?.let { put("total_discounts", it) }
            discounts?.let { put("discounts", it) }
            put("cancel_reason", validCancelReason)
            put("products", JSONArray(validProducts.map { it.toWireJson() }))
            put("source", validSource)
            metadata?.let { put("metadata", it) }
        }
    }

    fun logOrderCancelled(context: Context, payload: JSONObject) {
        requireConfiguredInstance(context).logCustomEvent("ecommerce.order_cancelled", BrazeProperties(payload))
    }

    fun buildOrderRefundedPayload(
        orderId: String?,
        totalValue: Double?,
        currency: String?,
        totalDiscounts: Double?,
        discounts: JSONArray?,
        products: JSONArray?,
        source: String?,
        metadata: JSONObject?,
    ): JSONObject {
        val validOrderId = requireNonBlank(orderId, "orderId")
        val validTotalValue = requireNonNegative(totalValue, "totalValue")
        val validCurrency = requireValidCurrency(currency)
        val validSource = requireNonBlank(source, "source")
        totalDiscounts?.let { requireNonNegative(it, "totalDiscounts") }
        val validProducts = parseProducts(products)

        return JSONObject().apply {
            put("order_id", validOrderId)
            put("total_value", validTotalValue)
            put("currency", validCurrency)
            totalDiscounts?.let { put("total_discounts", it) }
            discounts?.let { put("discounts", it) }
            put("products", JSONArray(validProducts.map { it.toWireJson() }))
            put("source", validSource)
            metadata?.let { put("metadata", it) }
        }
    }

    fun logOrderRefunded(context: Context, payload: JSONObject) {
        requireConfiguredInstance(context).logCustomEvent("ecommerce.order_refunded", BrazeProperties(payload))
    }

    // --- shared eCommerce parsing/validation helpers ---

    /**
     * Builds the product line items via the real [EcommerceProduct] class,
     * so per-product validation (non-blank/255-char string fields,
     * non-negative price/quantity) is identical for every eCommerce event,
     * whether or not that event has its own native class.
     */
    private fun parseProducts(products: JSONArray?): List<EcommerceProduct> {
        if (products == null || products.length() == 0) {
            throw IllegalArgumentException("\"products\" must contain at least one item.")
        }
        return (0 until products.length()).map { index ->
            val product = products.getJSONObject(index)
            EcommerceProduct(
                productId = product.optString("productId"),
                productName = product.optString("productName"),
                variantId = product.optString("variantId"),
                // optDouble's own missing-key default is already NaN, which fails
                // EcommerceProduct's own "must be non-negative" check below.
                // optLong's missing-key default is 0, which would NOT fail that
                // check, so a missing quantity is defaulted to -1 here instead.
                price = product.optDouble("price"),
                quantity = if (product.has("quantity")) product.optLong("quantity") else -1L,
                imageUrl = product.optStringOrNull("imageUrl"),
                productUrl = product.optStringOrNull("productUrl"),
                metadata = product.optJSONObject("metadata")?.let { BrazeProperties(it) },
            )
        }
    }

    private fun parseDiscounts(discounts: JSONArray?): List<Any>? {
        if (discounts == null) return null
        return (0 until discounts.length()).map { discounts.getJSONObject(it) }
    }

    private fun parseCartUpdatedAction(action: String?): CartUpdatedAction {
        if (action == null) return CartUpdatedAction.REPLACE
        return CartUpdatedAction.entries.firstOrNull { it.wireValue.equals(action, ignoreCase = true) }
            ?: throw IllegalArgumentException("\"action\" must be one of: \"add\", \"remove\", \"replace\".")
    }

    private fun JSONObject.optStringOrNull(key: String): String? = if (has(key) && !isNull(key)) getString(key) else null

    private fun EcommerceProduct.toWireJson(): JSONObject =
        JSONObject().apply {
            put("product_id", productId)
            put("product_name", productName)
            put("variant_id", variantId)
            imageUrl?.let { put("image_url", it) }
            productUrl?.let { put("product_url", it) }
            put("quantity", quantity)
            put("price", price)
            metadata?.let { put("metadata", it.forJsonPut()) }
        }

    private fun requireNonBlank(value: String?, field: String): String {
        if (value.isNullOrBlank() || value.length > MAX_STRING_LENGTH) {
            throw IllegalArgumentException("\"$field\" must be non-blank and at most $MAX_STRING_LENGTH characters.")
        }
        return value
    }

    private fun requireNonNegative(value: Double?, field: String): Double {
        if (value == null || value < 0) {
            throw IllegalArgumentException("\"$field\" must be a non-negative number.")
        }
        return value
    }

    private fun requireValidCurrency(value: String?): String {
        val currency = requireNonBlank(value, "currency")
        if (!ISO_4217_FORMAT.matches(currency)) {
            throw IllegalArgumentException(
                "\"currency\" must be a valid ISO 4217 code (3 letters). Received: \"$currency\"",
            )
        }
        return currency.uppercase()
    }

    companion object {
        private const val MAX_STRING_LENGTH = 255
        private val ISO_4217_FORMAT = Regex("^[A-Za-z]{3}$")
    }
}
