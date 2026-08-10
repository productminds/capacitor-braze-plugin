package com.minders.capacitorbraze

import android.content.Context
import com.braze.Braze as BrazeSdk
import com.braze.models.outgoing.BrazeProperties
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
}
