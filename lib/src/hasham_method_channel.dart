import 'package:flutter/services.dart';
import 'hasham_platform_interface.dart';

class HashamMethodChannel extends HashamMobilePlatform {
  static const _channel = MethodChannel('com.chamsswitch.hasham/mobile');

  @override
  Future<void> configure(HashamConfig config) async {
    await _channel.invokeMethod<void>('configure', config.toMap());
  }

  @override
  Future<String> getDeviceId() async {
    final id = await _channel.invokeMethod<String>('getDeviceId');
    return id!;
  }

  @override
  Future<bool> isEnrolled() async {
    final result = await _channel.invokeMethod<bool>('isEnrolled');
    return result!;
  }

  @override
  Future<String> enroll(String enrollmentToken, String platformToken) async {
    final deviceId = await _channel.invokeMethod<String>('enroll', {
      'enrollmentToken': enrollmentToken,
      'platformToken': platformToken,
    });
    return deviceId!;
  }

  @override
  Future<String> capturePIN(String pan) async {
    final block = await _channel.invokeMethod<String>('capturePIN', {'pan': pan});
    return block!;
  }

  @override
  Future<ChangePINResult> changePIN(ChangePINParams params) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'changePIN',
      params.toMap(),
    );
    return ChangePINResult(
      oldPinBlock: result!['oldPinBlock'] as String,
      newPinBlock: result['newPinBlock'] as String,
      wrappedPan: result['wrappedPan'] as String,
    );
  }

  @override
  Future<String> createPinBlock(String pan, String pin) async {
    final block = await _channel.invokeMethod<String>(
      'createPinBlock',
      {'pan': pan, 'pin': pin},
    );
    return block!;
  }

  @override
  Future<String> wrapPan(String pan) async {
    final result = await _channel.invokeMethod<String>('wrapPan', {'pan': pan});
    return result!;
  }

  @override
  Future<void> clearEnrollment() async {
    await _channel.invokeMethod<void>('clearEnrollment');
  }

  @override
  Future<SignResult> sign(int signedAt) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'sign',
      {'signedAt': signedAt},
    );
    return SignResult(
      deviceSignature: result!['deviceSignature'] as String,
      sdkSignature: result['sdkSignature'] as String,
      signedAt: result['signedAt'] as int,
    );
  }
}
