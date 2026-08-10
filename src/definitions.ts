/**
 * Options for {@link BrazePlugin.changeUser}.
 */
export interface ChangeUserOptions {
  /**
   * The external (app-assigned) user ID to associate with the current
   * device, e.g. your backend's user ID once the user has logged in.
   */
  externalId: string;
}

/**
 * Options for {@link BrazePlugin.logCustomEvent}.
 */
export interface LogCustomEventOptions {
  /**
   * The name of the custom event, as it will appear in the Braze dashboard.
   */
  eventName: string;

  /**
   * Optional key/value properties attached to the event. Values must be
   * JSON-serializable (string, number, boolean, or null); nested objects
   * and arrays are not supported by the native Braze SDKs.
   */
  properties?: Record<string, unknown>;
}

/**
 * Options for {@link BrazePlugin.logPurchase}.
 */
export interface LogPurchaseOptions {
  /**
   * The identifier for the purchased product (e.g. a SKU).
   */
  productId: string;

  /**
   * The ISO 4217 currency code for the purchase (e.g. `"USD"`).
   */
  currency: string;

  /**
   * The price of a single unit of the product, in the given currency.
   */
  price: number;

  /**
   * The number of units purchased.
   */
  quantity: number;

  /**
   * Optional key/value properties attached to the purchase event. Values
   * must be JSON-serializable (string, number, boolean, or null); nested
   * objects and arrays are not supported by the native Braze SDKs.
   */
  properties?: Record<string, unknown>;
}

/**
 * A single product line item, used by the eCommerce events that carry a
 * product list ({@link BrazePlugin.logCartUpdated},
 * {@link BrazePlugin.logCheckoutStarted}, {@link BrazePlugin.logOrderPlaced},
 * {@link BrazePlugin.logOrderCancelled}, {@link BrazePlugin.logOrderRefunded}).
 */
export interface EcommerceProduct {
  /**
   * The identifier for the product (e.g. a SKU).
   */
  productId: string;

  /**
   * The display name of the product.
   */
  productName: string;

  /**
   * The identifier for the specific variant of the product (e.g. size/color).
   */
  variantId: string;

  /**
   * A URL for an image of the product.
   */
  imageUrl?: string;

  /**
   * A URL to the product's page.
   */
  productUrl?: string;

  /**
   * The number of units of this product in the line item. Must be a
   * non-negative integer.
   */
  quantity: number;

  /**
   * The price of a single unit of the product.
   */
  price: number;

  /**
   * Optional key/value properties attached to this line item.
   */
  metadata?: Record<string, string | number | boolean>;
}

/**
 * The action that changed a shopping cart, for {@link BrazePlugin.logCartUpdated}.
 */
export type CartUpdatedAction = 'add' | 'remove' | 'replace';

/**
 * A single order-level discount entry, used by
 * {@link BrazePlugin.logOrderPlaced}, {@link BrazePlugin.logOrderCancelled},
 * and {@link BrazePlugin.logOrderRefunded}.
 */
export interface OrderDiscount {
  /**
   * The discount code applied to the order.
   */
  code: string;

  /**
   * The monetary amount discounted.
   */
  amount: number;

  /**
   * The type of discount (e.g. `"percentage"`, `"fixed"`).
   */
  type?: string;
}

/**
 * Options for {@link BrazePlugin.logProductViewed}.
 */
export interface ProductViewedOptions {
  /**
   * The identifier for the viewed product (e.g. a SKU).
   */
  productId: string;

  /**
   * The display name of the viewed product.
   */
  productName: string;

  /**
   * The identifier for the specific variant of the product being viewed.
   */
  variantId: string;

  /**
   * A URL for an image of the product.
   */
  imageUrl?: string;

  /**
   * A URL to the product's page.
   */
  productUrl?: string;

  /**
   * The price of the product, in the given currency.
   */
  price: number;

  /**
   * The ISO 4217 currency code for the price (e.g. `"USD"`).
   */
  currency: string;

  /**
   * A label identifying where this view occurred in your app (e.g. a screen
   * or feature name).
   */
  source: string;

  /**
   * Optional tags describing why this product is being surfaced.
   */
  type?: ('price_drop' | 'back_in_stock')[];

  /**
   * Optional key/value properties attached to the event.
   */
  metadata?: Record<string, string | number | boolean>;
}

/**
 * Options for {@link BrazePlugin.logCartUpdated}.
 */
export interface CartUpdatedOptions {
  /**
   * The identifier for the shopping cart.
   */
  cartId: string;

  /**
   * How the cart changed. Defaults to `"replace"`.
   */
  action?: CartUpdatedAction;

  /**
   * The cart's total value after this update. Required when `action` is
   * omitted or `"replace"`; optional when `action` is `"add"` or `"remove"`.
   */
  totalValue?: number;

  /**
   * The cart's subtotal value (before tax/shipping), if available.
   */
  subtotalValue?: number;

  /**
   * The tax amount applied to the cart, if available.
   */
  tax?: number;

  /**
   * The shipping cost applied to the cart, if available.
   */
  shipping?: number;

  /**
   * The ISO 4217 currency code for the monetary values (e.g. `"USD"`).
   */
  currency: string;

  /**
   * The product line items in the cart. Must contain at least one item.
   */
  products: EcommerceProduct[];

  /**
   * A label identifying where this update occurred in your app.
   */
  source: string;

  /**
   * Optional key/value properties attached to the event.
   */
  metadata?: Record<string, string | number | boolean>;
}

/**
 * Options for {@link BrazePlugin.logCheckoutStarted}.
 */
export interface CheckoutStartedOptions {
  /**
   * The identifier for this checkout.
   */
  checkoutId: string;

  /**
   * The identifier for the shopping cart that started checkout, if available.
   */
  cartId?: string;

  /**
   * The checkout's total value.
   */
  totalValue: number;

  /**
   * The checkout's subtotal value (before tax/shipping), if available.
   */
  subtotalValue?: number;

  /**
   * The tax amount applied to the checkout, if available.
   */
  tax?: number;

  /**
   * The shipping cost applied to the checkout, if available.
   */
  shipping?: number;

  /**
   * The ISO 4217 currency code for the monetary values (e.g. `"USD"`).
   */
  currency: string;

  /**
   * The product line items being checked out. Must contain at least one item.
   */
  products: EcommerceProduct[];

  /**
   * A label identifying where checkout started in your app.
   */
  source: string;

  /**
   * Optional key/value properties attached to the event. Braze recognizes
   * the `checkout_url` metadata key for a link back to the checkout.
   */
  metadata?: Record<string, string | number | boolean>;
}

/**
 * Options for {@link BrazePlugin.logOrderPlaced}.
 */
export interface OrderPlacedOptions {
  /**
   * The identifier for the placed order.
   */
  orderId: string;

  /**
   * The identifier for the shopping cart the order was placed from, if
   * available.
   */
  cartId?: string;

  /**
   * The order's total value.
   */
  totalValue: number;

  /**
   * The order's subtotal value (before tax/shipping), if available.
   */
  subtotalValue?: number;

  /**
   * The tax amount applied to the order, if available.
   */
  tax?: number;

  /**
   * The shipping cost applied to the order, if available.
   */
  shipping?: number;

  /**
   * The ISO 4217 currency code for the monetary values (e.g. `"USD"`).
   */
  currency: string;

  /**
   * The total monetary amount discounted on this order, if any.
   */
  totalDiscounts?: number;

  /**
   * The individual discounts applied to this order, if any.
   */
  discounts?: OrderDiscount[];

  /**
   * The product line items in the order. Must contain at least one item.
   */
  products: EcommerceProduct[];

  /**
   * A label identifying where the order was placed in your app.
   */
  source: string;

  /**
   * Optional key/value properties attached to the event. Braze recognizes
   * the `order_status_url` metadata key for a link to order status.
   */
  metadata?: Record<string, string | number | boolean>;
}

/**
 * Options for {@link BrazePlugin.logOrderCancelled}.
 */
export interface OrderCancelledOptions {
  /**
   * The identifier for the cancelled order.
   */
  orderId: string;

  /**
   * The order's total value. Must be non-negative.
   */
  totalValue: number;

  /**
   * The order's subtotal value (before tax/shipping), if available.
   */
  subtotalValue?: number;

  /**
   * The tax amount applied to the order, if available.
   */
  tax?: number;

  /**
   * The shipping cost applied to the order, if available.
   */
  shipping?: number;

  /**
   * The ISO 4217 currency code for the monetary values (e.g. `"USD"`).
   */
  currency: string;

  /**
   * The total monetary amount discounted on this order, if any.
   */
  totalDiscounts?: number;

  /**
   * The individual discounts applied to this order, if any.
   */
  discounts?: OrderDiscount[];

  /**
   * The reason the order was cancelled.
   */
  cancelReason: string;

  /**
   * The product line items in the cancelled order. Must contain at least one
   * item.
   */
  products: EcommerceProduct[];

  /**
   * A label identifying where the cancellation was initiated in your app.
   */
  source: string;

  /**
   * Optional key/value properties attached to the event. Braze recognizes
   * the `order_status_url` metadata key for a link to order status.
   */
  metadata?: Record<string, string | number | boolean>;
}

/**
 * Options for {@link BrazePlugin.logOrderRefunded}.
 */
export interface OrderRefundedOptions {
  /**
   * The identifier for the refunded order.
   */
  orderId: string;

  /**
   * The refunded amount. Must be non-negative. For partial refunds, send
   * only the amount that was refunded, not the original order total.
   */
  totalValue: number;

  /**
   * The ISO 4217 currency code for the monetary values (e.g. `"USD"`).
   */
  currency: string;

  /**
   * The total monetary amount discounted on this order, if any.
   */
  totalDiscounts?: number;

  /**
   * The individual discounts applied to this order, if any.
   */
  discounts?: OrderDiscount[];

  /**
   * The product line items in the refunded order. Must contain at least one
   * item.
   */
  products: EcommerceProduct[];

  /**
   * A label identifying where the refund was initiated in your app.
   */
  source: string;

  /**
   * Optional key/value properties attached to the event. Braze recognizes
   * the `order_status_url` metadata key for a link to order status.
   */
  metadata?: Record<string, string | number | boolean>;
}

/**
 * Options for {@link BrazePlugin.setCustomUserAttribute}.
 */
export interface SetCustomUserAttributeOptions {
  /**
   * The name of the custom attribute, as it will appear in the Braze
   * dashboard.
   */
  key: string;

  /**
   * The value to set for the attribute. Arrays and objects are not
   * supported by this method; use the native SDK directly for array-typed
   * custom attributes.
   */
  value: string | number | boolean;
}

/**
 * Capacitor plugin that wraps the core analytics and user identity APIs of
 * the native Braze SDKs (Android and iOS).
 *
 * This plugin does not configure the Braze SDK and does not accept API
 * keys or endpoints — the host app must configure the native Braze SDK
 * declaratively (Android string resources / iOS `AppDelegate` code)
 * before calling any method here. See the README's "Native configuration"
 * section for the exact steps. Every method below rejects with a clear
 * error if the native SDK has not been configured yet.
 *
 * This plugin intentionally covers a focused "core" surface — see the
 * "Not covered by this plugin" section of the README for functionality
 * (push notifications, manual session control, in-app messages, Content
 * Cards) that is left to direct native SDK integration.
 */
export interface BrazePlugin {
  /**
   * Identifies the current user to Braze with an external (app-assigned)
   * user ID, e.g. after login. Calling this with a different ID than the
   * currently identified user starts a new user session and clears
   * previously set user data on the client, per standard Braze SDK
   * behavior.
   *
   * @param options The external ID to identify the user with.
   * @throws If `externalId` is empty, or if the native Braze SDK has not
   * been configured natively yet.
   *
   * @example
   * await Braze.changeUser({ externalId: 'user-1234' });
   */
  changeUser(options: ChangeUserOptions): Promise<void>;

  /**
   * Logs a custom event to Braze, optionally with additional properties.
   *
   * @param options The event name and optional properties.
   * @throws If `eventName` is empty, or if the native Braze SDK has not
   * been configured natively yet.
   *
   * @example
   * await Braze.logCustomEvent({
   *   eventName: 'viewed_product',
   *   properties: { productId: 'sku-123', category: 'shoes' },
   * });
   */
  logCustomEvent(options: LogCustomEventOptions): Promise<void>;

  /**
   * Logs a purchase event to Braze.
   *
   * @param options The purchase details.
   * @throws If `productId` or `currency` is empty, if `price` or
   * `quantity` is negative, or if the native Braze SDK has not been
   * configured natively yet.
   *
   * @example
   * await Braze.logPurchase({
   *   productId: 'sku-123',
   *   currency: 'USD',
   *   price: 19.99,
   *   quantity: 2,
   *   properties: { color: 'blue' },
   * });
   */
  logPurchase(options: LogPurchaseOptions): Promise<void>;

  /**
   * Sets a custom attribute on the current user's Braze profile.
   *
   * @param options The attribute key and value.
   * @throws If `key` is empty, if `value` is not a string, number, or
   * boolean, or if the native Braze SDK has not been configured natively
   * yet.
   *
   * @example
   * await Braze.setCustomUserAttribute({ key: 'favorite_color', value: 'blue' });
   */
  setCustomUserAttribute(options: SetCustomUserAttributeOptions): Promise<void>;

  /**
   * Logs Braze's recommended `product_viewed` eCommerce event.
   *
   * Backed by a native Braze SDK class (Android `ProductViewedEvent`, iOS
   * `Braze.Ecommerce.ProductViewedEvent`), which validates the payload
   * before the event is queued.
   *
   * @param options The product view details.
   * @throws If a required field is missing or invalid (e.g. empty
   * `productId`, negative `price`, non-ISO-4217 `currency`), or if the
   * native Braze SDK has not been configured natively yet.
   *
   * @example
   * await Braze.logProductViewed({
   *   productId: 'sku-123',
   *   productName: 'Running Shoes',
   *   variantId: 'sku-123-blue-10',
   *   price: 89.99,
   *   currency: 'USD',
   *   source: 'product_detail_screen',
   * });
   */
  logProductViewed(options: ProductViewedOptions): Promise<void>;

  /**
   * Logs Braze's recommended `cart_updated` eCommerce event.
   *
   * Backed by a native Braze SDK class (Android `CartUpdatedEvent`, iOS
   * `Braze.Ecommerce.CartUpdatedEvent`), which validates the payload before
   * the event is queued.
   *
   * @param options The cart update details.
   * @throws If a required field is missing or invalid (e.g. empty
   * `products`, missing `totalValue` when `action` is omitted or
   * `"replace"`, non-ISO-4217 `currency`), or if the native Braze SDK has
   * not been configured natively yet.
   *
   * @example
   * await Braze.logCartUpdated({
   *   cartId: 'cart-456',
   *   totalValue: 89.99,
   *   currency: 'USD',
   *   source: 'cart_screen',
   *   products: [
   *     { productId: 'sku-123', productName: 'Running Shoes', variantId: 'sku-123-blue-10', quantity: 1, price: 89.99 },
   *   ],
   * });
   */
  logCartUpdated(options: CartUpdatedOptions): Promise<void>;

  /**
   * Logs Braze's recommended `checkout_started` eCommerce event.
   *
   * Backed by a native Braze SDK class (Android `CheckoutStartedEvent`, iOS
   * `Braze.Ecommerce.CheckoutStartedEvent`), which validates the payload
   * before the event is queued.
   *
   * @param options The checkout details.
   * @throws If a required field is missing or invalid (e.g. empty
   * `products`, negative `totalValue`, non-ISO-4217 `currency`), or if the
   * native Braze SDK has not been configured natively yet.
   *
   * @example
   * await Braze.logCheckoutStarted({
   *   checkoutId: 'checkout-789',
   *   totalValue: 89.99,
   *   currency: 'USD',
   *   source: 'checkout_screen',
   *   products: [
   *     { productId: 'sku-123', productName: 'Running Shoes', variantId: 'sku-123-blue-10', quantity: 1, price: 89.99 },
   *   ],
   * });
   */
  logCheckoutStarted(options: CheckoutStartedOptions): Promise<void>;

  /**
   * Logs Braze's recommended `order_placed` eCommerce event.
   *
   * Backed by a native Braze SDK class (Android `OrderPlacedEvent`, iOS
   * `Braze.Ecommerce.OrderPlacedEvent`), which validates the payload before
   * the event is queued.
   *
   * @param options The order details.
   * @throws If a required field is missing or invalid (e.g. empty
   * `products`, negative `totalValue`, non-ISO-4217 `currency`), or if the
   * native Braze SDK has not been configured natively yet.
   *
   * @example
   * await Braze.logOrderPlaced({
   *   orderId: 'order-321',
   *   totalValue: 89.99,
   *   currency: 'USD',
   *   source: 'checkout_screen',
   *   products: [
   *     { productId: 'sku-123', productName: 'Running Shoes', variantId: 'sku-123-blue-10', quantity: 1, price: 89.99 },
   *   ],
   * });
   */
  logOrderPlaced(options: OrderPlacedOptions): Promise<void>;

  /**
   * Logs Braze's recommended `order_cancelled` eCommerce event.
   *
   * Braze does not provide a native typed class for this event on either
   * platform — this method validates the payload natively (replicating the
   * same rules the typed classes above enforce) and dispatches it via
   * `logCustomEvent` with the event name `"ecommerce.order_cancelled"`, so
   * that invalid payloads fail fast here instead of being silently ingested.
   *
   * @param options The cancellation details.
   * @throws If a required field is missing or invalid (e.g. empty
   * `products`, empty `cancelReason`, negative `totalValue`, non-ISO-4217
   * `currency`), or if the native Braze SDK has not been configured
   * natively yet.
   *
   * @example
   * await Braze.logOrderCancelled({
   *   orderId: 'order-321',
   *   totalValue: 89.99,
   *   currency: 'USD',
   *   cancelReason: 'customer_request',
   *   source: 'support_screen',
   *   products: [
   *     { productId: 'sku-123', productName: 'Running Shoes', variantId: 'sku-123-blue-10', quantity: 1, price: 89.99 },
   *   ],
   * });
   */
  logOrderCancelled(options: OrderCancelledOptions): Promise<void>;

  /**
   * Logs Braze's recommended `order_refunded` eCommerce event.
   *
   * Braze does not provide a native typed class for this event on either
   * platform — this method validates the payload natively (replicating the
   * same rules the typed classes above enforce) and dispatches it via
   * `logCustomEvent` with the event name `"ecommerce.order_refunded"`, so
   * that invalid payloads fail fast here instead of being silently ingested.
   *
   * @param options The refund details.
   * @throws If a required field is missing or invalid (e.g. empty
   * `products`, negative `totalValue`, non-ISO-4217 `currency`), or if the
   * native Braze SDK has not been configured natively yet.
   *
   * @example
   * await Braze.logOrderRefunded({
   *   orderId: 'order-321',
   *   totalValue: 29.99,
   *   currency: 'USD',
   *   source: 'support_screen',
   *   products: [
   *     { productId: 'sku-123', productName: 'Running Shoes', variantId: 'sku-123-blue-10', quantity: 1, price: 29.99 },
   *   ],
   * });
   */
  logOrderRefunded(options: OrderRefundedOptions): Promise<void>;
}
