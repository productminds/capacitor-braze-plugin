# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-08-11

### Fixed

- Installing the plugin directly from git (e.g. `npm install github:productminds/capacitor-braze-plugin`) no longer produces a package missing `dist/`. A `prepare` script now runs the build automatically after a git-based install, matching the compiled output that `npm publish` already includes for registry installs.

## [0.2.0] - 2026-08-10

### Added

- `logProductViewed`, `logCartUpdated`, `logCheckoutStarted`, `logOrderPlaced`, `logOrderCancelled`, and `logOrderRefunded` methods, covering Braze's 6 recommended eCommerce events with a uniform typed API. The first 4 are backed by native Braze SDK classes; `logOrderCancelled`/`logOrderRefunded` have no native typed class on either platform, so they're validated natively and dispatched via `logCustomEvent`.
- `EcommerceProduct`, `OrderDiscount`, and `CartUpdatedAction` shared types, along with per-method options interfaces (`ProductViewedOptions`, `CartUpdatedOptions`, `CheckoutStartedOptions`, `OrderPlacedOptions`, `OrderCancelledOptions`, `OrderRefundedOptions`).
