import 'package:flutter/material.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_data.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryRadarComparisonChart extends StatelessWidget {
  final CategoryRadarComparison comparison;

  const CategoryRadarComparisonChart({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final currentEntries = comparison.currentValues
        .map((value) => RadarEntry(value: value))
        .toList();
    final previousEntries = comparison.previousValues
        .map((value) => RadarEntry(value: value))
        .toList();

    final hasValues =
        comparison.currentValues.any((value) => value > 0) ||
        comparison.previousValues.any((value) => value > 0);

    if (comparison.labels.length < 3) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Text(
            'Add more categories to see the radar chart',
            style: TextStyle(
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ),
        ),
      );
    }

    if (!hasValues) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Text(
            'No category totals to compare',
            style: TextStyle(
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 5,
              titlePositionPercentageOffset: 0.18,
              radarBackgroundColor: Colors.transparent,
              radarBorderData: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
              tickBorderData: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              gridBorderData: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
              titleTextStyle: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              ticksTextStyle: TextStyle(
                color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                fontSize: 9,
              ),
              getTitle: (index, angle) {
                if (index < 0 || index >= comparison.labels.length) {
                  return const RadarChartTitle(text: '');
                }
                return RadarChartTitle(
                  text: comparison.labels[index],
                  angle: angle,
                  positionPercentageOffset: 0.18,
                );
              },
              dataSets: [
                RadarDataSet(
                  dataEntries: previousEntries,
                  fillColor: Colors.blue.withValues(alpha: 0.12),
                  borderColor: Colors.blue.shade400,
                  borderWidth: 2,
                  entryRadius: 3,
                ),
                RadarDataSet(
                  dataEntries: currentEntries,
                  fillColor: Colors.pink.withValues(alpha: 0.16),
                  borderColor: Colors.pink.shade500,
                  borderWidth: 2.5,
                  entryRadius: 3,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendDot(isDark ? Colors.pink.shade300 : Colors.pink.shade500, comparison.currentMonthLabel, isDark),
            const SizedBox(width: 16),
            _buildLegendDot(
              isDark ? Colors.blue.shade300 : Colors.blue.shade400,
              comparison.previousMonthLabel,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
          ),
        ),
      ],
    );
  }
}
