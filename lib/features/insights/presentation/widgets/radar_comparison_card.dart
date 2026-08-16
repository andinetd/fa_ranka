import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_data.dart';
import 'package:faranka/features/insights/presentation/widgets/category_radar_comparison_chart.dart';

class RadarComparisonCard extends ConsumerWidget {
  final Stream<CategoryRadarComparison?> stream;

  const RadarComparisonCard({super.key, required this.stream});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    return Container(
      width: double.infinity,
      padding: dims.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : AppColors.homeCardShadowStyle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Balance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
            ),
          ),
          SizedBox(height: dims.spacingXs),
          Text(
            'This month vs last month across your top spending categories',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ),
          SizedBox(height: dims(20)),
          StreamBuilder<CategoryRadarComparison?>(
            stream: stream,
            builder: (context, snapshot) {
              final comparison = snapshot.data;
              if (comparison == null || comparison.labels.isEmpty) {
                return SizedBox(
                  height: dims(280),
                  child: Center(
                    child: Text(
                      'No category data to compare yet',
                      style: TextStyle(
                        color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                      ),
                    ),
                  ),
                );
              }

              return CategoryRadarComparisonChart(comparison: comparison);
            },
          ),
        ],
      ),
    );
  }
}
