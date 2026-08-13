# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-08-13

First stable release. No breaking changes and no new functionality since 0.3.0 — this version is validated end-to-end against a real Braze workspace, covering all 14 methods on both Android and iOS and confirming data reaches the Braze dashboard correctly, marking the plugin's official exit from pre-release.

## [0.3.0] - 2026-08-11

### Added

- `unsetCustomUserAttribute`, `addToCustomUserAttributeArray`, `removeFromCustomUserAttributeArray`, and `setUserProfile` methods, rounding out user-attribute coverage: unsetting a custom attribute, modifying array-typed custom attributes, and setting all 9 of Braze's reserved profile fields (`email`, `firstName`, `lastName`, `country`, `language`, `homeCity`, `phoneNumber`, `gender`, `dateOfBirth`).
- `UnsetCustomUserAttributeOptions`, `ModifyCustomUserAttributeArrayOptions`, `SetUserProfileOptions`, and `UserGender` types.

## [0.2.1] - 2026-08-11

### Fixed

- Installing the plugin directly from git (e.g. `npm install github:productminds/capacitor-braze-plugin`) no longer produces a package missing `dist/`. A `prepare` script now runs the build automatically after a git-based install, matching the compiled output that `npm publish` already includes for registry installs.

## [0.2.0] - 2026-08-10

### Added

- `logProductViewed`, `logCartUpdated`, `logCheckoutStarted`, `logOrderPlaced`, `logOrderCancelled`, and `logOrderRefunded` methods, covering Braze's 6 recommended eCommerce events with a uniform typed API. The first 4 are backed by native Braze SDK classes; `logOrderCancelled`/`logOrderRefunded` have no native typed class on either platform, so they're validated natively and dispatched via `logCustomEvent`.
- `EcommerceProduct`, `OrderDiscount`, and `CartUpdatedAction` shared types, along with per-method options interfaces (`ProductViewedOptions`, `CartUpdatedOptions`, `CheckoutStartedOptions`, `OrderPlacedOptions`, `OrderCancelledOptions`, `OrderRefundedOptions`).
