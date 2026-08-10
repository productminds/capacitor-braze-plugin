# capacitor-braze-plugin

Braze has no official Capacitor SDK — this plugin wraps the native Braze Android and iOS SDKs and exposes a core set of methods to the JS/TypeScript layer of any Ionic/Capacitor app.

[![license](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![build](https://github.com/productminds/capacitor-braze-plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/productminds/capacitor-braze-plugin/actions/workflows/ci.yml)

> **This plugin does not handle Braze credentials or SDK initialization.** There is no `initialize()` method — Braze API keys differ per platform, so configuring the native SDK (API key + endpoint) is exclusively the responsibility of your app's own native, declarative configuration (see [Native configuration](#native-configuration)). Every method below rejects with a clear error if you call it before that native configuration is in place.

## Installation

This package is not published to the npm registry — install it directly from GitHub:

```bash
npm install github:productminds/capacitor-braze-plugin
npx cap sync
```

## Requirements

| | Minimum version |
| --- | --- |
| Capacitor | 8.0.0 |
| Android (minSdk) | 24 |
| iOS (deployment target) | 15.0 |

This plugin does not bundle any Braze credentials. Configure the native Braze SDK declaratively in your app before using any method below — see [Native configuration](#native-configuration).

## Quick start

Assumes you've already completed the [native configuration](#native-configuration) step for each platform you target.

```typescript
import { Braze } from 'capacitor-braze-plugin';

// Identify the current user, e.g. right after login.
await Braze.changeUser({ externalId: 'user-1234' });

// Log a custom event.
await Braze.logCustomEvent({
  eventName: 'viewed_product',
  properties: { productId: 'sku-123', category: 'shoes' },
});

// Log a purchase.
await Braze.logPurchase({
  productId: 'sku-123',
  currency: 'USD',
  price: 19.99,
  quantity: 2,
  properties: { color: 'blue' },
});

// Set a custom attribute on the current user's profile.
await Braze.setCustomUserAttribute({ key: 'favorite_color', value: 'blue' });
```

## eCommerce events

This plugin exposes Braze's [6 recommended eCommerce events](https://www.braze.com/docs/developer_guide/analytics/ecommerce) — `product_viewed`, `cart_updated`, `checkout_started`, `order_placed`, `order_cancelled`, `order_refunded` — as 6 methods with a uniform, fully-typed API: every method takes a single typed `options` object and returns `Promise<void>`, the same shape as every other method in this plugin.

Underneath, the implementation differs per event, because Braze itself doesn't offer the same tooling for all 6:

* **`logProductViewed`, `logCartUpdated`, `logCheckoutStarted`, `logOrderPlaced`** are backed by a native Braze SDK class on each platform (Android `ProductViewedEvent`/`CartUpdatedEvent`/`CheckoutStartedEvent`/`OrderPlacedEvent`, iOS `Braze.Ecommerce.*`). Those native classes validate the payload when they're constructed and reject with a clear error before anything is queued.
* **`logOrderCancelled`, `logOrderRefunded`** have no native typed class on either platform — Braze's own guidance is to log these two manually via `logCustomEvent`. This plugin validates their payload natively (replicating the same non-blank/length and non-negative rules the typed classes above enforce, including reusing the native product line-item type for the `products` array) before dispatching via `logCustomEvent` with the event names `"ecommerce.order_cancelled"` / `"ecommerce.order_refunded"`, so an invalid payload is still rejected immediately instead of being silently ingested. One difference: `currency` is only checked for a 3-letter format here, not against a real ISO 4217 code list the way the native SDK classes may do for the other 4 events.

From the calling code, that difference is invisible — both call shapes below are equally simple:

```typescript
// Backed by a native Braze SDK class.
await Braze.logProductViewed({
  productId: 'sku-123',
  productName: 'Running Shoes',
  variantId: 'sku-123-blue-10',
  price: 89.99,
  currency: 'USD',
  source: 'product_detail_screen',
});

// No native class — validated here, then dispatched via logCustomEvent.
await Braze.logOrderRefunded({
  orderId: 'order-321',
  totalValue: 29.99, // partial refund: only the refunded amount
  currency: 'USD',
  source: 'support_screen',
  products: [
    { productId: 'sku-123', productName: 'Running Shoes', variantId: 'sku-123-blue-10', quantity: 1, price: 29.99 },
  ],
});
```

See the [Braze eCommerce events guide](https://www.braze.com/docs/developer_guide/analytics/ecommerce) for the full schema of each event, and the [API](#api) section below for this plugin's exact option types.

## API

<docgen-index>

* [`changeUser(...)`](#changeuser)
* [`logCustomEvent(...)`](#logcustomevent)
* [`logPurchase(...)`](#logpurchase)
* [`setCustomUserAttribute(...)`](#setcustomuserattribute)
* [`logProductViewed(...)`](#logproductviewed)
* [`logCartUpdated(...)`](#logcartupdated)
* [`logCheckoutStarted(...)`](#logcheckoutstarted)
* [`logOrderPlaced(...)`](#logorderplaced)
* [`logOrderCancelled(...)`](#logordercancelled)
* [`logOrderRefunded(...)`](#logorderrefunded)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

Capacitor plugin that wraps the core analytics and user identity APIs of
the native Braze SDKs (Android and iOS).

This plugin does not configure the Braze SDK and does not accept API
keys or endpoints — the host app must configure the native Braze SDK
declaratively (Android string resources / iOS `AppDelegate` code)
before calling any method here. See the README's "Native configuration"
section for the exact steps. Every method below rejects with a clear
error if the native SDK has not been configured yet.

This plugin intentionally covers a focused "core" surface — see the
"Not covered by this plugin" section of the README for functionality
(push notifications, manual session control, in-app messages, Content
Cards) that is left to direct native SDK integration.

### changeUser(...)

```typescript
changeUser(options: ChangeUserOptions) => Promise<void>
```

Identifies the current user to Braze with an external (app-assigned)
user ID, e.g. after login. Calling this with a different ID than the
currently identified user starts a new user session and clears
previously set user data on the client, per standard Braze SDK
behavior.

| Param         | Type                                                            | Description                                |
| ------------- | --------------------------------------------------------------- | ------------------------------------------ |
| **`options`** | <code><a href="#changeuseroptions">ChangeUserOptions</a></code> | The external ID to identify the user with. |

--------------------


### logCustomEvent(...)

```typescript
logCustomEvent(options: LogCustomEventOptions) => Promise<void>
```

Logs a custom event to Braze, optionally with additional properties.

| Param         | Type                                                                    | Description                             |
| ------------- | ----------------------------------------------------------------------- | --------------------------------------- |
| **`options`** | <code><a href="#logcustomeventoptions">LogCustomEventOptions</a></code> | The event name and optional properties. |

--------------------


### logPurchase(...)

```typescript
logPurchase(options: LogPurchaseOptions) => Promise<void>
```

Logs a purchase event to Braze.

| Param         | Type                                                              | Description           |
| ------------- | ----------------------------------------------------------------- | --------------------- |
| **`options`** | <code><a href="#logpurchaseoptions">LogPurchaseOptions</a></code> | The purchase details. |

--------------------


### setCustomUserAttribute(...)

```typescript
setCustomUserAttribute(options: SetCustomUserAttributeOptions) => Promise<void>
```

Sets a custom attribute on the current user's Braze profile.

| Param         | Type                                                                                    | Description                  |
| ------------- | --------------------------------------------------------------------------------------- | ---------------------------- |
| **`options`** | <code><a href="#setcustomuserattributeoptions">SetCustomUserAttributeOptions</a></code> | The attribute key and value. |

--------------------


### logProductViewed(...)

```typescript
logProductViewed(options: ProductViewedOptions) => Promise<void>
```

Logs Braze's recommended `product_viewed` eCommerce event.

Backed by a native Braze SDK class (Android `ProductViewedEvent`, iOS
`Braze.Ecommerce.ProductViewedEvent`), which validates the payload
before the event is queued.

| Param         | Type                                                                  | Description               |
| ------------- | --------------------------------------------------------------------- | ------------------------- |
| **`options`** | <code><a href="#productviewedoptions">ProductViewedOptions</a></code> | The product view details. |

--------------------


### logCartUpdated(...)

```typescript
logCartUpdated(options: CartUpdatedOptions) => Promise<void>
```

Logs Braze's recommended `cart_updated` eCommerce event.

Backed by a native Braze SDK class (Android `CartUpdatedEvent`, iOS
`Braze.Ecommerce.CartUpdatedEvent`), which validates the payload before
the event is queued.

| Param         | Type                                                              | Description              |
| ------------- | ----------------------------------------------------------------- | ------------------------ |
| **`options`** | <code><a href="#cartupdatedoptions">CartUpdatedOptions</a></code> | The cart update details. |

--------------------


### logCheckoutStarted(...)

```typescript
logCheckoutStarted(options: CheckoutStartedOptions) => Promise<void>
```

Logs Braze's recommended `checkout_started` eCommerce event.

Backed by a native Braze SDK class (Android `CheckoutStartedEvent`, iOS
`Braze.Ecommerce.CheckoutStartedEvent`), which validates the payload
before the event is queued.

| Param         | Type                                                                      | Description           |
| ------------- | ------------------------------------------------------------------------- | --------------------- |
| **`options`** | <code><a href="#checkoutstartedoptions">CheckoutStartedOptions</a></code> | The checkout details. |

--------------------


### logOrderPlaced(...)

```typescript
logOrderPlaced(options: OrderPlacedOptions) => Promise<void>
```

Logs Braze's recommended `order_placed` eCommerce event.

Backed by a native Braze SDK class (Android `OrderPlacedEvent`, iOS
`Braze.Ecommerce.OrderPlacedEvent`), which validates the payload before
the event is queued.

| Param         | Type                                                              | Description        |
| ------------- | ----------------------------------------------------------------- | ------------------ |
| **`options`** | <code><a href="#orderplacedoptions">OrderPlacedOptions</a></code> | The order details. |

--------------------


### logOrderCancelled(...)

```typescript
logOrderCancelled(options: OrderCancelledOptions) => Promise<void>
```

Logs Braze's recommended `order_cancelled` eCommerce event.

Braze does not provide a native typed class for this event on either
platform — this method validates the payload natively (replicating the
same rules the typed classes above enforce) and dispatches it via
`logCustomEvent` with the event name `"ecommerce.order_cancelled"`, so
that invalid payloads fail fast here instead of being silently ingested.

| Param         | Type                                                                    | Description               |
| ------------- | ----------------------------------------------------------------------- | ------------------------- |
| **`options`** | <code><a href="#ordercancelledoptions">OrderCancelledOptions</a></code> | The cancellation details. |

--------------------


### logOrderRefunded(...)

```typescript
logOrderRefunded(options: OrderRefundedOptions) => Promise<void>
```

Logs Braze's recommended `order_refunded` eCommerce event.

Braze does not provide a native typed class for this event on either
platform — this method validates the payload natively (replicating the
same rules the typed classes above enforce) and dispatches it via
`logCustomEvent` with the event name `"ecommerce.order_refunded"`, so
that invalid payloads fail fast here instead of being silently ingested.

| Param         | Type                                                                  | Description         |
| ------------- | --------------------------------------------------------------------- | ------------------- |
| **`options`** | <code><a href="#orderrefundedoptions">OrderRefundedOptions</a></code> | The refund details. |

--------------------


### Interfaces


#### ChangeUserOptions

Options for {@link BrazePlugin.changeUser}.

| Prop             | Type                | Description                                                                                                                        |
| ---------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **`externalId`** | <code>string</code> | The external (app-assigned) user ID to associate with the current device, e.g. your backend's user ID once the user has logged in. |


#### LogCustomEventOptions

Options for {@link BrazePlugin.logCustomEvent}.

| Prop             | Type                                                             | Description                                                                                                                                                                                     |
| ---------------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`eventName`**  | <code>string</code>                                              | The name of the custom event, as it will appear in the Braze dashboard.                                                                                                                         |
| **`properties`** | <code><a href="#record">Record</a>&lt;string, unknown&gt;</code> | Optional key/value properties attached to the event. Values must be JSON-serializable (string, number, boolean, or null); nested objects and arrays are not supported by the native Braze SDKs. |


#### LogPurchaseOptions

Options for {@link BrazePlugin.logPurchase}.

| Prop             | Type                                                             | Description                                                                                                                                                                                              |
| ---------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`productId`**  | <code>string</code>                                              | The identifier for the purchased product (e.g. a SKU).                                                                                                                                                   |
| **`currency`**   | <code>string</code>                                              | The ISO 4217 currency code for the purchase (e.g. `"USD"`).                                                                                                                                              |
| **`price`**      | <code>number</code>                                              | The price of a single unit of the product, in the given currency.                                                                                                                                        |
| **`quantity`**   | <code>number</code>                                              | The number of units purchased.                                                                                                                                                                           |
| **`properties`** | <code><a href="#record">Record</a>&lt;string, unknown&gt;</code> | Optional key/value properties attached to the purchase event. Values must be JSON-serializable (string, number, boolean, or null); nested objects and arrays are not supported by the native Braze SDKs. |


#### SetCustomUserAttributeOptions

Options for {@link BrazePlugin.setCustomUserAttribute}.

| Prop        | Type                                     | Description                                                                                                                                             |
| ----------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`key`**   | <code>string</code>                      | The name of the custom attribute, as it will appear in the Braze dashboard.                                                                             |
| **`value`** | <code>string \| number \| boolean</code> | The value to set for the attribute. Arrays and objects are not supported by this method; use the native SDK directly for array-typed custom attributes. |


#### ProductViewedOptions

Options for {@link BrazePlugin.logProductViewed}.

| Prop              | Type                                                                                 | Description                                                                               |
| ----------------- | ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- |
| **`productId`**   | <code>string</code>                                                                  | The identifier for the viewed product (e.g. a SKU).                                       |
| **`productName`** | <code>string</code>                                                                  | The display name of the viewed product.                                                   |
| **`variantId`**   | <code>string</code>                                                                  | The identifier for the specific variant of the product being viewed.                      |
| **`imageUrl`**    | <code>string</code>                                                                  | A URL for an image of the product.                                                        |
| **`productUrl`**  | <code>string</code>                                                                  | A URL to the product's page.                                                              |
| **`price`**       | <code>number</code>                                                                  | The price of the product, in the given currency.                                          |
| **`currency`**    | <code>string</code>                                                                  | The ISO 4217 currency code for the price (e.g. `"USD"`).                                  |
| **`source`**      | <code>string</code>                                                                  | A label identifying where this view occurred in your app (e.g. a screen or feature name). |
| **`type`**        | <code>('price_drop' \| 'back_in_stock')[]</code>                                     | Optional tags describing why this product is being surfaced.                              |
| **`metadata`**    | <code><a href="#record">Record</a>&lt;string, string \| number \| boolean&gt;</code> | Optional key/value properties attached to the event.                                      |


#### CartUpdatedOptions

Options for {@link BrazePlugin.logCartUpdated}.

| Prop                | Type                                                                                 | Description                                                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **`cartId`**        | <code>string</code>                                                                  | The identifier for the shopping cart.                                                                                                        |
| **`action`**        | <code><a href="#cartupdatedaction">CartUpdatedAction</a></code>                      | How the cart changed. Defaults to `"replace"`.                                                                                               |
| **`totalValue`**    | <code>number</code>                                                                  | The cart's total value after this update. Required when `action` is omitted or `"replace"`; optional when `action` is `"add"` or `"remove"`. |
| **`subtotalValue`** | <code>number</code>                                                                  | The cart's subtotal value (before tax/shipping), if available.                                                                               |
| **`tax`**           | <code>number</code>                                                                  | The tax amount applied to the cart, if available.                                                                                            |
| **`shipping`**      | <code>number</code>                                                                  | The shipping cost applied to the cart, if available.                                                                                         |
| **`currency`**      | <code>string</code>                                                                  | The ISO 4217 currency code for the monetary values (e.g. `"USD"`).                                                                           |
| **`products`**      | <code>EcommerceProduct[]</code>                                                      | The product line items in the cart. Must contain at least one item.                                                                          |
| **`source`**        | <code>string</code>                                                                  | A label identifying where this update occurred in your app.                                                                                  |
| **`metadata`**      | <code><a href="#record">Record</a>&lt;string, string \| number \| boolean&gt;</code> | Optional key/value properties attached to the event.                                                                                         |


#### EcommerceProduct

A single product line item, used by the eCommerce events that carry a
product list ({@link BrazePlugin.logCartUpdated},
{@link BrazePlugin.logCheckoutStarted}, {@link BrazePlugin.logOrderPlaced},
{@link BrazePlugin.logOrderCancelled}, {@link BrazePlugin.logOrderRefunded}).

| Prop              | Type                                                                                 | Description                                                                           |
| ----------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| **`productId`**   | <code>string</code>                                                                  | The identifier for the product (e.g. a SKU).                                          |
| **`productName`** | <code>string</code>                                                                  | The display name of the product.                                                      |
| **`variantId`**   | <code>string</code>                                                                  | The identifier for the specific variant of the product (e.g. size/color).             |
| **`imageUrl`**    | <code>string</code>                                                                  | A URL for an image of the product.                                                    |
| **`productUrl`**  | <code>string</code>                                                                  | A URL to the product's page.                                                          |
| **`quantity`**    | <code>number</code>                                                                  | The number of units of this product in the line item. Must be a non-negative integer. |
| **`price`**       | <code>number</code>                                                                  | The price of a single unit of the product.                                            |
| **`metadata`**    | <code><a href="#record">Record</a>&lt;string, string \| number \| boolean&gt;</code> | Optional key/value properties attached to this line item.                             |


#### CheckoutStartedOptions

Options for {@link BrazePlugin.logCheckoutStarted}.

| Prop                | Type                                                                                 | Description                                                                                                                            |
| ------------------- | ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| **`checkoutId`**    | <code>string</code>                                                                  | The identifier for this checkout.                                                                                                      |
| **`cartId`**        | <code>string</code>                                                                  | The identifier for the shopping cart that started checkout, if available.                                                              |
| **`totalValue`**    | <code>number</code>                                                                  | The checkout's total value.                                                                                                            |
| **`subtotalValue`** | <code>number</code>                                                                  | The checkout's subtotal value (before tax/shipping), if available.                                                                     |
| **`tax`**           | <code>number</code>                                                                  | The tax amount applied to the checkout, if available.                                                                                  |
| **`shipping`**      | <code>number</code>                                                                  | The shipping cost applied to the checkout, if available.                                                                               |
| **`currency`**      | <code>string</code>                                                                  | The ISO 4217 currency code for the monetary values (e.g. `"USD"`).                                                                     |
| **`products`**      | <code>EcommerceProduct[]</code>                                                      | The product line items being checked out. Must contain at least one item.                                                              |
| **`source`**        | <code>string</code>                                                                  | A label identifying where checkout started in your app.                                                                                |
| **`metadata`**      | <code><a href="#record">Record</a>&lt;string, string \| number \| boolean&gt;</code> | Optional key/value properties attached to the event. Braze recognizes the `checkout_url` metadata key for a link back to the checkout. |


#### OrderPlacedOptions

Options for {@link BrazePlugin.logOrderPlaced}.

| Prop                 | Type                                                                                 | Description                                                                                                                           |
| -------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| **`orderId`**        | <code>string</code>                                                                  | The identifier for the placed order.                                                                                                  |
| **`cartId`**         | <code>string</code>                                                                  | The identifier for the shopping cart the order was placed from, if available.                                                         |
| **`totalValue`**     | <code>number</code>                                                                  | The order's total value.                                                                                                              |
| **`subtotalValue`**  | <code>number</code>                                                                  | The order's subtotal value (before tax/shipping), if available.                                                                       |
| **`tax`**            | <code>number</code>                                                                  | The tax amount applied to the order, if available.                                                                                    |
| **`shipping`**       | <code>number</code>                                                                  | The shipping cost applied to the order, if available.                                                                                 |
| **`currency`**       | <code>string</code>                                                                  | The ISO 4217 currency code for the monetary values (e.g. `"USD"`).                                                                    |
| **`totalDiscounts`** | <code>number</code>                                                                  | The total monetary amount discounted on this order, if any.                                                                           |
| **`discounts`**      | <code>OrderDiscount[]</code>                                                         | The individual discounts applied to this order, if any.                                                                               |
| **`products`**       | <code>EcommerceProduct[]</code>                                                      | The product line items in the order. Must contain at least one item.                                                                  |
| **`source`**         | <code>string</code>                                                                  | A label identifying where the order was placed in your app.                                                                           |
| **`metadata`**       | <code><a href="#record">Record</a>&lt;string, string \| number \| boolean&gt;</code> | Optional key/value properties attached to the event. Braze recognizes the `order_status_url` metadata key for a link to order status. |


#### OrderDiscount

A single order-level discount entry, used by
{@link BrazePlugin.logOrderPlaced}, {@link BrazePlugin.logOrderCancelled},
and {@link BrazePlugin.logOrderRefunded}.

| Prop         | Type                | Description                                            |
| ------------ | ------------------- | ------------------------------------------------------ |
| **`code`**   | <code>string</code> | The discount code applied to the order.                |
| **`amount`** | <code>number</code> | The monetary amount discounted.                        |
| **`type`**   | <code>string</code> | The type of discount (e.g. `"percentage"`, `"fixed"`). |


#### OrderCancelledOptions

Options for {@link BrazePlugin.logOrderCancelled}.

| Prop                 | Type                                                                                 | Description                                                                                                                           |
| -------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| **`orderId`**        | <code>string</code>                                                                  | The identifier for the cancelled order.                                                                                               |
| **`totalValue`**     | <code>number</code>                                                                  | The order's total value. Must be non-negative.                                                                                        |
| **`subtotalValue`**  | <code>number</code>                                                                  | The order's subtotal value (before tax/shipping), if available.                                                                       |
| **`tax`**            | <code>number</code>                                                                  | The tax amount applied to the order, if available.                                                                                    |
| **`shipping`**       | <code>number</code>                                                                  | The shipping cost applied to the order, if available.                                                                                 |
| **`currency`**       | <code>string</code>                                                                  | The ISO 4217 currency code for the monetary values (e.g. `"USD"`).                                                                    |
| **`totalDiscounts`** | <code>number</code>                                                                  | The total monetary amount discounted on this order, if any.                                                                           |
| **`discounts`**      | <code>OrderDiscount[]</code>                                                         | The individual discounts applied to this order, if any.                                                                               |
| **`cancelReason`**   | <code>string</code>                                                                  | The reason the order was cancelled.                                                                                                   |
| **`products`**       | <code>EcommerceProduct[]</code>                                                      | The product line items in the cancelled order. Must contain at least one item.                                                        |
| **`source`**         | <code>string</code>                                                                  | A label identifying where the cancellation was initiated in your app.                                                                 |
| **`metadata`**       | <code><a href="#record">Record</a>&lt;string, string \| number \| boolean&gt;</code> | Optional key/value properties attached to the event. Braze recognizes the `order_status_url` metadata key for a link to order status. |


#### OrderRefundedOptions

Options for {@link BrazePlugin.logOrderRefunded}.

| Prop                 | Type                                                                                 | Description                                                                                                                           |
| -------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| **`orderId`**        | <code>string</code>                                                                  | The identifier for the refunded order.                                                                                                |
| **`totalValue`**     | <code>number</code>                                                                  | The refunded amount. Must be non-negative. For partial refunds, send only the amount that was refunded, not the original order total. |
| **`currency`**       | <code>string</code>                                                                  | The ISO 4217 currency code for the monetary values (e.g. `"USD"`).                                                                    |
| **`totalDiscounts`** | <code>number</code>                                                                  | The total monetary amount discounted on this order, if any.                                                                           |
| **`discounts`**      | <code>OrderDiscount[]</code>                                                         | The individual discounts applied to this order, if any.                                                                               |
| **`products`**       | <code>EcommerceProduct[]</code>                                                      | The product line items in the refunded order. Must contain at least one item.                                                         |
| **`source`**         | <code>string</code>                                                                  | A label identifying where the refund was initiated in your app.                                                                       |
| **`metadata`**       | <code><a href="#record">Record</a>&lt;string, string \| number \| boolean&gt;</code> | Optional key/value properties attached to the event. Braze recognizes the `order_status_url` metadata key for a link to order status. |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>


#### CartUpdatedAction

The action that changed a shopping cart, for {@link BrazePlugin.logCartUpdated}.

<code>'add' | 'remove' | 'replace'</code>

</docgen-api>

## Native configuration

Braze API keys are different per platform, and this plugin never accepts one from JS — configuring the native SDK (API key + endpoint) is entirely your app's responsibility, done natively and declaratively, once per platform, before any method on this plugin is called. There is no runtime/JS initialization path.

### Android

Declare your API key and endpoint as string resources — Braze reads these directly from `res/values/`, not from `AndroidManifest.xml`. Create (or edit) `android/app/src/main/res/values/braze.xml` in your app:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="com_braze_api_key" translatable="false">YOUR-ANDROID-API-KEY</string>
    <string name="com_braze_custom_endpoint" translatable="false">YOUR-BRAZE-ENDPOINT</string>
</resources>
```

That's it — no Kotlin/Java code, no `Application` subclass, no manifest changes required. The Braze Android SDK reads these resources the first time it's used. See the [Braze Android SDK integration guide](https://www.braze.com/docs/developer_guide/sdk_integration?sdktab=android) for the full list of optional configuration keys.

### iOS

BrazeKit has no manifest/plist-based configuration — it must be configured in Swift code, once, before this plugin is used. The module name you `import` for this plugin depends on how your app integrates it — **Capacitor 8 uses SPM by default**, so that's the primary path below; CocoaPods is documented as the alternative.

Add `BrazeKit` as a **direct** dependency of your iOS app (not just of this plugin), then configure it in your app's `AppDelegate` and assign the instance to this plugin's `BrazeBridge.sharedInstance` before `application(_:didFinishLaunchingWithOptions:)` returns.

#### Swift Package Manager (default for Capacitor 8)

1. In Xcode: File → Add Package Dependencies… → `https://github.com/braze-inc/braze-swift-sdk`.
2. `AppDelegate.swift` — import this plugin's SPM target, **`BrazePlugin`**:

```swift
import UIKit
import Capacitor
import BrazeKit
import BrazePlugin

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let configuration = Braze.Configuration(
            apiKey: "YOUR-IOS-API-KEY",
            endpoint: "YOUR-BRAZE-ENDPOINT"
        )
        BrazeBridge.sharedInstance = Braze(configuration: configuration)
        return true
    }
}
```

#### CocoaPods (alternative)

1. Add to your app's `Podfile` (BrazeKit ships a static xcframework, so `use_frameworks!` needs static linkage):

   ```ruby
   use_frameworks! :linkage => :static

   target 'App' do
     pod 'CapacitorBrazePlugin', :path => '../../node_modules/capacitor-braze-plugin'
     pod 'BrazeKit'
   end
   ```

2. `AppDelegate.swift` — import this plugin's CocoaPods module, **`CapacitorBrazePlugin`** (not `BrazePlugin` — that name only resolves under SPM):

```swift
import UIKit
import Capacitor
import BrazeKit
import CapacitorBrazePlugin

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let configuration = Braze.Configuration(
            apiKey: "YOUR-IOS-API-KEY",
            endpoint: "YOUR-BRAZE-ENDPOINT"
        )
        BrazeBridge.sharedInstance = Braze(configuration: configuration)
        return true
    }
}
```

Both snippets configure the exact same `BrazeBridge.sharedInstance` — only the `import` line differs. See the [Braze Swift SDK setup guide](https://www.braze.com/docs/developer_guide/sdk_integration?sdktab=swift) for the full list of optional `Braze.Configuration` options.

No additional runtime permissions are required by this plugin beyond what the native Braze SDKs declare in their own manifests/frameworks.

## Not covered by this plugin

This plugin covers a focused core surface only. The following are **explicitly out of scope** and are not implemented, not stubbed, and not planned for a future version of this core API — integrate the native Braze SDK directly in your app for these:

* **Push notifications** (device token registration, notification payload handling)
* **Manual session control** (`openSession()` / `closeSession()`)
* **In-app messages**
* **Content Cards**

Two of these are a single line of native code to enable — for the rest, see the [Braze developer docs](https://www.braze.com/docs/developer_guide/home).

**Session tracking (Android)** — in your app's `Application.onCreate()`:

```kotlin
registerActivityLifecycleCallbacks(BrazeActivityLifecycleCallbackListener())
```

This also automatically handles open/close session and in-app message event subscription — no separate step needed for Android in-app messages.

**In-app messages (iOS)** — in `AppDelegate`, right after setting `BrazeBridge.sharedInstance`:

```swift
BrazeBridge.sharedInstance?.inAppMessagePresenter = BrazeInAppMessageUI()
```

Requires adding the `BrazeUI` package/pod (alongside `BrazeKit`) and `import BrazeUI`. See the [Braze in-app messages guide](https://www.braze.com/docs/developer_guide/platform_integration_guides/swift/in-app_messaging/integration).

## Updating the native Braze SDK version

* **Android**: the Braze SDK version is declared in [`android/build.gradle`](./android/build.gradle) as the `brazeAndroidSdkVersion` property (`implementation "com.braze:android-sdk-ui:$brazeAndroidSdkVersion"`). Bump that value, or override `brazeAndroidSdkVersion` from your app's root `build.gradle`. See the [Braze Android SDK releases](https://github.com/braze-inc/braze-android-sdk/releases) for changelogs.
* **iOS**: the Braze SDK version is declared in [`Package.swift`](./Package.swift) (for SPM-based Capacitor apps) and in [`CapacitorBrazePlugin.podspec`](./CapacitorBrazePlugin.podspec) (for CocoaPods-based apps), as the `braze-swift-sdk` / `BrazeKit` dependency version. Bump both to keep them in sync. See the [Braze Swift SDK releases](https://github.com/braze-inc/braze-swift-sdk/releases) for changelogs.

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](./CONTRIBUTING.md) for how to set up the project locally and submit changes.

## License

[MIT](./LICENSE) © Minders
