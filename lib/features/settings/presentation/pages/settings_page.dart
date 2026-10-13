import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/auth/presentation/providers/biometric_provider.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/features/settings/presentation/widgets/calendar_settings_sheet.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/features/auth/data/biometric_service.dart';
import 'package:faranka/features/settings/presentation/widgets/settings_card.dart';
import 'package:faranka/features/settings/presentation/widgets/display_settings_sheet.dart';
import 'package:faranka/features/settings/presentation/widgets/notification_settings_sheet.dart';
import 'package:faranka/features/settings/presentation/widgets/data_management_section.dart';
import 'package:faranka/features/settings/presentation/widgets/settings_version_tile.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _smsAlerts = true;
  bool _compactNumbers = true;
  bool _isDarkMode = false;
  bool _biometricLock = false;
  bool _biometricAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    if (!mounted) return;

    final sp = await SharedPreferences.getInstance();
    bool biometricAvailable = false;
    if (Platform.isAndroid || Platform.isIOS) {
      biometricAvailable = await BiometricService.canAuthenticate();
    }
    if (!mounted) return;

    setState(() {
      _smsAlerts = AppSettingsService.getBoolSync(
        AppSettingsService.keySmsAlerts,
        fallback: true,
      );
      _compactNumbers = AppSettingsService.getBoolSync(
        AppSettingsService.keyCompactNumbers,
        fallback: true,
      );
      _isDarkMode = AppSettingsService.getThemeModeSync() == ThemeMode.dark;
      _biometricLock = sp.getBool(AppSettingsService.keyBiometricLock) ?? false;
      _biometricAvailable = biometricAvailable;
      _isLoading = false;
    });
  }

  Future<void> _updateBool(String key, bool value) async {
    await AppSettingsService.setBool(key, value);
  }

  void _showDisplayDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.isDark(context)
          ? DarkAppColors.scaffoldBackground
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DisplaySettingsSheet(
        initialTextScale: AppSettingsService.getTextScaleSync(),
        initialSpacingScale: AppSettingsService.getSpacingScaleSync(),
        onChanged: () => setState(() {}),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.isDark(context)
          ? DarkAppColors.scaffoldBackground
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotificationSettingsSheet(
        onChanged: () => setState(() {}),
      ),
    );
  }

  Widget _buildNotificationSubtitle() {
    final parts = <String>[];
    if (AppSettingsService.transactionNotificationsNotifier.value) {
      parts.add('Alerts');
    }

    String fmt(int h, int m) {
      final p = h >= 12 ? 'PM' : 'AM';
      return '${h == 0 ? 12 : (h > 12 ? h - 12 : h)}:${m.toString().padLeft(2, '0')} $p';
    }

    if (AppSettingsService.summaryDailyNotifier.value) {
      parts.add(
        'Daily ${fmt(AppSettingsService.summaryDailyHourNotifier.value, AppSettingsService.summaryDailyMinuteNotifier.value)}',
      );
    }
    if (AppSettingsService.summaryWeeklyNotifier.value) {
      parts.add('Weekly');
    }
    if (AppSettingsService.summaryMonthlyNotifier.value) {
      parts.add('Monthly');
    }
    if (AppSettingsService.budgetAlertsNotifier.value) {
      parts.add('Budgets');
    }
    final text = parts.isEmpty ? 'All off' : parts.join(' \u00b7 ');
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: isDark
          ? DarkAppColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? DarkAppColors.homeCardBackground : Colors.white,
        foregroundColor: isDark
            ? DarkAppColors.appBarForeground
            : AppColors.appBarForeground,
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                SettingsCard(
                  title: 'General',
                  subtitle: 'Appearance, calendar, and formatting.',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.settings_display_outlined),
                      title: const Text('Display'),
                      subtitle: Text(
                        'Text ${(AppSettingsService.getTextScaleSync() * 100).round()}% · Spacing ${(AppSettingsService.getSpacingScaleSync() * 100).round()}%',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showDisplayDialog,
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Calendar'),
                      subtitle: Text(
                        ref.watch(calendarModeProvider) == CalendarMode.gregorian
                            ? 'Gregorian'
                            : 'Ethiopian',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: isDark
                              ? DarkAppColors.scaffoldBackground
                              : Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => const CalendarSettingsSheet(),
                        );
                      },
                    ),
                    const Divider(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _compactNumbers,
                      title: const Text('Compact numbers'),
                      subtitle:
                          const Text('Example: ETB 12.3K instead of ETB 12,300.'),
                      onChanged: (value) {
                        setState(() => _compactNumbers = value);
                        _updateBool(AppSettingsService.keyCompactNumbers, value);
                      },
                    ),
                    const Divider(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isDarkMode,
                      title: const Text('Dark mode'),
                      subtitle:
                          const Text('Switch between light and dark appearance.'),
                      onChanged: (value) {
                        setState(() => _isDarkMode = value);
                        AppSettingsService.setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsCard(
                  title: 'Notifications',
                  subtitle:
                      'Transaction alerts, summaries, and app behavior.',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: _buildNotificationSubtitle(),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showNotificationSettings,
                    ),
                    const Divider(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _smsAlerts,
                      title: const Text('Show import alerts'),
                      subtitle:
                          const Text('Display status messages for new imports.'),
                      onChanged: (value) {
                        setState(() => _smsAlerts = value);
                        _updateBool(AppSettingsService.keySmsAlerts, value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const DataManagementSection(),
                const SizedBox(height: 12),
                SettingsCard(
                  title: 'Security',
                  subtitle: 'App lock.',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _biometricLock,
                      title: const Text('Require biometric authentication'),
                      subtitle: const Text(
                        'Lock the app behind fingerprint or face unlock.',
                      ),
                      onChanged: _biometricAvailable
                          ? (value) async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await BiometricService.authenticate(
                                reason: value
                                    ? 'Confirm your identity to enable biometric lock'
                                    : 'Confirm your identity to disable biometric lock',
                              );
                              if (!ok) return;
                              setState(() => _biometricLock = value);
                              final sp =
                                  await SharedPreferences.getInstance();
                              await sp.setBool(
                                AppSettingsService.keyBiometricLock,
                                value,
                              );
                              setBiometricEnabled(value);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? 'Biometric lock enabled'
                                        : 'Biometric lock disabled',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsCard(
                  title: 'Legal & Support',
                  subtitle: 'Privacy, help, and app info.',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      subtitle: const Text('How your data is handled.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/privacy-policy'),
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & FAQ'),
                      subtitle: const Text('Common questions and answers.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/help-faq'),
                    ),
                    const Divider(height: 8),
                    const SettingsVersionTile(),
                  ],
                ),
              ],
            ),
    );
  }
}
