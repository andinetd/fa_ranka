import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';

class SplitRowData {
  String category;
  double amount;
  final TextEditingController amountController;

  SplitRowData({required this.category, required this.amount})
    : amountController = TextEditingController(
        text: amount == 0 ? '' : amount.toStringAsFixed(2),
      );

  void dispose() {
    amountController.dispose();
  }
}

class SplitCategorySheet extends ConsumerStatefulWidget {
  final TransactionData txn;
  final List<TransactionSplit> existingSplits;
  final List<String> allCategories;

  const SplitCategorySheet({
    super.key,
    required this.txn,
    required this.existingSplits,
    required this.allCategories,
  });

  @override
  ConsumerState<SplitCategorySheet> createState() => SplitCategorySheetState();
}

class SplitCategorySheetState extends ConsumerState<SplitCategorySheet> {
  late List<SplitRowData> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.existingSplits.map((s) => SplitRowData(
      category: s.category,
      amount: s.amount,
    )).toList();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final totalAmount = widget.txn.amount;
    final allocated = _rows.fold<double>(0, (sum, r) => sum + r.amount);
    final remaining = totalAmount - allocated;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: dims.all(20),
        decoration: BoxDecoration(
          color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: dims(12)),
            Text(
              'Split Transaction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
              ),
            ),
            SizedBox(height: dims(4)),
            Row(
              children: [
                Text(
                  'Total: ${totalAmount.toStringAsFixed(2)} ETB',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  ),
                ),
                SizedBox(width: dims(12)),
                Text(
                  'Remaining: ${remaining.toStringAsFixed(2)} ETB',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: remaining < -0.009
                        ? const Color(0xFFB85C5C)
                        : isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                  ),
                ),
              ],
            ),
            SizedBox(height: dims(12)),

            // Split rows
            if (_rows.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _rows.length,
                  itemBuilder: (context, index) => _buildSplitRow(index),
                ),
              ),

            // Add split button
            TextButton.icon(
              onPressed: _addRow,
              icon: Icon(Icons.add, size: 18, color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected),
              label: Text('Add Split', style: TextStyle(color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected)),
            ),
            SizedBox(height: dims(8)),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.homeNavigationSelected.withValues(alpha: 0.5),
                      ),
                      foregroundColor: isDark ? DarkAppColors.appBarForeground : null,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: dims(10)),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? DarkAppColors.homeAccentGreen : null,
                      foregroundColor: isDark ? Colors.white : null,
                    ),
                    child: const Text('Save Splits'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitRow(int index) {
    final isDark = AppColors.isDark(context);
    final row = _rows[index];
    final dims = ref.watch(dimensionsProvider);

    return Padding(
      padding: dims.only(b: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                final input = textEditingValue.text.toLowerCase();
                if (input.isEmpty) return widget.allCategories;
                return widget.allCategories.where((c) =>
                    c.toLowerCase().contains(input));
              },
              initialValue: TextEditingValue(text: row.category),
              onSelected: (value) => setState(() => _rows[index].category = value),
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth: MediaQuery.of(context).size.width * 0.4,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, i) {
                          final option = options.elementAt(i);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: dims.symmetric(h: 12, v: 8),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? DarkAppColors.appBarForeground : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Category',
                    hintStyle: TextStyle(
                      color: isDark ? DarkAppColors.balanceCardMuted.withValues(alpha: 0.6) : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: dims.symmetric(h: 8, v: 8),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                  ),
                  cursorColor: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
                  onChanged: (value) {
                    _rows[index].category = value;
                  },
                  onSubmitted: (value) {
                    _rows[index].category = value;
                    onSubmitted();
                  },
                );
              },
            ),
          ),
          SizedBox(width: dims(6)),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Amount',
                hintStyle: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted.withValues(alpha: 0.6) : null,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
                    width: 1.5,
                  ),
                ),
                contentPadding: dims.symmetric(h: 8, v: 8),
              ),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
              ),
              cursorColor: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
              onChanged: (v) {
                final parsed = double.tryParse(v);
                setState(() {
                  _rows[index].amount = parsed ?? 0;
                });
              },
            ),
          ),
          SizedBox(width: dims(4)),
          IconButton(
            icon: Icon(Icons.close, size: dims.icon(18)),
            color: const Color(0xFFB85C5C),
            onPressed: () {
              _rows[index].dispose();
              setState(() => _rows.removeAt(index));
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _addRow() {
    setState(() {
      _rows.add(SplitRowData(category: '', amount: 0));
    });
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);

    final valid = _rows.where((r) =>
        r.category.trim().isNotEmpty && r.amount > 0.009).toList();
    if (valid.isEmpty) {
      await db.deleteSplitsForTransaction(widget.txn.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final splits = valid.map((r) => TransactionSplit(
      transactionId: widget.txn.id,
      category: r.category.trim(),
      amount: r.amount,
    )).toList();

    final total = splits.fold<double>(0, (s, sp) => s + sp.amount);
    if (total > widget.txn.amount + 0.009) {
      final scale = widget.txn.amount / total;
      for (int i = 0; i < splits.length; i++) {
        splits[i] = TransactionSplit(
          transactionId: widget.txn.id,
          category: splits[i].category,
          amount: splits[i].amount * scale,
        );
      }
    }

    try {
      await db.saveSplits(widget.txn.id, splits);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save splits: $e')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Splits saved')),
    );
  }
}
