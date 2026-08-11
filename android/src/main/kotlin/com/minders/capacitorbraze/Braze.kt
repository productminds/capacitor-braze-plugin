package com.minders.capacitorbraze

import android.content.Context
import com.braze.Braze as BrazeSdk
import com.braze.enums.Gender
import com.braze.enums.Month
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
import java.util.GregorianCalendar

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

    fun unsetCustomUserAttribute(context: Context, key: String, onComplete: (Boolean) -> Unit) {
        requireConfiguredInstance(context).getCurrentUser { user ->
            onComplete(user.unsetCustomUserAttribute(key))
        }
    }

    fun addToCustomUserAttributeArray(context: Context, key: String, value: String, onComplete: (Boolean) -> Unit) {
        requireConfiguredInstance(context).getCurrentUser { user ->
            onComplete(user.addToCustomAttributeArray(key, value))
        }
    }

    fun removeFromCustomUserAttributeArray(context: Context, key: String, value: String, onComplete: (Boolean) -> Unit) {
        requireConfiguredInstance(context).getCurrentUser { user ->
            onComplete(user.removeFromCustomAttributeArray(key, value))
        }
    }

    /**
     * Validates a {@link setUserProfile} payload: at least one field must be
     * present, and any present field must be individually valid (non-blank
     * strings; `gender` must be a recognized value; `dateOfBirth` must be a
     * valid ISO 8601 date). Pure (no [Context], no SDK calls) so an invalid
     * payload is rejected before any native user setter is ever reached,
     * and so it can be unit tested directly.
     */
    fun validateUserProfileFields(
        email: String?,
        firstName: String?,
        lastName: String?,
        country: String?,
        language: String?,
        homeCity: String?,
        phoneNumber: String?,
        gender: String?,
        dateOfBirth: String?,
    ) {
        if (
            email == null && firstName == null && lastName == null && country == null &&
            language == null && homeCity == null && phoneNumber == null && gender == null &&
            dateOfBirth == null
        ) {
            throw IllegalArgumentException(
                "At least one of \"email\", \"firstName\", \"lastName\", \"country\", " +
                    "\"language\", \"homeCity\", \"phoneNumber\", \"gender\", or \"dateOfBirth\" is required.",
            )
        }
        email?.let { requireNonBlank(it, "email") }
        firstName?.let { requireNonBlank(it, "firstName") }
        lastName?.let { requireNonBlank(it, "lastName") }
        country?.let { requireNonBlank(it, "country") }
        language?.let { requireNonBlank(it, "language") }
        homeCity?.let { requireNonBlank(it, "homeCity") }
        phoneNumber?.let { requireNonBlank(it, "phoneNumber") }
        gender?.let { parseGender(it) }
        dateOfBirth?.let { parseDateOfBirth(it) }
    }

    /**
     * Sets one or more reserved profile fields. Unlike custom attributes,
     * every native setter here (`setEmail`, `setFirstName`, ..., including
     * `setPhoneNumber`) returns a Boolean success flag — Braze applies its
     * own native-side validation (e.g. phone number format) independently
     * of this plugin's own non-blank checks above, and a value it rejects
     * comes back as `false` rather than an exception. [onComplete] receives
     * the names of any fields that failed to set, so the plugin layer can
     * reject instead of silently reporting success.
     */
    fun setUserProfile(
        context: Context,
        email: String?,
        firstName: String?,
        lastName: String?,
        country: String?,
        language: String?,
        homeCity: String?,
        phoneNumber: String?,
        gender: String?,
        dateOfBirth: String?,
        onComplete: (List<String>) -> Unit,
    ) {
        validateUserProfileFields(email, firstName, lastName, country, language, homeCity, phoneNumber, gender, dateOfBirth)
        val parsedGender = gender?.let { parseGender(it) }
        val parsedDateOfBirth = dateOfBirth?.let { parseDateOfBirth(it) }

        requireConfiguredInstance(context).getCurrentUser { user ->
            val failedFields = mutableListOf<String>()
            fun track(field: String, success: Boolean) {
                if (!success) failedFields += field
            }
            email?.let { track("email", user.setEmail(it)) }
            firstName?.let { track("firstName", user.setFirstName(it)) }
            lastName?.let { track("lastName", user.setLastName(it)) }
            country?.let { track("country", user.setCountry(it)) }
            language?.let { track("language", user.setLanguage(it)) }
            homeCity?.let { track("homeCity", user.setHomeCity(it)) }
            phoneNumber?.let { track("phoneNumber", user.setPhoneNumber(it)) }
            parsedGender?.let { track("gender", user.setGender(it)) }
            parsedDateOfBirth?.let { (year, month, day) -> track("dateOfBirth", user.setDateOfBirth(year, month, day)) }
            onComplete(failedFields)
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

    /**
     * Maps this plugin's own `gender` string values (documented in the
     * README, shared with the iOS implementation) to the real
     * [com.braze.enums.Gender] enum. Not delegated to
     * [com.braze.enums.Gender.Companion.getGender], which parses Braze's
     * internal single-letter wire codes ("m", "f", ...), not the readable
     * values this plugin's TypeScript API exposes.
     */
    private fun parseGender(value: String): Gender {
        return VALID_GENDERS[value] ?: throw IllegalArgumentException(
            "\"gender\" must be one of: ${VALID_GENDERS.keys.joinToString(", ") { "\"$it\"" }}. Received: \"$value\"",
        )
    }

    /**
     * Parses a `"YYYY-MM-DD"` string into the (year, [Month], day) triple
     * [com.braze.BrazeUser.setDateOfBirth] takes. [GregorianCalendar] with
     * `isLenient = false` is used (instead of `java.time`, which needs API
     * 26+ or desugaring — this plugin supports minSdk 24) to reject
     * calendar-invalid dates the regex alone can't catch, e.g. "2020-02-30".
     */
    private fun parseDateOfBirth(value: String): Triple<Int, Month, Int> {
        val match = ISO_DATE_FORMAT.matchEntire(value) ?: throw invalidDateOfBirth(value)
        val (yearStr, monthStr, dayStr) = match.destructured
        val year = yearStr.toInt()
        val isoMonth = monthStr.toInt()
        val day = dayStr.toInt()

        try {
            val calendar = GregorianCalendar()
            calendar.isLenient = false
            calendar.clear()
            calendar.set(year, isoMonth - 1, day)
            calendar.timeInMillis
        } catch (e: IllegalArgumentException) {
            throw invalidDateOfBirth(value)
        }

        // Month.value is 0-indexed (JANUARY = 0), matching java.util.Calendar's
        // MONTH field — NOT the 1-indexed month in the "YYYY-MM-DD" wire format.
        // getMonth returns null for an out-of-range index, which shouldn't be
        // reachable here (the non-lenient Calendar above already rejects a
        // month outside 0-11), but is handled rather than force-unwrapped.
        val month = Month.getMonth(isoMonth - 1) ?: throw invalidDateOfBirth(value)
        return Triple(year, month, day)
    }

    private fun invalidDateOfBirth(value: String) = IllegalArgumentException(
        "\"dateOfBirth\" must be a valid ISO 8601 date (\"YYYY-MM-DD\"). Received: \"$value\"",
    )

    companion object {
        private const val MAX_STRING_LENGTH = 255
        private val ISO_4217_FORMAT = Regex("^[A-Za-z]{3}$")
        private val ISO_DATE_FORMAT = Regex("^(\\d{4})-(\\d{2})-(\\d{2})$")
        private val VALID_GENDERS = mapOf(
            "male" to Gender.MALE,
            "female" to Gender.FEMALE,
            "other" to Gender.OTHER,
            "unknown" to Gender.UNKNOWN,
            "not_applicable" to Gender.NOT_APPLICABLE,
            "prefer_not_to_say" to Gender.PREFER_NOT_TO_SAY,
        )
    }
}
