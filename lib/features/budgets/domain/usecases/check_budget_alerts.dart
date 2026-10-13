import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/app/core/services/notification_service.dart';

class BudgetAlertResult {
  final int budgetId;
  final String budgetName;
  final String period;
  final double spent;
  final double limit;
  final int threshold;

  BudgetAlertResult({
    required this.budgetId,
    required this.budgetName,
    required this.period,
    required this.spent,
    required this.limit,
    required this.threshold,
  });
}

class BudgetAlertChecker {
  static ({int startMs, int endMs}) _getPeriodRange(BudgetConfigRow budget, DateTime now) {
    if (budget.startAt > 0 && budget.endAt > 0) {
      return (startMs: budget.startAt, endMs: budget.endAt);
    }

    final startOfDay = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end;

    switch (budget.period) {
      case 'Weekly':
        start = startOfDay.subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case 'Monthly':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case 'Quarterly':
        final quarter = ((now.month - 1) / 3).floor();
        start = DateTime(now.year, quarter * 3 + 1, 1);
        end = DateTime(now.year, (quarter + 1) * 3 + 1, 1);
        break;
      case 'Yearly':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1);
        break;
      default:
        // Default to last 30 days
        start = startOfDay.subtract(const Duration(days: 30));
        end = startOfDay.add(const Duration(days: 1));
        break;
    }

    return (
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
    );
  }

  static String _currentPeriodKey(BudgetConfigRow budget, DateTime now) {
    if (budget.startAt > 0 && budget.endAt > 0) {
      return '${budget.startAt}_${budget.endAt}';
    }
    switch (budget.period) {
      case 'Weekly':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateFormat("yyyy-'W'ww").format(weekStart);
      case 'Monthly':
        return DateFormat('yyyy-MM').format(now);
      case 'Quarterly':
        final quarter = ((now.month - 1) / 3).floor() + 1;
        return '${now.year}-Q$quarter';
      case 'Yearly':
        return '${now.year}';
      default:
        return 'one_time';
    }
  }

  /// Check all budgets and return alerts that haven't been sent yet.
  /// After returning, each alert is marked as sent in SharedPreferences
  /// to avoid duplicate notifications for the same threshold+period.
  static Future<List<BudgetAlertResult>> checkAlerts(
    AppDatabase db,
  ) async {
    if (!AppSettingsService.budgetAlertsNotifier.value) return [];
    final budgets = await db.getBudgetConfigs();
    if (budgets.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final alerts = <BudgetAlertResult>[];

    // Fetch all debit transactions once
    final allTxns = await db.select(db.transactions).get();
    final txnIds = allTxns.map((t) => t.id).toList();
    final splitMap = await db.getSplitsByTransactionIds(txnIds);
    final now = DateTime.now();

    for (final budget in budgets) {
      final range = _getPeriodRange(budget, now);

      // Get alert thresholds for this budget
      final prefix = 'budget_${budget.id}_';
      final thresholdStrings =
          prefs.getStringList('${prefix}alert_thresholds') ?? ['75', '90', '100'];
      final thresholds = thresholdStrings
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .toSet();
      if (thresholds.isEmpty) continue;

      // Calculate spending for this budget's categories within the period
      double spent = 0;
      for (final txn in allTxns) {
        if (txn.direction != TransactionDirection.debit) continue;
        if (txn.smsTimestamp < range.startMs || txn.smsTimestamp >= range.endMs) {
          continue;
        }

        // Account filter if specified
        if (budget.account.isNotEmpty && budget.account != 'All Accounts') {
          final bank = (txn.bankName ?? '').toLowerCase();
          if (!bank.contains(budget.account.toLowerCase())) continue;
        }

        // If budget has no categories, match all transactions
        if (budget.categories.isEmpty) {
          spent += txn.amount;
        } else if (budget.isExcludeMode) {
          final txnSplits = splitMap[txn.id];
          if (txnSplits != null && txnSplits.isNotEmpty) {
            double includedSplitAmount = 0;
            double splitSum = 0;
            for (final split in txnSplits) {
              splitSum += split.amount;
              if (!budget.categories.contains(split.category)) {
                includedSplitAmount += split.amount;
              }
            }
            spent += includedSplitAmount;

            // Handle unallocated remainder if parent category is NOT excluded
            final remainder = txn.amount - splitSum;
            if (remainder > 0.009 && !budget.categories.contains(txn.parsedCategory)) {
              spent += remainder;
            }
          } else if (!budget.categories.contains(txn.parsedCategory)) {
            spent += txn.amount;
          }
        } else {
          final txnSplits = splitMap[txn.id];
          if (txnSplits != null && txnSplits.isNotEmpty) {
            double matchedSplitAmount = 0;
            double splitSum = 0;
            for (final split in txnSplits) {
              splitSum += split.amount;
              if (budget.categories.contains(split.category)) {
                matchedSplitAmount += split.amount;
              }
            }
            spent += matchedSplitAmount;

            // Handle unallocated remainder if parent category is in budget
            final remainder = txn.amount - splitSum;
            if (remainder > 0.009 && budget.categories.contains(txn.parsedCategory)) {
              spent += remainder;
            }
          } else if (budget.categories.contains(txn.parsedCategory)) {
            spent += txn.amount;
          }
        }
      }

      if (budget.amount <= 0) continue;
      final usage = spent / budget.amount;

      final periodKey = _currentPeriodKey(budget, now);

      for (final threshold in thresholds) {
        final thresholdFraction = threshold / 100;
        if (usage < thresholdFraction) continue;

        final sentKey = '${prefix}alert_sent_${threshold}_$periodKey';
        final alreadySent = prefs.getBool(sentKey) ?? false;
        if (alreadySent) continue;

        alerts.add(BudgetAlertResult(
          budgetId: budget.id,
          budgetName: budget.name,
          period: budget.period,
          spent: spent,
          limit: budget.amount,
          threshold: threshold,
        ));

        // Mark as sent to avoid duplicates
        await prefs.setBool(sentKey, true);
      }
    }

    return alerts;
  }

  /// Show notifications for all pending alerts.
  static Future<void> showAlerts(List<BudgetAlertResult> alerts) async {
    for (final alert in alerts) {
      await NotificationService.instance.showBudgetAlert(
        budgetId: alert.budgetId,
        budgetName: alert.budgetName,
        period: alert.period,
        spent: alert.spent,
        limit: alert.limit,
        threshold: alert.threshold,
      );
    }
  }
}
