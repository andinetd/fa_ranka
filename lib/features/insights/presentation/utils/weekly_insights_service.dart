import 'package:faranka/database/database.dart';
import 'package:faranka/features/insights/presentation/widgets/weekly_insights_card.dart';

/// Service for calculating weekly insights from transaction data
class WeeklyInsightsService {
  /// Get the Monday of the last complete week (most recent past Monday)
  /// If today is Monday, returns last Monday (7 days ago)
  /// If today is Sunday, returns Monday 6 days ago (start of week that just ended)
  static DateTime getLastCompleteWeekStart(DateTime date) {
    // Get the most recent past Sunday
    final lastSunday = getLastSunday(date);
    // Go back 6 days to get Monday
    return lastSunday.subtract(const Duration(days: 6));
  }

  /// Get the Sunday of the last complete week
  /// This is the most recent past Sunday
  static DateTime getLastCompleteWeekEnd(DateTime date) {
    return getLastSunday(date);
  }

  /// Get the most recent past Sunday (or today if today is Sunday)
  static DateTime getLastSunday(DateTime date) {
    final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    if (dayOfWeek == 7) {
      // Today is Sunday, return today
      return date;
    } else {
      // Go back to the most recent Sunday
      return date.subtract(Duration(days: dayOfWeek));
    }
  }

  /// Check if today is Sunday (end of week)
  static bool isWeekEnd(DateTime date) {
    return date.weekday == 7; // 7 = Sunday
  }

  /// Get the Monday of the week containing the given date
  static DateTime getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday; // 1 = Monday
    return date.subtract(Duration(days: dayOfWeek - 1));
  }

  /// Get Sunday of the week containing the given date
  static DateTime getWeekEnd(DateTime date) {
    final weekStart = getWeekStart(date);
    return weekStart.add(const Duration(days: 7)); // Sunday is start + 7 days
  }

  /// Get previous week start date
  static DateTime getPreviousWeekStart(DateTime date) {
    return getWeekStart(date).subtract(const Duration(days: 7));
  }

  /// Calculate weekly insights from transaction data for the last complete week
  static Future<WeeklyInsightsSummary> calculateWeeklyInsights(
    AppDatabase db,
    DateTime date,
  ) async {
    final transactions = await db.select(db.transactions).get();
    final txnIds = transactions.map((t) => t.id).toList();
    final splitMap = await db.getSplitsByTransactionIds(txnIds);

    // Get last complete week (Monday-Sunday)
    final weekStart = getLastCompleteWeekStart(date);
    final weekEnd = getLastCompleteWeekEnd(date).add(const Duration(days: 1)); // End is exclusive
    
    // Week before that
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = weekStart; // End is exclusive

    final dailySpending = <String, double>{};
    final dailyIncome = <String, double>{};
    final dailyDates = <String, DateTime>{};
    final categoryBreakdown = <String, double>{};
    double totalSpending = 0;
    double totalIncome = 0;
    double previousWeekSpending = 0;
    double previousWeekIncome = 0;

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Initialize daily data
    for (int i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      final dayKey = weekDays[i];
      dailySpending[dayKey] = 0;
      dailyIncome[dayKey] = 0;
      dailyDates[dayKey] = dayDate;
    }

    // Process transactions
    for (final txn in transactions) {
      final isDebit = txn.direction == TransactionDirection.debit;
      final txnDate =
          DateTime.fromMillisecondsSinceEpoch(txn.smsTimestamp);
      final txnDateOnly = DateTime(txnDate.year, txnDate.month, txnDate.day);

      // Last complete week
      if (!txnDateOnly.isBefore(weekStart) && txnDateOnly.isBefore(weekEnd)) {
        final dayIndex = txnDate.weekday - 1; // 0 = Monday
        final dayKey = weekDays[dayIndex];
        if (isDebit) {
          dailySpending[dayKey] = (dailySpending[dayKey] ?? 0) + txn.amount;
          totalSpending += txn.amount;
        } else {
          dailyIncome[dayKey] = (dailyIncome[dayKey] ?? 0) + txn.amount;
          totalIncome += txn.amount;
        }

        // Category breakdown only for spending
        if (isDebit) {
          final txnSplits = splitMap[txn.id];
          if (txnSplits != null && txnSplits.isNotEmpty) {
            double splitSum = 0;
            for (final split in txnSplits) {
              categoryBreakdown[split.category] =
                  (categoryBreakdown[split.category] ?? 0) + split.amount;
              splitSum += split.amount;
            }
            final remainder = txn.amount - splitSum;
            if (remainder > 0.009) {
              final cat = txn.parsedCategory.trim().isEmpty
                  ? 'Uncategorized'
                  : txn.parsedCategory;
              categoryBreakdown[cat] =
                  (categoryBreakdown[cat] ?? 0) + remainder;
            }
          } else {
            final category = txn.parsedCategory.trim().isEmpty
                ? 'Uncategorized'
                : txn.parsedCategory;
            categoryBreakdown[category] =
                (categoryBreakdown[category] ?? 0) + txn.amount;
          }
        }
      }

      // Previous week
      if (!txnDateOnly.isBefore(previousWeekStart) &&
          txnDateOnly.isBefore(previousWeekEnd)) {
        if (isDebit) {
          previousWeekSpending += txn.amount;
        } else {
          previousWeekIncome += txn.amount;
        }
      }
    }

    // Find top category
    String topCategory = 'No spending';
    double topCategoryAmount = 0;
    if (categoryBreakdown.isNotEmpty) {
      final topEntry = categoryBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      topCategory = topEntry.key;
      topCategoryAmount = topEntry.value;
    }

    // Create daily data objects
    final dailyDataList = <WeeklyDailyData>[];
    final combinedDailyTotal = <String, double>{};
    for (int i = 0; i < 7; i++) {
      final dayKey = weekDays[i];
      final spend = dailySpending[dayKey]!;
      final income = dailyIncome[dayKey]!;
      final dayTotal = spend + income;
      combinedDailyTotal[dayKey] = dayTotal;
      final combinedTotal = totalSpending + totalIncome;
      final percentage =
          combinedTotal > 0 ? (dayTotal / combinedTotal) * 100 : 0.0;

      dailyDataList.add(
        WeeklyDailyData(
          day: dayKey,
          amount: dayTotal,
          date: dailyDates[dayKey]!,
          percentageOfWeek: percentage.toDouble(),
        ),
      );
    }

    return WeeklyInsightsSummary(
      weekStart: weekStart,
      weekEnd: getLastCompleteWeekEnd(date),
      totalSpending: totalSpending,
      previousWeekSpending: previousWeekSpending,
      totalIncome: totalIncome,
      previousWeekIncome: previousWeekIncome,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      dailySpending: dailySpending,
      dailyIncome: dailyIncome,
      categoryBreakdown: categoryBreakdown,
      dailyData: dailyDataList,
    );
  }

  /// Stream weekly insights so UI updates when data changes
  static Stream<WeeklyInsightsSummary> watchWeeklyInsights(
    AppDatabase db,
    DateTime date,
  ) {
    return db.select(db.transactions).watch().asyncMap(
      (_) async => await calculateWeeklyInsights(db, date),
    );
  }

  static Future<({double total, String topCategory, int count})>
      calculateDailySummary(AppDatabase db, DateTime date) async {
    final transactions = await db.select(db.transactions).get();
    final txnIds = transactions.map((t) => t.id).toList();
    final splitMap = await db.getSplitsByTransactionIds(txnIds);

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final categoryBreakdown = <String, double>{};
    double totalSpending = 0;
    int count = 0;

    for (final txn in transactions) {
      if (txn.direction != TransactionDirection.debit) continue;
      final txnDate = DateTime.fromMillisecondsSinceEpoch(txn.smsTimestamp);
      final txnDateOnly = DateTime(txnDate.year, txnDate.month, txnDate.day);
      if (txnDateOnly.isBefore(dayStart) || !txnDateOnly.isBefore(dayEnd)) {
        continue;
      }
      totalSpending += txn.amount;
      count++;

      final txnSplits = splitMap[txn.id];
      if (txnSplits != null && txnSplits.isNotEmpty) {
        for (final split in txnSplits) {
          categoryBreakdown[split.category] =
              (categoryBreakdown[split.category] ?? 0) + split.amount;
        }
        final splitSum = txnSplits.fold<double>(0, (s, sp) => s + sp.amount);
        final remainder = txn.amount - splitSum;
        if (remainder > 0.009) {
          final cat = txn.parsedCategory.trim().isEmpty
              ? 'Uncategorized'
              : txn.parsedCategory;
          categoryBreakdown[cat] =
              (categoryBreakdown[cat] ?? 0) + remainder;
        }
      } else {
        final category = txn.parsedCategory.trim().isEmpty
            ? 'Uncategorized'
            : txn.parsedCategory;
        categoryBreakdown[category] =
            (categoryBreakdown[category] ?? 0) + txn.amount;
      }
    }

    String topCategory = 'No spending';
    if (categoryBreakdown.isNotEmpty) {
      topCategory = categoryBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return (total: totalSpending, topCategory: topCategory, count: count);
  }

  static Future<({double total, String topCategory, int count})>
      calculateMonthlySummary(AppDatabase db, DateTime date) async {
    final transactions = await db.select(db.transactions).get();
    final txnIds = transactions.map((t) => t.id).toList();
    final splitMap = await db.getSplitsByTransactionIds(txnIds);

    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 1);

    final categoryBreakdown = <String, double>{};
    double totalSpending = 0;
    int count = 0;

    for (final txn in transactions) {
      if (txn.direction != TransactionDirection.debit) continue;
      final txnDate = DateTime.fromMillisecondsSinceEpoch(txn.smsTimestamp);
      final txnDateOnly = DateTime(txnDate.year, txnDate.month, txnDate.day);
      if (txnDateOnly.isBefore(monthStart) || !txnDateOnly.isBefore(monthEnd)) {
        continue;
      }
      totalSpending += txn.amount;
      count++;

      final txnSplits = splitMap[txn.id];
      if (txnSplits != null && txnSplits.isNotEmpty) {
        for (final split in txnSplits) {
          categoryBreakdown[split.category] =
              (categoryBreakdown[split.category] ?? 0) + split.amount;
        }
        final splitSum = txnSplits.fold<double>(0, (s, sp) => s + sp.amount);
        final remainder = txn.amount - splitSum;
        if (remainder > 0.009) {
          final cat = txn.parsedCategory.trim().isEmpty
              ? 'Uncategorized'
              : txn.parsedCategory;
          categoryBreakdown[cat] =
              (categoryBreakdown[cat] ?? 0) + remainder;
        }
      } else {
        final category = txn.parsedCategory.trim().isEmpty
            ? 'Uncategorized'
            : txn.parsedCategory;
        categoryBreakdown[category] =
            (categoryBreakdown[category] ?? 0) + txn.amount;
      }
    }

    String topCategory = 'No spending';
    if (categoryBreakdown.isNotEmpty) {
      topCategory = categoryBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return (total: totalSpending, topCategory: topCategory, count: count);
  }
}
