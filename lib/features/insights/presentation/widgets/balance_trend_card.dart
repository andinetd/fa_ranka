import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_enums.dart';

class BalanceTrendCard extends ConsumerWidget {
  final BalanceTrendPeriod period;
  final Stream<List<double>> stream;
  final BankBalanceFilter bankFilter;
  final ValueChanged<BalanceTrendPeriod> onPeriodChanged;
  final ValueChanged<BankBalanceFilter> onBankFilterChanged;

  const BalanceTrendCard({
    super.key,
    required this.period,
    required this.stream,
    required this.bankFilter,
    required this.onPeriodChanged,
    required this.onBankFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final chipBg = isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF3F3F6);
    final accent = isDark ? DarkAppColors.balanceCardAccent : AppColors.balanceCardAccent;
    final onAccent = isDark ? Colors.black : Colors.white;

    return Container(
      width: double.infinity,
      padding: dims.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
        borderRadius: homeCardBorderRadius,
        boxShadow: isDark
            ? DarkAppColors.homeCardShadowStyle
            : AppColors.homeCardShadowStyle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color:
                  isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
            ),
          ),
          SizedBox(height: dims.spacingXs),
          Text(
            'Your balance over the last ${period.days} days',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ),
          SizedBox(height: dims(14)),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: BalanceTrendPeriod.values.map((p) {
                      final selected = p == period;
                      return Padding(
                        padding: EdgeInsets.only(right: dims(6)),
                        child: GestureDetector(
                          onTap: () => onPeriodChanged(p),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: dims(10), vertical: dims(5)),
                            decoration: BoxDecoration(
                              color: selected ? accent : chipBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected ? onAccent : (isDark ? Colors.white70 : const Color(0xFF7A7D8F)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(width: dims(6)),
              PopupMenuButton<BankBalanceFilter>(
                tooltip: 'Filter by bank',
                position: PopupMenuPosition.under,
                onSelected: onBankFilterChanged,
                itemBuilder: (context) => BankBalanceFilter.values.map((b) {
                  return PopupMenuItem(
                    value: b,
                    child: Text(b.label),
                  );
                }).toList(),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: dims(8), vertical: dims(4)),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bankFilter.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF7A7D8F),
                        ),
                      ),
                      SizedBox(width: dims(3)),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF7A7D8F),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dims(16)),
          SizedBox(
            height: dims(220),
            child: StreamBuilder<List<double>>(
              stream: stream,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null || data.isEmpty) {
                  return Center(
                    child: Text(
                      'No balance data yet',
                      style: TextStyle(
                        color: isDark
                            ? DarkAppColors.balanceCardMuted
                            : AppColors.balanceCardMuted,
                      ),
                    ),
                  );
                }
                final safePoints = data.map((v) => v.isFinite ? v : 0.0).toList();
                final maxVal = safePoints.reduce((a, b) => a > b ? a : b);
                final minVal = safePoints.reduce((a, b) => a < b ? a : b);
                final range = (maxVal - minVal).clamp(1.0, double.infinity);
                final topY = maxVal + range * 0.15;
                final bottomY = (minVal - range * 0.15).clamp(0.0, double.infinity);

                final gridColor = isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06);
                final labelColor = isDark
                    ? DarkAppColors.balanceCardMuted
                    : AppColors.balanceCardMuted;

                final startDate = DateTime.now().subtract(
                  Duration(days: safePoints.length - 1),
                );

                final maxBottomLabels = safePoints.length <= 8
                    ? safePoints.length
                    : safePoints.length <= 31
                    ? 6
                    : 5;
                final step = safePoints.length <= maxBottomLabels
                    ? 1
                    : (safePoints.length / (maxBottomLabels - 1)).ceil();
                final xInterval = step.toDouble();

                String yLabel(double value) {
                  return NumberFormat.compact(locale: 'en_US').format(value);
                }

                final datePattern = safePoints.length <= 8
                    ? 'MMM d'
                    : safePoints.length <= 31
                    ? 'd MMM'
                    : 'MMM';

                final spots = safePoints.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value);
                }).toList();

                return LineChart(
                  LineChartData(
                    minY: bottomY,
                    maxY: topY,
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: gridColor, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: topY / 3,
                          getTitlesWidget: (value, meta) => Text(
                            yLabel(value),
                            style: TextStyle(
                              color: labelColor,
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
                              padding: const EdgeInsets.only(top: 6),
                              child: SizedBox(
                                width: 36,
                                child: Text(
                                  date.fmt(datePattern, calMode),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: TextStyle(
                                    color: labelColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.0,
                        color: accent.withValues(alpha: 0.6),
                        barWidth: 1.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: accent,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final formatter = NumberFormat('#,###');
                            final date = startDate.add(
                              Duration(days: spot.x.toInt()),
                            );
                            return LineTooltipItem(
                              '${date.fmt('MMM d', calMode)}\nETB ${formatter.format(spot.y)}',
                              TextStyle(
                                color: onAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
