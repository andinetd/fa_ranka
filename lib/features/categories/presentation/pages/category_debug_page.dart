import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';
import 'package:faranka/features/categories/presentation/widgets/category_card.dart';
import 'package:faranka/features/categories/presentation/widgets/category_filter_card.dart';

export 'package:faranka/features/categories/presentation/widgets/category_filter_card.dart'
    show CategorySortBy;

List<CategorySum> prepareCategorySummaries(
  List<CategorySum> categories, {
  required CategorySortBy sortBy,
}) {
  final sorted = List<CategorySum>.from(categories);
  switch (sortBy) {
    case CategorySortBy.nameAsc:
      sorted.sort((a, b) => a.name.compareTo(b.name));
      break;
    case CategorySortBy.nameDesc:
      sorted.sort((a, b) => b.name.compareTo(a.name));
      break;
    case CategorySortBy.countDesc:
      sorted.sort((a, b) => b.count - a.count);
      break;
    case CategorySortBy.countAsc:
      sorted.sort((a, b) => a.count - b.count);
      break;
    case CategorySortBy.amountDesc:
      sorted.sort((a, b) => b.total.compareTo(a.total));
      break;
    case CategorySortBy.amountAsc:
      sorted.sort((a, b) => a.total.compareTo(b.total));
      break;
  }
  return sorted;
}

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  TransactionDirection? selectedDirection = TransactionDirection.debit;
  CategoryFilterPeriod selectedPeriod = CategoryFilterPeriod.oneMonth;
  BankBalanceFilter selectedBankFilter = BankBalanceFilter.all;
  String searchQuery = '';
  CategorySortBy sortBy = CategorySortBy.countDesc;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isCustomPeriod = false;

  int _daysForPeriod(CategoryFilterPeriod period) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    return Scaffold(
      backgroundColor: isDark
          ? DarkAppColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? DarkAppColors.homeCardBackground : Colors.white,
        foregroundColor: isDark
            ? DarkAppColors.appBarForeground
            : AppColors.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 2,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text(
          'Categories',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: dims.fromLTRB(14, 12, 14, 4),
            child: CategoryFilterCard(
              selectedDirection: selectedDirection,
              onDirectionChanged: (dir) =>
                  setState(() => selectedDirection = dir),
              selectedPeriod: selectedPeriod,
              onPeriodChanged: (p) => setState(() => selectedPeriod = p),
              selectedBankFilter: selectedBankFilter,
              onBankFilterChanged: (b) =>
                  setState(() => selectedBankFilter = b),
              searchQuery: searchQuery,
              onSearchChanged: (q) => setState(() => searchQuery = q),
              sortBy: sortBy,
              onSortChanged: (s) => setState(() => sortBy = s),
              customStartDate: _customStartDate,
              customEndDate: _customEndDate,
              isCustomPeriod: _isCustomPeriod,
              onDateRangeChanged: (start, end, isCustom) {
                setState(() {
                  _customStartDate = start;
                  _customEndDate = end;
                  _isCustomPeriod = isCustom;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CategorySum>>(
              stream: ref.watch(databaseProvider).watchCategorySummaryAllParsed(
                direction: selectedDirection,
                days: _isCustomPeriod ? null : _daysForPeriod(selectedPeriod),
                bankFilter: selectedBankFilter.dbFilter,
                startTimestamp: _isCustomPeriod
                    ? _customStartDate?.millisecondsSinceEpoch
                    : null,
                endTimestamp: _isCustomPeriod
                    ? _customEndDate?.millisecondsSinceEpoch
                    : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: dims.icon(48),
                            color: isDark
                                ? DarkAppColors.balanceCardMuted
                                : AppColors.balanceCardMuted,
                          ),
                          SizedBox(height: dims.spacingMd),
                          Text(
                            'Could not load categories',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? DarkAppColors.balanceCardMuted
                                  : AppColors.balanceCardMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                var categories = snapshot.data ?? const [];

                // Filter by search query
                if (searchQuery.isNotEmpty) {
                  categories = categories
                      .where((cat) => cat.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                      .toList();
                }

                // Sort categories
                categories = prepareCategorySummaries(
                  categories,
                  sortBy: sortBy,
                );

                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: dims.icon(64),
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                                  .withValues(alpha: 0.5)
                              : AppColors.balanceCardMuted
                                  .withValues(alpha: 0.5),
                        ),
                        SizedBox(height: dims.spacingMd),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No categories match'
                              : 'No categories yet',
                          style: TextStyle(
                            color: isDark
                                ? DarkAppColors.balanceCardMuted
                                : AppColors.balanceCardMuted,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: dims.spacingSm),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Import messages to see categories',
                          style: TextStyle(
                            color: isDark
                                ? DarkAppColors.balanceCardMuted
                                : AppColors.balanceCardMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: dims.fromLTRB(14, 8, 14, 18),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: dims(10)),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryCard(
                      name: category.name,
                      count: category.count,
                      amount: category.total,
                      onTap: () => context.push(
                        '/category/${Uri.encodeComponent(category.name)}?direction=${selectedDirection?.index ?? 0}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
