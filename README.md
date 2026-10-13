# hasham_mobile_sdk

Flutter plugin for the [Chamsswitch Hasham Mobile SDK](https://chamsswitch.com) — hardware-backed device attestation and PCI DSS-compliant PIN management.

## Features

- **Device enrollment** — register a device with the IAM platform using Play Integrity (Android) or App Attest (iOS)
- **PIN capture** — SDK-rendered secure overlay; raw PIN digits never pass through the host app
- **PIN change** — multi-step overlay supporting virtual cards (PAN provided) and physical cards (masked PAN)
- **PIN block** — low-level ISO-0 PIN block encryption for custom accessibility flows
- **PAN wrapping** — RSA-OAEP-SHA256 PAN encryption using the tenant key stored at enrollment
- **Device signing** — dual-signature for the IAM device-token exchange

## Installation

**Snapshot (dev)** — references the `hasham-flutter-sdk` distribution repo directly:

```yaml
dependencies:
  hasham_mobile_sdk:
    git:
      url: https://github.com/PelPay/hasham-flutter-sdk.git
      ref: snapshot
```

**Beta / Release** — published to [pub.dev](https://pub.dev/packages/hasham_mobile_sdk):

```yaml
dependencies:
  hasham_mobile_sdk: ^<version>
```

## Usage

```dart
import 'package:hasham_mobile_sdk/hasham_mobile_sdk.dart';

// 1. Configure (omit in production — api.chamsswitch.com is used automatically)
await HashamMobileSDK.configure(HashamConfig(
  discoveryUrl: 'https://api.dev.chamsswitch.com/auth/.well-known/mobile-sdk',
));

// 2. Check enrollment on app launch
if (!await HashamMobileSDK.isEnrolled()) {
  final token = await myBackend.getEnrollmentToken();

  // Android only: extract challenge for Play Integrity nonce
  final challenge = HashamMobileSDK.extractChallenge(token);
  final integrityToken = await getPlayIntegrityToken(challenge);

  await HashamMobileSDK.enroll(token, integrityToken);
}

// 3. Capture a PIN (shows secure overlay)
final pinBlock = await HashamMobileSDK.capturePIN(pan);

// 4. Sign before a card operation
final sig = await HashamMobileSDK.sign();
await myBackend.getDeviceToken(
  deviceId: await HashamMobileSDK.getDeviceId(),
  deviceSignature: sig.deviceSignature,
  sdkSignature: sig.sdkSignature,
  signedAt: sig.signedAt,
);
```

## Requirements

- Flutter ≥ 3.10.0
- Android API 24+
- iOS 16+
