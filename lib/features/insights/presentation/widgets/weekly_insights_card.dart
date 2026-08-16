import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';

class WeeklyInsightsSummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalSpending;
  final double previousWeekSpending;
  final double totalIncome;
  final double previousWeekIncome;
  final String topCategory;
  final double topCategoryAmount;
  final Map<String, double> dailySpending;
  final Map<String, double> dailyIncome;
  final Map<String, double> categoryBreakdown;
  final List<WeeklyDailyData> dailyData;

  WeeklyInsightsSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.totalSpending,
    required this.previousWeekSpending,
    required this.totalIncome,
    required this.previousWeekIncome,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.dailySpending,
    required this.dailyIncome,
    required this.categoryBreakdown,
    required this.dailyData,
  });

  double get netCashFlow => totalIncome - totalSpending;
  double get previousWeekNetCashFlow => previousWeekIncome - previousWeekSpending;
  double get netChange => netCashFlow - previousWeekNetCashFlow;
  double get netPercentageChange =>
      previousWeekNetCashFlow > 0
          ? ((netChange / previousWeekNetCashFlow) * 100)
          : netCashFlow > 0
              ? 100
              : netCashFlow < 0
                  ? -100
                  : 0;

  String get netDirection => netCashFlow > previousWeekNetCashFlow
      ? 'Better'
      : netCashFlow < previousWeekNetCashFlow
          ? 'Worse'
          : 'Same';

  double get spendingChange => totalSpending - previousWeekSpending;
  double get spendingPercentageChange =>
      previousWeekSpending > 0
          ? ((spendingChange / previousWeekSpending) * 100)
          : 0;

  String get spendingDirection => totalSpending > previousWeekSpending
      ? 'Higher'
      : totalSpending < previousWeekSpending
          ? 'Lower'
          : 'Same';

  double get incomeChange => totalIncome - previousWeekIncome;
  double get incomePercentageChange =>
      previousWeekIncome > 0
          ? ((incomeChange / previousWeekIncome) * 100)
          : 0;

  String get incomeDirection => totalIncome > previousWeekIncome
      ? 'Higher'
      : totalIncome < previousWeekIncome
          ? 'Lower'
          : 'Same';
}

class WeeklyDailyData {
  final String day;
  final double amount;
  final DateTime date;
  final double percentageOfWeek;

  WeeklyDailyData({
    required this.day,
    required this.amount,
    required this.date,
    required this.percentageOfWeek,
  });
}

class WeeklyInsightsCard extends ConsumerWidget {
  final WeeklyInsightsSummary insights;
  final VoidCallback? onTap;

  const WeeklyInsightsCard({
    super.key,
    required this.insights,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final cardBg = isDark ? DarkAppColors.homeCardBackground : Colors.white;
    final shadow = isDark ? DarkAppColors.homeCardShadowStyle : AppColors.homeCardShadowStyle;
    final textPrimary = isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground;
    final textSecondary = isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted;
    final calMode = ref.watch(calendarModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: shadow,
      ),
      padding: dims.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textPrimary, textSecondary, isDark, dims, calMode),
          SizedBox(height: dims.spacingMd),
          _buildHero(textPrimary, textSecondary, isDark, dims),
          SizedBox(height: dims(12)),
          _buildNetInsight(textPrimary, textSecondary, isDark, dims),
          SizedBox(height: dims(12)),
          _buildCategoryList(textPrimary, textSecondary, dims),
          SizedBox(height: dims.spacingMd),
          _buildFooter(textPrimary, textSecondary, dims),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary, bool isDark, AppDimensions dims, CalendarMode calMode) {
    final trendColor = insights.spendingPercentageChange > 0
        ? const Color(0xFFEF4444)
        : insights.spendingPercentageChange < 0
            ? isDark ? DarkAppColors.homeAccentGreen : AppColors.homeAccentGreen
            : const Color(0xFF6B7280);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: dims(2)),
              Text(
                '${insights.weekStart.fmt('MMM d', calMode)} \u2013 ${insights.weekEnd.fmt('MMM d', calMode)}',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: dims.symmetric(h: 10, v: 6),
          decoration: BoxDecoration(
            color: trendColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                insights.spendingPercentageChange > 0
                    ? Icons.arrow_upward_rounded
                    : insights.spendingPercentageChange < 0
                        ? Icons.arrow_downward_rounded
                        : Icons.remove_rounded,
                size: 14,
                color: trendColor,
              ),
              SizedBox(width: dims.spacingXs),
              Text(
                '${insights.spendingPercentageChange.abs().toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(Color textPrimary, Color textSecondary, bool isDark, AppDimensions dims) {
    final trendColor = insights.spendingPercentageChange > 0
        ? const Color(0xFFEF4444)
        : insights.spendingPercentageChange < 0
            ? isDark ? DarkAppColors.homeAccentGreen : AppColors.homeAccentGreen
            : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total spending',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: dims(6)),
        Text(
          'ETB ${insights.totalSpending.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        SizedBox(height: dims(6)),
        Row(
          children: [
            Text(
              '${insights.spendingPercentageChange.abs().toStringAsFixed(1)}% ${insights.spendingDirection.toLowerCase()}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: trendColor,
              ),
            ),
            SizedBox(width: dims.spacingXs),
            Text(
              'than last week',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetInsight(Color textPrimary, Color textSecondary, bool isDark, AppDimensions dims) {
    final green = isDark ? DarkAppColors.homeAccentGreen : AppColors.homeAccentGreen;
    final red = const Color(0xFFEF4444);
    final color = insights.netCashFlow >= 0 ? green : red;
    final sign = insights.netCashFlow >= 0 ? '+' : '';

    return Text(
      'Net: $sign ETB ${insights.netCashFlow.abs().toStringAsFixed(0)}  ·  ${insights.netDirection.toLowerCase()} than last week',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildCategoryList(Color textPrimary, Color textSecondary, AppDimensions dims) {
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    final categoryFormatter = useCompact ? NumberFormat.compact() : NumberFormat('#,##0');
    final topCategories = insights.categoryBreakdown.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (topCategories.isEmpty) return const SizedBox.shrink();

    final display = topCategories.length > 3 ? topCategories.take(3).toList() : topCategories;
    final remaining = topCategories.length - 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top categories',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: dims.spacingSm),
        ...display.map((entry) => Padding(
          padding: dims.only(b: 6),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.homeCategoryPalette[
                    entry.key.hashCode % AppColors.homeCategoryPalette.length],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: dims.spacingSm),
              Expanded(
                child: Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                'ETB ${categoryFormatter.format(entry.value)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        )),
        if (remaining > 0)
          Padding(
            padding: dims.only(t: 2),
            child: Text(
              '+ $remaining more',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(Color textPrimary, Color textSecondary, AppDimensions dims) {
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    final dayFormatter = useCompact ? NumberFormat.compact() : NumberFormat('#,##0');
    final busyDay = insights.dailyData
        .reduce((a, b) => a.amount > b.amount ? a : b);
    final daysWithSpending = insights.dailyData
        .fold<int>(0, (sum, d) => sum + (d.amount > 0 ? 1 : 0));

    return Container(
      padding: dims.all(12),
      decoration: BoxDecoration(
        color: textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: textSecondary,
          ),
          SizedBox(width: dims.spacingSm),
          Expanded(
            child: Text(
              busyDay.amount > 0
                  ? 'Busiest day: ${busyDay.day} \u00b7 ETB ${dayFormatter.format(busyDay.amount)}'
                  : 'No spending this week',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
          Text(
            '$daysWithSpending / 7 days',
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
