package com.minders.capacitorbraze

import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import java.math.BigDecimal

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
}
