import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/services/app_settings_service.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final notifier = AppSettingsService.themeModeNotifier;
    notifier.addListener(_sync);
    ref.onDispose(() => notifier.removeListener(_sync));
    return notifier.value;
  }

  void _sync() {
    state = AppSettingsService.themeModeNotifier.value;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await AppSettingsService.setThemeMode(mode);
  }
}
