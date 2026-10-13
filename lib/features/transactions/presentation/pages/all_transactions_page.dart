import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_data_providers.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_filters_provider.dart';
import 'package:faranka/features/transactions/presentation/widgets/advanced_filters_panel.dart';
import 'package:faranka/features/transactions/presentation/widgets/search_bar_widget.dart';

import '../widgets/transactions_filter_chips_row.dart';
import '../widgets/transactions_empty_state.dart';
import '../widgets/transaction_group_sliver.dart';
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
                        child: TransactionsFilterChipsRow(
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
                          child: TransactionsEmptyState(
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
                          TransactionGroupSliver(
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

