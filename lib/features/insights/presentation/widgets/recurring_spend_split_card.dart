import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:fl_chart/fl_chart.dart';

class RecurringSpendSnapshot {
  final String monthLabel;
  final double recurringTotal;
  final double oneOffTotal;
  final double totalSpend;
  final int recurringCount;
  final int oneOffCount;
  final List<String> recurringCategoryLabels;

  RecurringSpendSnapshot({
    required this.monthLabel,
    required this.recurringTotal,
    required this.oneOffTotal,
    required this.totalSpend,
    required this.recurringCount,
    required this.oneOffCount,
    required this.recurringCategoryLabels,
  });
}

class RecurringSpendSplitCard extends StatelessWidget {
  final RecurringSpendSnapshot snapshot;

  const RecurringSpendSplitCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final recurringShare = snapshot.totalSpend == 0
        ? 0.0
        : snapshot.recurringTotal / snapshot.totalSpend;
    final oneOffShare = snapshot.totalSpend == 0
        ? 0.0
        : snapshot.oneOffTotal / snapshot.totalSpend;
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    final recurringCurrency = useCompact
        ? NumberFormat.compactCurrency(symbol: 'ETB ')
        : NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(enabled: false),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 56,
                    sections: [
                      PieChartSectionData(
                        color: Colors.green.shade500,
                        value: snapshot.recurringTotal,
                        title: '',
                        radius: 58,
                      ),
                      PieChartSectionData(
                        color: Colors.orange.shade400,
                        value: snapshot.oneOffTotal,
                        title: '',
                        radius: 58,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    recurringCurrency.format(snapshot.recurringTotal),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.appBarForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Committed spend floor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: recurringShare,
            backgroundColor: Colors.orange.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetric(
              'Recurring',
              snapshot.recurringTotal,
              Colors.green.shade700,
            ),
            _buildMetric(
              'One-off',
              snapshot.oneOffTotal,
              Colors.orange.shade700,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(recurringShare * 100).toStringAsFixed(0)}% committed floor',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.balanceCardMuted,
              ),
            ),
            Text(
              '${(oneOffShare * 100).toStringAsFixed(0)}% variable',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.balanceCardMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildZoneDot(Colors.green.shade500, 'Fixed'),
            const SizedBox(width: 10),
            _buildZoneDot(Colors.orange.shade400, 'Variable'),
            const SizedBox(width: 10),
            _buildZoneDot(
              Colors.black26,
              '${snapshot.recurringCount + snapshot.oneOffCount} txns',
            ),
          ],
        ),
        if (snapshot.recurringCategoryLabels.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: snapshot.recurringCategoryLabels
                .map(
                  (label) => Chip(
                    label: Text(label),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.appBarForeground,
                    ),
                    backgroundColor: Colors.green.shade50,
                    side: BorderSide(color: Colors.green.shade100),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMetric(String label, double value, Color color) {
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    final metricCurrency = useCompact
        ? NumberFormat.compactCurrency(symbol: 'ETB ')
        : NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.balanceCardMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metricCurrency.format(value),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildZoneDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.balanceCardMuted,
          ),
        ),
      ],
    );
  }
}
