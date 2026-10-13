import 'package:flutter/material.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/features/home/presentation/widgets/transaction_tile.dart';
import 'package:faranka/features/transactions/models/transaction_group.dart';

/// A date-group of transactions rendered as a lazy, virtualized sliver group
/// with a pinned header. Guarantees tiles are built/disposed per-viewport item
/// instead of laying out an entire bucket's `Column` at once, which is what
/// made scrolling through large groups stutter.
class TransactionGroupSliver extends StatelessWidget {
  final TransactionRelativeGroup group;
  final bool isDark;
  final AppDimensions dims;

  const TransactionGroupSliver({
    super.key,
    required this.group,
    required this.isDark,
    required this.dims,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: DateGroupHeaderDelegate(
            label: group.label,
            isDark: isDark,
            dims: dims,
          ),
        ),
        SliverList.builder(
          itemCount: group.rows.length,
          itemBuilder: (context, index) {
            final view = group.rows[index];
            return RepaintBoundary(
              key: ValueKey<int>(view.id),
              child: Padding(
                padding: dims.symmetric(h: 16),
                child: TransactionTile.forView(view, bottomMargin: 4),
              ),
            );
          },
        ),
      ],
    );
  }
}

class DateGroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  DateGroupHeaderDelegate({
    required this.label,
    required this.isDark,
    required this.dims,
  });

  final String label;
  final bool isDark;
  final AppDimensions dims;

  @override
  double get minExtent => 28 * dims.spacingScale;

  @override
  double get maxExtent => 28 * dims.spacingScale;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: dims.only(l: 20, t: 5, b: 5),
      color: isDark
          ? DarkAppColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant DateGroupHeaderDelegate oldDelegate) =>
      oldDelegate.label != label || oldDelegate.isDark != isDark;
}
