import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/widgets/sensitive_text.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/models/transaction_tile_view.dart';
import 'package:faranka/features/transactions/presentation/widgets/bank_logo.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.txn,
    this.sms,
    this.bottomMargin = 6,
    this.splits,
  }) : view = null;

  const TransactionTile.forView(
    this.view, {
    super.key,
    this.bottomMargin = 6,
  })  : txn = null,
        sms = null,
        splits = null;

  final TransactionData? txn;
  final SmsInboxData? sms;
  final double bottomMargin;
  final List<TransactionSplit>? splits;

  /// Pre-formatted snapshot; bypasses all formatting/preference work in build.
  final TransactionTileView? view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dims = ref.watch(dimensionsProvider);
    final isDark = AppColors.isDark(context);
    final tile = view ??
        buildTransactionTileView(
          txn: txn!,
          sms: sms,
          splits: splits,
          calendarMode: ref.watch(calendarModeProvider),
          useCompact: ref.watch(compactNumbersProvider),
        );

    final isCredit = tile.isCredit;
    final bgColor = isCredit
        ? (isDark
            ? DarkAppColors.transactionReceived
            : AppColors.transactionReceived)
        : (isDark
            ? DarkAppColors.transactionSent
            : AppColors.transactionSent);
    final textColor = isCredit
        ? (isDark
            ? DarkAppColors.transactionReceivedFont
            : AppColors.transactionReceivedFont)
        : (isDark
            ? DarkAppColors.transactionSentFont
            : AppColors.transactionSentFont);
    final bankName = tile.bankName ?? 'CBE';
    final hasSplits = tile.hasSplits;

    return Padding(
      padding: dims.only(b: bottomMargin),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tile.sms == null
              ? null
              : () => context.push('/receipt-details', extra: tile.sms),
          borderRadius: BorderRadius.circular(3),
          child: Container(
            padding: dims.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.18),
                  blurRadius: 4,
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
                      Row(
                        children: [
                          Icon(
                            isCredit ? Icons.south_west : Icons.north_east,
                            size: dims.icon(14),
                            color: textColor,
                          ),
                          SizedBox(width: dims(4)),
                          Flexible(
                            child: Text(
                              tile.dateTimeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dims(1)),
                      Text(
                        tile.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: dims(1)),
                      Row(
                        children: [
                          if (hasSplits) ...[
                            Icon(
                              Icons.call_split,
                              size: dims.icon(11),
                              color: textColor.withValues(alpha: 0.7),
                            ),
                            SizedBox(width: dims(3)),
                          ],
                          if (BankLogo.hasLogo(bankName)) ...[
                            BankLogo(bankName: bankName, size: 13),
                            SizedBox(width: dims(4)),
                          ],
                          Flexible(
                            child: Text(
                              '$bankName • ${tile.secondaryLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SensitiveText(
                  tile.amountText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}