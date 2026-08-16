import 'package:flutter/material.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_enums.dart';

class CalendarMetricToggle extends StatelessWidget {
  final CalendarMetric value;
  final ValueChanged<CalendarMetric> onChanged;

  const CalendarMetricToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPill(
          context,
          label: 'Spending',
          selected: value == CalendarMetric.spending,
          onTap: () => onChanged(CalendarMetric.spending),
        ),
        const SizedBox(width: 8),
        _buildPill(
          context,
          label: 'Income',
          selected: value == CalendarMetric.income,
          onTap: () => onChanged(CalendarMetric.income),
        ),
      ],
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final pillBg = selected
        ? (isDark ? DarkAppColors.homeCardBackground : Colors.white)
        : (isDark ? const Color(0xFF2D2D40) : const Color(0xFFF3F3F6));
    final borderColor = selected
        ? (isDark ? DarkAppColors.appBarForeground : const Color(0xFF2E3048))
        : (isDark ? Colors.white10 : Colors.transparent);
    final fgColor = selected
        ? (isDark ? DarkAppColors.appBarForeground : const Color(0xFF1F2133))
        : (isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF7A7D8F));

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: fgColor,
          ),
        ),
      ),
    );
  }
}
