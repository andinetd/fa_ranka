import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';

class CalendarSettingsSheet extends ConsumerWidget {
  const CalendarSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final textPrimary =
        isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground;
    final currentMode = ref.watch(calendarModeProvider);

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
                'Calendar Settings',
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
          _buildOption(
            context: context,
            value: CalendarMode.gregorian,
            label: 'Gregorian',
            icon: Icons.calendar_month_outlined,
            description: 'Standard international calendar (default).',
            selected: currentMode,
            textPrimary: textPrimary,
            isDark: isDark,
            onTap: () {
              ref.read(calendarModeProvider.notifier).setMode(
                    CalendarMode.gregorian,
                  );
              Navigator.pop(context);
            },
          ),
          const Divider(height: 8),
          _buildOption(
            context: context,
            value: CalendarMode.ethiopian,
            label: 'Ethiopian',
            icon: Icons.calendar_view_month_outlined,
            description: 'Traditional Ethiopian calendar (13 months).',
            selected: currentMode,
            textPrimary: textPrimary,
            isDark: isDark,
            onTap: () {
              ref.read(calendarModeProvider.notifier).setMode(
                    CalendarMode.ethiopian,
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required CalendarMode value,
    required String label,
    required IconData icon,
    required String description,
    required CalendarMode selected,
    required Color textPrimary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selected;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : textPrimary,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? DarkAppColors.balanceCardMuted
              : AppColors.balanceCardMuted,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }

}
