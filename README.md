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

## API

<docgen-index>

* [`changeUser(...)`](#changeuser)
* [`logCustomEvent(...)`](#logcustomevent)
* [`logPurchase(...)`](#logpurchase)
* [`setCustomUserAttribute(...)`](#setcustomuserattribute)
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


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

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
