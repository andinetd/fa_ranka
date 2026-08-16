import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

final textScaleProvider = NotifierProvider<TextScaleNotifier, double>(
  TextScaleNotifier.new,
);

class TextScaleNotifier extends Notifier<double> {
  @override
  double build() {
    final notifier = AppSettingsService.textScaleNotifier;
    notifier.addListener(_sync);
    ref.onDispose(() => notifier.removeListener(_sync));
    return notifier.value;
  }

  void _sync() {
    state = AppSettingsService.textScaleNotifier.value;
  }

  Future<void> setTextScale(double value) async {
    await AppSettingsService.setTextScale(value);
  }
}

final spacingScaleProvider = NotifierProvider<SpacingScaleNotifier, double>(
  SpacingScaleNotifier.new,
);

class SpacingScaleNotifier extends Notifier<double> {
  @override
  double build() {
    final notifier = AppSettingsService.spacingScaleNotifier;
    notifier.addListener(_sync);
    ref.onDispose(() => notifier.removeListener(_sync));
    return notifier.value;
  }

  void _sync() {
    state = AppSettingsService.spacingScaleNotifier.value;
  }

  Future<void> setSpacingScale(double value) async {
    await AppSettingsService.setSpacingScale(value);
  }
}

final dimensionsProvider = Provider<AppDimensions>((ref) {
  final scale = ref.watch(spacingScaleProvider);
  return AppDimensions(scale);
});

final compactNumbersProvider = NotifierProvider<CompactNumbersNotifier, bool>(
  CompactNumbersNotifier.new,
);

class CompactNumbersNotifier extends Notifier<bool> {
  @override
  bool build() {
    final notifier = AppSettingsService.compactNumbersNotifier;
    notifier.addListener(_sync);
    ref.onDispose(() => notifier.removeListener(_sync));
    return notifier.value;
  }

  void _sync() {
    state = AppSettingsService.compactNumbersNotifier.value;
  }
}
