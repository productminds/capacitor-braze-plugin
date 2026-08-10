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
}
