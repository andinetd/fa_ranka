import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/providers/database_provider.dart';

final categorySummaryProvider =
    StreamProvider<List<CategorySum>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchCategorySummaryAllParsed(
    days: 30,
    direction: TransactionDirection.debit,
  );
});

final budgetConfigsProvider =
    StreamProvider<List<BudgetConfigRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchBudgetConfigs();
});

final goalConfigsProvider =
    StreamProvider<List<GoalRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchGoals();
});


