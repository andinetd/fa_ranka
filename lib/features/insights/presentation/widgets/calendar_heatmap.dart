import 'package:flutter/material.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_enums.dart';

class CalendarHeatmap extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, double> dailyData;
  final CalendarMetric metric;
  final Set<DateTime> activeDates;
  final ValueChanged<DateTime> onDateTap;

  const CalendarHeatmap({
    super.key,
    required this.year,
    required this.month,
    required this.dailyData,
    required this.metric,
    required this.activeDates,
    required this.onDateTap,
  });

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getColorForSpending(double spending, bool isDark) {
    if (spending == 0) {
      return isDark ? const Color(0xFF2A2A2A) : const Color.fromARGB(255, 245, 241, 241);
    }
    if (metric == CalendarMetric.spending) {
      if (spending < 500) {
        return Colors.pink.shade50;
      }
      if (spending < 1500) {
        return Colors.pink.shade100;
      }
      if (spending < 3000) {
        return Colors.pink.shade300;
      }
      return Colors.pink.shade600;
    }

    if (spending < 500) {
      return Colors.green.shade100;
    }
    if (spending < 1500) {
      return Colors.green.shade300;
    }
    if (spending < 3000) {
      return Colors.green.shade500;
    }
    return Colors.green.shade800;
  }

  List<Color> _legendColors() {
    if (metric == CalendarMetric.spending) {
      return [
        const Color.fromARGB(255, 252, 246, 248),
        Colors.pink.shade50,
        Colors.pink.shade100,
        Colors.pink.shade300,
        Colors.pink.shade600,
      ];
    }

    return [
      const Color.fromARGB(255, 229, 236, 232),
      Colors.green.shade100,
      Colors.green.shade300,
      Colors.green.shade500,
      Colors.green.shade800,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    const cellPadding = 6.0;
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOfMonth = DateTime(year, month, 1).weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            7,
            (dayIndex) => Expanded(
              child: Padding(
                padding: EdgeInsets.all(cellPadding),
                child: Center(
                  child: Text(
                    dayLabels[dayIndex],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (
              int week = 0;
              week < ((firstDayOfMonth + daysInMonth - 1) / 7).ceil();
              week++
            )
              Row(
                children: List.generate(7, (dayIndex) {
                  final dayOfMonth =
                      (week * 7) + dayIndex - firstDayOfMonth + 1;

                  if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(cellPadding),
                        child: Container(),
                      ),
                    );
                  }

                  final date = DateTime(year, month, dayOfMonth);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(cellPadding),
                      child: _buildDayCell(date, isDark),
                    ),
                  );
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Less activity',
              style: TextStyle(fontSize: 11, color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
            ),
            const SizedBox(width: 12),
            ..._legendColors().map((c) => _buildLegendCell(c, isDark)),
            const SizedBox(width: 12),
            Text(
              'More activity',
              style: TextStyle(fontSize: 11, color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date, bool isDark) {
    final spending = dailyData[date] ?? 0.0;
    final color = _getColorForSpending(spending, isDark);
    final textColor = isDark && spending == 0
        ? Colors.white
        : spending >= 1500
            ? Colors.white
            : (isDark ? Colors.black87 : AppColors.appBarForeground);
    final amountLabel = metric == CalendarMetric.spending
        ? 'spent'
        : 'received';
    final hasActivity = activeDates.contains(date);
    final today = _isToday(date);

    return Tooltip(
      message:
          '${date.day}: ${spending > 0 ? '${_formatDayAmount(spending)} $amountLabel' : 'No activity'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: hasActivity ? () => onDateTap(date) : null,
          child: AspectRatio(
            aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: today
                        ? (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.25))
                        : isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                    width: today ? 2 : 0.5,
                  ),
                ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      if (spending > 0) ...[
                        const SizedBox(height: 1),
                        Text(
                          _formatDayAmount(spending),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDayAmount(double spending) {
    if (spending >= 1000000) {
      return '${(spending / 1000000).toStringAsFixed(1)}M';
    }
    if (spending >= 1000) {
      return '${(spending / 1000).toStringAsFixed(1)}k';
    }
    return spending.toStringAsFixed(0);
  }

  Widget _buildLegendCell(Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}
