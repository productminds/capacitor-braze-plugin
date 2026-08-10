package com.minders.capacitorbraze

import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * [Braze.buildOrderCancelledPayload] and [Braze.buildOrderRefundedPayload] are
 * the only validation path for `order_cancelled`/`order_refunded` — Braze has
 * no native typed class for either event, so this plugin must reject invalid
 * payloads itself before ever reaching `logCustomEvent`. These tests call the
 * pure payload builders directly (no [android.content.Context], no Braze SDK
 * instance involved) so a missing required field is provably rejected without
 * the event ever being dispatched.
 */
class BrazeEcommerceValidationTest {

    private val implementation = Braze()

    @Test
    fun logOrderCancelledPayloadRejectsWhenProductsMissing() {
        val exception =
            assertThrows(IllegalArgumentException::class.java) {
                implementation.buildOrderCancelledPayload(
                    orderId = "order-1",
                    totalValue = 10.0,
                    subtotalValue = null,
                    tax = null,
                    shipping = null,
                    currency = "USD",
                    totalDiscounts = null,
                    discounts = null,
                    cancelReason = "customer_request",
                    products = null,
                    source = "test",
                    metadata = null,
                )
            }
        assertTrue(exception.message.orEmpty().contains("products"))
    }

    @Test
    fun logOrderRefundedPayloadRejectsWhenProductsMissing() {
        val exception =
            assertThrows(IllegalArgumentException::class.java) {
                implementation.buildOrderRefundedPayload(
                    orderId = "order-1",
                    totalValue = 10.0,
                    currency = "USD",
                    totalDiscounts = null,
                    discounts = null,
                    products = null,
                    source = "test",
                    metadata = null,
                )
            }
        assertTrue(exception.message.orEmpty().contains("products"))
    }
}
