import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

enum CategorySortBy { nameAsc, nameDesc, countDesc, countAsc, amountDesc, amountAsc }

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

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  TransactionDirection? selectedDirection = TransactionDirection.debit;
  CategoryFilterPeriod selectedPeriod = CategoryFilterPeriod.oneMonth;
  BankBalanceFilter selectedBankFilter = BankBalanceFilter.all;
  String searchQuery = '';
  CategorySortBy sortBy = CategorySortBy.countDesc;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isCustomPeriod = false;
  bool _showFilters = false;


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

  String _periodLabel(CategoryFilterPeriod period) {
    switch (period) {
      case CategoryFilterPeriod.oneWeek:
        return '1W';
      case CategoryFilterPeriod.oneMonth:
        return '1M';
      case CategoryFilterPeriod.threeMonths:
        return '3M';
      case CategoryFilterPeriod.oneYear:
        return '1Y';
      case CategoryFilterPeriod.all:
        return 'ALL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        foregroundColor: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
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
            child: _buildFilterCard(dims, calMode),
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
                          Icon(Icons.error_outline, size: dims.icon(48),
                              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
                          SizedBox(height: dims.spacingMd),
                          Text('Could not load categories',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
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
                          color: isDark ? DarkAppColors.balanceCardMuted.withValues(alpha: 0.5) : AppColors.balanceCardMuted.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: dims.spacingMd),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No categories match'
                              : 'No categories yet',
                          style: TextStyle(
                            color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: dims.spacingSm),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Import messages to see categories',
                          style: TextStyle(color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted, fontSize: 14),
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
                    return _CategoryCard(
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

  Widget _buildFilterCard(AppDimensions dims, CalendarMode calMode) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: dims.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  ),
                ),
                Spacer(),
                Icon(
                  _showFilters ? Icons.expand_less : Icons.expand_more,
                  size: dims.icon(18),
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _showFilters
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: dims.spacingSm),
                      _buildSearchField(dims),
                      SizedBox(height: dims(10)),
                      Row(
                        children: [
                          Expanded(child: _buildDirectionSelector(dims)),
                          SizedBox(width: dims.spacingSm),
                          _buildSortDropdown(dims),
                        ],
                      ),
                      SizedBox(height: dims(10)),
                      Row(
                        children: [
                          Expanded(child: _buildPeriodSelector(dims)),
                          SizedBox(width: dims.spacingSm),
                          _buildBankPicker(dims),
                        ],
                      ),
                      SizedBox(height: dims(8)),
                      if (_isCustomPeriod)
                        _buildDateRangeRow(dims, calMode)
                      else
                        _buildCustomRangeButton(dims),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppDimensions dims) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search categories...',
          hintStyle: TextStyle(
            color: (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted).withValues(alpha: 0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: dims.icon(18),
            color: (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted).withValues(alpha: 0.6),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: dims.icon(18),
                    color: (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted).withValues(alpha: 0.6),
                  ),
                  onPressed: () => setState(() => searchQuery = ''),
              )
              : null,
          border: InputBorder.none,
          contentPadding: dims.symmetric(v: 10),
        ),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
        ),
      ),
    );
  }

  Widget _buildSortDropdown(AppDimensions dims) {
    final isDark = AppColors.isDark(context);
    return PopupMenuButton<CategorySortBy>(
      onSelected: (value) => setState(() => sortBy = value),
      tooltip: 'Sort',
      color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      itemBuilder: (context) => [
        PopupMenuItem<CategorySortBy>(
          value: CategorySortBy.countDesc,
          child: Text(
            'Count (High)',
            style: TextStyle(
              fontWeight: sortBy == CategorySortBy.countDesc
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
            ),
          ),
        ),
        PopupMenuItem<CategorySortBy>(
          value: CategorySortBy.countAsc,
          child: Text(
            'Count (Low)',
            style: TextStyle(
              fontWeight: sortBy == CategorySortBy.countAsc
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
            ),
          ),
        ),
        PopupMenuItem<CategorySortBy>(
          value: CategorySortBy.nameAsc,
          child: Text(
            'Name (A-Z)',
            style: TextStyle(
              fontWeight: sortBy == CategorySortBy.nameAsc
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
            ),
          ),
        ),
        PopupMenuItem<CategorySortBy>(
          value: CategorySortBy.nameDesc,
          child: Text(
            'Name (Z-A)',
            style: TextStyle(
              fontWeight: sortBy == CategorySortBy.nameDesc
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
            ),
          ),
        ),
        PopupMenuItem<CategorySortBy>(
          value: CategorySortBy.amountDesc,
          child: Text(
            'Amount (High)',
            style: TextStyle(
              fontWeight: sortBy == CategorySortBy.amountDesc
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
            ),
          ),
        ),
        PopupMenuItem<CategorySortBy>(
          value: CategorySortBy.amountAsc,
          child: Text(
            'Amount (Low)',
            style: TextStyle(
              fontWeight: sortBy == CategorySortBy.amountAsc
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
            ),
          ),
        ),
      ],
      child: Container(
        padding: dims.symmetric(h: 8, v: 8),
        decoration: BoxDecoration(
          color: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: dims.icon(14),
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
            Icon(
              Icons.unfold_more,
              size: dims.icon(12),
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionSelector(AppDimensions dims) {
    return Row(
      children: [
        Expanded(
          child: _buildDirectionChip(
            label: 'Spending',
            active: selectedDirection == TransactionDirection.debit,
            onTap: () => setState(
              () => selectedDirection = TransactionDirection.debit,
            ),
            dims: dims,
          ),
        ),
        SizedBox(width: dims.spacingSm),
        Expanded(
          child: _buildDirectionChip(
            label: 'Income',
            active: selectedDirection == TransactionDirection.credit,
            onTap: () => setState(
              () => selectedDirection = TransactionDirection.credit,
            ),
            dims: dims,
          ),
        ),
        SizedBox(width: dims.spacingSm),
        Expanded(
          child: _buildDirectionChip(
            label: 'Unknown',
            active: selectedDirection == TransactionDirection.unknown,
            onTap: () => setState(
              () => selectedDirection = TransactionDirection.unknown,
            ),
            dims: dims,
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required AppDimensions dims,
  }) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: dims.symmetric(h: 10, v: 8),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? DarkAppColors.balanceCardChipBackground : AppColors.balanceCardChipBackground)
              : (isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? (isDark ? DarkAppColors.balanceCardForeground.withValues(alpha: 0.6) : AppColors.balanceCardForeground.withValues(alpha: 0.6))
                : (isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: active
                ? (isDark ? DarkAppColors.balanceCardForeground : AppColors.balanceCardForeground)
                : (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AppDimensions dims) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...CategoryFilterPeriod.values.map((period) {
            final isSelected = selectedPeriod == period && !_isCustomPeriod;
            return Padding(
              padding: dims.only(r: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => setState(() {
                  selectedPeriod = period;
                  _isCustomPeriod = false;
                }),
                child: _periodChip(label: _periodLabel(period), isSelected: isSelected, dims: dims),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _periodChip({required String label, required bool isSelected, required AppDimensions dims}) {
    final isDark = AppColors.isDark(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: dims.symmetric(h: 10, v: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? DarkAppColors.balanceCardChipBackground : AppColors.balanceCardChipBackground)
            : (isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? (isDark ? DarkAppColors.balanceCardForeground.withValues(alpha: 0.6) : AppColors.balanceCardForeground.withValues(alpha: 0.6))
              : (isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder),
          width: 1,
        ),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isSelected
              ? (isDark ? DarkAppColors.balanceCardForeground : AppColors.balanceCardForeground)
              : (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
        ),
      ),
    );
  }

  Widget _buildDateRangeRow(AppDimensions dims, CalendarMode calMode) {
    final isDark = AppColors.isDark(context);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(true, dims),
            child: Container(
              padding: dims.symmetric(h: 12, v: 10),
              decoration: BoxDecoration(
                color: isDark ? DarkAppColors.balanceCardChipBackground : Colors.transparent,
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey[200]!,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: dims.icon(16),
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                  ),
                  SizedBox(width: dims.spacingSm),
                  Expanded(
                    child: Text(
                      _customStartDate == null
                          ? 'From'
                          : _customStartDate!.fmt('MMM dd', calMode),
                      style: TextStyle(
                        fontSize: 12,
                        color: _customStartDate == null
                            ? (isDark ? Colors.grey.shade500 : Colors.grey[400])
                            : (isDark ? DarkAppColors.appBarForeground : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: dims(8)),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(false, dims),
            child: Container(
              padding: dims.symmetric(h: 12, v: 10),
              decoration: BoxDecoration(
                color: isDark ? DarkAppColors.balanceCardChipBackground : Colors.transparent,
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey[200]!,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: dims.icon(16),
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                  ),
                  SizedBox(width: dims.spacingSm),
                  Expanded(
                    child: Text(
                      _customEndDate == null
                          ? 'To'
                          : _customEndDate!.fmt('MMM dd', calMode),
                      style: TextStyle(
                        fontSize: 12,
                        color: _customEndDate == null
                            ? (isDark ? Colors.grey.shade500 : Colors.grey[400])
                            : (isDark ? DarkAppColors.appBarForeground : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: dims(8)),
        GestureDetector(
          onTap: () => setState(() {
            _customStartDate = null;
            _customEndDate = null;
            _isCustomPeriod = false;
          }),
          child: Container(
            padding: dims.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.close,
              size: dims.icon(16),
              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(bool isStart, AppDimensions dims) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_customStartDate ?? DateTime.now())
          : (_customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _customStartDate = date;
        } else {
          _customEndDate = date;
        }
        _isCustomPeriod = true;
      });
    }
  }

  Widget _buildCustomRangeButton(AppDimensions dims) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: () {
        _customStartDate = DateTime.now().subtract(const Duration(days: 30));
        _customEndDate = DateTime.now();
        setState(() => _isCustomPeriod = true);
      },
      child: Container(
        padding: dims.symmetric(h: 12, v: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: dims.icon(16),
              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
            ),
            SizedBox(width: dims(6)),
            Text(
              'Custom range',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankPicker(AppDimensions dims) {
    final isDark = AppColors.isDark(context);
    return PopupMenuButton<BankBalanceFilter>(
      onSelected: (bank) => setState(() => selectedBankFilter = bank),
      tooltip: 'Select bank',
      color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      itemBuilder: (context) => BankBalanceFilter.values.map((bank) {
        final isSelected = bank == selectedBankFilter;
        return PopupMenuItem<BankBalanceFilter>(
          value: bank,
          child: Text(
            bank.label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: dims.symmetric(h: 10, v: 8),
        decoration: BoxDecoration(
          color: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedBankFilter.label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
              ),
            ),
            SizedBox(width: dims(6)),
            Icon(
              Icons.unfold_more,
              size: dims.icon(16),
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final String name;
  final int count;
  final double amount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.count,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dims = ref.watch(dimensionsProvider);
    final isDark = AppColors.isDark(context);
    return Material(
      color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: dims.symmetric(h: 12, v: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
              width: 1,
            ),
            boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                      ),
                    ),
                    SizedBox(height: dims(2)),
                    Builder(builder: (context) {
                      final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
                      final fmt = useCompact
                          ? NumberFormat.compactCurrency(symbol: 'ETB ')
                          : NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
                      final formatted = fmt.format(amount);
                      return Text(
                        '$formatted • $count messages',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  size: dims.icon(18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
