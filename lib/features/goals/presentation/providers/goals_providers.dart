import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/providers/database_provider.dart';

final goalProgressProvider =
    FutureProvider.family<Map<String, double>, int>((ref, goalId) async {
  final db = ref.watch(databaseProvider);
  final goals = await db.getGoals();
  final goal = goals.where((g) => g.id == goalId).firstOrNull;
  if (goal == null) return {'current': 0.0, 'target': 0.0};
  return db.computeGoalProgress(goal);
});
