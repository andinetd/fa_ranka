import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faranka/database/database.dart';

Future<void> _insertSms(AppDatabase db, String id, DateTime date) {
  return db
      .into(db.smsInbox)
      .insert(
        SmsInboxCompanion.insert(
          id: id,
          address: 'CBE',
          body: 'body $id',
          date: date,
        ),
      );
}

Future<int> _insertTransaction(
  AppDatabase db, {
  required String id,
  required int smsTimestamp,
  required int importedAt,
  TransactionDirection direction = TransactionDirection.debit,
}) {
  return db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          transactionHash: id,
          amount: 100,
          direction: direction,
          reasonRawText: 'reason $id',
          normalizedReason: 'reason $id',
          smsId: id,
          threadId: 'thread',
          senderAddress: 'CBE',
          rawSmsBody: 'body $id',
          smsTimestamp: smsTimestamp,
          importedAt: importedAt,
          parserVersion: 1,
          bankName: const Value('CBE'),
        ),
      );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('watchRecentTransactions emits the newest limited rows', () async {
    final base = DateTime(2026, 8, 1).millisecondsSinceEpoch;
    for (var i = 0; i < 8; i++) {
      final smsId = 'sms_$i';
      await _insertSms(db, smsId, DateTime(2026, 8, i + 1));
      await _insertTransaction(
        db,
        id: smsId,
        smsTimestamp: base + i,
        importedAt: i,
      );
    }

    final rows = await db.watchRecentTransactions(limit: 6).first;

    expect(rows, hasLength(6));
    expect(rows.map((r) => r.readTable(db.transactions).transactionHash), [
      'sms_7',
      'sms_6',
      'sms_5',
      'sms_4',
      'sms_3',
      'sms_2',
    ]);
  });

  test(
    'watchTransactionDateRange emits min and max transaction dates',
    () async {
      final firstDate = DateTime(2026, 1, 5);
      final lastDate = DateTime(2026, 2, 10);
      await _insertSms(db, 'first', firstDate);
      await _insertTransaction(
        db,
        id: 'first',
        smsTimestamp: firstDate.millisecondsSinceEpoch,
        importedAt: firstDate.millisecondsSinceEpoch,
      );
      await _insertSms(db, 'last', lastDate);
      await _insertTransaction(
        db,
        id: 'last',
        smsTimestamp: lastDate.millisecondsSinceEpoch,
        importedAt: lastDate.millisecondsSinceEpoch,
      );

      final range = await db.watchTransactionDateRange().first;

      expect(range, isNotNull);
      expect(range!.start, firstDate);
      expect(range.end, lastDate);
    },
  );

  test('getSplitsByTransactionIds keeps split order', () async {
    await _insertSms(db, 'split_txn', DateTime(2026, 8, 1));
    final txnId = await _insertTransaction(
      db,
      id: 'split_txn',
      smsTimestamp: DateTime(2026, 8, 1).millisecondsSinceEpoch,
      importedAt: 1,
    );
    await db.saveSplits(txnId, [
      TransactionSplit(transactionId: txnId, category: 'Food', amount: 40),
      TransactionSplit(transactionId: txnId, category: 'Transport', amount: 60),
    ]);

    final splits = await db.getSplitsByTransactionIds([txnId]);

    expect(splits[txnId]!.map((split) => split.category), [
      'Food',
      'Transport',
    ]);
  });
}
