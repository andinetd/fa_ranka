import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:drift/drift.dart' as d;
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';

import 'package:faranka/database/database.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_recategorizer.dart';

class CategoryMessagesPage extends ConsumerStatefulWidget {
  final String category;
  final TransactionDirection? direction;

  const CategoryMessagesPage({
    super.key,
    required this.category,
    this.direction = TransactionDirection.debit,
  });

  @override
  ConsumerState<CategoryMessagesPage> createState() =>
      _CategoryMessagesPageState();
}

class _CategoryMessagesPageState extends ConsumerState<CategoryMessagesPage> {
  bool _isRecategorizing = false;

  Future<void> _recategorizeAll() async {
    setState(() => _isRecategorizing = true);
    
    try {
      final recategorizer = TransactionRecategorizer(ref.read(databaseProvider));
      final count = await recategorizer.deepParseCategory(widget.category);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deep parsed and updated $count transactions'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecategorizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    final money = useCompact
        ? NumberFormat.compactCurrency(symbol: 'ETB ')
        : NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : null,
      appBar: AppBar(
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        foregroundColor: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
        title: Text(
          widget.direction == TransactionDirection.credit
              ? '${widget.category} Income'
              : widget.direction == TransactionDirection.unknown
                  ? '${widget.category} Unknown'
                  : '${widget.category} Spending',
        ),
        actions: [
          if (_isRecategorizing)
            Center(
              child: Padding(
                padding: dims.symmetric(h: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _recategorizeAll,
              tooltip: 'Deep parse all receipts in this category',
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages Stream
          Expanded(
            child: StreamBuilder<_CategoryTxnBundle>(
              stream: () {
                final db = ref.watch(databaseProvider);
                final base = db.select(db.transactions).join([
                  d.leftOuterJoin(
                    db.smsInbox,
                    db.smsInbox.id.equalsExp(db.transactions.smsId),
                  ),
                ])
                  ..where(db.transactions.direction
                      .equalsValue(widget.direction));
                final splitsChanged = db.tableUpdates(
                  d.TableUpdateQuery.onTableName('transaction_splits'),
                ).asyncMap((_) => base.get());

                return Rx.merge([base.watch(), splitsChanged]).asyncMap((rows) async {
                  final ids = rows.map((r) => r.readTable(db.transactions).id).toList();
                  final splitMap = await db.getSplitsByTransactionIds(ids);

                  // Filter to only rows matching the category (via parsedCategory or splits)
                  final categoryLower = widget.category.toLowerCase();
                  final filtered = rows.where((r) {
                    final txn = r.readTable(db.transactions);
                    if (txn.parsedCategory.toLowerCase() == categoryLower) return true;
                    final splits = splitMap[txn.id];
                    return splits?.any((s) =>
                        s.category.toLowerCase() == categoryLower) ?? false;
                  }).toList();

                  return _CategoryTxnBundle(rows: filtered, splits: splitMap);
                });
              }(),
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
                          Icon(Icons.error_outline, size: 48,
                              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
                          SizedBox(height: 16),
                          Text('Could not load messages',
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
                final db = ref.watch(databaseProvider);
                final bundle = snapshot.data;
                final allRows = (bundle?.rows ?? [])
                  ..sort((a, b) {
                    final aTxn = a.readTable(db.transactions);
                    final bTxn = b.readTable(db.transactions);
                    final timeCompare = bTxn.smsTimestamp.compareTo(
                      aTxn.smsTimestamp,
                    );
                    if (timeCompare != 0) return timeCompare;
                    return bTxn.importedAt.compareTo(aTxn.importedAt);
                  });

                // Display all transactions
                final rows = allRows;

                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages found for this category.',
                      style:
                          TextStyle(color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
                    ),
                  );
                }

                return ListView.separated(
                  padding: dims.all(16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => SizedBox(height: dims(10)),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final txn = row.readTable(db.transactions);
                    final isCredit =
                        txn.direction == TransactionDirection.credit;
                    final amountPrefix = isCredit ? '+' : '-';
                    final displayedAmount = txn.amount;
                    final title =
                        txn.counterpartyName ?? txn.bankName ?? 'Unknown';
                    final timestamp = DateTime.fromMillisecondsSinceEpoch(
                      txn.smsTimestamp,
                    );

              return Container(
                margin: dims.symmetric(h: 14, v: 6),
                padding: dims.all(14),
                decoration: BoxDecoration(
                  color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
                  borderRadius: homeCardBorderRadius,
                  border: Border.all(color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder),
                  boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : AppColors.homeCardShadowStyle,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                            ),
                          ),
                        ),
                        Text(
                          '$amountPrefix${money.format(displayedAmount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCredit
                                ? AppColors.transactionReceivedFont
                                : AppColors.transactionSentFont,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: dims(6)),
                    Text(
                      timestamp.fmt('yyyy-MM-dd HH:mm', calMode),
                      style: TextStyle(
                          color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted, fontSize: 12),
                    ),
                    SizedBox(height: dims.spacingSm),
                    Text(
                      txn.rawSmsBody,
                      style: TextStyle(fontSize: 13, height: 1.35, color: isDark ? DarkAppColors.appBarForeground : null),
                    ),
                    SizedBox(height: dims.spacingSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            size: dims.icon(18),
                            color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                          ),
                          onPressed: () async {
                            if (!context.mounted) return;
                            await Clipboard.setData(
                              ClipboardData(text: txn.rawSmsBody),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message copied to clipboard'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
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

class _CategoryTxnBundle {
  final List<d.TypedResult> rows;
  final Map<int, List<TransactionSplit>> splits;
  _CategoryTxnBundle({required this.rows, required this.splits});
}
