import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:rxdart/rxdart.dart';
import 'package:faranka/features/receipts/data/parsers/awash_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/boa_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/cbe_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/telebirr_sms_parser.dart';
import 'database.dart';

extension SmsLogic on AppDatabase {
  Future<void> _ensureBudgetConfigsTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS budget_configs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        period TEXT NOT NULL,
        amount REAL NOT NULL,
        categories_json TEXT NOT NULL,
        account TEXT NOT NULL,
        start_at INTEGER NOT NULL DEFAULT 0,
        end_at INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    try {
      await customStatement(
        'ALTER TABLE budget_configs ADD COLUMN start_at INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
    try {
      await customStatement(
        'ALTER TABLE budget_configs ADD COLUMN end_at INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
  }

  Future<void> _ensureTransactionSplitsTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS transaction_splits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<List<TransactionSplit>> getSplitsForTransaction(
    int transactionId,
  ) async {
    await _ensureTransactionSplitsTable();
    final rows = await customSelect(
      'SELECT id, transaction_id, category, amount, sort_order FROM transaction_splits WHERE transaction_id = ? ORDER BY sort_order',
      variables: [Variable<int>(transactionId)],
    ).get();
    return rows
        .map(
          (r) => TransactionSplit(
            id: r.read<int>('id'),
            transactionId: r.read<int>('transaction_id'),
            category: r.read<String>('category'),
            amount: r.read<double>('amount'),
            sortOrder: r.read<int>('sort_order'),
          ),
        )
        .toList();
  }

  Future<Map<int, List<TransactionSplit>>> getSplitsByTransactionIds(
    List<int> ids,
  ) async {
    if (ids.isEmpty) return {};
    await _ensureTransactionSplitsTable();
    final placeholders = ids.map((_) => '?').join(',');
    final rows = await customSelect(
      'SELECT id, transaction_id, category, amount, sort_order FROM transaction_splits WHERE transaction_id IN ($placeholders) ORDER BY transaction_id, sort_order',
      variables: ids.map((id) => Variable<int>(id)).toList(),
    ).get();
    final Map<int, List<TransactionSplit>> result = {};
    for (final r in rows) {
      final txnId = r.read<int>('transaction_id');
      result.putIfAbsent(txnId, () => []);
      result[txnId]!.add(
        TransactionSplit(
          id: r.read<int>('id'),
          transactionId: txnId,
          category: r.read<String>('category'),
          amount: r.read<double>('amount'),
          sortOrder: r.read<int>('sort_order'),
        ),
      );
    }
    return result;
  }

  Stream<List<TypedResult>> watchRecentTransactions({int limit = 6}) {
    final query =
        select(transactions).join([
            leftOuterJoin(smsInbox, smsInbox.id.equalsExp(transactions.smsId)),
          ])
          ..orderBy([
            OrderingTerm(
              expression: transactions.smsTimestamp,
              mode: OrderingMode.desc,
            ),
            OrderingTerm(
              expression: transactions.importedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit);
    return query.watch();
  }

  Stream<TransactionDateRange?> watchTransactionDateRange() {
    return customSelect(
      '''
        SELECT MIN(sms_timestamp) AS min_ts, MAX(sms_timestamp) AS max_ts
        FROM transactions
      ''',
      readsFrom: {transactions},
    ).watchSingle().map((row) {
      final minTs = row.readNullable<int>('min_ts');
      final maxTs = row.readNullable<int>('max_ts');
      if (minTs == null || maxTs == null) return null;

      final now = DateTime.now();
      final end = DateTime.fromMillisecondsSinceEpoch(maxTs);
      return TransactionDateRange(
        start: DateTime.fromMillisecondsSinceEpoch(minTs),
        end: now.isBefore(end) ? now : end,
      );
    });
  }

  Future<void> saveSplits(
    int transactionId,
    List<TransactionSplit> splits,
  ) async {
    await _ensureTransactionSplitsTable();
    await transaction(() async {
      await customStatement(
        'DELETE FROM transaction_splits WHERE transaction_id = ?',
        [transactionId],
      );
      for (int i = 0; i < splits.length; i++) {
        final s = splits[i];
        await customInsert(
          'INSERT INTO transaction_splits (transaction_id, category, amount, sort_order) VALUES (?, ?, ?, ?)',
          variables: [
            Variable<int>(transactionId),
            Variable<String>(s.category),
            Variable<double>(s.amount),
            Variable<int>(i),
          ],
        );
      }
    });
    notifyUpdates({const TableUpdate('transactions')});
  }

  Future<void> deleteSplitsForTransaction(int transactionId) async {
    await _ensureTransactionSplitsTable();
    await customStatement(
      'DELETE FROM transaction_splits WHERE transaction_id = ?',
      [transactionId],
    );
    notifyUpdates({const TableUpdate('transactions')});
  }

  Future<void> saveBudgetConfig({
    required String name,
    required String period,
    required double amount,
    required List<String> categories,
    required String account,
    int startAt = 0,
    int endAt = 0,
  }) async {
    await _ensureBudgetConfigsTable();
    final now = DateTime.now().millisecondsSinceEpoch;
    final categoriesJson = jsonEncode(categories);
    await customInsert(
      '''
        INSERT INTO budget_configs (name, period, amount, categories_json, account, start_at, end_at, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable<String>(name),
        Variable<String>(period),
        Variable<double>(amount),
        Variable<String>(categoriesJson),
        Variable<String>(account),
        Variable<int>(startAt),
        Variable<int>(endAt),
        Variable<int>(now),
        Variable<int>(now),
      ],
    );
    notifyUpdates({const TableUpdate('budget_configs')});
  }

  Future<void> updateBudgetConfig({
    required int id,
    required String name,
    required String period,
    required double amount,
    required List<String> categories,
    required String account,
    int startAt = 0,
    int endAt = 0,
  }) async {
    await _ensureBudgetConfigsTable();
    final now = DateTime.now().millisecondsSinceEpoch;
    final categoriesJson = jsonEncode(categories);
    await customUpdate(
      '''
        UPDATE budget_configs
        SET name = ?, period = ?, amount = ?, categories_json = ?, account = ?, start_at = ?, end_at = ?, updated_at = ?
        WHERE id = ?
      ''',
      variables: [
        Variable<String>(name),
        Variable<String>(period),
        Variable<double>(amount),
        Variable<String>(categoriesJson),
        Variable<String>(account),
        Variable<int>(startAt),
        Variable<int>(endAt),
        Variable<int>(now),
        Variable<int>(id),
      ],
    );
    notifyUpdates({const TableUpdate('budget_configs')});
  }

  Future<void> deleteBudgetConfig({required int id}) async {
    await _ensureBudgetConfigsTable();
    await customStatement('DELETE FROM budget_configs WHERE id = ?', [id]);
    notifyUpdates({const TableUpdate('budget_configs')});
  }

  Future<List<BudgetConfigRow>> getBudgetConfigs() async {
    await _ensureBudgetConfigsTable();
    final rows = await customSelect('''
      SELECT id, name, period, amount, categories_json, account, start_at, end_at, created_at, updated_at
      FROM budget_configs
      ORDER BY updated_at DESC
      ''').get();
    return rows.map((row) {
      final categoriesRaw = row.read<String>('categories_json');
      List<String> decoded;
      try {
        decoded = (jsonDecode(categoriesRaw) as List<dynamic>)
            .map((item) => item.toString())
            .toList();
      } catch (_) {
        decoded = [];
      }
      return BudgetConfigRow(
        id: row.read<int>('id'),
        name: row.read<String>('name'),
        period: row.read<String>('period'),
        amount: row.read<double>('amount'),
        categories: decoded,
        account: row.read<String>('account'),
        startAt: row.read<int>('start_at'),
        endAt: row.read<int>('end_at'),
        createdAt: row.read<int>('created_at'),
        updatedAt: row.read<int>('updated_at'),
      );
    }).toList();
  }

  Stream<List<BudgetConfigRow>> watchBudgetConfigs() async* {
    await _ensureBudgetConfigsTable();
    yield await getBudgetConfigs();
    yield* tableUpdates(
      TableUpdateQuery.onTableName('budget_configs'),
    ).asyncMap((_) {
      return getBudgetConfigs();
    });
  }

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

  double _calculateBalanceForRows(
    List<TransactionData> rows, {
    String? normalizedFilter,
    int? cutoffTimestamp,
  }) {
    final filteredRows = normalizedFilter == null || normalizedFilter.isEmpty
        ? rows
        : rows.where((row) {
            final bank = row.bankName?.toLowerCase() ?? '';
            return bank == normalizedFilter || bank.contains(normalizedFilter);
          }).toList();

    if (filteredRows.isEmpty) return 0.0;

    final Map<String, List<TransactionData>> bankGroups = {};
    for (final row in filteredRows) {
      final bank = row.bankName?.toLowerCase() ?? 'unknown';
      bankGroups.putIfAbsent(bank, () => []).add(row);
    }

    double totalBalance = 0;
    for (final entry in bankGroups.entries) {
      final bankRows = entry.value;
      if (bankRows.isEmpty) continue;

      final orderedRows = List<TransactionData>.from(bankRows)
        ..sort((a, b) {
          final timeCompare = a.smsTimestamp.compareTo(b.smsTimestamp);
          if (timeCompare != 0) return timeCompare;
          return a.importedAt.compareTo(b.importedAt);
        });

      double? runningBalance;
      for (final row in orderedRows) {
        if (cutoffTimestamp != null && row.smsTimestamp > cutoffTimestamp) {
          break;
        }

        final snapshot = row.balanceAfter;
        if (snapshot != null) {
          runningBalance = snapshot;
          continue;
        }

        if (runningBalance == null) continue;
        if (row.direction == TransactionDirection.credit) {
          runningBalance += row.amount;
        } else if (row.direction == TransactionDirection.debit) {
          runningBalance -= row.amount;
        }
      }

      if (runningBalance != null) {
        totalBalance += runningBalance;
      } else {
        double sum = 0;
        for (final row in orderedRows) {
          if (cutoffTimestamp != null && row.smsTimestamp > cutoffTimestamp) {
            break;
          }
          if (row.direction == TransactionDirection.credit) {
            sum += row.amount;
          } else if (row.direction == TransactionDirection.debit) {
            sum -= row.amount;
          }
        }
        totalBalance += sum;
      }
    }

    return totalBalance;
  }

  Stream<double> watchTotalBalance({String? bankFilter}) {
    final normalizedFilter = bankFilter?.toLowerCase().trim();
    final hasBankFilter =
        normalizedFilter != null && normalizedFilter.isNotEmpty;
    return customSelect(
      '''
        SELECT COALESCE(SUM(
          CASE
            WHEN direction = 'credit' THEN amount
            WHEN direction = 'debit' THEN -amount
            ELSE 0
          END
        ), 0.0) AS balance
        FROM transactions
        WHERE (? = 0 OR lower(coalesce(bank_name, '')) LIKE ?)
      ''',
      variables: [
        Variable<int>(hasBankFilter ? 1 : 0),
        Variable<String>(hasBankFilter ? '%$normalizedFilter%' : ''),
      ],
      readsFrom: {transactions},
    ).watchSingle().map((row) => row.read<double>('balance'));
  }

  Stream<double> watchBalanceChangePercentForDays(
    int days, {
    String? bankFilter,
  }) {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final normalizedFilter = bankFilter?.toLowerCase().trim();

    return select(transactions).watch().map((rows) {
      final currentBalance = _calculateBalanceForRows(
        rows,
        normalizedFilter: normalizedFilter,
      );
      final previousBalance = _calculateBalanceForRows(
        rows,
        normalizedFilter: normalizedFilter,
        cutoffTimestamp: cutoff,
      );

      if (previousBalance == 0) {
        if (currentBalance == 0) return 0.0;
        return currentBalance > 0 ? 100.0 : -100.0;
      }

      return ((currentBalance - previousBalance) / previousBalance.abs()) * 100;
    });
  }

  // Inside your database extension or AppDatabase class
  Stream<Map<String, double>> watchStatsForDays(
    int days, {
    String? bankFilter,
  }) {
    // Calculate the cutoff timestamp (Current time - X days)
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final normalizedFilter = bankFilter?.toLowerCase().trim();

    final hasBankFilter =
        normalizedFilter != null && normalizedFilter.isNotEmpty;

    return customSelect(
      '''
        SELECT
          COALESCE(SUM(CASE WHEN direction = 'debit' THEN amount ELSE 0 END), 0.0) AS sent,
          COALESCE(SUM(CASE WHEN direction = 'credit' THEN amount ELSE 0 END), 0.0) AS received
        FROM transactions
        WHERE sms_timestamp >= ?
          AND (? = 0 OR lower(coalesce(bank_name, '')) LIKE ?)
      ''',
      variables: [
        Variable<int>(cutoff),
        Variable<int>(hasBankFilter ? 1 : 0),
        Variable<String>(hasBankFilter ? '%$normalizedFilter%' : ''),
      ],
      readsFrom: {transactions},
    ).watchSingle().map((row) {
      return {
        'sent': row.read<double>('sent'),
        'received': row.read<double>('received'),
      };
    });
  }

  Stream<List<double>> watchDailySpendingForDays(
    int days, {
    String? bankFilter,
  }) {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days - 1))
        .millisecondsSinceEpoch;
    final normalizedFilter = bankFilter?.toLowerCase().trim();

    return (select(
      transactions,
    )..where((t) => t.smsTimestamp.isBiggerOrEqualValue(cutoff))).watch().map((
      rows,
    ) {
      final now = DateTime.now();
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days - 1));

      final buckets = List<double>.filled(days, 0.0);

      for (final row in rows) {
        if (row.direction != TransactionDirection.debit) continue;

        if (normalizedFilter != null && normalizedFilter.isNotEmpty) {
          final bank = row.bankName?.toLowerCase() ?? '';
          if (!(bank == normalizedFilter || bank.contains(normalizedFilter))) {
            continue;
          }
        }

        final ts = DateTime.fromMillisecondsSinceEpoch(row.smsTimestamp);
        final dayKey = DateTime(ts.year, ts.month, ts.day);
        final index = dayKey.difference(startDate).inDays;
        if (index < 0 || index >= days) continue;

        buckets[index] += row.amount;
      }

      return buckets;
    });
  }

  Stream<List<double>> watchBalanceHistoryForDays(
    int days, {
    String? bankFilter,
  }) {
    final normalizedFilter = bankFilter?.toLowerCase().trim();
    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    return select(transactions).watch().map((rows) {
      final balances = List<double>.filled(days, 0.0);
      for (int i = 0; i < days; i++) {
        final endOfDay =
            DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            ).add(Duration(days: i + 1)).millisecondsSinceEpoch -
            1;

        balances[i] = _calculateBalanceForRows(
          rows,
          normalizedFilter: normalizedFilter,
          cutoffTimestamp: endOfDay,
        );
      }
      return balances;
    });
  }

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
      await _ensureTransactionSplitsTable();
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
      await _ensureTransactionSplitsTable();
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

      // --- THE FIXES FOR YOUR ERRORS ---
      senderAddress:
          originalSms.address, // Maps 'address' from SMS to 'senderAddress'
      threadId: originalSms.threadId ?? '0',
      // Other Required Fields from your Table definition
      smsId: originalSms.id,
      rawSmsBody: originalSms.body,
      smsTimestamp: originalSms.date.millisecondsSinceEpoch,
      importedAt: DateTime.now().millisecondsSinceEpoch,
      reasonRawText: parsedData['reason'] ?? defaultReason,
      normalizedReason: parsedData['reason'] ?? '',
      parsedCategory: Value(parsedData['parsedCategory'] ?? 'Uncategorized'),
      parserVersion: 1,

      // Nullable/Optional Fields
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

  /// Backfills incorrect transaction amounts using parsed sms_inbox.amount.
  /// This corrects historical rows where amount was saved from balance-like totals.
  /// Re-extracts balance from rawSmsBody for transactions where
  /// balanceAfter is missing or stale, using the parser balance patterns.
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

  Stream<List<CategorySum>> watchCategorySummaryAllParsed({
    int? days,
    TransactionDirection? direction,
    String? bankFilter,
    int? startTimestamp,
    int? endTimestamp,
  }) {
    // Filter by direction: debit (spending), credit (income), or null (all)
    final query = select(transactions).join([
      leftOuterJoin(smsInbox, smsInbox.id.equalsExp(transactions.smsId)),
    ]);

    if (direction != null) {
      query.where(transactions.direction.equalsValue(direction));
    }

    if (startTimestamp != null) {
      query.where(
        transactions.smsTimestamp.isBiggerOrEqualValue(startTimestamp),
      );
    } else if (days != null) {
      final cutoff = DateTime.now()
          .subtract(Duration(days: days))
          .millisecondsSinceEpoch;
      query.where(transactions.smsTimestamp.isBiggerOrEqualValue(cutoff));
    }

    if (endTimestamp != null) {
      query.where(
        transactions.smsTimestamp.isSmallerOrEqualValue(endTimestamp),
      );
    }

    final normalizedFilter = bankFilter?.toLowerCase().trim();

    final transactionStream = query.watch();
    final splitChanges = tableUpdates(
      TableUpdateQuery.onTableName('transaction_splits'),
    ).asyncMap((_) => query.get());

    return Rx.merge([transactionStream, splitChanges]).asyncMap((rows) async {
      final filteredRows = normalizedFilter == null || normalizedFilter.isEmpty
          ? rows
          : rows.where((row) {
              final transaction = row.readTable(transactions);
              final bank = transaction.bankName?.toLowerCase() ?? '';
              return bank == normalizedFilter ||
                  bank.contains(normalizedFilter);
            }).toList();

      final txnIds = filteredRows
          .map((r) => r.readTable(transactions).id)
          .toList();
      final allSplits = await getSplitsByTransactionIds(txnIds);

      final Map<String, double> sums = {};
      final Map<String, int> counts = {};
      for (final row in filteredRows) {
        final transaction = row.readTable(transactions);
        final spendingAmount = transaction.amount;
        final txnSplits = allSplits[transaction.id];

        if (txnSplits == null || txnSplits.isEmpty) {
          sums[transaction.parsedCategory] =
              (sums[transaction.parsedCategory] ?? 0) + spendingAmount;
          counts[transaction.parsedCategory] =
              (counts[transaction.parsedCategory] ?? 0) + 1;
        } else {
          double splitSum = 0;
          for (final split in txnSplits) {
            sums[split.category] = (sums[split.category] ?? 0) + split.amount;
            splitSum += split.amount;
            counts[split.category] = (counts[split.category] ?? 0) + 1;
          }
          final remainder = spendingAmount - splitSum;
          if (remainder > 0.009) {
            sums[transaction.parsedCategory] =
                (sums[transaction.parsedCategory] ?? 0) + remainder;
            counts[transaction.parsedCategory] =
                (counts[transaction.parsedCategory] ?? 0) + 1;
          }
        }
      }

      final sorted =
          sums.entries
              .map(
                (e) => CategorySum(
                  name: e.key,
                  total: e.value,
                  count: counts[e.key] ?? 0,
                ),
              )
              .toList()
            ..sort((a, b) => b.total.compareTo(a.total));

      return sorted;
    });
  }

  Stream<List<CategoryMessageCount>> watchCategoryMessageCounts({
    TransactionDirection? direction,
    int? days,
    String? bankFilter,
  }) {
    final query = select(transactions);

    if (direction != null) {
      query.where((t) => t.direction.equalsValue(direction));
    }

    if (days != null) {
      final cutoff = DateTime.now()
          .subtract(Duration(days: days))
          .millisecondsSinceEpoch;
      query.where((t) => t.smsTimestamp.isBiggerOrEqualValue(cutoff));
    }

    final normalizedFilter = bankFilter?.toLowerCase().trim();

    return query.watch().map((rows) {
      final Map<String, int> counts = {};

      final filteredRows = normalizedFilter == null || normalizedFilter.isEmpty
          ? rows
          : rows.where((row) {
              final bank = row.bankName?.toLowerCase() ?? '';
              return bank == normalizedFilter ||
                  bank.contains(normalizedFilter);
            }).toList();

      for (final transaction in filteredRows) {
        counts[transaction.parsedCategory] =
            (counts[transaction.parsedCategory] ?? 0) + 1;
      }

      final sorted =
          counts.entries
              .map(
                (entry) => CategoryMessageCount(
                  name: entry.key,
                  messageCount: entry.value,
                ),
              )
              .toList()
            ..sort((a, b) {
              final countCompare = b.messageCount.compareTo(a.messageCount);
              if (countCompare != 0) return countCompare;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

      return sorted;
    });
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

extension GoalsLogic on AppDatabase {
  Future<void> _ensureGoalsTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        target_amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'ETB',
        period TEXT NOT NULL DEFAULT '',
        start_date INTEGER NOT NULL DEFAULT 0,
        end_date INTEGER NOT NULL DEFAULT 0,
        account_filter TEXT NOT NULL DEFAULT 'All Accounts',
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        growth_mode INTEGER NOT NULL DEFAULT 0,
        starting_balance REAL NOT NULL DEFAULT 0.0
      )
    ''');
    try {
      await customStatement(
        'ALTER TABLE goals ADD COLUMN growth_mode INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
    try {
      await customStatement(
        'ALTER TABLE goals ADD COLUMN starting_balance REAL NOT NULL DEFAULT 0.0',
      );
    } catch (_) {}
  }

  Future<void> saveGoal({
    required String name,
    required String type,
    required double targetAmount,
    String currency = 'ETB',
    String? period,
    int startDate = 0,
    int endDate = 0,
    String accountFilter = 'All Accounts',
    bool growthMode = false,
    double startingBalance = 0.0,
  }) async {
    await _ensureGoalsTable();
    final now = DateTime.now().millisecondsSinceEpoch;
    final periodValue = period ?? '';
    await customInsert(
      '''
        INSERT INTO goals (name, type, target_amount, currency, period, start_date, end_date, account_filter, created_at, updated_at, growth_mode, starting_balance)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable<String>(name),
        Variable<String>(type),
        Variable<double>(targetAmount),
        Variable<String>(currency),
        Variable<String>(periodValue),
        Variable<int>(startDate),
        Variable<int>(endDate),
        Variable<String>(accountFilter),
        Variable<int>(now),
        Variable<int>(now),
        Variable<int>(growthMode ? 1 : 0),
        Variable<double>(startingBalance),
      ],
    );
    notifyUpdates({const TableUpdate('goals')});
  }

  Future<void> updateGoal({
    required int id,
    required String name,
    required String type,
    required double targetAmount,
    String? period,
    int startDate = 0,
    int endDate = 0,
    String accountFilter = 'All Accounts',
    bool growthMode = false,
    double startingBalance = 0.0,
  }) async {
    await _ensureGoalsTable();
    final now = DateTime.now().millisecondsSinceEpoch;
    final periodValue = period ?? '';
    await customUpdate(
      '''
        UPDATE goals
        SET name = ?, type = ?, target_amount = ?, period = ?, start_date = ?, end_date = ?, account_filter = ?, updated_at = ?, growth_mode = ?, starting_balance = ?
        WHERE id = ?
      ''',
      variables: [
        Variable<String>(name),
        Variable<String>(type),
        Variable<double>(targetAmount),
        Variable<String>(periodValue),
        Variable<int>(startDate),
        Variable<int>(endDate),
        Variable<String>(accountFilter),
        Variable<int>(now),
        Variable<int>(growthMode ? 1 : 0),
        Variable<double>(startingBalance),
        Variable<int>(id),
      ],
    );
    notifyUpdates({const TableUpdate('goals')});
  }

  Future<void> deleteGoal({required int id}) async {
    await _ensureGoalsTable();
    await customStatement('DELETE FROM goals WHERE id = ?', [id]);
    notifyUpdates({const TableUpdate('goals')});
  }

  Future<List<GoalRow>> getGoals() async {
    await _ensureGoalsTable();
    final rows = await customSelect('''
      SELECT id, name, type, target_amount, currency, period, start_date, end_date, account_filter, is_completed, completed_at, created_at, updated_at, growth_mode, starting_balance
      FROM goals
      ORDER BY updated_at DESC
    ''').get();
    return rows.map((row) {
      final rawPeriod = row.read<String>('period');
      return GoalRow(
        id: row.read<int>('id'),
        name: row.read<String>('name'),
        type: row.read<String>('type'),
        targetAmount: row.read<double>('target_amount'),
        currency: row.read<String>('currency'),
        period: rawPeriod.isEmpty ? null : rawPeriod,
        startDate: row.read<int>('start_date'),
        endDate: row.read<int>('end_date'),
        accountFilter: row.read<String>('account_filter'),
        isCompleted: row.read<int>('is_completed') == 1,
        completedAt: row.read<int?>('completed_at'),
        createdAt: row.read<int>('created_at'),
        updatedAt: row.read<int>('updated_at'),
        growthMode: row.read<int>('growth_mode') == 1,
        startingBalance: row.read<double>('starting_balance'),
      );
    }).toList();
  }

  Stream<List<GoalRow>> watchGoals() async* {
    await _ensureGoalsTable();
    yield await getGoals();
    yield* tableUpdates(TableUpdateQuery.onTableName('goals')).asyncMap((_) {
      return getGoals();
    });
  }

  Future<void> markGoalCompleted(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await customUpdate(
      'UPDATE goals SET is_completed = 1, completed_at = ?, updated_at = ? WHERE id = ?',
      variables: [Variable<int>(now), Variable<int>(now), Variable<int>(id)],
    );
    notifyUpdates({const TableUpdate('goals')});
  }

  Future<void> markGoalIncomplete(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await customUpdate(
      'UPDATE goals SET is_completed = 0, completed_at = NULL, updated_at = ? WHERE id = ?',
      variables: [Variable<int>(now), Variable<int>(id)],
    );
    notifyUpdates({const TableUpdate('goals')});
  }

  Future<Map<String, double>> computeGoalProgress(GoalRow goal) async {
    double current = 0.0;
    double target = goal.targetAmount;

    if (goal.type == 'balance_target') {
      final result = await _computeBalanceForGoal(goal);
      current = result['current']!;
      target = result['target']!;
    } else if (goal.type == 'income_target') {
      current = await _computeIncomeForGoal(goal);
    }

    return {'current': current, 'target': target};
  }

  Future<Map<String, double>> _computeBalanceForGoal(GoalRow goal) async {
    final cutoff = goal.endDate > 0
        ? goal.endDate
        : DateTime.now().millisecondsSinceEpoch;

    final rows = await (select(
      transactions,
    )..where((t) => t.smsTimestamp.isSmallerOrEqualValue(cutoff))).get();

    final normalizedFilter = goal.accountFilter.toLowerCase().trim();
    final filtered =
        normalizedFilter.isEmpty || normalizedFilter == 'all accounts'
        ? rows
        : rows.where((r) {
            final bank = r.bankName?.toLowerCase() ?? '';
            return bank.contains(normalizedFilter);
          }).toList();

    final balance = _calculateBalanceForRows(filtered);

    if (!goal.growthMode) {
      return {'current': balance, 'target': goal.targetAmount};
    }

    // Growth mode: progress = (current balance - starting balance) / (target * periods elapsed)
    final periods = _periodsElapsed(goal);
    final cumulativeTarget = goal.targetAmount * periods;
    final gained = balance - goal.startingBalance;
    return {
      'current': gained.clamp(0.0, double.infinity),
      'target': cumulativeTarget,
    };
  }

  int _periodsElapsed(GoalRow goal) {
    if (goal.period == null || goal.period!.isEmpty) return 1;
    final now = DateTime.now();
    final start = goal.startDate > 0
        ? DateTime.fromMillisecondsSinceEpoch(goal.startDate)
        : now;
    switch (goal.period) {
      case 'Weekly':
        return (now.difference(start).inDays / 7).ceil();
      case 'Monthly':
        return (now.year - start.year) * 12 + now.month - start.month + 1;
      case 'Yearly':
        return now.year - start.year + 1;
      default:
        return 1;
    }
  }

  Future<double> _computeIncomeForGoal(GoalRow goal) async {
    int startMs;
    int endMs;

    if (goal.period == null || goal.period == 'One time') {
      startMs = goal.startDate > 0 ? goal.startDate : 0;
      endMs = goal.endDate > 0
          ? goal.endDate
          : DateTime.now().millisecondsSinceEpoch;
    } else {
      final now = DateTime.now();
      DateTime periodStart;
      if (goal.period == 'Weekly') {
        periodStart = now.subtract(Duration(days: now.weekday - 1));
      } else if (goal.period == 'Monthly') {
        periodStart = DateTime(now.year, now.month, 1);
      } else if (goal.period == 'Yearly') {
        periodStart = DateTime(now.year, 1, 1);
      } else {
        periodStart = now;
      }
      startMs = periodStart.millisecondsSinceEpoch;
      endMs = now.millisecondsSinceEpoch;

      if (goal.startDate > 0 && goal.startDate > startMs) {
        startMs = goal.startDate;
      }
      if (goal.endDate > 0 && goal.endDate < endMs) {
        endMs = goal.endDate;
      }
    }

    final rows =
        await (select(transactions)
              ..where((t) => t.smsTimestamp.isBiggerOrEqualValue(startMs))
              ..where((t) => t.smsTimestamp.isSmallerOrEqualValue(endMs))
              ..where(
                (t) => t.direction.equalsValue(TransactionDirection.credit),
              ))
            .get();

    final normalizedFilter = goal.accountFilter.toLowerCase().trim();
    final filtered =
        normalizedFilter.isEmpty || normalizedFilter == 'all accounts'
        ? rows
        : rows.where((r) {
            final bank = r.bankName?.toLowerCase() ?? '';
            return bank.contains(normalizedFilter);
          }).toList();

    return filtered.fold<double>(0, (sum, t) => sum + t.amount);
  }

  double _calculateBalanceForRows(List<TransactionData> rows) {
    if (rows.isEmpty) return 0.0;
    final ordered = List<TransactionData>.from(rows)
      ..sort((a, b) {
        final tc = a.smsTimestamp.compareTo(b.smsTimestamp);
        if (tc != 0) return tc;
        return a.importedAt.compareTo(b.importedAt);
      });
    double? runningBalance;
    for (final row in ordered) {
      final snap = row.balanceAfter;
      if (snap != null) {
        runningBalance = snap;
        continue;
      }
      if (runningBalance == null) continue;
      if (row.direction == TransactionDirection.credit) {
        runningBalance += row.amount;
      } else if (row.direction == TransactionDirection.debit) {
        runningBalance -= row.amount;
      }
    }
    if (runningBalance != null) return runningBalance;
    double sum = 0;
    for (final row in ordered) {
      if (row.direction == TransactionDirection.credit) {
        sum += row.amount;
      } else if (row.direction == TransactionDirection.debit) {
        sum -= row.amount;
      }
    }
    return sum;
  }
}
