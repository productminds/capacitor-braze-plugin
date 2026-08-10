import { WebPlugin } from '@capacitor/core';

import type {
  BrazePlugin,
  CartUpdatedOptions,
  ChangeUserOptions,
  CheckoutStartedOptions,
  LogCustomEventOptions,
  LogPurchaseOptions,
  OrderCancelledOptions,
  OrderPlacedOptions,
  OrderRefundedOptions,
  ProductViewedOptions,
  SetCustomUserAttributeOptions,
} from './definitions';

const WEB_NOT_SUPPORTED_MESSAGE =
  'capacitor-braze-plugin has no web implementation. This method is a no-op outside of Android and iOS; ' +
  'use the Braze Web SDK directly if you need Braze analytics in a browser context.';

/**
 * Web fallback for {@link BrazePlugin}. Braze's native SDKs (Android/iOS)
 * are the only supported targets for this plugin, so every method here is
 * a no-op that logs a warning instead of throwing, so that shared JS code
 * calling these methods does not crash when running on the web.
 */
export class BrazeWeb extends WebPlugin implements BrazePlugin {
  async changeUser(_options: ChangeUserOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }

  async logCustomEvent(_options: LogCustomEventOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }

  async logPurchase(_options: LogPurchaseOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }

  async setCustomUserAttribute(_options: SetCustomUserAttributeOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }

  async logProductViewed(_options: ProductViewedOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }

  async logCartUpdated(_options: CartUpdatedOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }

  async logCheckoutStarted(_options: CheckoutStartedOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }

  async logOrderPlaced(_options: OrderPlacedOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }

  async logOrderCancelled(_options: OrderCancelledOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }

  async logOrderRefunded(_options: OrderRefundedOptions): Promise<void> {
    console.warn(WEB_NOT_SUPPORTED_MESSAGE);
  }
}
