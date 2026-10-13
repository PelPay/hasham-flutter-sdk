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

class PinThemeColors {
  final String? primary;
  final String? background;
  final String? keyBackground;
  final String? keyText;
  final String? dotFilled;
  final String? dotEmpty;
  final String? titleColor;
  final String? subtitleColor;

  const PinThemeColors({
    this.primary,
    this.background,
    this.keyBackground,
    this.keyText,
    this.dotFilled,
    this.dotEmpty,
    this.titleColor,
    this.subtitleColor,
  });

  Map<String, dynamic> toMap() => {
        if (primary != null) 'primary': primary,
        if (background != null) 'background': background,
        if (keyBackground != null) 'keyBackground': keyBackground,
        if (keyText != null) 'keyText': keyText,
        if (dotFilled != null) 'dotFilled': dotFilled,
        if (dotEmpty != null) 'dotEmpty': dotEmpty,
        if (titleColor != null) 'titleColor': titleColor,
        if (subtitleColor != null) 'subtitleColor': subtitleColor,
      };
}

class PinThemeTypography {
  final double? titleSize;
  final double? subtitleSize;
  final double? keySize;
  final String? fontFamily;

  const PinThemeTypography({
    this.titleSize,
    this.subtitleSize,
    this.keySize,
    this.fontFamily,
  });

  Map<String, dynamic> toMap() => {
        if (titleSize != null) 'titleSize': titleSize,
        if (subtitleSize != null) 'subtitleSize': subtitleSize,
        if (keySize != null) 'keySize': keySize,
        if (fontFamily != null) 'fontFamily': fontFamily,
      };
}

enum PinKeyShape { circle, rounded, square }

class PinThemeShape {
  final PinKeyShape keyShape;
  final double cornerRadius;

  const PinThemeShape({
    this.keyShape = PinKeyShape.circle,
    this.cornerRadius = 8.0,
  });

  Map<String, dynamic> toMap() => {
        'keyShape': keyShape.name,
        'cornerRadius': cornerRadius,
      };
}

class PinThemeStrings {
  final String? title;
  final String? subtitle;

  const PinThemeStrings({this.title, this.subtitle});

  Map<String, dynamic> toMap() => {
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
      };
}

class PinTheme {
  final PinThemeColors colors;
  final PinThemeTypography typography;
  final PinThemeShape shape;
  final PinThemeStrings strings;

  /// Number of PIN digits. Android only — iOS always uses 4.
  final int pinLength;

  const PinTheme({
    this.colors = const PinThemeColors(),
    this.typography = const PinThemeTypography(),
    this.shape = const PinThemeShape(),
    this.strings = const PinThemeStrings(),
    this.pinLength = 4,
  });

  Map<String, dynamic> toMap() => {
        'colors': colors.toMap(),
        'typography': typography.toMap(),
        'shape': shape.toMap(),
        'strings': strings.toMap(),
        'pinLength': pinLength,
      };
}

class ChangePINParams {
  final String cardType;
  final String? maskedPan;
  final String? pan;
  final PinTheme? theme;

  const ChangePINParams({required this.cardType, this.maskedPan, this.pan, this.theme});

  Map<String, dynamic> toMap() => {
        'cardType': cardType,
        if (maskedPan != null) 'maskedPan': maskedPan,
        if (pan != null) 'pan': pan,
        if (theme != null) 'theme': theme!.toMap(),
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
  Future<String> capturePIN(String pan, {PinTheme? theme});
  Future<ChangePINResult> changePIN(ChangePINParams params);
  Future<String> createPinBlock(String pan, String pin);
  Future<String> wrapPan(String pan);
  Future<void> clearEnrollment();
  Future<SignResult> sign(int signedAt);
}
