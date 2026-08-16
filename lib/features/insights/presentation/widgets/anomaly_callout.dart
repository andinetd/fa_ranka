import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_data.dart';

class AnomalyCallout extends ConsumerWidget {
  final SpendingAnomaly anomaly;

  const AnomalyCallout({super.key, required this.anomaly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? DarkAppColors.homeCardBackground : Colors.white;
    final textPrimary = isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground;
    final textMuted = isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted;
    final shadow = isDark ? DarkAppColors.homeCardShadowStyle : AppColors.homeCardShadowStyle;
    final dims = ref.watch(dimensionsProvider);
    final message = anomaly.direction == 'overspending'
        ? '${anomaly.ratio.toStringAsFixed(1)}x your 3-month average'
        : '${(anomaly.ratio * 100).toStringAsFixed(0)}% of your 3-month average';
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    final anomalyCurrency = useCompact
        ? NumberFormat.compactCurrency(symbol: 'ETB ')
        : NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    return Padding(
      padding: dims.only(b: 12),
      child: Container(
        padding: dims.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: shadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: dims.all(8),
              decoration: BoxDecoration(
                color: anomaly.trendColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                anomaly.direction == 'overspending'
                    ? Icons.trending_up
                    : Icons.trending_down,
                size: 14,
                color: anomaly.trendColor,
              ),
            ),
            SizedBox(width: dims(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          anomaly.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: dims.spacingSm),
                      Text(
                        anomalyCurrency.format(anomaly.currentTotal),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dims(3)),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
