import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';

class MonthNavigator extends ConsumerWidget {
  final DateTime selectedDate;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthNavigator({
    super.key,
    required this.selectedDate,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final calMode = ref.watch(calendarModeProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canGoPrevious ? onPrevious : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: canGoPrevious
                  ? (isDark ? DarkAppColors.homeCardBackground : Colors.white)
                  : (isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF3F3F6)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: canGoPrevious
                    ? (isDark ? DarkAppColors.appBarForeground : const Color(0xFF2E3048))
                    : Colors.transparent,
                width: 1.1,
              ),
            ),
            child: Icon(
              Icons.chevron_left,
              size: 16,
              color: canGoPrevious
                  ? (isDark ? DarkAppColors.appBarForeground : const Color(0xFF1F2133))
                  : (isDark ? const Color(0xFF4A4D62) : const Color(0xFFB5B7C3)),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF3F3F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                selectedDate.fmt('MMM yyyy', calMode),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DarkAppColors.appBarForeground : const Color(0xFF4A4D62),
                ),
              ),
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canGoNext ? onNext : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: canGoNext
                  ? (isDark ? DarkAppColors.homeCardBackground : Colors.white)
                  : (isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF3F3F6)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: canGoNext
                    ? (isDark ? DarkAppColors.appBarForeground : const Color(0xFF2E3048))
                    : Colors.transparent,
                width: 1.1,
              ),
            ),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: canGoNext
                  ? (isDark ? DarkAppColors.appBarForeground : const Color(0xFF1F2133))
                  : (isDark ? const Color(0xFF4A4D62) : const Color(0xFFB5B7C3)),
            ),
          ),
        ),
      ],
    );
  }
}
