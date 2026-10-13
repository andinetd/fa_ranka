import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';

enum CategorySortBy {
  nameAsc,
  nameDesc,
  countDesc,
  countAsc,
  amountDesc,
  amountAsc,
}

class CategoryFilterCard extends ConsumerStatefulWidget {
  final TransactionDirection? selectedDirection;
  final ValueChanged<TransactionDirection?> onDirectionChanged;
  final CategoryFilterPeriod selectedPeriod;
  final ValueChanged<CategoryFilterPeriod> onPeriodChanged;
  final BankBalanceFilter selectedBankFilter;
  final ValueChanged<BankBalanceFilter> onBankFilterChanged;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final CategorySortBy sortBy;
  final ValueChanged<CategorySortBy> onSortChanged;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool isCustomPeriod;
  final void Function(DateTime? start, DateTime? end, bool isCustom)
  onDateRangeChanged;

  const CategoryFilterCard({
    super.key,
    required this.selectedDirection,
    required this.onDirectionChanged,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.selectedBankFilter,
    required this.onBankFilterChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sortBy,
    required this.onSortChanged,
    required this.customStartDate,
    required this.customEndDate,
    required this.isCustomPeriod,
    required this.onDateRangeChanged,
  });

  @override
  ConsumerState<CategoryFilterCard> createState() => _CategoryFilterCardState();
}

class _CategoryFilterCardState extends ConsumerState<CategoryFilterCard> {
  bool _showFilters = false;

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
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final isDark = AppColors.isDark(context);

    return Container(
      padding: dims.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isDark
            ? DarkAppColors.homeCardShadowStyle
            : [
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
                    color: isDark
                        ? DarkAppColors.balanceCardMuted
                        : AppColors.balanceCardMuted,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showFilters ? Icons.expand_less : Icons.expand_more,
                  size: dims.icon(18),
                  color: isDark
                      ? DarkAppColors.balanceCardMuted
                      : AppColors.balanceCardMuted,
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
                      if (widget.isCustomPeriod)
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
        color: isDark
            ? DarkAppColors.balanceCardChipBackground
            : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? DarkAppColors.balanceCardChipBorder
              : AppColors.balanceCardChipBorder,
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: widget.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search categories...',
          hintStyle: TextStyle(
            color: (isDark
                    ? DarkAppColors.balanceCardMuted
                    : AppColors.balanceCardMuted)
                .withValues(alpha: 0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: dims.icon(18),
            color: (isDark
                    ? DarkAppColors.balanceCardMuted
                    : AppColors.balanceCardMuted)
                .withValues(alpha: 0.6),
          ),
          suffixIcon: widget.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: dims.icon(18),
                    color: (isDark
                            ? DarkAppColors.balanceCardMuted
                            : AppColors.balanceCardMuted)
                        .withValues(alpha: 0.6),
                  ),
                  onPressed: () => widget.onSearchChanged(''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: dims.symmetric(v: 10),
        ),
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? DarkAppColors.appBarForeground
              : AppColors.appBarForeground,
        ),
      ),
    );
  }

  Widget _buildSortDropdown(AppDimensions dims) {
    final isDark = AppColors.isDark(context);
    return PopupMenuButton<CategorySortBy>(
      onSelected: widget.onSortChanged,
      tooltip: 'Sort',
      color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      itemBuilder: (context) => [
        PopupMenuItem<CategorySortBy>(
          value: CategorySortBy.countDesc,
          child: Text(
            'Count (High)',
            style: TextStyle(
              fontWeight: widget.sortBy == CategorySortBy.countDesc
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
              fontWeight: widget.sortBy == CategorySortBy.countAsc
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
              fontWeight: widget.sortBy == CategorySortBy.nameAsc
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
              fontWeight: widget.sortBy == CategorySortBy.nameDesc
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
              fontWeight: widget.sortBy == CategorySortBy.amountDesc
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
              fontWeight: widget.sortBy == CategorySortBy.amountAsc
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
          color: isDark
              ? DarkAppColors.balanceCardChipBackground
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? DarkAppColors.balanceCardChipBorder
                : AppColors.balanceCardChipBorder,
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
              color: isDark
                  ? DarkAppColors.balanceCardMuted
                  : AppColors.balanceCardMuted,
            ),
            Icon(
              Icons.unfold_more,
              size: dims.icon(12),
              color: isDark
                  ? DarkAppColors.balanceCardMuted
                  : AppColors.balanceCardMuted,
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
            active: widget.selectedDirection == TransactionDirection.debit,
            onTap: () => widget.onDirectionChanged(TransactionDirection.debit),
            dims: dims,
          ),
        ),
        SizedBox(width: dims.spacingSm),
        Expanded(
          child: _buildDirectionChip(
            label: 'Income',
            active: widget.selectedDirection == TransactionDirection.credit,
            onTap: () => widget.onDirectionChanged(TransactionDirection.credit),
            dims: dims,
          ),
        ),
        SizedBox(width: dims.spacingSm),
        Expanded(
          child: _buildDirectionChip(
            label: 'Unknown',
            active: widget.selectedDirection == TransactionDirection.unknown,
            onTap: () =>
                widget.onDirectionChanged(TransactionDirection.unknown),
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
              ? (isDark
                  ? DarkAppColors.balanceCardChipBackground
                  : AppColors.balanceCardChipBackground)
              : (isDark
                  ? DarkAppColors.balanceCardChipBackground
                  : const Color(0xFFF7F8FA)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? (isDark
                    ? DarkAppColors.balanceCardForeground.withValues(alpha: 0.6)
                    : AppColors.balanceCardForeground.withValues(alpha: 0.6))
                : (isDark
                    ? DarkAppColors.balanceCardChipBorder
                    : AppColors.balanceCardChipBorder),
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
                ? (isDark
                    ? DarkAppColors.balanceCardForeground
                    : AppColors.balanceCardForeground)
                : (isDark
                    ? DarkAppColors.balanceCardMuted
                    : AppColors.balanceCardMuted),
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
            final isSelected =
                widget.selectedPeriod == period && !widget.isCustomPeriod;
            return Padding(
              padding: dims.only(r: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  widget.onPeriodChanged(period);
                  widget.onDateRangeChanged(null, null, false);
                },
                child: _periodChip(
                  label: _periodLabel(period),
                  isSelected: isSelected,
                  dims: dims,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _periodChip({
    required String label,
    required bool isSelected,
    required AppDimensions dims,
  }) {
    final isDark = AppColors.isDark(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: dims.symmetric(h: 10, v: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? DarkAppColors.balanceCardChipBackground
                : AppColors.balanceCardChipBackground)
            : (isDark
                ? DarkAppColors.balanceCardChipBackground
                : const Color(0xFFF7F8FA)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? (isDark
                  ? DarkAppColors.balanceCardForeground.withValues(alpha: 0.6)
                  : AppColors.balanceCardForeground.withValues(alpha: 0.6))
              : (isDark
                  ? DarkAppColors.balanceCardChipBorder
                  : AppColors.balanceCardChipBorder),
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
              ? (isDark
                  ? DarkAppColors.balanceCardForeground
                  : AppColors.balanceCardForeground)
              : (isDark
                  ? DarkAppColors.balanceCardMuted
                  : AppColors.balanceCardMuted),
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
                color: isDark
                    ? DarkAppColors.balanceCardChipBackground
                    : Colors.transparent,
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
                      widget.customStartDate == null
                          ? 'From'
                          : widget.customStartDate!.fmt('MMM dd', calMode),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.customStartDate == null
                            ? (isDark ? Colors.grey.shade500 : Colors.grey[400])
                            : (isDark
                                ? DarkAppColors.appBarForeground
                                : Colors.black87),
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
                color: isDark
                    ? DarkAppColors.balanceCardChipBackground
                    : Colors.transparent,
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
                      widget.customEndDate == null
                          ? 'To'
                          : widget.customEndDate!.fmt('MMM dd', calMode),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.customEndDate == null
                            ? (isDark ? Colors.grey.shade500 : Colors.grey[400])
                            : (isDark
                                ? DarkAppColors.appBarForeground
                                : Colors.black87),
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
          onTap: () => widget.onDateRangeChanged(null, null, false),
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
          ? (widget.customStartDate ?? DateTime.now())
          : (widget.customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      if (isStart) {
        widget.onDateRangeChanged(date, widget.customEndDate, true);
      } else {
        widget.onDateRangeChanged(widget.customStartDate, date, true);
      }
    }
  }

  Widget _buildCustomRangeButton(AppDimensions dims) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: () {
        widget.onDateRangeChanged(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now(),
          true,
        );
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

  Widget _buildBankPicker(AppDimensions dims) {
    final isDark = AppColors.isDark(context);
    return PopupMenuButton<BankBalanceFilter>(
      onSelected: widget.onBankFilterChanged,
      tooltip: 'Select bank',
      color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      itemBuilder: (context) => BankBalanceFilter.values.map((bank) {
        final isSelected = bank == widget.selectedBankFilter;
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
          color: isDark
              ? DarkAppColors.balanceCardChipBackground
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? DarkAppColors.balanceCardChipBorder
                : AppColors.balanceCardChipBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.selectedBankFilter.label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? DarkAppColors.balanceCardMuted
                    : AppColors.balanceCardMuted,
              ),
            ),
            SizedBox(width: dims(6)),
            Icon(
              Icons.unfold_more,
              size: dims.icon(16),
              color: isDark
                  ? DarkAppColors.balanceCardMuted
                  : AppColors.balanceCardMuted,
            ),
          ],
        ),
      ),
    );
  }
}
