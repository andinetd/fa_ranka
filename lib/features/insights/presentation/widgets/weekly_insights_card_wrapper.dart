import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';
import 'package:faranka/features/insights/presentation/widgets/weekly_insights_card.dart';
import 'package:faranka/features/insights/presentation/utils/weekly_insights_service.dart';

class WeeklyInsightsCardWrapper extends ConsumerWidget {
  const WeeklyInsightsCardWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final db = ref.watch(databaseProvider);
    return FutureBuilder<WeeklyInsightsSummary>(
      future: WeeklyInsightsService.calculateWeeklyInsights(
        db,
        DateTime.now(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: dims.all(16),
            decoration: BoxDecoration(
              color: isDark ? DarkAppColors.homeCardBackground : homeCardBackground,
              borderRadius: homeCardBorderRadius,
              boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : homeCardShadow,
            ),
            child: Center(
              child: SizedBox(
                height: dims(40),
                width: dims(40),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final insights = snapshot.data!;
        final isWeekEnd = WeeklyInsightsService.isWeekEnd(DateTime.now());
        final accentColor = isDark ? DarkAppColors.homeAccentGreen : AppColors.homeAccentGreen;

        return Column(
          children: [
            if (isWeekEnd)
              Container(
                width: double.infinity,
                padding: dims.all(12),
                margin: dims.only(b: 12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: dims.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(width: dims(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week Summary Ready',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            'Your week summary has been calculated',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            WeeklyInsightsCard(
              insights: insights,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }
}
