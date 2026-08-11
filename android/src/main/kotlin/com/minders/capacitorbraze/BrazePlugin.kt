package com.minders.capacitorbraze

import com.getcapacitor.JSArray
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import java.math.BigDecimal

/** Rejects [PluginCall] with `"<key>" is required` and returns null when [key] is missing/empty. */
private fun PluginCall.requiredString(key: String): String? {
    val value = getString(key)
    if (value.isNullOrEmpty()) {
        reject("\"$key\" is required")
        return null
    }
    return value
}

/** Rejects [PluginCall] with `"<key>" is required` and returns null when [key] is missing. */
private fun PluginCall.requiredDouble(key: String): Double? {
    val value = getDouble(key)
    if (value == null) {
        reject("\"$key\" is required")
        return null
    }
    return value
}

/** Rejects [PluginCall] with `"<key>" must contain at least one item` and returns null when [key] is missing/empty. */
private fun PluginCall.requiredArray(key: String): JSArray? {
    val value = getArray(key)
    if (value == null || value.length() == 0) {
        reject("\"$key\" must contain at least one item")
        return null
    }
    return value
}

@CapacitorPlugin(name = "Braze")
class BrazePlugin : Plugin() {

    private val implementation = Braze()

    @PluginMethod
    fun changeUser(call: PluginCall) {
        val externalId = call.getString("externalId")
        if (externalId.isNullOrEmpty()) {
            call.reject("\"externalId\" is required")
            return
        }

        try {
            implementation.changeUser(context, externalId)
            call.resolve()
        } catch (e: Exception) {
            call.reject("Failed to change user: ${e.message}", e)
        }
    }

    @PluginMethod
    fun logCustomEvent(call: PluginCall) {
        val eventName = call.getString("eventName")
        if (eventName.isNullOrEmpty()) {
            call.reject("\"eventName\" is required")
            return
        }

        try {
            implementation.logCustomEvent(context, eventName, call.getObject("properties"))
            call.resolve()
        } catch (e: Exception) {
            call.reject("Failed to log custom event: ${e.message}", e)
        }
    }

    @PluginMethod
    fun logPurchase(call: PluginCall) {
        val productId = call.getString("productId")
        val currency = call.getString("currency")
        val price: Double? = call.getDouble("price")
        val quantity: Int? = call.getInt("quantity")

        if (productId.isNullOrEmpty()) {
            call.reject("\"productId\" is required")
            return
        }
        if (currency.isNullOrEmpty()) {
            call.reject("\"currency\" is required")
            return
        }
        if (price == null || price < 0) {
            call.reject("\"price\" must be a non-negative number")
            return
        }
        if (quantity == null || quantity < 0) {
            call.reject("\"quantity\" must be a non-negative integer")
            return
        }

        try {
            implementation.logPurchase(
                context,
                productId,
                currency,
                BigDecimal.valueOf(price),
                quantity,
                call.getObject("properties"),
            )
            call.resolve()
        } catch (e: Exception) {
            call.reject("Failed to log purchase: ${e.message}", e)
        }
    }

    @PluginMethod
    fun setCustomUserAttribute(call: PluginCall) {
        val key = call.getString("key")
        if (key.isNullOrEmpty()) {
            call.reject("\"key\" is required")
            return
        }
        if (!call.data.has("value")) {
            call.reject("\"value\" is required")
            return
        }

        val value: Any = when (val raw = call.data.get("value")) {
            is String, is Int, is Double, is Boolean -> raw
            is Long -> raw.toInt()
            else -> {
                call.reject("\"value\" must be a string, number, or boolean")
                return
            }
        }

        try {
            implementation.setCustomUserAttribute(context, key, value) { success ->
                if (success) {
                    call.resolve()
                } else {
                    call.reject("Failed to set custom user attribute")
                }
            }
        } catch (e: Exception) {
            call.reject("Failed to set custom user attribute: ${e.message}", e)
        }
    }

    @PluginMethod
    fun unsetCustomUserAttribute(call: PluginCall) {
        val key = call.requiredString("key") ?: return

        try {
            implementation.unsetCustomUserAttribute(context, key) { success ->
                if (success) {
                    call.resolve()
                } else {
                    call.reject("Failed to unset custom user attribute")
                }
            }
        } catch (e: Exception) {
            call.reject("Failed to unset custom user attribute: ${e.message}", e)
        }
    }

    @PluginMethod
    fun addToCustomUserAttributeArray(call: PluginCall) {
        val key = call.requiredString("key") ?: return
        val value = call.requiredString("value") ?: return

        try {
            implementation.addToCustomUserAttributeArray(context, key, value) { success ->
                if (success) {
                    call.resolve()
                } else {
                    call.reject("Failed to add to custom user attribute array")
                }
            }
        } catch (e: Exception) {
            call.reject("Failed to add to custom user attribute array: ${e.message}", e)
        }
    }

    @PluginMethod
    fun removeFromCustomUserAttributeArray(call: PluginCall) {
        val key = call.requiredString("key") ?: return
        val value = call.requiredString("value") ?: return

        try {
            implementation.removeFromCustomUserAttributeArray(context, key, value) { success ->
                if (success) {
                    call.resolve()
                } else {
                    call.reject("Failed to remove from custom user attribute array")
                }
            }
        } catch (e: Exception) {
            call.reject("Failed to remove from custom user attribute array: ${e.message}", e)
        }
    }

    @PluginMethod
    fun setUserProfile(call: PluginCall) {
        try {
            implementation.setUserProfile(
                context,
                call.getString("email"),
                call.getString("firstName"),
                call.getString("lastName"),
                call.getString("country"),
                call.getString("language"),
                call.getString("homeCity"),
                call.getString("phoneNumber"),
                call.getString("gender"),
                call.getString("dateOfBirth"),
            ) { failedFields ->
                if (failedFields.isEmpty()) {
                    call.resolve()
                } else {
                    call.reject("Braze rejected the following field(s): ${failedFields.joinToString(", ")}")
                }
            }
        } catch (e: IllegalArgumentException) {
            call.reject(e.message ?: "Invalid user profile payload", e)
        } catch (e: Exception) {
            call.reject("Failed to set user profile: ${e.message}", e)
        }
    }

    @PluginMethod
    fun logProductViewed(call: PluginCall) {
        val productId = call.requiredString("productId") ?: return
        val productName = call.requiredString("productName") ?: return
        val variantId = call.requiredString("variantId") ?: return
        val price = call.requiredDouble("price") ?: return
        val currency = call.requiredString("currency") ?: return
        val source = call.requiredString("source") ?: return

        try {
            implementation.logProductViewed(
                context,
                productId,
                productName,
                variantId,
                price,
                currency,
                source,
                call.getString("imageUrl"),
                call.getString("productUrl"),
                call.getArray("type")?.toList(),
                call.getObject("metadata"),
            )
            call.resolve()
        } catch (e: IllegalArgumentException) {
            call.reject(e.message ?: "Invalid product_viewed payload", e)
        } catch (e: Exception) {
            call.reject("Failed to log product viewed event: ${e.message}", e)
        }
    }

    @PluginMethod
    fun logCartUpdated(call: PluginCall) {
        val cartId = call.requiredString("cartId") ?: return
        val currency = call.requiredString("currency") ?: return
        val source = call.requiredString("source") ?: return
        val products = call.requiredArray("products") ?: return

        try {
            implementation.logCartUpdated(
                context,
                cartId,
                call.getString("action"),
                call.getDouble("totalValue"),
                call.getDouble("subtotalValue"),
                call.getDouble("tax"),
                call.getDouble("shipping"),
                currency,
                products,
                source,
                call.getObject("metadata"),
            )
            call.resolve()
        } catch (e: IllegalArgumentException) {
            call.reject(e.message ?: "Invalid cart_updated payload", e)
        } catch (e: Exception) {
            call.reject("Failed to log cart updated event: ${e.message}", e)
        }
    }

    @PluginMethod
    fun logCheckoutStarted(call: PluginCall) {
        val checkoutId = call.requiredString("checkoutId") ?: return
        val totalValue = call.requiredDouble("totalValue") ?: return
        val currency = call.requiredString("currency") ?: return
        val source = call.requiredString("source") ?: return
        val products = call.requiredArray("products") ?: return

        try {
            implementation.logCheckoutStarted(
                context,
                checkoutId,
                call.getString("cartId"),
                totalValue,
                call.getDouble("subtotalValue"),
                call.getDouble("tax"),
                call.getDouble("shipping"),
                currency,
                products,
                source,
                call.getObject("metadata"),
            )
            call.resolve()
        } catch (e: IllegalArgumentException) {
            call.reject(e.message ?: "Invalid checkout_started payload", e)
        } catch (e: Exception) {
            call.reject("Failed to log checkout started event: ${e.message}", e)
        }
    }

    @PluginMethod
    fun logOrderPlaced(call: PluginCall) {
        val orderId = call.requiredString("orderId") ?: return
        val totalValue = call.requiredDouble("totalValue") ?: return
        val currency = call.requiredString("currency") ?: return
        val source = call.requiredString("source") ?: return
        val products = call.requiredArray("products") ?: return

        try {
            implementation.logOrderPlaced(
                context,
                orderId,
                call.getString("cartId"),
                totalValue,
                call.getDouble("subtotalValue"),
                call.getDouble("tax"),
                call.getDouble("shipping"),
                currency,
                call.getDouble("totalDiscounts"),
                call.getArray("discounts"),
                products,
                source,
                call.getObject("metadata"),
            )
            call.resolve()
        } catch (e: IllegalArgumentException) {
            call.reject(e.message ?: "Invalid order_placed payload", e)
        } catch (e: Exception) {
            call.reject("Failed to log order placed event: ${e.message}", e)
        }
    }

    @PluginMethod
    fun logOrderCancelled(call: PluginCall) {
        try {
            val payload = implementation.buildOrderCancelledPayload(
                call.getString("orderId"),
                call.getDouble("totalValue"),
                call.getDouble("subtotalValue"),
                call.getDouble("tax"),
                call.getDouble("shipping"),
                call.getString("currency"),
                call.getDouble("totalDiscounts"),
                call.getArray("discounts"),
                call.getString("cancelReason"),
                call.getArray("products"),
                call.getString("source"),
                call.getObject("metadata"),
            )
            implementation.logOrderCancelled(context, payload)
            call.resolve()
        } catch (e: IllegalArgumentException) {
            call.reject(e.message ?: "Invalid order_cancelled payload", e)
        } catch (e: Exception) {
            call.reject("Failed to log order cancelled event: ${e.message}", e)
        }
    }

    @PluginMethod
    fun logOrderRefunded(call: PluginCall) {
        try {
            val payload = implementation.buildOrderRefundedPayload(
                call.getString("orderId"),
                call.getDouble("totalValue"),
                call.getString("currency"),
                call.getDouble("totalDiscounts"),
                call.getArray("discounts"),
                call.getArray("products"),
                call.getString("source"),
                call.getObject("metadata"),
            )
            implementation.logOrderRefunded(context, payload)
            call.resolve()
        } catch (e: IllegalArgumentException) {
            call.reject(e.message ?: "Invalid order_refunded payload", e)
        } catch (e: Exception) {
            call.reject("Failed to log order refunded event: ${e.message}", e)
        }
    }
}
