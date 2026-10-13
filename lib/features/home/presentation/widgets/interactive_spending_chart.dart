import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/app/core/widgets/sensitive_text.dart';
import 'balance_card_theme.dart';

class InteractiveSpendingChart extends StatelessWidget {
  const InteractiveSpendingChart({
    super.key,
    required this.points,
    required this.accent,
    required this.grid,
    required this.dims,
    required this.hidden,
    required this.calMode,
  });

  final List<double> points;
  final Color accent;
  final Color grid;
  final AppDimensions dims;
  final bool hidden;
  final CalendarMode calMode;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No spending data yet',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.white70,
            fontSize: 12,
          ),
        ),
      );
    }

    final safePoints = points.map((v) => v.isFinite ? v : 0.0).toList();
    final maxY = safePoints.reduce((a, b) => a > b ? a : b);
    final avgY =
        safePoints.fold<double>(0.0, (sum, v) => sum + v) / safePoints.length;
    final topY = maxY <= 0 ? 1.0 : maxY * 1.25;
    const tooltipPattern = 'MMM d';
    final axisPattern = safePoints.length <= 8
        ? 'MMM d'
        : safePoints.length <= 31
            ? 'd MMM'
            : 'MMM';
    final startDate = DateTime.now().subtract(
      Duration(days: safePoints.length - 1),
    );

    String yLabel(double value) {
      final useCompact = AppSettingsService.getBoolSync(
        AppSettingsService.keyCompactNumbers,
        fallback: true,
      );
      if (!useCompact) {
        return NumberFormat('#,###').format(value);
      }
      return NumberFormat.compact().format(value);
    }

    final barWidth = safePoints.length > 90
        ? 2.0
        : safePoints.length > 30
            ? 4.0
            : 6.0;

    final barGroups = List.generate(safePoints.length, (i) {
      final value = safePoints[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            width: barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(BalanceCardTheme.cornerRadius),
              topRight: Radius.circular(BalanceCardTheme.cornerRadius),
            ),
            color: accent,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: topY,
              color: grid,
            ),
          ),
        ],
      );
    });

    final maxBottomLabels = safePoints.length <= 8
        ? safePoints.length
        : safePoints.length <= 31
            ? 6
            : 5;
    final step = safePoints.length <= maxBottomLabels
        ? 1
        : (safePoints.length / (maxBottomLabels - 1)).ceil();
    final xInterval = step.toDouble();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: topY,
        barGroups: barGroups,
        alignment: BarChartAlignment.spaceBetween,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: grid, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: topY / 3,
              getTitlesWidget: (value, meta) => SensitiveText(
                yLabel(value),
                style: TextStyle(
                  color: isDark
                      ? DarkAppColors.balanceCardMuted
                      : AppColors.balanceCardMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= safePoints.length) {
                  return const SizedBox.shrink();
                }

                final isFirst = i == 0;
                final isLast = i == safePoints.length - 1;
                if (!isFirst && !isLast && i % step != 0) {
                  return const SizedBox.shrink();
                }

                final date = startDate.add(Duration(days: i));
                return Padding(
                  padding: dims.only(t: 6),
                  child: SizedBox(
                    width: 36,
                    child: Text(
                      date.fmt(axisPattern, calMode),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: isDark
                            ? DarkAppColors.balanceCardMuted
                            : AppColors.balanceCardMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: avgY,
              color: grid,
              strokeWidth: 1,
              dashArray: [6, 6],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                  color: isDark
                      ? DarkAppColors.balanceCardMuted
                      : AppColors.balanceCardMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                labelResolver: (_) => 'avg',
              ),
            ),
          ],
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: BalanceCardTheme.cornerRadius,
            tooltipPadding: dims.symmetric(
              h: 10,
              v: 6,
            ),
            tooltipBorder: BorderSide(
              color: isDark
                  ? DarkAppColors.balanceCardGrid
                  : AppColors.balanceCardGrid,
            ),
            tooltipBgColor:
                isDark ? DarkAppColors.homeCardBackground : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x.clamp(0, safePoints.length - 1);
              final date = startDate.add(Duration(days: index));
              final useCompact = AppSettingsService.getBoolSync(
                AppSettingsService.keyCompactNumbers,
                fallback: true,
              );
              final prefix = hidden
                  ? '****'
                  : '${useCompact ? NumberFormat.compact() : NumberFormat('#,###').format(rod.toY)} etb';
              return BarTooltipItem(
                '${date.fmt(tooltipPattern, calMode)}\n',
                TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: prefix,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
          touchCallback: (event, response) {},
        ),
      ),
    );
  }
}
