import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_enums.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_data.dart';
import 'package:faranka/features/insights/presentation/widgets/counterparty_leaders_chart.dart';

class CounterpartyLeadersCard extends ConsumerWidget {
  final Stream<CounterpartyInsightsSnapshot> stream;
  final PeriodOption period;
  final DateTime selectedDate;
  final ValueChanged<PeriodOption> onPeriodChanged;

  const CounterpartyLeadersCard({
    super.key,
    required this.stream,
    required this.period,
    required this.selectedDate,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
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
            'Most Sent To',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
            ),
          ),
          SizedBox(height: dims.spacingXs),
          Row(
            children: [
              Expanded(
                child: Text(
                  period == PeriodOption.followGlobal
                      ? selectedDate.fmt('MMM yyyy', calMode)
                      : period == PeriodOption.month
                      ? selectedDate.fmt('MMM yyyy', calMode)
                      : period == PeriodOption.threeMonths
                      ? '3 months'
                      : period == PeriodOption.year
                      ? '${selectedDate.year}'
                      : 'All time',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  ),
                ),
              ),
              PopupMenuButton<PeriodOption>(
                tooltip: 'Change period',
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: PeriodOption.followGlobal,
                    child: Text('Follow main period'),
                  ),
                  const PopupMenuItem(
                    value: PeriodOption.month,
                    child: Text('This month'),
                  ),
                  const PopupMenuItem(
                    value: PeriodOption.threeMonths,
                    child: Text('Last 3 months'),
                  ),
                  const PopupMenuItem(
                    value: PeriodOption.year,
                    child: Text('This year'),
                  ),
                  const PopupMenuItem(
                    value: PeriodOption.all,
                    child: Text('All time'),
                  ),
                ],
                onSelected: onPeriodChanged,
                child: Icon(
                  Icons.tune,
                  size: 18,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: dims(2)),
          Text(
            period == PeriodOption.followGlobal
                ? 'Top debit counterparties in the selected month'
                : period == PeriodOption.month
                ? 'Top debit counterparties in the selected month'
                : period == PeriodOption.threeMonths
                ? 'Top debit counterparties in the last 3 months'
                : period == PeriodOption.year
                ? 'Top debit counterparties in the year'
                : 'Top debit counterparties (all time)',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ),
          SizedBox(height: dims(20)),
          StreamBuilder<CounterpartyInsightsSnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) {
                return SizedBox(
                  height: dims(140),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (data.topSentTo.isEmpty) {
                return SizedBox(
                  height: dims(100),
                  child: Center(
                    child: Text(
                      'No debit counterparties found for this period',
                      style: TextStyle(
                        color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                      ),
                    ),
                  ),
                );
              }

              return CounterpartyLeadersChart(snapshot: data);
            },
          ),
        ],
      ),
    );
  }
}
