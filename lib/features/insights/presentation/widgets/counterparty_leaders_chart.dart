import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_data.dart';

class CounterpartyLeadersChart extends ConsumerWidget {
  final CounterpartyInsightsSnapshot snapshot;

  const CounterpartyLeadersChart({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _CounterpartyPanel(
          title: 'Most Sent To',
          icon: Icons.north_east,
          color: const Color.fromARGB(255, 139, 101, 114),
          items: snapshot.topSentTo,
          emptyMessage: 'No debit transfers found',
        ),
      ],
    );
  }
}

class _CounterpartyPanel extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<CounterpartyInsightItem> items;
  final String emptyMessage;

  const _CounterpartyPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final totalAmount = items.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return Container(
      padding: dims.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.25 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              SizedBox(width: dims.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                  ),
                ),
              ),
              Text(
                AppSettingsService.getBoolSync(
                      AppSettingsService.keyCompactNumbers,
                      fallback: true,
                    )
                    ? NumberFormat.compactCurrency(symbol: 'ETB ').format(
                        totalAmount,
                      )
                    : NumberFormat.currency(symbol: 'ETB ').format(totalAmount),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: dims(10)),
          if (items.isEmpty)
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
              ),
            )
          else
            ...items.asMap().entries.map(
              (entry) => _CounterpartyBarRow(
                rank: entry.key + 1,
                item: entry.value,
                maxAmount: items.first.amount,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _CounterpartyBarRow extends ConsumerWidget {
  final int rank;
  final CounterpartyInsightItem item;
  final double maxAmount;
  final Color color;

  const _CounterpartyBarRow({
    required this.rank,
    required this.item,
    required this.maxAmount,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final progress = maxAmount <= 0
        ? 0.0
        : (item.amount / maxAmount).clamp(0.0, 1.0);

    return Padding(
      padding: dims.only(b: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              SizedBox(width: dims.spacingSm),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                  ),
                ),
              ),
              SizedBox(width: dims.spacingSm),
              Text(
                AppSettingsService.getBoolSync(
                      AppSettingsService.keyCompactNumbers,
                      fallback: true,
                    )
                    ? NumberFormat.compactCurrency(symbol: 'ETB ').format(
                        item.amount,
                      )
                    : NumberFormat.currency(symbol: 'ETB ').format(item.amount),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                ),
              ),
            ],
          ),
          SizedBox(height: dims(6)),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              SizedBox(width: dims.spacingSm),
              Text(
                '${item.count} txns',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
