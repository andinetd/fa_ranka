import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'calendar_mode';

enum CalendarMode { gregorian, ethiopian }

bool _cachedCalendarMode = false;

final calendarModeProvider = NotifierProvider<CalendarModeNotifier, CalendarMode>(
  CalendarModeNotifier.new,
);

class CalendarModeNotifier extends Notifier<CalendarMode> {
  @override
  CalendarMode build() =>
      _cachedCalendarMode ? CalendarMode.ethiopian : CalendarMode.gregorian;

  Future<void> setMode(CalendarMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, mode == CalendarMode.ethiopian);
  }

  Future<void> toggle() async =>
      setMode(state == CalendarMode.gregorian
          ? CalendarMode.ethiopian
          : CalendarMode.gregorian);
}

Future<void> initCalendarMode() async {
  final prefs = await SharedPreferences.getInstance();
  _cachedCalendarMode = prefs.getBool(_key) ?? false;
}
