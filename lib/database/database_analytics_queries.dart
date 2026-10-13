import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'database.dart';

extension AnalyticsLogic on AppDatabase {
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

  Stream<Map<String, double>> watchStatsForDays(
    int days, {
    String? bankFilter,
  }) {
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

  Stream<List<CategorySum>> watchCategorySummaryAllParsed({
    int? days,
    TransactionDirection? direction,
    String? bankFilter,
    int? startTimestamp,
    int? endTimestamp,
  }) {
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
}
