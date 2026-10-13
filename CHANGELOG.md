# Changelog — hasham_mobile_sdk (Flutter)

All notable changes to the `hasham_mobile_sdk` Flutter plugin are documented here.
Follows [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

---

## [0.2.1-snapshot] - 2026-10-13

### Added
- `HashamMobileSDK.extractChallenge(enrollmentToken)` — pure-Dart JWT parser that extracts the
  `challenge` claim from an enrollment token. Pass the result as the Play Integrity nonce on Android.
- `HashamMobileSDK.createPinBlock(pan, pin)` — low-level ISO-0 PIN block encryption without the
  SDK overlay. Use only when managing PIN collection through a custom accessibility flow.
- `HashamMobileSDK.wrapPan(pan)` — wraps a PAN with the tenant RSA enc_public_key stored at
  enrollment (RSA-OAEP-SHA256). Use alongside `createPinBlock` for custom PIN-change flows.
- `HashamMobileSDK.clearEnrollment()` — removes all enrollment data (working key + related keys)
  from the device. After calling, `isEnrolled()` returns false.
- `HashamMobileSDK.sign({signedAt})` — produces a dual-signature `SignResult` for the IAM
  device-token exchange (`POST /mobile/devices/:deviceId/token`).
- `SignResult` class — `deviceSignature`, `sdkSignature`, `signedAt`; now exported from the package.

### iOS native SDK
- Added `HashamMobile.clearEnrollment()` public method (no-op if not yet enrolled).

---

## [0.2.0] - 2026-09-11

### Added
- `HashamMobile.sign()` — produces a dual-signature result:
  - `deviceSignature` (Base64 `String`): RSA-SHA256 over `device:{deviceId}:op:{signedAt}`.
  - `sdkSignature` (`String`): compact JWS ES256 signed by the SDK EC P-256 key.
- `SignResult` class with fields `deviceSignature`, `sdkSignature`, `signedAt`.

### Changed
- PIN change flow requires calling `HashamMobile.sign()` **after** `changePIN()` and
  forwarding all three `SignResult` fields to the backend gateway for IAM attestation.

---

## [0.1.0] - 2026-08-01

### Added
- Initial release: `HashamMobile` with `getDeviceId()`, `isEnrolled()`, `enroll()`,
  `capturePIN()`, `changePIN()`.
- `ChangePinParams` and `ChangePinResult` model classes.
- Android plugin (`HashamMobileSdkPlugin.kt`) targeting `hasham-mobile-sdk` ≥ 0.1.0.
- iOS plugin (`HashamMobileSdkPlugin.swift`) targeting `HashamMobileSDK` ≥ 0.1.0.
