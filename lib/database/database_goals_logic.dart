import 'package:drift/drift.dart';
import 'database.dart';

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
