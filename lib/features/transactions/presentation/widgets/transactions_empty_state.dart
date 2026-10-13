import 'package:flutter/material.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_filters_provider.dart';

class TransactionsEmptyState extends StatelessWidget {
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

  const TransactionsEmptyState({
    super.key,
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
