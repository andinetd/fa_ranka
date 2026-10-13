import 'package:faranka/features/transactions/presentation/widgets/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_filters_provider.dart';

class TransactionsFilterChipsRow extends ConsumerStatefulWidget {
  final int count;
  final bool isDark;

  const TransactionsFilterChipsRow({
    super.key,
    required this.count,
    required this.isDark,
  });

  @override
  ConsumerState<TransactionsFilterChipsRow> createState() =>
      _TransactionsFilterChipsRowState();
}

class _TransactionsFilterChipsRowState
    extends ConsumerState<TransactionsFilterChipsRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dims = ref.watch(dimensionsProvider);
    final directionFilter = ref.watch(directionFilterProvider);
    final categoryFilter = ref.watch(categoryFilterProvider);
    final countText =
        '${widget.count} transaction${widget.count == 1 ? '' : 's'}';
    return Padding(
      padding: dims.fromLTRB(12, 0, 12, 8),
      child: Scrollbar(
        thumbVisibility: true,
        controller: _scrollController,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FilterChipWidget(
                label: 'All',
                selected: directionFilter == null,
                onTap: () =>
                    ref.read(directionFilterProvider.notifier).setValue(null),
              ),
              SizedBox(width: dims.spacingSm),
              FilterChipWidget(
                label: 'Sent',
                selected: directionFilter == TransactionDirection.debit,
                onTap: () => ref
                    .read(directionFilterProvider.notifier)
                    .setValue(TransactionDirection.debit),
              ),
              SizedBox(width: dims.spacingSm),
              FilterChipWidget(
                label: 'Received',
                selected: directionFilter == TransactionDirection.credit,
                onTap: () => ref
                    .read(directionFilterProvider.notifier)
                    .setValue(TransactionDirection.credit),
              ),
              if (categoryFilter != null) ...[
                SizedBox(width: dims.spacingSm),
                TransactionsCategoryFilterChip(
                  label: categoryFilter,
                  isDark: widget.isDark,
                  dims: dims,
                  onClear: () =>
                      ref.read(categoryFilterProvider.notifier).setValue(null),
                ),
              ],
              SizedBox(width: dims.spacingSm),
              const AdvancedFilterToggleButton(),
              SizedBox(width: dims.spacingMd),
              Text(
                countText,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark
                      ? DarkAppColors.balanceCardMuted
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdvancedFilterToggleButton extends ConsumerWidget {
  const AdvancedFilterToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final show = ref.watch(showAdvancedFiltersProvider);
    final bank = ref.watch(bankFilterProvider);
    final sort = ref.watch(sortByProvider);
    final start = ref.watch(startDateProvider);
    final end = ref.watch(endDateProvider);
    final minAmount = ref.watch(minAmountProvider);
    final maxAmount = ref.watch(maxAmountProvider);
    final category = ref.watch(categoryFilterProvider);

    var activeCount = 0;
    if (bank != 'All banks') activeCount++;
    if (sort != TransactionSort.newest) activeCount++;
    if (start != null || end != null) activeCount++;
    if (minAmount != null || maxAmount != null) activeCount++;
    if (category != null) activeCount++;

    return GestureDetector(
      onTap: () =>
          ref.read(showAdvancedFiltersProvider.notifier).setValue(!show),
      child: Container(
        padding: dims.symmetric(h: 10, v: 6),
        decoration: BoxDecoration(
          color: show
              ? Colors.blue.withValues(alpha: 0.15)
              : (isDark ? DarkAppColors.homeCardBackground : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: show
              ? Colors.blue
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: dims.icon(14),
              color: show
                  ? Colors.blue
                  : (isDark ? DarkAppColors.appBarForeground : Colors.black87),
            ),
            SizedBox(width: dims(6)),
            Text(
              activeCount > 0 ? 'Filters ($activeCount)' : 'Filters',
              style: TextStyle(
                color: show
                    ? Colors.blue
                    : (isDark
                          ? DarkAppColors.appBarForeground
                          : Colors.black87),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionsCategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final AppDimensions dims;
  final VoidCallback onClear;

  const TransactionsCategoryFilterChip({
    super.key,
    required this.label,
    required this.isDark,
    required this.dims,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: dims.symmetric(h: 4, v: 6),
      decoration: BoxDecoration(
        color: isDark
            ? DarkAppColors.balanceCardChipBackground
            : AppColors.balanceCardChipBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? DarkAppColors.balanceCardChipBorder
              : AppColors.balanceCardChipBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: dims.only(l: 4),
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? DarkAppColors.balanceCardForeground
                    : AppColors.balanceCardForeground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: dims(2)),
          GestureDetector(
            onTap: onClear,
            child: Padding(
              padding: dims.all(4),
              child: Icon(
                Icons.close,
                size: dims.icon(14),
                color: isDark
                    ? DarkAppColors.balanceCardForeground
                    : AppColors.balanceCardForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
