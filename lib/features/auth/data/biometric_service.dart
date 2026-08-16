import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate({required String reason}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (!await canAuthenticate()) return false;
    try {
      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
      return result;
    } catch (e) {
      debugPrint('Biometric auth failed: $e');
      return false;
    }
  }

  static Future<bool> hasBiometrics() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }
}
