import 'package:flutter/material.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';

class GoalGrowthInfoDialog extends StatelessWidget {
  final bool isDark;

  const GoalGrowthInfoDialog({super.key, required this.isDark});

  static Future<void> show(BuildContext context, bool isDark) {
    return showDialog(
      context: context,
      builder: (ctx) => GoalGrowthInfoDialog(isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: isDark
          ? DarkAppColors.homeCardBackground
          : Colors.white,
      title: Text(
        'Growth Mode',
        style: TextStyle(
          color: isDark ? DarkAppColors.appBarForeground : null,
        ),
      ),
      content: Text(
        'Fixed: Same target each period (e.g., "have ETB 50K every month"). Progress resets each period.\n\n'
        'Growth: Target increases by the amount each period (e.g., "grow ETB 50K per month" '
        '→ 50K, 100K, 150K...). Progress is cumulative from your starting balance.',
        style: TextStyle(
          color: isDark ? DarkAppColors.balanceCardMuted : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

class GoalDatePickers extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final CalendarMode calMode;
  final bool isDark;
  final ValueChanged<DateTime> onStartDatePicked;
  final ValueChanged<DateTime> onEndDatePicked;

  const GoalDatePickers({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.calMode,
    required this.isDark,
    required this.onStartDatePicked,
    required this.onEndDatePicked,
  });

  String _formatDate(DateTime date, CalendarMode mode) =>
      date.fmt('MMM d, yyyy', mode);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Start date',
            style: TextStyle(
              color: isDark ? DarkAppColors.appBarForeground : null,
            ),
          ),
          subtitle: Text(
            startDate == null
                ? 'Choose a start date'
                : _formatDate(startDate!, calMode),
            style: TextStyle(
              color: isDark ? DarkAppColors.balanceCardMuted : null,
            ),
          ),
          trailing: Icon(
            Icons.event_outlined,
            color: isDark ? DarkAppColors.balanceCardMuted : null,
          ),
          onTap: () async {
            final now = DateTime.now();
            final last = endDate ?? DateTime(now.year + 10);
            final picked = await showDatePicker(
              context: context,
              initialDate: startDate ?? now,
              firstDate: DateTime(now.year - 5),
              lastDate: last,
            );
            if (picked != null) {
              onStartDatePicked(
                DateTime(picked.year, picked.month, picked.day),
              );
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'End date (deadline)',
            style: TextStyle(
              color: isDark ? DarkAppColors.appBarForeground : null,
            ),
          ),
          subtitle: Text(
            endDate == null
                ? 'Choose an end date'
                : _formatDate(endDate!, calMode),
            style: TextStyle(
              color: isDark ? DarkAppColors.balanceCardMuted : null,
            ),
          ),
          trailing: Icon(
            Icons.event_outlined,
            color: isDark ? DarkAppColors.balanceCardMuted : null,
          ),
          onTap: () async {
            final now = DateTime.now();
            final first = startDate ?? DateTime(now.year - 5);
            final picked = await showDatePicker(
              context: context,
              initialDate: endDate ?? startDate ?? now,
              firstDate: first,
              lastDate: DateTime(now.year + 10),
            );
            if (picked != null) {
              onEndDatePicked(
                DateTime(picked.year, picked.month, picked.day),
              );
            }
          },
        ),
      ],
    );
  }
}

class GoalGrowthModeTile extends StatelessWidget {
  final bool growthMode;
  final String? period;
  final String amountText;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const GoalGrowthModeTile({
    super.key,
    required this.growthMode,
    required this.period,
    required this.amountText,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final periodName = period?.toLowerCase() ?? '';
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Text(
            'Incremental growth per period',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? DarkAppColors.appBarForeground : null,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              size: 18,
              color: isDark
                  ? DarkAppColors.balanceCardMuted
                  : const Color(0xFF6B7280),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => GoalGrowthInfoDialog.show(context, isDark),
          ),
        ],
      ),
      subtitle: Text(
        growthMode
            ? 'Target grows by ETB ${amountText.isNotEmpty ? amountText : 'X'} each $periodName'
            : 'Same target every $periodName',
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? DarkAppColors.balanceCardMuted
              : const Color(0xFF6B7280),
        ),
      ),
      value: growthMode,
      onChanged: onChanged,
      activeThumbColor: isDark ? DarkAppColors.homeAccentGreen : null,
    );
  }
}
