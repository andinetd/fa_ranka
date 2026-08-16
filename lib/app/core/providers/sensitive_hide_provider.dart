import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'sensitive_hidden';

bool _cachedSensitiveHidden = false;

final sensitiveHideProvider = NotifierProvider<SensitiveHideNotifier, bool>(
  SensitiveHideNotifier.new,
);

class SensitiveHideNotifier extends Notifier<bool> {
  @override
  bool build() => _cachedSensitiveHidden;

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

Future<void> initSensitiveHide() async {
  final prefs = await SharedPreferences.getInstance();
  _cachedSensitiveHidden = prefs.getBool(_key) ?? false;
}
