import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';
import 'transaction_tile.dart';

class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final db = ref.watch(databaseProvider);
    final textColor = isDark ? DarkAppColors.appBarForeground : Colors.black;
    return StreamBuilder<List<d.TypedResult>>(
      stream: db.watchRecentTransactions(limit: 6),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: dims.symmetric(h: 14),
            child: Container(
              padding: dims.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: dims.icon(16),
                    color: isDark
                        ? DarkAppColors.balanceCardMuted
                        : const Color(0xFF6B7280),
                  ),
                  SizedBox(width: dims(8)),
                  Text(
                    'Could not load recent transactions',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? DarkAppColors.balanceCardMuted
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final recent = List<d.TypedResult>.from(snapshot.data ?? []);

        return FutureBuilder<Map<int, List<TransactionSplit>>>(
          future: db.getSplitsByTransactionIds(
            recent.map((r) => r.readTable(db.transactions).id).toList(),
          ),
          builder: (context, splitSnapshot) {
            final hasSplitError = splitSnapshot.hasError;
            final splitMap = splitSnapshot.data ?? const {};

            return Padding(
              padding: dims.symmetric(h: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      InkWell(
                        onTap: () => context.go('/transactions'),
                        child: Row(
                          children: [
                            Text(
                              'see all',
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                            SizedBox(width: dims(6)),
                            Icon(
                              Icons.chevron_right,
                              size: dims.icon(18),
                              color: textColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dims(10)),
                  if (recent.isEmpty)
                    Center(
                      child: Padding(
                        padding: dims.symmetric(v: 16),
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: isDark
                                ? DarkAppColors.balanceCardMuted
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  else
                    ...recent.map((row) {
                      final txn = row.readTable(db.transactions);
                      final sms = row.readTableOrNull(db.smsInbox);
                      return TransactionTile(
                        txn: txn,
                        sms: sms,
                        splits: splitMap[txn.id],
                      );
                    }),
                  if (hasSplitError)
                    Padding(
                      padding: dims.only(t: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: dims.icon(12),
                            color: isDark
                                ? DarkAppColors.balanceCardMuted
                                : const Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: dims(4)),
                          Text(
                            'Split data unavailable',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? DarkAppColors.balanceCardMuted
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
