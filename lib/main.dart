import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as sms_inbox;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:workmanager/workmanager.dart';

import 'features/auth/presentation/providers/biometric_provider.dart';
import 'app/core/providers/calendar_mode_provider.dart';
import 'app/core/providers/database_provider.dart';
import 'app/core/providers/is_first_run_provider.dart';
import 'app/core/providers/sensitive_hide_provider.dart';
import 'app/router.dart';
import 'app/core/theme/app_theme.dart';
import 'database/database.dart';
import 'features/budgets/domain/usecases/check_budget_alerts.dart';
import 'features/transactions/domain/usecases/transaction_processor.dart';
import 'infrastructure/background/background_worker.dart';
import 'app/core/services/app_settings_service.dart';
import 'app/core/services/notification_service.dart';
import 'app/core/services/widget_update_service.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(SmsMessage message) async {
  final sender = message.address ?? '';
  if (_isSupportedBankSender(sender)) {
    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerOneOffTask(
        'sync_${DateTime.now().millisecondsSinceEpoch}',
        syncTransactionTask,
        inputData: {'body': message.body, 'sender': message.address},
      );
    } catch (e) {
      debugPrint('Background message handler failed: $e');
    }
  }
}

void main() async {
  final bootTimer = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  _logBootStep(bootTimer, 'Flutter binding ready');

  // Start platform/network init and the lazy DB open concurrently so the
  // pre-frame wall-clock is roughly the max() of the two, not their sum.
  // All futures are still awaited before runApp, so settings stay correct.
  final prefsFuture = SharedPreferences.getInstance();

  final db = AppDatabase();
  initDatabase(db);
  _logBootStep(bootTimer, 'Database created');

  final prefs = await prefsFuture;
  setIsFirstRun(prefs.getBool('setup_complete') == null);
  await AppSettingsService.initialize();
  setBiometricEnabled(
    prefs.getBool(AppSettingsService.keyBiometricLock) ?? false,
  );
  await initSensitiveHide();
  await initCalendarMode();
  _logBootStep(bootTimer, 'Preferences and settings initialized');

  final notif = NotificationService.instance;
  notif.onWeeklySummaryTap = () => router.go('/insights');
  notif.onBudgetAlertTap = (budgetId) => router.go('/budgets/$budgetId');
  _logBootStep(bootTimer, 'Notifications callbacks set');

  runApp(const ProviderScope(child: MyApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _logBootStep(bootTimer, 'First frame rendered');
    unawaited(_initializeNotificationsAfterFrame(notif, bootTimer));
    unawaited(
      Future.delayed(
        const Duration(seconds: 2),
        () => _runStartupRepairs(db, bootTimer),
      ),
    );
  });

  if (Platform.isAndroid) {
    unawaited(_initializeAndroidServices(bootTimer));
  }
}

void _logBootStep(Stopwatch timer, String label) {
  debugPrint('[startup] ${timer.elapsedMilliseconds}ms $label');
}

/// Notification plugin init (channel creation) and the OS permission request
/// are not needed for the first frame, so they run after it renders.
Future<void> _initializeNotificationsAfterFrame(
  NotificationService notif,
  Stopwatch bootTimer,
) async {
  try {
    await notif.initialize();
    _logBootStep(bootTimer, 'Notifications initialized');
    if (Platform.isAndroid || Platform.isIOS) {
      notif.requestPermission();
    }
  } catch (e) {
    debugPrint('Notification init failed, continuing: $e');
  }
}

Future<void> _runStartupRepairs(AppDatabase db, Stopwatch bootTimer) async {
  try {
    final repaired = await db.repairTransactionAmountsFromSms();
    if (repaired > 0) {
      debugPrint(
        'Repaired $repaired transaction amount(s) from sms_inbox.amount',
      );
    }

    final balanceRepairs = await db.repairTransactionBalances();
    if (balanceRepairs > 0) {
      debugPrint(
        'Repaired $balanceRepairs transaction balance(s) from rawSmsBody',
      );
    }
    _logBootStep(bootTimer, 'Startup repairs completed');
  } catch (e) {
    debugPrint('Startup repair failed, continuing: $e');
  }
}

Future<void> _initializeAndroidServices(Stopwatch bootTimer) async {
  final autoSyncEnabled = AppSettingsService.getBoolSync(
    AppSettingsService.keyAutoSync,
    fallback: true,
  );

  try {
    await Workmanager().initialize(callbackDispatcher);
    if (autoSyncEnabled) {
      await Workmanager().registerPeriodicTask(
        'periodic_catchup',
        syncCatchupTask,
        frequency: const Duration(hours: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } else {
      await Workmanager().cancelByUniqueName('periodic_catchup');
    }
  } catch (e) {
    debugPrint('Workmanager init failed: $e');
  }

  try {
    Telephony.instance.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        unawaited(_handleForegroundSms(message));
      },
      onBackgroundMessage: onBackgroundMessage,
    );
  } catch (e) {
    debugPrint('Telephony init failed: $e');
  }

  if (autoSyncEnabled) {
    unawaited(
      Future.delayed(
        const Duration(seconds: 2),
        () => _runStartupCatchupSweep(),
      ),
    );
  }

  unawaited(
    Future.delayed(
      const Duration(seconds: 2),
      () => WidgetUpdateService.pushAllWidgets(database),
    ),
  );

  _rescheduleAllSummaryTasks();

  void onSummarySettingChanged() => _rescheduleAllSummaryTasks();
  AppSettingsService.summaryDailyNotifier.addListener(onSummarySettingChanged);
  AppSettingsService.summaryDailyHourNotifier.addListener(
    onSummarySettingChanged,
  );
  AppSettingsService.summaryDailyMinuteNotifier.addListener(
    onSummarySettingChanged,
  );
  AppSettingsService.summaryWeeklyNotifier.addListener(onSummarySettingChanged);
  AppSettingsService.summaryWeeklyHourNotifier.addListener(
    onSummarySettingChanged,
  );
  AppSettingsService.summaryWeeklyMinuteNotifier.addListener(
    onSummarySettingChanged,
  );
  AppSettingsService.summaryMonthlyNotifier.addListener(
    onSummarySettingChanged,
  );
  AppSettingsService.summaryMonthlyHourNotifier.addListener(
    onSummarySettingChanged,
  );
  AppSettingsService.summaryMonthlyMinuteNotifier.addListener(
    onSummarySettingChanged,
  );

  await Workmanager().registerOneOffTask(
    'budget_alert_daily',
    budgetAlertDailyTask,
    initialDelay: const Duration(hours: 1),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
  _logBootStep(bootTimer, 'Android services initialized');
}

Future<void> _rescheduleAllSummaryTasks() async {
  final cadences = [
    (
      cadence: 'daily',
      enabled: AppSettingsService.summaryDailyNotifier.value,
      hour: AppSettingsService.summaryDailyHourNotifier.value,
      minute: AppSettingsService.summaryDailyMinuteNotifier.value,
    ),
    (
      cadence: 'weekly',
      enabled: AppSettingsService.summaryWeeklyNotifier.value,
      hour: AppSettingsService.summaryWeeklyHourNotifier.value,
      minute: AppSettingsService.summaryWeeklyMinuteNotifier.value,
    ),
    (
      cadence: 'monthly',
      enabled: AppSettingsService.summaryMonthlyNotifier.value,
      hour: AppSettingsService.summaryMonthlyHourNotifier.value,
      minute: AppSettingsService.summaryMonthlyMinuteNotifier.value,
    ),
  ];

  try {
    for (final c in cadences) {
      await Workmanager().cancelByUniqueName('summary_${c.cadence}');
      if (c.enabled) {
        await _scheduleNextSummary(c.cadence, c.hour, c.minute);
      }
    }
  } catch (e) {
    debugPrint('Summary task scheduling failed: $e');
  }
}

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
        final nextLastDay = DateTime(
          nextMonth.year,
          nextMonth.month + 1,
          0,
        ).day;
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setBiometricPassed(false);
    } else if (state == AppLifecycleState.resumed) {
      router.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettingsService.themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<double>(
          valueListenable: AppSettingsService.textScaleNotifier,
          builder: (context, textScale, _) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                child = MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.textScalerOf(context).scale(1.0) * textScale,
                    ),
                  ),
                  child: child!,
                );
                return child;
              },
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              routerConfig: router,
            );
          },
        );
      },
    );
  }
}

bool _isSupportedBankSender(String sender) {
  final lower = sender.toLowerCase();
  return lower.contains('awash') ||
      lower.contains('cbe') ||
      lower == '127' ||
      lower.contains('telebirr') ||
      lower.contains('ethio telecom') ||
      lower.contains('boa') ||
      lower.contains('abyssinia');
}

Future<void> _handleForegroundSms(SmsMessage message) async {
  final sender = message.address ?? '';
  final body = message.body ?? '';

  if (body.trim().isEmpty || !_isSupportedBankSender(sender)) return;

  try {
    final processor = TransactionProcessor(database);
    await processor.processIncomingSms(body, sender);

    if (AppSettingsService.transactionNotificationsNotifier.value) {
      final notification = NotificationService.instance;
      await notification.showTransactionNotification(
        amount: 0, // placeholder; actual amount comes from parsed txn
        category: '',
        bankName: sender,
      );
    }

    final alerts = await BudgetAlertChecker.checkAlerts(database);
    if (alerts.isNotEmpty) {
      await BudgetAlertChecker.showAlerts(alerts);
    }
  } catch (e) {
    debugPrint('Foreground SMS processing failed: $e');
  }
}

Future<void> _runStartupCatchupSweep() async {
  if (!Platform.isAndroid) {
    return;
  }

  try {
    final smsGranted = await Permission.sms.status.isGranted;
    if (!smsGranted) {
      debugPrint('Startup catch-up sweep skipped: SMS permission not granted');
      return;
    }

    final query = sms_inbox.SmsQuery();
    final latestSms = await query.querySms(
      kinds: [sms_inbox.SmsQueryKind.inbox],
      count: 300,
    );
    final bankSms = latestSms.where((sms) {
      final sender = sms.address ?? '';
      return _isSupportedBankSender(sender);
    }).toList();

    final lastSync = AppSettingsService.lastSyncNotifier.value;
    final newBankSms = lastSync != null
        ? bankSms
              .where((s) => (s.date?.millisecondsSinceEpoch ?? 0) > lastSync)
              .toList()
        : bankSms;

    final newSmsCount = newBankSms.length;
    final notifyEnabled =
        AppSettingsService.transactionNotificationsNotifier.value;

    if (newBankSms.isNotEmpty) {
      await database.syncRawMessages(newBankSms);
    }

    final processor = TransactionProcessor(database);
    await processor.processPendingSms(limit: 200, maxAttempts: 5);
    try {
      await processor.retryFailedExtractions(limit: 50);
    } catch (e) {
      debugPrint('Startup retryFailedExtractions failed: $e');
    }

    await AppSettingsService.setLastSyncTimestamp();

    if (notifyEnabled &&
        newSmsCount >= NotificationService.syncBatchThreshold) {
      try {
        final notification = NotificationService.instance;
        await notification.initialize();
        await notification.showSyncProgressNotification(
          notificationId: NotificationService.syncProgressNotificationId,
          isOngoing: false,
          newCount: newSmsCount,
        );
      } catch (e) {
        debugPrint('Startup sync notification failed: $e');
      }
    }

    final deadLetters = await database.getDeadLetterMessages(limit: 20);
    if (deadLetters.isNotEmpty) {
      debugPrint(
        'Catch-up sweep finished with ${deadLetters.length} dead-letter message(s).',
      );
    }
  } catch (e) {
    debugPrint('Startup catch-up sweep failed: $e');
  }
}
