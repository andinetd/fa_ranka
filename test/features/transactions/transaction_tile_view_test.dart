import 'package:flutter_test/flutter_test.dart';

import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/models/transaction_tile_view.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';

void main() {
  test('Telebirr debit shows category instead of generic sender title', () {
    final view = _build(
      bankName: 'Ethio telecom',
      counterpartyName: 'Ethio telecom',
      parsedCategory: 'Buy Package USSD',
      direction: TransactionDirection.debit,
    );
    expect(view.title, 'Buy Package USSD');
  });

  test('Telebirr P2P credit keeps counterparty name title', () {
    final view = _build(
      bankName: 'Ethio telecom',
      counterpartyName: 'Yohannes Hailelul',
      parsedCategory: 'Yohannes hailelul',
      direction: TransactionDirection.credit,
    );
    expect(view.title, 'Yohannes Hailelul');
  });

  test('Debit with empty counterparty keeps bank name title', () {
    final view = _build(
      bankName: 'CBE',
      counterpartyName: null,
      parsedCategory: 'Buna',
      direction: TransactionDirection.debit,
    );
    expect(view.title, 'CBE');
  });

  test('Non-generic debit keeps counterparty name title', () {
    final view = _build(
      bankName: 'CBE',
      counterpartyName: 'Abebe Kebede',
      parsedCategory: 'Buna',
      direction: TransactionDirection.debit,
    );
    expect(view.title, 'Abebe Kebede');
  });
}

TransactionTileView _build({
  required String bankName,
  required String? counterpartyName,
  required String parsedCategory,
  required TransactionDirection direction,
}) {
  final txn = TransactionData(
    id: 1,
    transactionHash: 'hash',
    amount: 10.0,
    currency: 'ETB',
    direction: direction,
    counterpartyName: counterpartyName,
    counterpartyNumber: null,
    bankName: bankName,
    bankTransactionId: null,
    referenceNumber: null,
    channel: null,
    location: null,
    balanceAfter: null,
    receiptUrl: null,
    localReceiptPath: null,
    reasonRawText: '',
    normalizedReason: '',
    parsedCategory: parsedCategory,
    commission: 0,
    vat: 0,
    branchName: null,
    smsId: '1',
    threadId: '1',
    senderAddress: '127',
    rawSmsBody: '',
    smsTimestamp: 0,
    importedAt: 0,
    smsRead: true,
    parserVersion: 1,
    isRecurring: false,
    recurringPattern: null,
    receiptExtractionStatus: 'none',
    receiptExtractionError: null,
    receiptExtractionAttemptedAt: null,
    extractionRetryAttempts: 0,
    extractionNextRetryAt: null,
  );
  return buildTransactionTileView(
    txn: txn,
    sms: null,
    splits: null,
    calendarMode: CalendarMode.gregorian,
    useCompact: false,
  );
}
