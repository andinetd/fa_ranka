import 'dart:convert';
import 'package:drift/drift.dart';
import 'database.dart';

extension BudgetLogic on AppDatabase {
  Future<void> ensureBudgetConfigsTable() async {
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
    try {
      await customStatement(
        "ALTER TABLE budget_configs ADD COLUMN category_mode TEXT NOT NULL DEFAULT 'include'",
      );
    } catch (_) {}
  }

  Future<void> _ensureBudgetConfigsTable() => ensureBudgetConfigsTable();

  Future<void> ensureTransactionSplitsTable() async {
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

  Future<void> _ensureTransactionSplitsTable() => ensureTransactionSplitsTable();

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
    String categoryMode = 'include',
    required String account,
    int startAt = 0,
    int endAt = 0,
  }) async {
    await _ensureBudgetConfigsTable();
    final now = DateTime.now().millisecondsSinceEpoch;
    final categoriesJson = jsonEncode(categories);
    await customInsert(
      '''
        INSERT INTO budget_configs (name, period, amount, categories_json, category_mode, account, start_at, end_at, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable<String>(name),
        Variable<String>(period),
        Variable<double>(amount),
        Variable<String>(categoriesJson),
        Variable<String>(categoryMode),
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
    String categoryMode = 'include',
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
        SET name = ?, period = ?, amount = ?, categories_json = ?, category_mode = ?, account = ?, start_at = ?, end_at = ?, updated_at = ?
        WHERE id = ?
      ''',
      variables: [
        Variable<String>(name),
        Variable<String>(period),
        Variable<double>(amount),
        Variable<String>(categoriesJson),
        Variable<String>(categoryMode),
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
      SELECT id, name, period, amount, categories_json, category_mode, account, start_at, end_at, created_at, updated_at
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
      final categoryMode = row.data['category_mode'] as String? ?? 'include';
      return BudgetConfigRow(
        id: row.read<int>('id'),
        name: row.read<String>('name'),
        period: row.read<String>('period'),
        amount: row.read<double>('amount'),
        categories: decoded,
        categoryMode: categoryMode,
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
}
