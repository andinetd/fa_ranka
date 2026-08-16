import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';

final totalBalanceProvider =
    StreamProvider.family<double, BankBalanceFilter>((ref, filter) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalBalance(bankFilter: filter.dbFilter);
});

final statsProvider = StreamProvider.family<Map<String, double>, (int days, BankBalanceFilter filter)>(
  (ref, params) {
    final db = ref.watch(databaseProvider);
    final (days, filter) = params;
    return db.watchStatsForDays(days, bankFilter: filter.dbFilter);
  },
);

final dailySpendingProvider =
    StreamProvider.family<List<double>, (int days, BankBalanceFilter filter)>(
  (ref, params) {
    final db = ref.watch(databaseProvider);
    final (days, filter) = params;
    return db.watchDailySpendingForDays(days, bankFilter: filter.dbFilter);
  },
);

final balanceHistoryProvider =
    StreamProvider.family<List<double>, (int days, BankBalanceFilter filter)>(
  (ref, params) {
    final db = ref.watch(databaseProvider);
    final (days, filter) = params;
    return db.watchBalanceHistoryForDays(days, bankFilter: filter.dbFilter);
  },
);

/// The bank filters the user actually has data for, always starting with
/// `all`. Anything not present in the transactions table is omitted so the
/// balance section only surfaces available banks.
final trackedBankFiltersProvider =
    StreamProvider.autoDispose<List<BankBalanceFilter>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT DISTINCT bank_name FROM transactions '
        "WHERE bank_name IS NOT NULL AND TRIM(bank_name) != '' "
        'ORDER BY bank_name',
        readsFrom: {db.transactions},
      )
      .watch()
      .map(
        (rows) {
          final filters = <BankBalanceFilter>{};
          for (final row in rows) {
            final filter = filterForBankName(row.read<String>('bank_name'));
            if (filter != null) filters.add(filter);
          }
          return [BankBalanceFilter.all, ...filters];
        },
      );
});
