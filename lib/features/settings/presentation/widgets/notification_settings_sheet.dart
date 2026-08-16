import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

class NotificationSettingsSheet extends ConsumerStatefulWidget {
  const NotificationSettingsSheet({
    super.key,
    this.onChanged,
  });

  final VoidCallback? onChanged;

  @override
  ConsumerState<NotificationSettingsSheet> createState() =>
      NotificationSettingsSheetState();
}

class NotificationSettingsSheetState
    extends ConsumerState<NotificationSettingsSheet> {
  late bool _transactionNotifications;
  late bool _dailyEnabled;
  late int _dailyHour;
  late int _dailyMinute;
  late bool _weeklyEnabled;
  late bool _monthlyEnabled;
  late bool _budgetAlerts;

  @override
  void initState() {
    super.initState();
    _transactionNotifications =
        AppSettingsService.transactionNotificationsNotifier.value;
    _dailyEnabled = AppSettingsService.summaryDailyNotifier.value;
    _dailyHour = AppSettingsService.summaryDailyHourNotifier.value;
    _dailyMinute = AppSettingsService.summaryDailyMinuteNotifier.value;
    _weeklyEnabled = AppSettingsService.summaryWeeklyNotifier.value;
    _monthlyEnabled = AppSettingsService.summaryMonthlyNotifier.value;
    _budgetAlerts = AppSettingsService.budgetAlertsNotifier.value;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Future<void> _pickTime({
    required int currentHour,
    required int currentMinute,
    required ValueChanged<int> onHour,
    required ValueChanged<int> onMinute,
  }) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );
    if (t == null) return;
    onHour(t.hour);
    onMinute(t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final textPrimary =
        isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground;
    final textSecondary =
        isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Notification Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTile(
            label: 'Transaction alerts',
            subtitle: 'Notify on each new transaction',
            value: _transactionNotifications,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onChanged: (v) {
              setState(() => _transactionNotifications = v);
              AppSettingsService.setBool(
                AppSettingsService.keyTransactionNotifications,
                v,
              );
              widget.onChanged?.call();
            },
          ),
          _buildTile(
            label: 'Daily summary',
            subtitle: _dailyEnabled ? _formatTime(_dailyHour, _dailyMinute) : null,
            value: _dailyEnabled,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onChanged: (v) {
              setState(() => _dailyEnabled = v);
              AppSettingsService.setSummaryDailyEnabled(v);
              widget.onChanged?.call();
            },
            onSubtitleTap: _dailyEnabled
                ? () => _pickTime(
                      currentHour: _dailyHour,
                      currentMinute: _dailyMinute,
                      onHour: (h) {
                        setState(() => _dailyHour = h);
                        AppSettingsService.setSummaryDailyTime(
                          h,
                          _dailyMinute,
                        );
                      },
                      onMinute: (m) {
                        setState(() => _dailyMinute = m);
                        AppSettingsService.setSummaryDailyTime(
                          _dailyHour,
                          m,
                        );
                      },
                    )
                : null,
          ),
          _buildTile(
            label: 'Weekly summary',
            value: _weeklyEnabled,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onChanged: (v) {
              setState(() => _weeklyEnabled = v);
              AppSettingsService.setSummaryWeeklyEnabled(v);
              widget.onChanged?.call();
            },
          ),
          _buildTile(
            label: 'Monthly summary',
            value: _monthlyEnabled,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onChanged: (v) {
              setState(() => _monthlyEnabled = v);
              AppSettingsService.setSummaryMonthlyEnabled(v);
              widget.onChanged?.call();
            },
          ),
          _buildTile(
            label: 'Budget alerts',
            subtitle: 'Notify when spending nears or exceeds budget limits',
            value: _budgetAlerts,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onChanged: (v) {
              setState(() => _budgetAlerts = v);
              AppSettingsService.setBool(
                AppSettingsService.keyBudgetAlerts,
                v,
              );
              widget.onChanged?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required String label,
    String? subtitle,
    required bool value,
    required Color textPrimary,
    required Color textSecondary,
    required ValueChanged<bool> onChanged,
    VoidCallback? onSubtitleTap,
  }) {
    Widget? subtitleWidget;
    if (subtitle != null && onSubtitleTap != null) {
      subtitleWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSubtitleTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time,
                size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                )),
          ],
        ),
      );
    } else if (subtitle != null) {
      subtitleWidget = Text(subtitle,
          style: TextStyle(fontSize: 13, color: textSecondary));
    }

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(label,
          style:
              TextStyle(fontWeight: FontWeight.w500, color: textPrimary)),
      subtitle: subtitleWidget,
      onChanged: onChanged,
    );
  }
}
