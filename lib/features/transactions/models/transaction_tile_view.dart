import 'package:intl/intl.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/database/database.dart';

/// Pre-formatted, immutable snapshot of everything a [TransactionTile] needs to
/// render plus the raw scalars the filter/sort pipeline operates on.
///
/// Building these once per data change (instead of per scroll frame) removes
/// all `NumberFormat`/`DateFormat` work, date math and preference lookups from
/// the build of every tile.
class TransactionTileView {
  final int id;
  final SmsInboxData? sms;
  final TransactionDirection direction;
  final String? bankName;
  final String? counterpartyName;
  final String reasonRawText;
  final String parsedCategory;
  final String? bankTransactionId;
  final double amount;
  final int smsTimestamp;

  final bool isCredit;
  final bool hasSplits;
  final List<String> splitCategories;
  final String title;
  final String reasonText;
  final String secondaryLabel;
  final String dateTimeLabel;
  final String amountText;

  const TransactionTileView({
    required this.id,
    this.sms,
    required this.direction,
    this.bankName,
    this.counterpartyName,
    required this.reasonRawText,
    required this.parsedCategory,
    this.bankTransactionId,
    required this.amount,
    required this.smsTimestamp,
    required this.isCredit,
    required this.hasSplits,
    required this.splitCategories,
    required this.title,
    required this.reasonText,
    required this.secondaryLabel,
    required this.dateTimeLabel,
    required this.amountText,
  });
}

/// Shared, pure conversion of raw drift rows into a pre-formatted
/// [TransactionTileView]. Used by both the list provider (bulk) and the
/// convenience raw-data path on [TransactionTile] (single, small lists).
TransactionTileView buildTransactionTileView({
  required TransactionData txn,
  required SmsInboxData? sms,
  required List<TransactionSplit>? splits,
  required CalendarMode calendarMode,
  required bool useCompact,
}) {
  final rawText = txn.reasonRawText.trim();
  final amount = txn.amount;
  final hasSplits = splits != null && splits.isNotEmpty;
  final isCredit = txn.direction == TransactionDirection.credit;
  final transactionDate = DateTime.fromMillisecondsSinceEpoch(txn.smsTimestamp);
  final now = DateTime.now();
  final datePattern = transactionDate.year == now.year
      ? 'MMM d • h:mm a'
      : 'MMM d, yyyy • h:mm a';
  final currency = useCompact
      ? NumberFormat.compact()
      : NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
  final currentBank = txn.bankName ?? 'CBE';
  final fromAccount = sms?.fromAccount;

  final counterpartyIsBoilerplate =
      (txn.counterpartyName?.isNotEmpty ?? false) &&
          txn.counterpartyName!.toLowerCase() == currentBank.toLowerCase();
  final title = isCredit
      ? (fromAccount != null && fromAccount.isNotEmpty
          ? fromAccount
          : ((txn.counterpartyName?.isNotEmpty ?? false)
              ? txn.counterpartyName!
              : currentBank))
      : ((txn.counterpartyName?.isNotEmpty ?? false) &&
              !counterpartyIsBoilerplate
          ? txn.counterpartyName!
          : (counterpartyIsBoilerplate && txn.parsedCategory.isNotEmpty
              ? txn.parsedCategory
              : currentBank));

  final secondaryLabel = isCredit
      ? (rawText.isNotEmpty ? rawText : 'Received')
      : hasSplits
          ? splits.map((s) => s.category).join(', ')
          : txn.parsedCategory;

  return TransactionTileView(
    id: txn.id,
    sms: sms,
    direction: txn.direction,
    bankName: currentBank,
    counterpartyName: txn.counterpartyName,
    reasonRawText: txn.reasonRawText,
    parsedCategory: txn.parsedCategory,
    bankTransactionId: txn.bankTransactionId,
    amount: amount,
    smsTimestamp: txn.smsTimestamp,
    isCredit: isCredit,
    hasSplits: hasSplits,
    splitCategories:
        splits?.map((s) => s.category).toList(growable: false) ?? const [],
    title: title,
    reasonText: rawText,
    secondaryLabel: secondaryLabel,
    dateTimeLabel: transactionDate.fmt(datePattern, calendarMode),
    amountText: '${useCompact ? 'ETB ' : ''}${currency.format(amount)}',
  );
}