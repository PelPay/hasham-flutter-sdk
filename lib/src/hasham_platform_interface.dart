import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'hasham_method_channel.dart';

class HashamConfig {
  final String? discoveryUrl;
  final int? timeoutMs;
  final double? timeoutSeconds;

  const HashamConfig({this.discoveryUrl, this.timeoutMs, this.timeoutSeconds});

  Map<String, dynamic> toMap() => {
        if (discoveryUrl != null) 'discoveryUrl': discoveryUrl,
        if (timeoutMs != null) 'timeoutMs': timeoutMs,
        if (timeoutSeconds != null) 'timeoutSeconds': timeoutSeconds,
      };
}

class ChangePINParams {
  final String cardType;
  final String? maskedPan;
  final String? pan;

  const ChangePINParams({required this.cardType, this.maskedPan, this.pan});

  Map<String, dynamic> toMap() => {
        'cardType': cardType,
        if (maskedPan != null) 'maskedPan': maskedPan,
        if (pan != null) 'pan': pan,
      };
}

class ChangePINResult {
  final String oldPinBlock;
  final String newPinBlock;
  final String wrappedPan;

  const ChangePINResult({
    required this.oldPinBlock,
    required this.newPinBlock,
    required this.wrappedPan,
  });
}

class SignResult {
  final String deviceSignature;
  final String sdkSignature;
  final int signedAt;

  const SignResult({
    required this.deviceSignature,
    required this.sdkSignature,
    required this.signedAt,
  });
}

abstract class HashamMobilePlatform extends PlatformInterface {
  HashamMobilePlatform() : super(token: _token);

  static final Object _token = Object();

  static HashamMobilePlatform _instance = HashamMethodChannel();

  static HashamMobilePlatform get instance => _instance;

  static set instance(HashamMobilePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> configure(HashamConfig config);
  Future<String> getDeviceId();
  Future<bool> isEnrolled();
  Future<String> enroll(String enrollmentToken, String platformToken);
  Future<String> capturePIN(String pan);
  Future<ChangePINResult> changePIN(ChangePINParams params);
  Future<String> createPinBlock(String pan, String pin);
  Future<String> wrapPan(String pan);
  Future<void> clearEnrollment();
  Future<SignResult> sign(int signedAt);
}
