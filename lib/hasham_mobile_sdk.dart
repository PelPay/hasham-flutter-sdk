export 'src/hasham_platform_interface.dart'
    show HashamConfig, ChangePINParams, ChangePINResult, SignResult;

import 'dart:convert';
import 'src/hasham_platform_interface.dart';

/// Chamsswitch Hasham Mobile SDK for Flutter.
///
/// Provides hardware-backed device attestation (Play Integrity / App Attest)
/// and PCI DSS-compliant PIN capture with an SDK-rendered secure overlay.
/// Private keys and working keys never leave the device's secure hardware.
class HashamMobileSDK {
  /// Override the default IAM discovery endpoint. Call once at app startup.
  /// Omit in production — the default (api.chamsswitch.com) is used automatically.
  static Future<void> configure(HashamConfig config) =>
      HashamMobilePlatform.instance.configure(config);

  /// Returns the stable hardware-backed device identifier.
  /// Pass this to your backend when requesting an enrollment token.
  static Future<String> getDeviceId() =>
      HashamMobilePlatform.instance.getDeviceId();

  /// Returns true if this device has completed enrollment and has a stored working key.
  /// Call on app launch — if false, run [enroll] before any PIN operation.
  static Future<bool> isEnrolled() =>
      HashamMobilePlatform.instance.isEnrolled();

  /// Register this device with the IAM platform.
  ///
  /// - [enrollmentToken] ES256 JWT from your backend's enrollment token endpoint.
  /// - [platformToken]   Play Integrity token (Android) or App Attest object (iOS).
  ///
  /// Returns the device identifier — store it and include as X-Device-ID on card API calls.
  static Future<String> enroll(String enrollmentToken, String platformToken) =>
      HashamMobilePlatform.instance.enroll(enrollmentToken, platformToken);

  /// Present a themed PIN entry overlay and return an encrypted ISO-0 PIN block.
  /// The raw PIN digits never leave the SDK.
  ///
  /// - [pan] Clear PAN digits (12–19 chars). Fetch from your backend immediately before calling.
  ///
  /// Returns a 16-char hex ISO-0 PIN block encrypted with the device working key.
  /// Throws a [PlatformException] with code "CANCELLED" if the user dismisses the overlay.
  static Future<String> capturePIN(String pan) =>
      HashamMobilePlatform.instance.capturePIN(pan);

  /// Multi-step PIN change overlay — optional PAN collection, then old PIN → new PIN → confirm.
  ///
  /// Throws a [PlatformException] with code "CANCELLED" if the user dismisses any step.
  /// Throws a [PlatformException] with code "INVALID_PARAMS" if required fields are missing.
  static Future<ChangePINResult> changePIN(ChangePINParams params) =>
      HashamMobilePlatform.instance.changePIN(params);

  /// Extract the `challenge` claim from an enrollment JWT.
  ///
  /// On Android, pass the returned value as the Play Integrity nonce before calling [enroll].
  /// Throws [ArgumentError] if the token is malformed or missing the `challenge` claim.
  static String extractChallenge(String enrollmentToken) {
    final parts = enrollmentToken.split('.');
    if (parts.length != 3) {
      throw ArgumentError('Invalid JWT — expected 3 segments');
    }
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    final padding = (4 - payload.length % 4) % 4;
    payload += '=' * padding;
    final decoded = utf8.decode(base64.decode(payload));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    final challenge = json['challenge'];
    if (challenge == null) {
      throw ArgumentError("JWT payload missing 'challenge' claim");
    }
    return challenge as String;
  }

  /// Encrypt a PIN block without the SDK overlay.
  ///
  /// Prefer [capturePIN] — it keeps raw PIN digits inside the SDK.
  /// Use this only when you manage PIN collection through a custom accessibility flow.
  /// [pin] must contain only ASCII digit characters (e.g. "1234").
  static Future<String> createPinBlock(String pan, String pin) =>
      HashamMobilePlatform.instance.createPinBlock(pan, pin);

  /// Wrap a PAN with the tenant RSA public key stored at enrollment (RSA-OAEP-SHA256).
  ///
  /// Use alongside [createPinBlock] for custom PIN-change flows.
  /// Throws a [PlatformException] with code "SDK_ERROR" if no enc_public_key was stored
  /// at enrollment (tenant must configure an enc key in IAM).
  static Future<String> wrapPan(String pan) =>
      HashamMobilePlatform.instance.wrapPan(pan);

  /// Remove all enrollment data for this device (working key + related keys).
  ///
  /// After this call [isEnrolled] returns false and [enroll] must be called again.
  static Future<void> clearEnrollment() =>
      HashamMobilePlatform.instance.clearEnrollment();

  /// Produce a short-lived dual-signature for the IAM device-token exchange.
  ///
  /// - [signedAt] Unix timestamp in seconds. Defaults to the current time.
  ///
  /// Returns a [SignResult] with `deviceSignature`, `sdkSignature`, and `signedAt`.
  /// Forward all three to your backend for `POST /mobile/devices/:deviceId/token`.
  static Future<SignResult> sign({int? signedAt}) =>
      HashamMobilePlatform.instance.sign(
        signedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
}
