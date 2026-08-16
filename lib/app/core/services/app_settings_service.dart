import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String keyAutoSync = 'settings_auto_sync';
  static const String keySmsAlerts = 'settings_sms_alerts';
  static const String keyCompactNumbers = 'settings_compact_numbers';
  static const String keyAutoUpdateChecks = 'settings_auto_update_checks';
  static const String keyWeeklySummary = 'settings_weekly_summary_notification';
  static const String keyBiometricLock = 'settings_biometric_lock';
  static const String keyThemeMode = 'settings_theme_mode';
  static const String keyTextScale = 'settings_text_scale';
  static const String keySpacingScale = 'settings_spacing_scale';
  static const String keyLastSyncTimestamp = 'last_sync_timestamp';
  static const String keyTransactionNotifications =
      'settings_transaction_notifications';
  static const String keyBudgetAlerts = 'settings_budget_alerts';
  static const String keySummaryDaily = 'settings_summary_daily';
  static const String keySummaryDailyHour = 'settings_summary_daily_hour';
  static const String keySummaryDailyMinute = 'settings_summary_daily_minute';
  static const String keySummaryWeekly = 'settings_summary_weekly';
  static const String keySummaryWeeklyHour = 'settings_summary_weekly_hour';
  static const String keySummaryWeeklyMinute = 'settings_summary_weekly_minute';
  static const String keySummaryMonthly = 'settings_summary_monthly';
  static const String keySummaryMonthlyHour = 'settings_summary_monthly_hour';
  static const String keySummaryMonthlyMinute = 'settings_summary_monthly_minute';
  static const String keySkippedUpdateVersion = 'skipped_update_version';
  // Kept for backward compatibility with older persisted settings.
  static const String keyDarkMode = 'settings_dark_mode';

  static final ValueNotifier<bool> autoSyncNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> smsAlertsNotifier = ValueNotifier<bool>(
    true,
  );
  static final ValueNotifier<bool> compactNumbersNotifier = ValueNotifier<bool>(
    false,
  );
  static final ValueNotifier<bool> autoUpdateChecksNotifier =
      ValueNotifier<bool>(true);
  static final ValueNotifier<bool> weeklySummaryNotifier =
      ValueNotifier<bool>(false);
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);
  static final ValueNotifier<double> textScaleNotifier =
      ValueNotifier<double>(1.0);
  static final ValueNotifier<double> spacingScaleNotifier =
      ValueNotifier<double>(1.0);
  static final ValueNotifier<int?> lastSyncNotifier =
      ValueNotifier<int?>(null);
  static final ValueNotifier<bool> summaryDailyNotifier =
      ValueNotifier<bool>(true);
  static final ValueNotifier<int> summaryDailyHourNotifier =
      ValueNotifier<int>(20);
  static final ValueNotifier<int> summaryDailyMinuteNotifier =
      ValueNotifier<int>(0);
  static final ValueNotifier<bool> summaryWeeklyNotifier =
      ValueNotifier<bool>(true);
  static final ValueNotifier<int> summaryWeeklyHourNotifier =
      ValueNotifier<int>(8);
  static final ValueNotifier<int> summaryWeeklyMinuteNotifier =
      ValueNotifier<int>(0);
  static final ValueNotifier<bool> summaryMonthlyNotifier =
      ValueNotifier<bool>(false);
  static final ValueNotifier<int> summaryMonthlyHourNotifier =
      ValueNotifier<int>(9);
  static final ValueNotifier<int> summaryMonthlyMinuteNotifier =
      ValueNotifier<int>(0);
  static final ValueNotifier<bool> transactionNotificationsNotifier =
      ValueNotifier<bool>(true);
  static final ValueNotifier<bool> budgetAlertsNotifier =
      ValueNotifier<bool>(true);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    autoSyncNotifier.value = prefs.getBool(keyAutoSync) ?? true;
    smsAlertsNotifier.value = prefs.getBool(keySmsAlerts) ?? true;
    compactNumbersNotifier.value = prefs.getBool(keyCompactNumbers) ?? false;
    autoUpdateChecksNotifier.value = prefs.getBool(keyAutoUpdateChecks) ?? true;
    weeklySummaryNotifier.value = prefs.getBool(keyWeeklySummary) ?? true;

    final storedThemeMode = prefs.getString(keyThemeMode);
    if (storedThemeMode != null) {
      themeModeNotifier.value = _themeModeFromString(storedThemeMode);
      return;
    }

    final legacyDarkMode = prefs.getBool(keyDarkMode);
    if (legacyDarkMode != null) {
      themeModeNotifier.value = legacyDarkMode
          ? ThemeMode.dark
          : ThemeMode.light;
      return;
    }

    themeModeNotifier.value = ThemeMode.light;

    textScaleNotifier.value = prefs.getDouble(keyTextScale) ?? 1.0;
    spacingScaleNotifier.value = prefs.getDouble(keySpacingScale) ?? 1.0;
    lastSyncNotifier.value = prefs.getInt(keyLastSyncTimestamp);
    summaryDailyNotifier.value =
        prefs.getBool(keySummaryDaily) ?? true;
    summaryDailyHourNotifier.value =
        prefs.getInt(keySummaryDailyHour) ?? 20;
    summaryDailyMinuteNotifier.value =
        prefs.getInt(keySummaryDailyMinute) ?? 0;
    summaryWeeklyNotifier.value =
        prefs.getBool(keySummaryWeekly) ?? false;
    summaryWeeklyHourNotifier.value =
        prefs.getInt(keySummaryWeeklyHour) ?? 8;
    summaryWeeklyMinuteNotifier.value =
        prefs.getInt(keySummaryWeeklyMinute) ?? 0;
    summaryMonthlyNotifier.value =
        prefs.getBool(keySummaryMonthly) ?? false;
    summaryMonthlyHourNotifier.value =
        prefs.getInt(keySummaryMonthlyHour) ?? 9;
    summaryMonthlyMinuteNotifier.value =
        prefs.getInt(keySummaryMonthlyMinute) ?? 0;
    transactionNotificationsNotifier.value =
        prefs.getBool(keyTransactionNotifications) ?? true;
    budgetAlertsNotifier.value = prefs.getBool(keyBudgetAlerts) ?? true;
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    _setNotifierValue(key, value);
  }

  static Future<bool> getBool(String key, {required bool fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == keyDarkMode) {
      final storedThemeMode = prefs.getString(keyThemeMode);
      if (storedThemeMode != null) {
        return _themeModeFromString(storedThemeMode) == ThemeMode.dark;
      }
    }
    return prefs.getBool(key) ?? fallback;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyThemeMode, _themeModeToString(mode));
    themeModeNotifier.value = mode;
  }

  static ThemeMode getThemeModeSync() {
    return themeModeNotifier.value;
  }

  static Future<void> setTextScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyTextScale, value);
    textScaleNotifier.value = value;
  }

  static double getTextScaleSync() => textScaleNotifier.value;

  static Future<void> setSpacingScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keySpacingScale, value);
    spacingScaleNotifier.value = value;
  }

  static double getSpacingScaleSync() => spacingScaleNotifier.value;

  static Future<void> setLastSyncTimestamp() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyLastSyncTimestamp, now);
    lastSyncNotifier.value = now;
  }

  static Future<void> setSummaryDailyEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySummaryDaily, value);
    summaryDailyNotifier.value = value;
  }

  static Future<void> setSummaryDailyTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keySummaryDailyHour, hour);
    await prefs.setInt(keySummaryDailyMinute, minute);
    summaryDailyHourNotifier.value = hour;
    summaryDailyMinuteNotifier.value = minute;
  }

  static Future<void> setSummaryWeeklyEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySummaryWeekly, value);
    summaryWeeklyNotifier.value = value;
  }

  static Future<void> setSummaryWeeklyTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keySummaryWeeklyHour, hour);
    await prefs.setInt(keySummaryWeeklyMinute, minute);
    summaryWeeklyHourNotifier.value = hour;
    summaryWeeklyMinuteNotifier.value = minute;
  }

  static Future<void> setSummaryMonthlyEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySummaryMonthly, value);
    summaryMonthlyNotifier.value = value;
  }

  static Future<void> setSummaryMonthlyTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keySummaryMonthlyHour, hour);
    await prefs.setInt(keySummaryMonthlyMinute, minute);
    summaryMonthlyHourNotifier.value = hour;
    summaryMonthlyMinuteNotifier.value = minute;
  }

  static bool getBoolSync(String key, {required bool fallback}) {
    switch (key) {
      case keyAutoSync:
        return autoSyncNotifier.value;
      case keySmsAlerts:
        return smsAlertsNotifier.value;
      case keyCompactNumbers:
        return compactNumbersNotifier.value;
      case keyAutoUpdateChecks:
        return autoUpdateChecksNotifier.value;
      case keyWeeklySummary:
        return weeklySummaryNotifier.value;
      case keyTransactionNotifications:
        return transactionNotificationsNotifier.value;
      case keyBudgetAlerts:
        return budgetAlertsNotifier.value;
      case keyDarkMode:
        return themeModeNotifier.value == ThemeMode.dark;
      default:
        return fallback;
    }
  }

  static void _setNotifierValue(String key, bool value) {
    switch (key) {
      case keyAutoSync:
        autoSyncNotifier.value = value;
        break;
      case keySmsAlerts:
        smsAlertsNotifier.value = value;
        break;
      case keyCompactNumbers:
        compactNumbersNotifier.value = value;
        break;
      case keyAutoUpdateChecks:
        autoUpdateChecksNotifier.value = value;
        break;
      case keyWeeklySummary:
        weeklySummaryNotifier.value = value;
        break;
      case keyTransactionNotifications:
        transactionNotificationsNotifier.value = value;
        break;
      case keyBudgetAlerts:
        budgetAlertsNotifier.value = value;
        break;
      case keyDarkMode:
        themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
        break;
    }
  }

  static ThemeMode _themeModeFromString(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  static Future<int?> getSkippedUpdateVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(keySkippedUpdateVersion);
    return v != null && v > 0 ? v : null;
  }

  static Future<void> setSkippedUpdateVersion(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keySkippedUpdateVersion, versionCode);
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'light';
    }
  }
}
