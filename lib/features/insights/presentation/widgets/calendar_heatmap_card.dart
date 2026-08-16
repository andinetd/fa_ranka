import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_enums.dart';
import 'package:faranka/features/insights/presentation/widgets/calendar_heatmap.dart';
import 'package:faranka/features/insights/presentation/widgets/calendar_metric_toggle.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_data_providers.dart';

class CalendarHeatmapCard extends ConsumerWidget {
  final CalendarMetric metric;
  final DateTime selectedDate;
  final Stream<Set<DateTime>> activityDatesStream;
  final Stream<Map<DateTime, double>> dailyAmountsStream;
  final ValueChanged<CalendarMetric> onMetricChanged;
  final ValueChanged<DateTime> onDateTap;
  final String bankFilter;
  final ValueChanged<String> onBankFilterChanged;

  const CalendarHeatmapCard({
    super.key,
    required this.metric,
    required this.selectedDate,
    required this.activityDatesStream,
    required this.dailyAmountsStream,
    required this.onMetricChanged,
    required this.onDateTap,
    required this.bankFilter,
    required this.onBankFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final accountOptions =
        ref.watch(accountOptionsProvider).asData?.value ??
        const ['All Accounts'];
    final bankOptions = bankFilterOptions(accountOptions, bankFilter);
    final hasBanks = accountOptions.length > 1;
    final title = metric == CalendarMetric.spending
        ? 'Spending Heatmap'
        : 'Income Heatmap';
    final subtitle = metric == CalendarMetric.spending
        ? 'Daily spending intensity for the selected month'
        : 'Daily income intensity for the selected month';

    return Container(
      width: double.infinity,
      padding: dims.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.homeCardBackground : homeCardBackground,
        borderRadius: homeCardBorderRadius,
        boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : homeCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                      ),
                    ),
                    SizedBox(height: dims.spacingXs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showFilterModal(
                    context,
                    dims,
                    bankOptions,
                    hasBanks,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF3F3F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune,
                      size: 18,
                      color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF7A7D8F),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dims(20)),
          StreamBuilder<Set<DateTime>>(
            stream: activityDatesStream,
            builder: (context, activitySnapshot) {
              if (!activitySnapshot.hasData) {
                return SizedBox(
                  height: dims(200),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              return StreamBuilder<Map<DateTime, double>>(
                stream: dailyAmountsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox(
                      height: dims(200),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final dailyData = snapshot.data ?? {};
                  return CalendarHeatmap(
                    year: selectedDate.year,
                    month: selectedDate.month,
                    dailyData: dailyData,
                    metric: metric,
                    activeDates: activitySnapshot.data ?? const <DateTime>{},
                    onDateTap: onDateTap,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFilterModal(
    BuildContext context,
    AppDimensions dims,
    List<String> bankOptions,
    bool hasBanks,
  ) {
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        var localMetric = metric;
        var localBankFilter = bankFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? DarkAppColors.scaffoldBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: dims(12)),
                  Row(
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: dims(16)),
                  Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: dims(8)),
                  CalendarMetricToggle(
                    value: localMetric,
                    onChanged: (m) {
                      setModalState(() => localMetric = m);
                      onMetricChanged(m);
                    },
                  ),
                  SizedBox(height: dims(20)),
                  Text(
                    'Bank',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: dims(8)),
                  Wrap(
                    spacing: dims(8),
                    runSpacing: dims(8),
                    children: bankOptions.map((b) {
                      final selected = b == localBankFilter;
                      final chipBg = selected
                          ? (isDark ? DarkAppColors.homeCardBackground : Colors.white)
                          : (isDark ? const Color(0xFF2D2D40) : const Color(0xFFF3F3F6));
                      final borderColor = selected
                          ? (isDark ? DarkAppColors.appBarForeground : const Color(0xFF2E3048))
                          : (isDark ? Colors.white10 : Colors.transparent);
                      final fgColor = selected
                          ? (isDark ? DarkAppColors.appBarForeground : const Color(0xFF1F2133))
                          : (isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF7A7D8F));

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setModalState(() => localBankFilter = b);
                          onBankFilterChanged(b);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: Text(
                            b,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: fgColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (!hasBanks) ...[
                    SizedBox(height: dims(8)),
                    Text(
                      'No banks found yet — sync SMS to add accounts.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? DarkAppColors.balanceCardMuted
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
      },
    );
  }
}
