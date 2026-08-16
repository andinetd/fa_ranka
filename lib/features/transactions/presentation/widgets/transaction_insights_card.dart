import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/presentation/widgets/editable_category_pill.dart';
import 'package:faranka/features/transactions/presentation/widgets/bank_logo.dart';
import 'package:faranka/features/transactions/presentation/widgets/extraction_retry_status_widget.dart';
import 'package:faranka/features/transactions/presentation/widgets/split_section.dart';

String _normalizeText(String? value) {
  return (value ?? '').trim().toLowerCase();
}

String _merchantLabel(TransactionData txn) {
  final counterparty = txn.counterpartyName?.trim();
  if (counterparty != null && counterparty.isNotEmpty) {
    return counterparty;
  }

  final reason = txn.reasonRawText.trim();
  if (reason.isNotEmpty) {
    return reason;
  }

  final bankName = txn.bankName?.trim();
  if (bankName != null && bankName.isNotEmpty) {
    return bankName;
  }

  return 'Unknown counterparty';
}

bool _isRelatedTransaction(
  TransactionData current,
  TransactionData candidate,
) {
  if (candidate.id == current.id) return false;
  if (candidate.direction != current.direction) return false;

  final currentCounterparty = _normalizeText(current.counterpartyName);
  final candidateCounterparty = _normalizeText(candidate.counterpartyName);
  if (currentCounterparty.isNotEmpty &&
      candidateCounterparty.isNotEmpty &&
      currentCounterparty == candidateCounterparty) {
    return true;
  }

  final currentCategory = current.parsedCategory.trim().toLowerCase();
  final candidateCategory = candidate.parsedCategory.trim().toLowerCase();
  if (currentCategory.isNotEmpty && currentCategory == candidateCategory) {
    return true;
  }

  final currentReason = _normalizeText(current.reasonRawText);
  final candidateReason = _normalizeText(candidate.reasonRawText);
  if (currentReason.isNotEmpty &&
      candidateReason.isNotEmpty &&
      currentReason == candidateReason) {
    return true;
  }

  final amountGap = (candidate.amount - current.amount).abs();
  final threshold = (current.amount * 0.08).clamp(5.0, 250.0);
  return amountGap <= threshold;
}

class TransactionInsightsCard extends ConsumerWidget {
  final TransactionData currentTxn;
  final List<TransactionData> allTransactions;
  final VoidCallback? onEditCategory;
  final VoidCallback? onSplitTransaction;
  final VoidCallback? onReparse;
  final GlobalKey? splitButtonKey;

  const TransactionInsightsCard({
    super.key,
    required this.currentTxn,
    required this.allTransactions,
    this.onEditCategory,
    this.onSplitTransaction,
    this.onReparse,
    this.splitButtonKey,
  });

  Widget _buildInsightPill(BuildContext context, WidgetRef ref, String label, String value) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    return Container(
      padding: dims.symmetric(h: 12, v: 10),
      decoration: BoxDecoration(
        color: (isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: dims(4)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedRow(BuildContext context, WidgetRef ref, TransactionData txn, CalendarMode calMode) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final isCredit = txn.direction == TransactionDirection.credit;
    final icon = isCredit ? Icons.south_west : Icons.north_east;
    final amountColor = isCredit
        ? AppColors.transactionReceivedFont
        : AppColors.transactionSentFont;
    final amountLabel = '${txn.amount.toStringAsFixed(2)} ETB';
    final date = DateTime.fromMillisecondsSinceEpoch(txn.smsTimestamp);
    final dateLabel = date.fmt('MMM d • h:mm a', calMode);

    return Container(
      margin: dims.only(t: 8),
      padding: dims.all(10),
      decoration: BoxDecoration(
        color: (isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: dims.icon(16), color: amountColor),
          SizedBox(width: dims.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _merchantLabel(txn),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: dims(2)),
                Row(
                  children: [
                    if (BankLogo.hasLogo(txn.bankName)) ...[
                      BankLogo(bankName: txn.bankName, size: 11),
                      SizedBox(width: dims(3)),
                    ],
                    Flexible(
                      child: Text(
                        '${txn.bankName ?? 'Unknown bank'} • ${txn.parsedCategory}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: dims.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountLabel,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: dims(2)),
              Text(
                dateLabel,
                style: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final narrowScreen = MediaQuery.of(context).size.width < 360;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final similarTransactions =
        allTransactions
            .where((txn) => txn.smsTimestamp >= cutoff.millisecondsSinceEpoch)
            .where((txn) => _isRelatedTransaction(currentTxn, txn))
            .toList()
          ..sort((a, b) => b.smsTimestamp.compareTo(a.smsTimestamp));

    final sameMerchantCount = allTransactions
        .where((txn) => txn.smsTimestamp >= cutoff.millisecondsSinceEpoch)
        .where(
          (txn) =>
              _normalizeText(txn.counterpartyName).isNotEmpty &&
              _normalizeText(txn.counterpartyName) ==
                  _normalizeText(currentTxn.counterpartyName),
        )
        .length;

    final categoryCount = allTransactions
        .where((txn) => txn.smsTimestamp >= cutoff.millisecondsSinceEpoch)
        .where(
          (txn) =>
              txn.parsedCategory.toLowerCase() ==
              currentTxn.parsedCategory.toLowerCase(),
        )
        .length;

    final similarTotal = similarTransactions.fold<double>(
      0,
      (sum, txn) => sum + txn.amount,
    );
    final recurring = sameMerchantCount >= 3 || categoryCount >= 5;

    return Container(
      margin: dims.only(t: 12),
      padding: dims.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : AppColors.homeCardShadowStyle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Insights',
            style: TextStyle(
              color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: dims(4)),
          Text(
            recurring
                ? 'This looks like a recurring transaction.'
                : 'Based on your history, this transaction does not look recurring yet.',
            style: TextStyle(
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          ExtractionRetryStatusWidget(
            transaction: currentTxn,
            onRefreshPressed: onReparse,
          ),
          SizedBox(height: dims(12)),
          if (narrowScreen)
            Column(
              children: [
                _buildInsightPill(context, ref, 'Counterparty', _merchantLabel(currentTxn)),
                SizedBox(height: dims.spacingSm),
                EditableCategoryPill(txn: currentTxn, onTap: onEditCategory),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildInsightPill(
                     context, ref, 'Counterparty', _merchantLabel(currentTxn),
                  ),
                ),
                SizedBox(width: dims(10)),
                Expanded(child: EditableCategoryPill(txn: currentTxn, onTap: onEditCategory)),
              ],
            ),
          SizedBox(height: dims(8)),
          SplitSection(
            key: splitButtonKey,
            txn: currentTxn,
            onSplitTap: onSplitTransaction,
          ),
          SizedBox(height: dims(10)),
          if (narrowScreen)
            Column(
              children: [
                _buildInsightPill(
                  context, ref, 'Similar in 30d',
                  similarTransactions.length.toString(),
                ),
                SizedBox(height: dims.spacingSm),
                _buildInsightPill(
                  context, ref, 'Similar total',
                  '${similarTotal.toStringAsFixed(2)} ETB',
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildInsightPill(
                    context, ref, 'Similar in 30d',
                    similarTransactions.length.toString(),
                  ),
                ),
                SizedBox(width: dims(10)),
                Expanded(
                  child: _buildInsightPill(
                    context, ref, 'Similar total',
                    '${similarTotal.toStringAsFixed(2)} ETB',
                  ),
                ),
              ],
            ),
          if (similarTransactions.isNotEmpty) ...[
            SizedBox(height: dims(14)),
            Text(
              'Related transactions',
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            for (final txn in similarTransactions.take(3))
              _buildRelatedRow(context, ref, txn, calMode),
          ],
          SizedBox(height: dims(14)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: currentTxn.parsedCategory.trim().isEmpty
                  ? null
                  : () => context.push(
                      '/category/${Uri.encodeComponent(currentTxn.parsedCategory)}',
                    ),
              icon: Icon(Icons.tune, size: dims.icon(18)),
              label: const Text('View same category history'),
            ),
          ),
        ],
      ),
    );
  }
}
