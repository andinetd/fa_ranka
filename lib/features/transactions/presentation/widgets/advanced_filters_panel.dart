import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_filters_provider.dart';

class AdvancedFiltersPanel extends ConsumerStatefulWidget {
  final List<String> bankOptions;
  final List<String> categories;
  final TextEditingController minAmountController;
  final TextEditingController maxAmountController;
  final VoidCallback? onResetAll;

  const AdvancedFiltersPanel({
    super.key,
    required this.bankOptions,
    required this.categories,
    required this.minAmountController,
    required this.maxAmountController,
    this.onResetAll,
  });

  @override
  ConsumerState<AdvancedFiltersPanel> createState() =>
      _AdvancedFiltersPanelState();
}

class _AdvancedFiltersPanelState extends ConsumerState<AdvancedFiltersPanel> {

  @override
  void initState() {
    super.initState();
    widget.minAmountController.addListener(_onMinChanged);
    widget.maxAmountController.addListener(_onMaxChanged);
  }

  void _onMinChanged() {
    final value = double.tryParse(widget.minAmountController.text);
    ref.read(minAmountProvider.notifier).setValue(value);
  }

  void _onMaxChanged() {
    final value = double.tryParse(widget.maxAmountController.text);
    ref.read(maxAmountProvider.notifier).setValue(value);
  }

  @override
  void dispose() {
    widget.minAmountController.removeListener(_onMinChanged);
    widget.maxAmountController.removeListener(_onMaxChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final bankFilter = ref.watch(bankFilterProvider);
    final sortBy = ref.watch(sortByProvider);
    final startDate = ref.watch(startDateProvider);
    final endDate = ref.watch(endDateProvider);
    final minAmount = ref.watch(minAmountProvider);
    final maxAmount = ref.watch(maxAmountProvider);
    final hasAmountContradiction = minAmount != null && maxAmount != null && minAmount > maxAmount;
    final hasDateContradiction = startDate != null && endDate != null && startDate.isAfter(endDate);

    return Container(
      margin: dims.fromLTRB(12, 0, 12, 12),
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
      child: SingleChildScrollView(
        child: Padding(
          padding: dims.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.minAmountController.clear();
                      widget.maxAmountController.clear();
                      ref.read(bankFilterProvider.notifier).setValue('All banks');
                      ref.read(sortByProvider.notifier).setValue(TransactionSort.newest);
                      ref.read(startDateProvider.notifier).setValue(null);
                      ref.read(endDateProvider.notifier).setValue(null);
                      ref.read(minAmountProvider.notifier).setValue(null);
                      ref.read(maxAmountProvider.notifier).setValue(null);
                      widget.onResetAll?.call();
                    },
                    child: Text(
                      'Reset All',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: dims(6)),

              // Bank filter
              Text(
                'Bank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                ),
              ),
              SizedBox(height: dims(6)),
              PopupMenuButton<String>(
                onSelected: (bank) => ref.read(bankFilterProvider.notifier).setValue(bank),
                tooltip: 'Select bank',
                color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                itemBuilder: (context) => widget.bankOptions.map((bank) {
                  final isSelected = bank == bankFilter;
                  return PopupMenuItem<String>(
                    value: bank,
                    child: Text(
                      bank,
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
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          bankFilter,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: dims(6)),
                      Icon(
                        Icons.unfold_more,
                        size: dims.icon(14),
                        color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: dims(10)),

              // Sort option
              Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                ),
              ),
              SizedBox(height: dims(6)),
              Wrap(
                spacing: dims(6),
                runSpacing: dims(6),
                children: [
                  _sortChip('Newest', TransactionSort.newest, sortBy),
                  _sortChip('Oldest', TransactionSort.oldest, sortBy),
                  _sortChip('Amount (High)', TransactionSort.amountHigh, sortBy),
                  _sortChip('Amount (Low)', TransactionSort.amountLow, sortBy),
                ],
              ),
              SizedBox(height: dims(10)),

              // Amount range
              Text(
                'Amount Range (ETB)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                ),
              ),
              SizedBox(height: dims(6)),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                        controller: widget.minAmountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Min',
                          hintStyle: TextStyle(
                            color: (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted).withValues(alpha: 0.6),
                          ),
                          contentPadding: dims.symmetric(
                            h: 10,
                            v: 8,
                          ),
                          filled: true,
                          fillColor: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
                            ),
                          ),
                        ),
                      ),
                  ),
                  SizedBox(width: dims(8)),
                  Expanded(
                      child: TextField(
                        controller: widget.maxAmountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Max',
                          hintStyle: TextStyle(
                            color: (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted).withValues(alpha: 0.6),
                          ),
                          contentPadding: dims.symmetric(
                            h: 10,
                            v: 8,
                          ),
                          filled: true,
                          fillColor: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
                            ),
                          ),
                        ),
                      ),
                  ),
                ],
              ),
              if (hasAmountContradiction)
                Padding(
                  padding: dims.only(t: 4),
                  child: Text(
                    'Min cannot be greater than Max',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              SizedBox(height: dims(8)),

              // Date range
              Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                ),
              ),
              SizedBox(height: dims(6)),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          ref.read(startDateProvider.notifier).setValue(date);
                        }
                      },
                      child: Container(
                        padding: dims.symmetric(
                          h: 10,
                          v: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA),
                          border: Border.all(
                            color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: dims.icon(14),
                              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                            ),
                            SizedBox(width: dims(6)),
                            Expanded(
                              child: Text(
                                startDate == null
                                    ? 'From'
                                    : startDate.fmt('MMM dd', calMode),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: startDate == null
                                      ? (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted)
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
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          ref.read(endDateProvider.notifier).setValue(date);
                        }
                      },
                      child: Container(
                        padding: dims.symmetric(
                          h: 10,
                          v: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA),
                          border: Border.all(
                            color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: dims.icon(14),
                              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                            ),
                            SizedBox(width: dims(6)),
                            Expanded(
                              child: Text(
                                endDate == null
                                    ? 'To'
                                    : endDate.fmt('MMM dd', calMode),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: endDate == null
                                      ? (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted)
                                      : (isDark ? DarkAppColors.appBarForeground : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (hasDateContradiction)
                Padding(
                  padding: dims.only(t: 4),
                  child: Text(
                    'Start date cannot be after End date',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              SizedBox(height: dims(10)),

              // Close button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    ref.read(showAdvancedFiltersProvider.notifier).setValue(false);
                  },
                  child: Container(
                    padding: dims.symmetric(v: 8),
                    decoration: BoxDecoration(
                      color: isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close,
                          size: dims.icon(14),
                          color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                        ),
                        SizedBox(width: dims(4)),
                        Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortChip(String label, TransactionSort value, TransactionSort currentSort) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final selected = currentSort == value;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => ref.read(sortByProvider.notifier).setValue(value),
      child: Container(
        padding: dims.symmetric(v: 7, h: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? DarkAppColors.balanceCardChipBackground : AppColors.balanceCardChipBackground)
              : (isDark ? DarkAppColors.balanceCardChipBackground : const Color(0xFFF7F8FA)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? (isDark ? DarkAppColors.balanceCardForeground.withValues(alpha: 0.6) : AppColors.balanceCardForeground.withValues(alpha: 0.6))
                : (isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? (isDark ? DarkAppColors.balanceCardForeground : AppColors.balanceCardForeground)
                : (isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
          ),
        ),
      ),
    );
  }
}
