import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/widgets/sensitive_text.dart';

import 'package:faranka/database/database.dart';
import 'home_types.dart';

class CategoryBreakdownSection extends ConsumerStatefulWidget {
  const CategoryBreakdownSection({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onCategoryTap,
    this.onSeeAllTap,
  });

  final CategoryFilterPeriod selectedPeriod;
  final ValueChanged<CategoryFilterPeriod> onPeriodChanged;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback? onSeeAllTap;

  @override
  ConsumerState<CategoryBreakdownSection> createState() =>
      _CategoryBreakdownSectionState();
}

class _CategoryBreakdownSectionState extends ConsumerState<CategoryBreakdownSection> {
  int _getDaysForPeriod(CategoryFilterPeriod period) {
    switch (period) {
      case CategoryFilterPeriod.oneWeek:
        return 7;
      case CategoryFilterPeriod.oneMonth:
        return 30;
      case CategoryFilterPeriod.threeMonths:
        return 90;
      case CategoryFilterPeriod.oneYear:
        return 365;
      case CategoryFilterPeriod.all:
        return 36500;
    }
  }

  String _periodLabel(CategoryFilterPeriod period) {
    switch (period) {
      case CategoryFilterPeriod.oneWeek:
        return 'this week';
      case CategoryFilterPeriod.oneMonth:
        return 'last 30 days';
      case CategoryFilterPeriod.threeMonths:
        return 'last 3 months';
      case CategoryFilterPeriod.oneYear:
        return 'this year';
      case CategoryFilterPeriod.all:
        return 'all time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final db = ref.watch(databaseProvider);
    return StreamBuilder<List<CategorySum>>(
      stream: db.watchCategorySummaryAllParsed(
        days: _getDaysForPeriod(widget.selectedPeriod),
        direction: TransactionDirection.debit,
      ),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        final displayedCategories = List<CategorySum>.from(data)
          ..sort((a, b) => b.total.compareTo(a.total));
        final categoryList = displayedCategories.take(5).toList();
        final othersTotal = displayedCategories.skip(5).fold<double>(
          0.0,
          (sum, cat) => sum + cat.total,
        );
        if (othersTotal > 0) {
          categoryList.add(CategorySum(name: 'All Others', total: othersTotal, count: 0));
        }
        final totalSpending = data.fold<double>(
          0.0,
          (sum, cat) => sum + cat.total,
        );
        final wholeNumber = NumberFormat('#,###');
        final cardBg = isDark ? DarkAppColors.homeCardBackground : Colors.white;
        final textColor = isDark ? DarkAppColors.appBarForeground : Colors.black87;
        final textColorStrong = isDark ? DarkAppColors.appBarForeground : Colors.black;

        return Container(
          margin: dims.symmetric(h: 14, v: 6),
          padding: dims.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (tappable to see all / open categories)
              InkWell(
                onTap: widget.onSeeAllTap,
                child: Row(
                  children: [
                    _buildGeometricIcon(textColorStrong, dims),
                    SizedBox(width: dims(12)),
                    Text(
                      'spending breakdown',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: textColorStrong, size: dims.icon(20)),
                  ],
                ),
              ),
              SizedBox(height: dims(14)),
              // Total Amount with lowercase etb
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SensitiveText(
                    wholeNumber.format(totalSpending),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: textColorStrong,
                    ),
                  ),
                  Text(
                    'etb',
                    style: TextStyle(fontSize: 14, color: textColorStrong),
                  ),
                ],
              ),
              SizedBox(height: dims(4)),
              Text(
                _periodLabel(widget.selectedPeriod),
                style: TextStyle(fontSize: 13, color: textColorStrong.withValues(alpha: 0.55)),
              ),
              SizedBox(height: dims(10)),
              // Hatched pill bar
              _HatchedPillBar(
                data: categoryList,
                total: totalSpending,
                isDark: isDark,
              ),
              SizedBox(height: dims(14)),
              // Category List
              ...categoryList.asMap().entries.map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final palette = isDark
                    ? DarkAppColors.homeCategoryPalette
                    : AppColors.homeCategoryPalette;
                final color = palette[i % palette.length];
                return _CategoryRow(
                  name: cat.name,
                  amount: cat.total.toInt().toString(),
                  color: color,
                  onTap: cat.name == 'All Others'
                      ? null
                      : () => widget.onCategoryTap(cat.name),
                  dims: dims,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeometricIcon(Color color, AppDimensions dims) {
    return Column(
      children: [
        Icon(Icons.change_history, size: dims.icon(12), color: color),
        Row(
          children: [
            Container(width: 6, height: 6, color: color),
            SizedBox(width: dims(2)),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  final String name;
  final String amount;
  final Color color;
  final VoidCallback? onTap;
  final AppDimensions dims;

  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.color,
    this.onTap,
    required this.dims,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final textColor = isDark ? DarkAppColors.appBarForeground : Colors.black87;
    final isMuted = onTap == null;
    final effectiveTextColor = isMuted
        ? textColor.withValues(alpha: 0.5)
        : textColor;
    return Padding(
      padding: dims.symmetric(v: 5),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: dims(8)),
            Text(name, style: TextStyle(fontSize: 15, color: effectiveTextColor)),
            const Spacer(),
            SensitiveText(amount, style: TextStyle(fontSize: 15, color: effectiveTextColor)),
          ],
        ),
      ),
    );
  }
}

class _HatchedPillBar extends StatelessWidget {
  final List<CategorySum> data;
  final double total;
  final bool isDark;

  const _HatchedPillBar({required this.data, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (total <= 0 || data.isEmpty) return const SizedBox.shrink();

    final palette = isDark
        ? DarkAppColors.homeCategoryPalette
        : AppColors.homeCategoryPalette;
    final pills = <Widget>[];
    for (int i = 0; i < data.length; i++) {
      if (i > 0) pills.add(const SizedBox(width: 3));
      final color = palette[i % palette.length];
      final flex = (data[i].total / total * 100).round().clamp(1, 100);
      pills.add(
        Expanded(
          flex: flex,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: CustomPaint(
              painter: _HatchPainter(),
              child: Container(color: color),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 20,
      child: Row(children: pills),
    );
  }
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;

    // Draw diagonal lines from bottom-left to top-right (45°)
    const spacing = 4.0;
    final endX = size.width + size.height;

    for (double start = -size.height; start <= endX; start += spacing) {
      canvas.drawLine(
        Offset(start, size.height),
        Offset(start + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
