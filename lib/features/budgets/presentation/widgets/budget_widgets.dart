import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';

class SectionCard extends ConsumerWidget {
  const SectionCard({super.key, required this.title, required this.child, required this.isDark});

  final String title;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dims = ref.watch(dimensionsProvider);
    return Container(
      width: double.infinity,
      padding: dims.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : AppColors.homeCardShadowStyle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? DarkAppColors.appBarForeground : null),
          ),
          SizedBox(height: dims(12)),
          child,
        ],
      ),
    );
  }
}

class InsightRow extends ConsumerWidget {
  const InsightRow({
    super.key,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueStyle,
  });

  final String label;
  final String value;
  final bool isDark;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dims = ref.watch(dimensionsProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280)),
          ),
        ),
        SizedBox(width: dims.spacingSm),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: valueStyle ??
                TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? DarkAppColors.appBarForeground : null),
          ),
        ),
      ],
    );
  }
}

class SpendingTimeline extends ConsumerWidget {
  const SpendingTimeline({super.key, required this.points, required this.isDark});

  final List<double> points;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dims = ref.watch(dimensionsProvider);
    if (points.isEmpty) {
      return Center(child: Text('No data', style: TextStyle(color: isDark ? DarkAppColors.balanceCardMuted : null)));
    }

    final maxY = points.reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) {
      return Center(
        child: Text(
          'No spending in this period',
          style: TextStyle(fontSize: 12, color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280)),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((v) {
        final normalized = (v / maxY).clamp(0.0, 1.0);
        return Expanded(
          child: Padding(
            padding: dims.symmetric(h: 1),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 6 + (72 * normalized),
                decoration: BoxDecoration(
                  color: AppColors.homeNavigationSelected.withValues(
                    alpha: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PaceIndicator extends ConsumerWidget {
  const PaceIndicator({
    super.key,
    required this.spent,
    required this.elapsedDays,
    required this.daysLeft,
    required this.budgetAmount,
    required this.remaining,
    required this.isDark,
    required this.currency,
  });

  final double spent;
  final int elapsedDays;
  final int daysLeft;
  final double budgetAmount;
  final double remaining;
  final bool isDark;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDays = elapsedDays + daysLeft;
    final actualRate = spent / math.max(1, elapsedDays);
    final budgetRate = budgetAmount / math.max(1, totalDays);
    final paceRatio = budgetRate > 0 ? actualRate / budgetRate : 0.0;
    final isOverPace = paceRatio > 1;
    final isNearLimit = !isOverPace && paceRatio >= 0.8;
    final paceColor = isOverPace
        ? const Color(0xFFB85C5C)
        : isNearLimit
        ? const Color(0xFFC4975A)
        : const Color(0xFF8EA78F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '${currency.format(actualRate)}/day spent',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: paceColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'of ${currency.format(budgetRate)}/day budget',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? DarkAppColors.balanceCardMuted
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(paceRatio * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: paceColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${currency.format(remaining)} remaining · $daysLeft days left',
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? DarkAppColors.balanceCardMuted
                : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
