import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _biometricPassed = false;
bool _biometricEnabled = false;

final biometricPassedProvider = Provider<bool>((ref) => _biometricPassed);
final biometricEnabledProvider = Provider<bool>((ref) => _biometricEnabled);

bool get biometricPassed => _biometricPassed;
bool get biometricEnabled => _biometricEnabled;

void setBiometricPassed(bool value) {
  _biometricPassed = value;
}

void setBiometricEnabled(bool value) {
  _biometricEnabled = value;
}
