import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/database/database.dart';

enum TransactionSort { newest, oldest, amountHigh, amountLow }

class _FilterValue<T> extends Notifier<T> {
  final T Function() _init;
  _FilterValue(this._init);

  @override
  T build() => _init();

  void setValue(T value) => state = value;
}

final directionFilterProvider =
    NotifierProvider<_FilterValue<TransactionDirection?>, TransactionDirection?>(
  () => _FilterValue(() => null),
);

final bankFilterProvider =
    NotifierProvider<_FilterValue<String>, String>(
  () => _FilterValue(() => 'All banks'),
);

final sortByProvider =
    NotifierProvider<_FilterValue<TransactionSort>, TransactionSort>(
  () => _FilterValue(() => TransactionSort.newest),
);

final searchQueryProvider =
    NotifierProvider<_FilterValue<String>, String>(
  () => _FilterValue(() => ''),
);

final minAmountProvider =
    NotifierProvider<_FilterValue<double?>, double?>(
  () => _FilterValue(() => null),
);

final maxAmountProvider =
    NotifierProvider<_FilterValue<double?>, double?>(
  () => _FilterValue(() => null),
);

final startDateProvider =
    NotifierProvider<_FilterValue<DateTime?>, DateTime?>(
  () => _FilterValue(() => null),
);

final endDateProvider =
    NotifierProvider<_FilterValue<DateTime?>, DateTime?>(
  () => _FilterValue(() => null),
);

final showAdvancedFiltersProvider =
    NotifierProvider<_FilterValue<bool>, bool>(
  () => _FilterValue(() => false),
);

final categoryFilterProvider =
    NotifierProvider<_FilterValue<String?>, String?>(
  () => _FilterValue(() => null),
);
