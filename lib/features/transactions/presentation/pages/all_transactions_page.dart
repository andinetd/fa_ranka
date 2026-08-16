import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/home/presentation/widgets/transaction_tile.dart';
import 'package:faranka/features/transactions/models/transaction_group.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_data_providers.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_filters_provider.dart';
import 'package:faranka/features/transactions/presentation/widgets/advanced_filters_panel.dart';
import 'package:faranka/features/transactions/presentation/widgets/search_bar_widget.dart';

class AllTransactionsPage extends ConsumerStatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? initialCategory;
  final TransactionDirection? initialDirection;

  const AllTransactionsPage({
    super.key,
    this.startDate,
    this.endDate,
    this.initialCategory,
    this.initialDirection,
  });

  @override
  ConsumerState<AllTransactionsPage> createState() =>
      _AllTransactionsPageState();
}

class _AllTransactionsPageState extends ConsumerState<AllTransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final _searchKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startDate != null) {
        ref.read(startDateProvider.notifier).setValue(widget.startDate);
      }
      if (widget.endDate != null) {
        ref.read(endDateProvider.notifier).setValue(widget.endDate);
      }
      if (widget.initialCategory != null) {
        ref
            .read(categoryFilterProvider.notifier)
            .setValue(widget.initialCategory);
      }
      if (widget.initialDirection != null) {
        ref
            .read(directionFilterProvider.notifier)
            .setValue(widget.initialDirection);
      }
    });
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).setValue(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('All Transactions'),
      ),
      body: SafeArea(
        child: ref
            .watch(transactionDataProvider)
            .when(
              skipLoadingOnRefresh: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: dims.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: dims.icon(48),
                        color: isDark
                            ? DarkAppColors.balanceCardMuted
                            : Colors.grey,
                      ),
                      SizedBox(height: dims.spacingMd),
                      Text(
                        'Could not load transactions',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (txData) {
                if (txData.rows.isEmpty) {
                  return Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: isDark
                            ? DarkAppColors.balanceCardMuted
                            : Colors.grey[600],
                      ),
                    ),
                  );
                }

                final filtered = ref.watch(filteredTransactionViewsProvider);
                final groups = ref.watch(transactionGroupsProvider);
                final bankOptions =
                    ref.watch(bankOptionsProvider).asData?.value ??
                    const ['All banks'];
                final categories =
                    ref.watch(categoryOptionsProvider).asData?.value ??
                    const [];

                return NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: dims.symmetric(h: 12, v: 8),
                            child: Container(
                              key: _searchKey,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                child: SearchBarWidget(
                                  searchController: _searchController,
                                  showAdvancedFilters: ref.watch(
                                    showAdvancedFiltersProvider,
                                  ),
                                  onDismissAdvancedFilters: () {
                                    ref
                                        .read(
                                          showAdvancedFiltersProvider.notifier,
                                        )
                                        .setValue(false);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _FilterChipsRow(
                          count: filtered.length,
                          isDark: isDark,
                        ),
                      ),
                      if (ref.watch(showAdvancedFiltersProvider))
                        SliverToBoxAdapter(
                          child: AdvancedFiltersPanel(
                            bankOptions: bankOptions,
                            categories: categories,
                            minAmountController: _minAmountController,
                            maxAmountController: _maxAmountController,
                            onResetAll: () {
                              _searchController.clear();
                              ref
                                  .read(searchQueryProvider.notifier)
                                  .setValue('');
                              ref
                                  .read(directionFilterProvider.notifier)
                                  .setValue(null);
                              ref
                                  .read(categoryFilterProvider.notifier)
                                  .setValue(null);
                            },
                          ),
                        ),
                      if (txData.hasSplitError)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: dims.fromLTRB(12, 0, 12, 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: dims.icon(12),
                                  color: isDark
                                      ? DarkAppColors.balanceCardMuted
                                      : Colors.grey,
                                ),
                                SizedBox(width: dims(4)),
                                Text(
                                  'Split data unavailable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? DarkAppColors.balanceCardMuted
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (groups.isEmpty)
                        SliverFillRemaining(
                          child: _EmptyStateWidget(
                            directionFilter: ref.watch(directionFilterProvider),
                            categoryFilter: ref.watch(categoryFilterProvider),
                            bankFilter: ref.watch(bankFilterProvider),
                            searchQuery: ref.watch(searchQueryProvider),
                            minAmount: ref.watch(minAmountProvider),
                            maxAmount: ref.watch(maxAmountProvider),
                            startDate: ref.watch(startDateProvider),
                            endDate: ref.watch(endDateProvider),
                            sortBy: ref.watch(sortByProvider),
                            isDark: isDark,
                            dims: dims,
                            onClearAll: () {
                              _searchController.clear();
                              _minAmountController.clear();
                              _maxAmountController.clear();
                              ref
                                  .read(searchQueryProvider.notifier)
                                  .setValue('');
                              ref
                                  .read(directionFilterProvider.notifier)
                                  .setValue(null);
                              ref
                                  .read(categoryFilterProvider.notifier)
                                  .setValue(null);
                              ref
                                  .read(bankFilterProvider.notifier)
                                  .setValue('All banks');
                              ref
                                  .read(sortByProvider.notifier)
                                  .setValue(TransactionSort.newest);
                              ref
                                  .read(startDateProvider.notifier)
                                  .setValue(null);
                              ref.read(endDateProvider.notifier).setValue(null);
                              ref
                                  .read(minAmountProvider.notifier)
                                  .setValue(null);
                              ref
                                  .read(maxAmountProvider.notifier)
                                  .setValue(null);
                            },
                          ),
                        )
                      else ...[
                        for (final group in groups)
                          _TransactionGroupSliver(
                            group: group,
                            isDark: isDark,
                            dims: dims,
                          ),
                        SliverToBoxAdapter(child: SizedBox(height: dims(16))),
                      ],
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }

  /// Loads the next page when the user nears the bottom of the list, but only
  /// while the DB is still returning a full page (i.e. more may exist).
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.metrics.pixels <
        notification.metrics.maxScrollExtent - 600) {
      return false;
    }
    final rows = ref.read(transactionDataProvider).value?.rows.length ?? 0;
    final pageLimit = ref.read(transactionsPageLimitProvider);
    if (rows >= pageLimit) {
      ref.read(transactionsPageLimitProvider.notifier).loadMore();
    }
    return false;
  }
}

class _FilterChipsRow extends ConsumerStatefulWidget {
  final int count;
  final bool isDark;

  const _FilterChipsRow({required this.count, required this.isDark});

  @override
  ConsumerState<_FilterChipsRow> createState() => _FilterChipsRowState();
}

class _FilterChipsRowState extends ConsumerState<_FilterChipsRow> {
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
                _FilterChip(
                  label: categoryFilter,
                  isDark: widget.isDark,
                  dims: dims,
                  onClear: () =>
                      ref.read(categoryFilterProvider.notifier).setValue(null),
                ),
              ],
              SizedBox(width: dims.spacingSm),
              _AdvancedFilterToggleButton(),
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

class _AdvancedFilterToggleButton extends ConsumerWidget {
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

class _EmptyStateWidget extends StatelessWidget {
  final TransactionDirection? directionFilter;
  final String? categoryFilter;
  final String bankFilter;
  final String searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionSort sortBy;
  final bool isDark;
  final AppDimensions dims;
  final VoidCallback onClearAll;

  const _EmptyStateWidget({
    required this.directionFilter,
    required this.categoryFilter,
    required this.bankFilter,
    required this.searchQuery,
    required this.minAmount,
    required this.maxAmount,
    required this.startDate,
    required this.endDate,
    required this.sortBy,
    required this.isDark,
    required this.dims,
    required this.onClearAll,
  });

  bool get _hasActiveFilters {
    if (directionFilter != null) return true;
    if (categoryFilter != null) return true;
    if (bankFilter != 'All banks') return true;
    if (searchQuery.isNotEmpty) return true;
    if (minAmount != null || maxAmount != null) return true;
    if (startDate != null || endDate != null) return true;
    if (sortBy != TransactionSort.newest) return true;
    return false;
  }

  String _directionLabel(TransactionDirection d) {
    switch (d) {
      case TransactionDirection.debit:
        return 'Sent';
      case TransactionDirection.credit:
        return 'Received';
      case TransactionDirection.unknown:
        return 'Unknown';
    }
  }

  String _sortLabel(TransactionSort s) {
    switch (s) {
      case TransactionSort.newest:
        return 'Newest';
      case TransactionSort.oldest:
        return 'Oldest';
      case TransactionSort.amountHigh:
        return 'Amount (High)';
      case TransactionSort.amountLow:
        return 'Amount (Low)';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActiveFilters) {
      return Center(
        child: Text(
          'No transactions found',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? DarkAppColors.balanceCardMuted : Colors.grey[600],
          ),
        ),
      );
    }

    final lines = <String>[];
    if (directionFilter != null) {
      lines.add('Direction: ${_directionLabel(directionFilter!)}');
    }
    if (categoryFilter != null) {
      lines.add('Category: $categoryFilter');
    }
    if (searchQuery.isNotEmpty) {
      lines.add('Search: "$searchQuery"');
    }
    if (bankFilter != 'All banks') {
      lines.add('Bank: $bankFilter');
    }
    if (minAmount != null && maxAmount != null) {
      lines.add(
        'Amount: ${minAmount!.toStringAsFixed(0)} - ${maxAmount!.toStringAsFixed(0)}',
      );
    } else if (minAmount != null) {
      lines.add('Min amount: ${minAmount!.toStringAsFixed(0)}');
    } else if (maxAmount != null) {
      lines.add('Max amount: ${maxAmount!.toStringAsFixed(0)}');
    }
    if (startDate != null && endDate != null) {
      lines.add(
        'Date: ${startDate!.day}/${startDate!.month} - ${endDate!.day}/${endDate!.month}',
      );
    } else if (startDate != null) {
      lines.add('From: ${startDate!.day}/${startDate!.month}');
    } else if (endDate != null) {
      lines.add('To: ${endDate!.day}/${endDate!.month}');
    }
    if (sortBy != TransactionSort.newest) {
      lines.add('Sort: ${_sortLabel(sortBy)}');
    }

    return Center(
      child: Padding(
        padding: dims.symmetric(h: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: dims.icon(40),
              color: isDark ? DarkAppColors.balanceCardMuted : Colors.grey[400],
            ),
            SizedBox(height: dims.spacingMd),
            Text(
              'No transactions match your filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              ),
            ),
            SizedBox(height: dims.spacingSm),
            ...lines.map(
              (line) => Padding(
                padding: dims.only(b: 4),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? DarkAppColors.balanceCardMuted
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            SizedBox(height: dims.spacingMd),
            OutlinedButton.icon(
              onPressed: onClearAll,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear all filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final AppDimensions dims;
  final VoidCallback onClear;

  const _FilterChip({
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

/// A date-group of transactions rendered as a lazy, virtualized sliver group
/// with a pinned header. Guarantees tiles are built/disposed per-viewport item
/// instead of laying out an entire bucket's `Column` at once, which is what
/// made scrolling through large groups stutter.
class _TransactionGroupSliver extends StatelessWidget {
  final TransactionRelativeGroup group;
  final bool isDark;
  final AppDimensions dims;

  const _TransactionGroupSliver({
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
          delegate: _DateGroupHeaderDelegate(
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

class _DateGroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DateGroupHeaderDelegate({
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
  bool shouldRebuild(covariant _DateGroupHeaderDelegate oldDelegate) =>
      oldDelegate.label != label || oldDelegate.isDark != isDark;
}
