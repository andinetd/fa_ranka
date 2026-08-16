import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:drift/drift.dart';

import 'package:faranka/database/database.dart';

String fmtDate(int millis) =>
    DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(millis));

Map<String, dynamic> cleanJson(TransactionData txn) => {
      'id': txn.id,
      'date': fmtDate(txn.smsTimestamp),
      'amount': txn.amount,
      'currency': txn.currency,
      'direction': txn.direction.name,
      'bank': txn.bankName,
      'counterparty': txn.counterpartyName,
      'category': txn.parsedCategory,
      'reason': txn.reasonRawText,
      'reference': txn.bankTransactionId ?? txn.referenceNumber,
      if (txn.channel != null && txn.channel!.isNotEmpty) 'channel': txn.channel,
      if (txn.branchName != null && txn.branchName!.isNotEmpty) 'branch': txn.branchName,
      if (txn.balanceAfter != null) 'balanceAfter': txn.balanceAfter,
      if (txn.commission != 0) 'commission': txn.commission,
      if (txn.vat != 0) 'vat': txn.vat,
      if (txn.receiptUrl != null && txn.receiptUrl!.isNotEmpty)
        'receiptUrl': txn.receiptUrl,
      'status': txn.receiptExtractionStatus,
      if (txn.receiptExtractionError != null &&
          txn.receiptExtractionError!.isNotEmpty)
        'error': txn.receiptExtractionError,
      'importedAt': fmtDate(txn.importedAt),
    };

List<Object?> csvRow(TransactionData txn) => [
      txn.id,
      fmtDate(txn.smsTimestamp),
      txn.amount,
      txn.currency,
      txn.direction.name,
      txn.bankName,
      txn.counterpartyName,
      txn.parsedCategory,
      txn.reasonRawText,
      txn.bankTransactionId ?? txn.referenceNumber,
      txn.channel,
      txn.branchName,
      txn.balanceAfter,
      txn.commission == 0 ? null : txn.commission,
      txn.vat == 0 ? null : txn.vat,
      txn.receiptUrl,
      txn.receiptExtractionStatus,
      txn.receiptExtractionError,
      fmtDate(txn.importedAt),
    ];

Future<void> exportAndShare(AppDatabase db, String extension, BuildContext context) async {
  final txns =
      await (db.select(db.transactions)..orderBy([
            (t) => OrderingTerm(
              expression: t.smsTimestamp,
              mode: OrderingMode.desc,
            ),
          ]))
          .get();

  final dir = Directory((await getTemporaryDirectory()).path);
  final fileName =
      'faranka_transactions_${DateTime.now().millisecondsSinceEpoch}.$extension';
  final file = File('${dir.path}/$fileName');

  if (extension == 'json') {
    final payload = txns.map(cleanJson).toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  } else {
    const headers = [
      'ID', 'Date', 'Amount', 'Currency', 'Direction', 'Bank',
      'Counterparty', 'Category', 'Reason', 'Reference', 'Channel',
      'Branch', 'Balance', 'Commission', 'VAT', 'Receipt URL',
      'Status', 'Error', 'Imported At',
    ];

    String escape(Object? value) {
      if (value == null) return '""';
      final raw = value.toString();
      return '"${raw.replaceAll('"', '""')}"';
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(escape).join(','));
    for (final txn in txns) {
      buffer.writeln(csvRow(txn).map(escape).join(','));
    }
    await file.writeAsString(buffer.toString());
  }

  if (!context.mounted) return;
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)]),
  );
}

Future<void> exportTransactionsJson(AppDatabase db, BuildContext context) =>
    exportAndShare(db, 'json', context);

Future<void> exportTransactionsCsv(AppDatabase db, BuildContext context) =>
    exportAndShare(db, 'csv', context);
