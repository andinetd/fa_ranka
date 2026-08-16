import 'dart:async';

import 'package:drift/drift.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/models/transaction_group.dart';
import 'package:faranka/features/transactions/models/transaction_tile_view.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_filters_provider.dart';
import 'package:faranka/features/transactions/presentation/utils/transaction_grouping.dart';

class TransactionData {
  final AppDatabase db;
  final List<d.TypedResult> rows;
  final Map<int, List<TransactionSplit>> splits;
  final bool hasSplitError;

  const TransactionData(
    this.db,
    this.rows,
    this.splits, {
    this.hasSplitError = false,
  });
}

/// How many raw transactions the list loads per page. Growing this (via
/// infinite scroll) widens the in-memory window until the whole history is
/// reached.
final transactionsPageLimitProvider =
    NotifierProvider<TransactionsPageLimitNotifier, int>(
      TransactionsPageLimitNotifier.new,
    );

class TransactionsPageLimitNotifier extends Notifier<int> {
  static const int pageSize = 300;

  @override
  int build() => pageSize;

  void loadMore() => state += pageSize;
}

String _escapeLikePattern(String value) =>
    value.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');

final _transactionsStreamProvider =
    StreamProvider.autoDispose<List<d.TypedResult>>((ref) {
      final db = ref.watch(databaseProvider);
      final pageLimit = ref.watch(transactionsPageLimitProvider);
      final startDate = ref.watch(startDateProvider);
      final endDate = ref.watch(endDateProvider);
      final searchQuery = ref.watch(debouncedSearchQueryProvider);

      // Push the filters that most affect how many rows must be materialized
      // (date range, search) down into SQL so the DB does the heavy lifting
      // and the loaded window stays bounded by `pageLimit`.
      final conditions = <d.Expression<bool>>[];
      if (startDate != null) {
        final s = DateTime(startDate.year, startDate.month, startDate.day);
        conditions.add(
          db.transactions.smsTimestamp.isBiggerOrEqualValue(
            s.millisecondsSinceEpoch,
          ),
        );
      }
      if (endDate != null) {
        final e = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
        conditions.add(
          db.transactions.smsTimestamp.isSmallerOrEqualValue(
            e.millisecondsSinceEpoch,
          ),
        );
      }
      if (searchQuery.isNotEmpty) {
        final pattern = '%${_escapeLikePattern(searchQuery)}%';
        conditions.add(
          d.Expression.or([
            db.transactions.reasonRawText.like(pattern, escapeChar: r'\'),
            db.transactions.counterpartyName.like(pattern, escapeChar: r'\'),
            db.transactions.parsedCategory.like(pattern, escapeChar: r'\'),
            db.transactions.bankTransactionId.like(pattern, escapeChar: r'\'),
          ]),
        );
      }

      final query = db.select(db.transactions).join([
        d.leftOuterJoin(
          db.smsInbox,
          db.smsInbox.id.equalsExp(db.transactions.smsId),
        ),
      ]);
      if (conditions.isNotEmpty) {
        query.where(d.Expression.and(conditions));
      }
      query.orderBy([
        d.OrderingTerm(
          expression: db.transactions.smsTimestamp,
          mode: d.OrderingMode.desc,
        ),
        d.OrderingTerm(
          expression: db.transactions.importedAt,
          mode: d.OrderingMode.desc,
        ),
      ]);
      query.limit(pageLimit);
      return query.watch().debounceTime(const Duration(milliseconds: 300));
    });

final transactionDataProvider = FutureProvider.autoDispose<TransactionData>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  final rows = await ref.watch(_transactionsStreamProvider.future);
  if (rows.isEmpty) return TransactionData(db, [], {});
  final ids = rows.map((r) => r.readTable(db.transactions).id).toList();
  try {
    final splits = await db.getSplitsByTransactionIds(ids);
    return TransactionData(db, rows, splits);
  } catch (_) {
    return TransactionData(db, rows, {}, hasSplitError: true);
  }
});

/// Pre-formatted, plain-data snapshots of all loaded transactions. Building
/// these once per data change keeps `NumberFormat`/`DateFormat` work and
/// preference reads out of every tile's build during scrolling. Rebuilds only
/// when the underlying rows change or a display setting (calendar mode,
/// compact numbers) toggles.
final tileViewsProvider = Provider.autoDispose<List<TransactionTileView>>((
  ref,
) {
  final data = ref.watch(transactionDataProvider).asData?.value;
  if (data == null || data.rows.isEmpty) return const [];
  final calendarMode = ref.watch(calendarModeProvider);
  final useCompact = ref.watch(compactNumbersProvider);
  final txnReader = data.db.transactions;
  final smsReader = data.db.smsInbox;
  final views = List<TransactionTileView>.generate(
    data.rows.length,
    (i) {
      final row = data.rows[i];
      final txn = row.readTable(txnReader);
      return buildTransactionTileView(
        txn: txn,
        sms: row.readTableOrNull(smsReader),
        splits: data.splits[txn.id],
        calendarMode: calendarMode,
        useCompact: useCompact,
      );
    },
    growable: false,
  );
  return views;
});

/// Search input debounced so filtering doesn't re-run on every keystroke.
final debouncedSearchQueryProvider =
    NotifierProvider<DebouncedSearchNotifier, String>(
      DebouncedSearchNotifier.new,
    );

class DebouncedSearchNotifier extends Notifier<String> {
  static const _delay = Duration(milliseconds: 250);
  Timer? _timer;
  String _last = '';

  @override
  String build() {
    ref.watch(searchQueryProvider);
    _timer?.cancel();
    _timer = Timer(_delay, () {
      final latest = ref.read(searchQueryProvider);
      if (latest != _last) {
        _last = latest;
        state = latest;
      }
    });
    ref.onDispose(() => _timer?.cancel());
    return _last;
  }
}

final bankOptionsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT DISTINCT bank_name FROM transactions '
        "WHERE bank_name IS NOT NULL AND TRIM(bank_name) != '' "
        'ORDER BY bank_name LIMIT 30',
        readsFrom: {db.transactions},
      )
      .watch()
      .map(
        (rows) => [
          'All banks',
          ...rows.map((r) => r.read<String>('bank_name')),
        ],
      );
});

final categoryOptionsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT DISTINCT parsed_category FROM transactions '
        "WHERE direction = '${TransactionDirection.debit.name}' "
        'ORDER BY parsed_category LIMIT 50',
        readsFrom: {db.transactions},
      )
      .watch()
      .map(
        (rows) => rows.map((r) => r.read<String>('parsed_category')).toList(),
      );
});

/// Builds the account dropdown options from the distinct bank names currently
/// present in the user's data. Always starts with `'All Accounts'`; trims,
/// drops blanks/dupes. Kept pure so it can be unit-tested and reused.
List<String> buildAccountOptions(Iterable<String>? dbBanks) {
  final seen = <String>{};
  final result = <String>['All Accounts'];
  for (final raw in dbBanks ?? const <String>[]) {
    final bank = raw.trim();
    if (bank.isEmpty || !seen.add(bank)) continue;
    result.add(bank);
  }
  return result;
}

/// Bank chips for the insights heatmap filter, derived from the data-driven
/// account options. Replaces the `'All Accounts'` sentinel with `'All Banks'`
/// and always keeps the currently selected value selectable.
List<String> bankFilterOptions(
  List<String> accountOptions,
  String selected,
) {
  final options = <String>[
    'All Banks',
    ...accountOptions.where((bank) => bank != 'All Accounts'),
  ];
  return options.contains(selected) ? options : [...options, selected];
}

/// Data-driven account list for budget/goal dropdowns: every bank the user has
/// synced (canonical `bank_name` values), prefixed with 'All Accounts'. Live,
/// so newly synced banks appear automatically without any hardcoded catalog.
final accountOptionsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT DISTINCT bank_name FROM transactions '
        "WHERE bank_name IS NOT NULL AND TRIM(bank_name) != '' "
        'ORDER BY bank_name LIMIT 50',
        readsFrom: {db.transactions},
      )
      .watch()
      .map(
        (rows) => buildAccountOptions(rows.map((r) => r.read<String>('bank_name'))),
      );
});

/// Pure filter/sort over the plain-data views. Cheap enough to run
/// synchronously; must be kept free of drift/Flutter types so it can be moved
/// to another isolate later if the dataset keeps growing.
List<TransactionTileView> filterAndSortViews({
  required List<TransactionTileView> views,
  required TransactionDirection? directionFilter,
  required String bankFilter,
  required String searchQuery,
  required double? minAmount,
  required double? maxAmount,
  required DateTime? startDate,
  required DateTime? endDate,
  required String? categoryFilter,
  required TransactionSort sortBy,
}) {
  var filtered = views.where((view) {
    if (directionFilter != null && view.direction != directionFilter) {
      return false;
    }

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      final matchesDirect =
          view.parsedCategory.toLowerCase() == categoryFilter.toLowerCase();
      final matchesSplit = view.splitCategories.any(
        (c) => c.toLowerCase() == categoryFilter.toLowerCase(),
      );
      if (!matchesDirect && !matchesSplit) {
        return false;
      }
    }

    if (bankFilter != 'All banks') {
      final bn = (view.bankName ?? 'Unknown').toLowerCase();
      if (!bn.contains(bankFilter.toLowerCase())) {
        return false;
      }
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final reason = view.reasonRawText.toLowerCase();
      final counterparty = (view.counterpartyName ?? '').toLowerCase();
      final category = view.parsedCategory.toLowerCase();

      if (!reason.contains(query) &&
          !counterparty.contains(query) &&
          !category.contains(query) &&
          (view.bankTransactionId == null ||
              !view.bankTransactionId!.toLowerCase().contains(query))) {
        return false;
      }
    }

    if (minAmount != null && view.amount < minAmount) {
      return false;
    }
    if (maxAmount != null && view.amount > maxAmount) {
      return false;
    }

    if (startDate != null) {
      final t = DateTime.fromMillisecondsSinceEpoch(view.smsTimestamp);
      final txnDate = DateTime(t.year, t.month, t.day);
      final filterDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      if (txnDate.isBefore(filterDate)) {
        return false;
      }
    }

    if (endDate != null) {
      final t = DateTime.fromMillisecondsSinceEpoch(view.smsTimestamp);
      final txnDate = DateTime(t.year, t.month, t.day);
      final filterDate = DateTime(endDate.year, endDate.month, endDate.day);
      if (txnDate.isAfter(filterDate)) {
        return false;
      }
    }

    return true;
  }).toList();

  filtered.sort((a, b) {
    switch (sortBy) {
      case TransactionSort.newest:
        return b.smsTimestamp.compareTo(a.smsTimestamp);
      case TransactionSort.oldest:
        return a.smsTimestamp.compareTo(b.smsTimestamp);
      case TransactionSort.amountHigh:
        return b.amount.compareTo(a.amount);
      case TransactionSort.amountLow:
        return a.amount.compareTo(b.amount);
    }
  });

  return filtered;
}

final filteredTransactionViewsProvider =
    Provider.autoDispose<List<TransactionTileView>>((ref) {
      final views = ref.watch(tileViewsProvider);
      if (views.isEmpty) return const [];

      final directionFilter = ref.watch(directionFilterProvider);
      final bankFilter = ref.watch(bankFilterProvider);
      final searchQuery = ref.watch(debouncedSearchQueryProvider);
      final minAmount = ref.watch(minAmountProvider);
      final maxAmount = ref.watch(maxAmountProvider);
      final startDate = ref.watch(startDateProvider);
      final endDate = ref.watch(endDateProvider);
      final categoryFilter = ref.watch(categoryFilterProvider);
      final sortBy = ref.watch(sortByProvider);

      return filterAndSortViews(
        views: views,
        directionFilter: directionFilter,
        bankFilter: bankFilter,
        searchQuery: searchQuery,
        minAmount: minAmount,
        maxAmount: maxAmount,
        startDate: startDate,
        endDate: endDate,
        categoryFilter: categoryFilter,
        sortBy: sortBy,
      );
    });

final transactionGroupsProvider =
    Provider.autoDispose<List<TransactionRelativeGroup>>((ref) {
      final filtered = ref.watch(filteredTransactionViewsProvider);
      if (filtered.isEmpty) return const [];
      return groupTransactionsByRelativeBucket(filtered);
    });
