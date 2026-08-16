import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_data.dart';
import 'package:faranka/features/insights/presentation/widgets/anomaly_callout.dart';

class AnomaliesCard extends ConsumerWidget {
  final Stream<List<SpendingAnomaly>> stream;
  final String monthLabel;

  const AnomaliesCard({
    super.key,
    required this.stream,
    required this.monthLabel,
  });

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
            'Spending Anomalies',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
            ),
          ),
          SizedBox(height: dims.spacingXs),
          Text(
            monthLabel,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ),
          SizedBox(height: dims(2)),
          Text(
            'Categories where spending significantly deviates from 3-month average',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ),
          SizedBox(height: dims(20)),
          StreamBuilder<List<SpendingAnomaly>>(
            stream: stream,
            builder: (context, snapshot) {
              final anomalies = snapshot.data ?? [];
              if (anomalies.isEmpty) {
                return SizedBox(
                  height: dims(100),
                  child: Center(
                    child: Text(
                      'No spending anomalies detected',
                      style: TextStyle(
                        color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: anomalies
                    .map((anomaly) => AnomalyCallout(anomaly: anomaly))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
