import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_processor.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_recategorizer.dart';
import 'package:faranka/features/insights/presentation/utils/weekly_insights_service.dart';
import 'package:faranka/features/budgets/domain/usecases/check_budget_alerts.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/app/core/services/notification_service.dart';

const String syncTransactionTask = 'sync_transaction';
const String syncCatchupTask = 'sync_catchup';
const String summaryTask = 'summary_notification';
const String budgetAlertDailyTask = 'budget_alert_daily';

/// Schedule the next summary notification for a specific cadence.
Future<void> _scheduleNextSummary(String cadence, int hour, int minute) async {
  final now = DateTime.now();
  final targetToday = DateTime(now.year, now.month, now.day, hour, minute);
  Duration delay;

  switch (cadence) {
    case 'daily':
      if (now.isAfter(targetToday)) {
        delay = targetToday.add(const Duration(days: 1)).difference(now);
      } else {
        delay = targetToday.difference(now);
      }
      break;
    case 'weekly':
      final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
      final nextSunday = DateTime(
        now.year,
        now.month,
        now.day + (daysUntilSunday == 0 ? 7 : daysUntilSunday),
        hour,
        minute,
      );
      delay = nextSunday.difference(now);
      break;
    case 'monthly':
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      var nextMonthEnd = DateTime(now.year, now.month, lastDay, hour, minute);
      if (now.isAfter(nextMonthEnd)) {
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final nextLastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        nextMonthEnd = DateTime(
          nextMonth.year,
          nextMonth.month,
          nextLastDay,
          hour,
          minute,
        );
      }
      delay = nextMonthEnd.difference(now);
      break;
    default:
      return;
  }

  if (delay.isNegative) delay = Duration.zero;

  final uniqueName = 'summary_$cadence';
  await Workmanager().registerOneOffTask(
    uniqueName,
    summaryTask,
    inputData: {'cadence': cadence},
    initialDelay: delay,
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
  debugPrint('Scheduled $cadence summary in ${delay.inDays} day(s)');
}

/// This is the "Top-Level" function that the Android OS calls when it
/// wakes the app up to do background work.
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    // 1. Log the start of the task for debugging
    debugPrint("Native: Background Task Started: $task");

    // 3. Initialize the Database
    // Note: Since this runs in a separate Isolate, we create a new instance
    final database = AppDatabase();
    final processor = TransactionProcessor(database);

    try {
      if (task == syncTransactionTask) {
        // These keys ('body' and 'sender') must match what you send in main.dart
        final String? body = inputData?['body'];
        final String? sender = inputData?['sender'];
        if (body == null || sender == null) {
          debugPrint("Native: Background task failed: Missing input data");
          await database.close();
          return false;
        }

        debugPrint("Native: Processing message from $sender");
        await processor.processIncomingSms(body, sender);
        debugPrint("Native: Background processing complete for $sender");
      } else if (task == syncCatchupTask) {
        debugPrint('Native: Running periodic catch-up sweep');

        final prefs = await SharedPreferences.getInstance();
        final txnNotificationsEnabled =
            prefs.getBool(AppSettingsService.keyTransactionNotifications) ?? false;
        final notification = NotificationService.instance;
        int? beforeCount;

        if (txnNotificationsEnabled) {
          beforeCount = (await database.select(database.transactions).get()).length;
          try {
            await notification.initialize();
            await notification.showSyncProgressNotification(
              notificationId: NotificationService.syncProgressNotificationId,
              isOngoing: true,
            );
          } catch (e) {
            debugPrint('Native: Sync start notification failed: $e');
          }
        }

        try {
          await processor.processPendingSms(limit: 200, maxAttempts: 5);
        } catch (e) {
          debugPrint('Native: processPendingSms error: $e');
          if (txnNotificationsEnabled) {
            try {
              await notification.showSyncProgressNotification(
                notificationId: NotificationService.syncProgressNotificationId,
                isOngoing: false,
                hasError: true,
              );
            } catch (e2) {
              debugPrint('Native: Sync error notification failed: $e2');
            }
          }
          rethrow;
        }

        try {
          await processor.retryFailedExtractions(limit: 50);
        } catch (e) {
          debugPrint('Native: retryFailedExtractions error: $e');
        }

        // Recategorize uncategorized transactions
        final recategorizer = TransactionRecategorizer(database);
        final recategorized = await recategorizer.recategorizeUncategorized(days: 30);
        final reextracted = await recategorizer.retryReasonExtraction(days: 30);
        final emptyImproved = await recategorizer.retryEmptyTransactions(days: 30);
        
        if (recategorized > 0 || reextracted > 0 || emptyImproved > 0) {
          debugPrint('Native: Recategorized: $recategorized, Re-extracted: $reextracted, Empty improved: $emptyImproved');
        }
        
        final deadLetters = await database.getDeadLetterMessages(limit: 20);
        if (deadLetters.isNotEmpty) {
          debugPrint(
            'Native: Dead-letter backlog count=${deadLetters.length}.',
          );
        }

        if (txnNotificationsEnabled && beforeCount != null) {
          final afterCount =
              (await database.select(database.transactions).get()).length;
          final newCount = afterCount - beforeCount;
          try {
            await notification.showSyncProgressNotification(
              notificationId: NotificationService.syncProgressNotificationId,
              isOngoing: false,
              newCount: newCount,
            );
          } catch (e) {
            debugPrint('Native: Sync result notification failed: $e');
          }
          if (newCount >= NotificationService.syncBatchThreshold) {
            debugPrint('Native: Sync notification shown ($newCount new transactions)');
          }
        }

        debugPrint('Native: Periodic catch-up sweep complete');

        final budgetAlerts = await BudgetAlertChecker.checkAlerts(database);
        if (budgetAlerts.isNotEmpty) {
          final notification = NotificationService.instance;
          await notification.initialize();
          await BudgetAlertChecker.showAlerts(budgetAlerts);
          debugPrint(
            'Native: Budget alerts shown: ${budgetAlerts.length}',
          );
        }
      } else if (task == summaryTask) {
        final cadence = inputData?['cadence'] as String? ?? 'weekly';
        debugPrint('Native: Summary task fired for cadence: $cadence');

        final prefs = await SharedPreferences.getInstance();
        final String enabledKey;
        final String hourKey;
        final String minuteKey;

        switch (cadence) {
          case 'daily':
            enabledKey = AppSettingsService.keySummaryDaily;
            hourKey = AppSettingsService.keySummaryDailyHour;
            minuteKey = AppSettingsService.keySummaryDailyMinute;
            break;
          case 'weekly':
            enabledKey = AppSettingsService.keySummaryWeekly;
            hourKey = AppSettingsService.keySummaryWeeklyHour;
            minuteKey = AppSettingsService.keySummaryWeeklyMinute;
            break;
          case 'monthly':
            enabledKey = AppSettingsService.keySummaryMonthly;
            hourKey = AppSettingsService.keySummaryMonthlyHour;
            minuteKey = AppSettingsService.keySummaryMonthlyMinute;
            break;
          default:
            debugPrint('Native: Unknown cadence $cadence');
            await database.close();
            return true;
        }

        final enabled = prefs.getBool(enabledKey) ?? false;
        if (!enabled) {
          debugPrint('Native: $cadence summary disabled, not rescheduling');
          await database.close();
          return true;
        }

        final hour = prefs.getInt(hourKey) ?? 8;
        final minute = prefs.getInt(minuteKey) ?? 0;
        final now = DateTime.now();

        if (cadence == 'weekly' && !WeeklyInsightsService.isWeekEnd(now)) {
          debugPrint('Native: Not Sunday, rescheduling');
          await _scheduleNextSummary(cadence, hour, minute);
          await database.close();
          return true;
        }

        if (cadence == 'monthly') {
          final lastDay = DateTime(now.year, now.month + 1, 0).day;
          if (now.day != lastDay) {
            debugPrint('Native: Not last day of month, rescheduling');
            await _scheduleNextSummary(cadence, hour, minute);
            await database.close();
            return true;
          }
        }

        debugPrint('Native: Generating $cadence summary notification');
        final notification = NotificationService.instance;
        await notification.initialize();

        if (cadence == 'daily') {
          final result = await WeeklyInsightsService.calculateDailySummary(
            database,
            now,
          );
          await notification.showSummaryNotification(
            cadence: 'daily',
            totalSpending: result.total,
            topCategory: result.topCategory,
            transactionDays: result.count,
          );
        } else if (cadence == 'weekly') {
          final summary = await WeeklyInsightsService.calculateWeeklyInsights(
            database,
            now,
          );
          final activeDays = summary.dailyData
              .fold<int>(0, (sum, d) => sum + (d.amount > 0 ? 1 : 0));
          await notification.showSummaryNotification(
            cadence: 'weekly',
            totalSpending: summary.totalSpending,
            topCategory: summary.topCategory,
            transactionDays: activeDays,
          );
        } else if (cadence == 'monthly') {
          final result = await WeeklyInsightsService.calculateMonthlySummary(
            database,
            now,
          );
          await notification.showSummaryNotification(
            cadence: 'monthly',
            totalSpending: result.total,
            topCategory: result.topCategory,
            transactionDays: result.count,
          );
        }

        await _scheduleNextSummary(cadence, hour, minute);
        debugPrint('Native: Rescheduled next $cadence summary');
      } else if (task == budgetAlertDailyTask) {
        debugPrint('Native: Checking budget alerts (daily)');
        try {
          final prefs = await SharedPreferences.getInstance();
          final budgetAlertsEnabled =
              prefs.getBool(AppSettingsService.keyBudgetAlerts) ?? true;
          if (!budgetAlertsEnabled) {
            debugPrint('Native: Budget alerts disabled, skipping');
            return true;
          }
          final budgets = await database.getBudgetConfigs();
          if (budgets.isEmpty) {
            debugPrint('Native: No budgets configured, skipping');
            return true;
          }
          final alerts = await BudgetAlertChecker.checkAlerts(database);
          if (alerts.isNotEmpty) {
            final notification = NotificationService.instance;
            await notification.initialize();
            await BudgetAlertChecker.showAlerts(alerts);
            debugPrint('Native: Budget alerts shown: ${alerts.length}');
          } else {
            debugPrint('Native: No new budget alerts');
          }
        } finally {
          await Workmanager().registerOneOffTask(
            'budget_alert_daily',
            budgetAlertDailyTask,
            initialDelay: const Duration(hours: 24),
            existingWorkPolicy: ExistingWorkPolicy.replace,
          );
        }
      } else {
        debugPrint('Native: Unknown task type $task');
      }

      // Close the database connection to free up memory
      await database.close();

      return true;
    } catch (e) {
      debugPrint("Native: Background task error: $e");

      // Cleanup even on error
      await database.close();
      return Future.value(false);
    }
  });
}
