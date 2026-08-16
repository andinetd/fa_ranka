import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';

class SplitSection extends ConsumerWidget {
  final TransactionData txn;
  final VoidCallback? onSplitTap;

  const SplitSection({
    super.key,
    required this.txn,
    this.onSplitTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final db = ref.read(databaseProvider);

    return FutureBuilder<List<TransactionSplit>>(
      future: db.getSplitsForTransaction(txn.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: dims.symmetric(h: 12, v: 10),
            decoration: BoxDecoration(
              color: (isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: dims.icon(14),
                    color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
                SizedBox(width: dims(8)),
                Text('Could not load splits',
                  style: TextStyle(fontSize: 13,
                      color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
                ),
              ],
            ),
          );
        }
        final splits = snapshot.data ?? const <TransactionSplit>[];
        final hasSplits = splits.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasSplits) ...[
              Container(
                padding: dims.symmetric(h: 12, v: 10),
                decoration: BoxDecoration(
                  color: (isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in splits)
                      Padding(
                        padding: dims.only(b: 4),
                        child: Row(
                          children: [
                            Icon(Icons.call_split, size: dims.icon(14),
                                color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
                            SizedBox(width: dims(6)),
                            Expanded(
                              child: Text(s.category,
                                style: TextStyle(fontSize: 12,
                                    color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
                              ),
                            ),
                            Text('${s.amount.toStringAsFixed(2)} ETB',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: dims(8)),
            ],
            OutlinedButton.icon(
              onPressed: onSplitTap,
              icon: Icon(Icons.add, size: dims.icon(16)),
              label: const Text('Split Transaction'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.homeNavigationSelected.withValues(alpha: 0.5),
                ),
                foregroundColor: isDark ? DarkAppColors.appBarForeground : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
