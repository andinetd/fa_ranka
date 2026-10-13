import 'package:drift/drift.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:faranka/features/receipts/data/parsers/awash_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/boa_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/cbe_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/telebirr_sms_parser.dart';
import 'database.dart';

extension SmsLogic on AppDatabase {
  // --- SYNC: Save raw messages (ignores duplicates) ---
  Future<int> syncRawMessages(List<SmsMessage> phoneMessages) async {
    final ids = phoneMessages.map((m) => m.id.toString()).toList();
    final existing = await (select(
      smsInbox,
    )..where((t) => t.id.isIn(ids))).get();
    final existingIds = existing.map((r) => r.id).toSet();
    final newRows = phoneMessages
        .where((msg) => !existingIds.contains(msg.id.toString()))
        .map(
          (msg) => SmsInboxCompanion.insert(
            id: msg.id.toString(),
            threadId: Value(msg.threadId.toString()),
            address: msg.address ?? 'Unknown',
            body: msg.body ?? '',
            date: msg.date ?? DateTime.now(),
            isProcessed: const Value(false),
          ),
        )
        .toList();

    if (newRows.isNotEmpty) {
      await batch((batch) {
        batch.insertAll(smsInbox, newRows);
      });
    }
    return newRows.length;
  }

  // --- GET UNPROCESSED ---
  Future<List<SmsInboxData>> getUnprocessedMessages(
    String bank, {
    required int limit,
  }) {
    return (select(smsInbox)
          ..where((t) => t.address.contains(bank))
          ..where((t) => t.isProcessed.equals(false))
          ..limit(
            limit,
          ) // <--- CRITICAL: Stops it from scanning your whole history
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .get();
  }

  // --- GET MESSAGES NEEDING ENRICHMENT ---
  // Includes unprocessed messages and older processed rows missing parsed fields.
  Future<List<SmsInboxData>> getMessagesNeedingAutoParse(
    String bank, {
    required int limit,
  }) {
    return (select(smsInbox)
          ..where((t) => t.address.contains(bank))
          ..where(
            (t) =>
                t.isProcessed.equals(false) |
                t.parseSource.isNull() |
                t.transactionId.isNull() |
                t.parsedDate.isNull() |
                t.parsedTime.isNull() |
                t.amount.isNull(),
          )
          ..limit(limit)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .get();
  }

  // --- MARK PROCESSED ---
  Future<void> markAsProcessed(String smsId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(smsInbox)..where((t) => t.id.equals(smsId))).write(
      SmsInboxCompanion(
        isProcessed: const Value(true),
        processedAt: Value(now),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markSmsProcessingStarted(String smsId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await customStatement(
      'UPDATE sms_inbox SET processing_attempts = processing_attempts + 1, last_tried_at = ?, last_error = NULL WHERE id = ?',
      [now, smsId],
    );
  }

  Future<void> markSmsFailed(String smsId, String error) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(smsInbox)..where((t) => t.id.equals(smsId))).write(
      SmsInboxCompanion(lastError: Value(error), lastTriedAt: Value(now)),
    );
  }

  Future<List<SmsInboxData>> getPendingSmsForProcessing({
    int limit = 100,
    int maxAttempts = 5,
  }) {
    return (select(smsInbox)
          ..where((t) => t.isProcessed.equals(false))
          ..where((t) => t.processingAttempts.isSmallerThanValue(maxAttempts))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<SmsInboxData>> getDeadLetterMessages({
    int limit = 100,
    int minAttempts = 5,
  }) {
    return (select(smsInbox)
          ..where((t) => t.isProcessed.equals(false))
          ..where((t) => t.processingAttempts.isBiggerOrEqualValue(minAttempts))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  // --- UPDATE PARSED FIELDS ---
  Future<void> updateSmsParsedFields({
    required String smsId,
    String? transactionId,
    String? date,
    String? time,
    double? amount,
    double? commission,
    double? vat,
    double? total,
    String? fromAccount,
    String? toAccount,
    String? beneficiaryAccount,
    String? beneficiaryBank,
    String? transactionType,
    String? reason,
    String? tillNumber,
    String? tin,
    String? vatReg,
    String? parseSource,
  }) async {
    await (update(smsInbox)..where((t) => t.id.equals(smsId))).write(
      SmsInboxCompanion(
        transactionId: Value(transactionId),
        parsedDate: Value(date),
        parsedTime: Value(time),
        amount: Value(amount),
        commission: Value(commission),
        vat: Value(vat),
        total: Value(total),
        fromAccount: Value(fromAccount),
        toAccount: Value(toAccount),
        beneficiaryAccount: Value(beneficiaryAccount),
        beneficiaryBank: Value(beneficiaryBank),
        transactionType: Value(transactionType),
        reason: Value(reason),
        tillNumber: Value(tillNumber),
        tin: Value(tin),
        vatReg: Value(vatReg),
        parseSource: Value(parseSource),
      ),
    );
  }

  // --- STATS: Watch remaining count ---
  Stream<int> watchUnprocessedCount() {
    final countColumn = smsInbox.id.count();
    final query = selectOnly(smsInbox)
      ..addColumns([countColumn])
      ..where(smsInbox.isProcessed.equals(false));
    return query.map((row) => row.read(countColumn) ?? 0).watchSingle();
  }

  Future<List<SmsInboxData>> getAllProcessedMessages() {
    return (select(smsInbox)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<Map<String, int>> getProcessedCountPerBank() async {
    final rows = await (select(
      smsInbox,
    )..where((t) => t.isProcessed.equals(true))).get();
    final Map<String, int> counts = {};
    for (final row in rows) {
      final addr = row.address.toLowerCase();
      if (addr.contains('awash')) {
        counts['awash'] = (counts['awash'] ?? 0) + 1;
      } else if (addr.contains('cbe')) {
        counts['cbe'] = (counts['cbe'] ?? 0) + 1;
      } else if (addr == '127' ||
          addr.contains('telebirr') ||
          addr.contains('ethio telecom')) {
        counts['telebirr'] = (counts['telebirr'] ?? 0) + 1;
      } else if (addr.contains('boa') || addr.contains('abyssinia')) {
        counts['boa'] = (counts['boa'] ?? 0) + 1;
      }
    }
    return counts;
  }

  // --- CATEGORY EDITING EXTENSIONS ---

  // 1. Rename Category
  Future<void> renameCategory(String oldName, String newName) async {
    await transaction(() async {
      // Update the category table
      await (update(categories)..where((t) => t.name.equals(oldName))).write(
        CategoriesCompanion(
          name: Value(newName),
          normalizedName: Value(newName.toLowerCase()),
        ),
      );
      // Update all transactions linked to this name
      await (update(transactions)
            ..where((t) => t.parsedCategory.equals(oldName)))
          .write(TransactionsCompanion(parsedCategory: Value(newName)));
      // Update all splits linked to this name
      await ensureTransactionSplitsTable();
      await customStatement(
        'UPDATE transaction_splits SET category = ? WHERE category = ?',
        [newName, oldName],
      );
    });
  }

  // 2. Merge Categories (Source is deleted, transactions move to Target)
  Future<void> mergeCategories(String sourceName, String targetName) async {
    await transaction(() async {
      // Move all transactions
      await (update(transactions)
            ..where((t) => t.parsedCategory.equals(sourceName)))
          .write(TransactionsCompanion(parsedCategory: Value(targetName)));
      // Move all splits
      await ensureTransactionSplitsTable();
      await customStatement(
        'UPDATE transaction_splits SET category = ? WHERE category = ?',
        [targetName, sourceName],
      );
      // Delete the source category
      await (delete(categories)..where((t) => t.name.equals(sourceName))).go();
    });
  }

  // 3. Reassign Single Transaction
  Future<void> reassignTransaction(int txnId, String newCategory) {
    return (update(transactions)..where((t) => t.id.equals(txnId))).write(
      TransactionsCompanion(parsedCategory: Value(newCategory)),
    );
  }

  Future<void> importAwashToTransactions({
    required Map<String, dynamic> parsedData,
    required SmsInboxData originalSms,
    String bankName = 'Awash Bank',
    String defaultReason = 'Bank Transaction',
    String? localImagePath,
  }) async {
    final dir = _resolveTransactionDirection(parsedData, originalSms.body);
    final transactionAmount =
        _toDouble(parsedData['total']) ??
        _toDouble(parsedData['amount']) ??
        originalSms.total ??
        originalSms.amount ??
        0.0;

    final companion = TransactionsCompanion.insert(
      // Unique hash (Required)
      transactionHash: parsedData['transactionId'] ?? originalSms.id,

      amount: transactionAmount,
      direction: dir,
      balanceAfter: Value(
        _toDouble(parsedData['balance']) ??
            _toDouble(parsedData['balance_after']) ??
            _toDouble(parsedData['balanceAfter']),
      ),

      senderAddress:
          originalSms.address, // Maps 'address' from SMS to 'senderAddress'
      threadId: originalSms.threadId ?? '0',
      smsId: originalSms.id,
      rawSmsBody: originalSms.body,
      smsTimestamp: originalSms.date.millisecondsSinceEpoch,
      importedAt: DateTime.now().millisecondsSinceEpoch,
      reasonRawText: parsedData['reason'] ?? defaultReason,
      normalizedReason: parsedData['reason'] ?? '',
      parsedCategory: Value(parsedData['parsedCategory'] ?? 'Uncategorized'),
      parserVersion: 1,

      bankName: Value(bankName),
      counterpartyName: Value(
        parsedData['counterparty'] ??
            (parsedData['direction'] == 'Credit'
                ? parsedData['from_account']
                : parsedData['to_account']),
      ),
      bankTransactionId: Value(
        parsedData['transactionId'] ??
            parsedData['transaction_id'] ??
            parsedData['transaction_ref'],
      ),
      commission: Value(parsedData['commission'] ?? 0.0),
      vat: Value(parsedData['vat'] ?? 0.0),
      receiptUrl: Value(parsedData['url']),
      localReceiptPath: Value(localImagePath),
      currency: const Value('ETB'),
    );

    await transaction(() async {
      await into(
        transactions,
      ).insert(companion, mode: InsertMode.insertOrReplace);
      await markAsProcessed(originalSms.id);
    });
  }

  /// Backfills incorrect transaction balances and amounts from SMS
  Future<int> repairTransactionBalances() async {
    final toFix = await customSelect('''
      SELECT t.id, t.bank_name, t.raw_sms_body, t.balance_after
      FROM transactions t
      WHERE t.raw_sms_body IS NOT NULL AND t.raw_sms_body != ''
    ''').get();

    int fixed = 0;
    for (final row in toFix) {
      final id = row.read<int>('id');
      final bankName = row.read<String?>('bank_name')?.toLowerCase() ?? '';
      final rawBody = row.read<String>('raw_sms_body');
      final currentBalance = row.read<double?>('balance_after');

      double? extractedBalance;
      if (bankName.contains('awash')) {
        extractedBalance = AwashSmsParser.extractBalance(rawBody);
      } else if (bankName.contains('cbe')) {
        extractedBalance = CbeSmsParser.extractBalance(rawBody);
      } else if (bankName.contains('tele') || bankName.contains('ethio')) {
        extractedBalance = TelebirrSmsParser.extractBalance(rawBody);
      } else if (bankName.contains('boa') || bankName.contains('abyssinia')) {
        extractedBalance = BoaSmsParser.extractBalance(rawBody);
      }

      if (extractedBalance != null &&
          (currentBalance == null ||
              (extractedBalance - currentBalance).abs() > 0.009)) {
        await (update(transactions)..where((t) => t.id.equals(id))).write(
          TransactionsCompanion(balanceAfter: Value(extractedBalance)),
        );
        fixed++;
      }
    }
    return fixed;
  }

  Future<int> repairTransactionAmountsFromSms() async {
    final toFix = await customSelect('''
      SELECT t.id, COALESCE(t.amount, 0) AS old_amount,
             COALESCE(s.total, s.amount) AS new_amount
      FROM transactions t
      JOIN sms_inbox s ON s.id = t.sms_id
      WHERE (s.total IS NOT NULL OR s.amount IS NOT NULL)
        AND ABS(COALESCE(t.amount, 0) - COALESCE(s.total, s.amount)) > 0.009
    ''').get();

    if (toFix.isEmpty) return 0;

    for (final row in toFix) {
      final id = row.read<int>('id');
      final oldAmount = row.read<double>('old_amount');
      final newAmount = row.read<double>('new_amount');

      await (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(amount: Value(newAmount)),
      );

      // Scale splits proportionally
      final splits = await getSplitsForTransaction(id);
      if (splits.isNotEmpty) {
        final ratio = newAmount / oldAmount;
        await saveSplits(
          id,
          splits
              .map(
                (s) => TransactionSplit(
                  transactionId: s.transactionId,
                  category: s.category,
                  amount: (s.amount * ratio).roundToDouble(),
                  sortOrder: s.sortOrder,
                ),
              )
              .toList(),
        );
      }
    }

    return toFix.length;
  }

  TransactionDirection _resolveTransactionDirection(
    Map<String, dynamic> parsedData,
    String rawSmsBody,
  ) {
    final direct = _directionFromText(parsedData['direction']?.toString());
    if (direct != TransactionDirection.unknown) return direct;

    // Fallback from transaction type labels extracted by receipt parser.
    final transactionType = parsedData['transaction_type']
        ?.toString()
        .toLowerCase();
    if (transactionType != null && transactionType.isNotEmpty) {
      if (transactionType.contains('cash in') ||
          transactionType.contains('deposit') ||
          transactionType.contains('receive')) {
        return TransactionDirection.credit;
      }
      if (transactionType.contains('transfer') ||
          transactionType.contains('payment') ||
          transactionType.contains('purchase') ||
          transactionType.contains('cash out') ||
          transactionType.contains('send')) {
        return TransactionDirection.debit;
      }
    }

    // Final fallback mirrors awash_parser_gui.py extract_direction behavior.
    return _directionFromText(rawSmsBody);
  }

  TransactionDirection _directionFromText(String? value) {
    final text = (value ?? '').toLowerCase();
    if (text.contains('credited') ||
        text.contains('received') ||
        text == 'credit') {
      return TransactionDirection.credit;
    }
    if (text.contains('debited') ||
        text.contains('you have sent') ||
        text.contains('have sent') ||
        text.contains('sent etb') ||
        text.contains('transferred') ||
        text.contains('transfered') ||
        text == 'debit') {
      return TransactionDirection.debit;
    }
    return TransactionDirection.unknown;
  }

  Future<List<TransactionData>> getRecentTransactions(int n) async {
    return (select(transactions)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.importedAt, mode: OrderingMode.desc),
          ])
          ..limit(n))
        .get();
  }

  Future<void> resetSmsToUnprocessed(String smsId) async {
    await (update(smsInbox)..where((t) => t.id.equals(smsId))).write(
      SmsInboxCompanion(
        isProcessed: const Value(false),
        processedAt: const Value(null),
        lastError: const Value(null),
        lastTriedAt: const Value(null),
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', ''));
  }
}
