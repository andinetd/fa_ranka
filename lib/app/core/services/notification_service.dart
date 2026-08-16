import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

class BudgetAlertPayload {
  final int budgetId;
  final int threshold;

  BudgetAlertPayload({required this.budgetId, required this.threshold});

  String encode() => 'budget_alert:$budgetId:$threshold';

  static BudgetAlertPayload? decode(String raw) {
    final parts = raw.split(':');
    if (parts.length != 3 || parts[0] != 'budget_alert') return null;
    final budgetId = int.tryParse(parts[1]);
    final threshold = int.tryParse(parts[2]);
    if (budgetId == null || threshold == null) return null;
    return BudgetAlertPayload(budgetId: budgetId, threshold: threshold);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  VoidCallback? onWeeklySummaryTap;
  void Function(int budgetId)? onBudgetAlertTap;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'View',
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'weekly_summary',
          'Weekly Summary',
          description: 'Weekly spending summary notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'budget_alerts',
          'Budget Alerts',
          description: 'Notifications when budgets approach or exceed their limits',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'transaction_alerts',
          'Transaction Alerts',
          description: 'Notifications for each new transaction',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'sync_progress',
          'Sync Progress',
          description: 'Background sync progress notifications',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
    }
  }

  Future<void> requestPermission() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      debugPrint('Notification permission denied');
    } else if (status.isPermanentlyDenied) {
      debugPrint('Notification permission permanently denied');
    }
  }

  void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    if ((payload == 'weekly_summary' || payload == 'summary') &&
        onWeeklySummaryTap != null) {
      onWeeklySummaryTap!();
      return;
    }
    final budgetPayload = BudgetAlertPayload.decode(payload);
    if (budgetPayload != null && onBudgetAlertTap != null) {
      onBudgetAlertTap!(budgetPayload.budgetId);
    }
  }

  static NumberFormat _numberFormatter() {
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    return useCompact ? NumberFormat.compact() : NumberFormat('#,##0');
  }

  Future<void> showSummaryNotification({
    required String cadence,
    required double totalSpending,
    required String topCategory,
    required int transactionDays,
  }) async {
    final currency = 'ETB';
    final totalFormatted = _numberFormatter().format(totalSpending);

    final String title;
    final String body;

    switch (cadence) {
      case 'daily':
        title = 'Today\u2019s Spending Summary';
        body = '$currency $totalFormatted total · Top: $topCategory';
        break;
      case 'weekly':
        title = 'Your Weekly Spending Summary';
        body =
            '$currency $totalFormatted total · Top: $topCategory · $transactionDays days';
        break;
      case 'monthly':
        title = 'Your Monthly Spending Summary';
        body = '$currency $totalFormatted total · Top: $topCategory';
        break;
      default:
        return;
    }

    final androidDetails = AndroidNotificationDetails(
      'weekly_summary',
      'Spending Summary',
      channelDescription: 'Periodic spending summary notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'summary',
    );
  }

  static const int syncProgressNotificationId = 9998;
  static const int syncBatchThreshold = 5;

  Future<void> showSyncProgressNotification({
    required int notificationId,
    required bool isOngoing,
    int? newCount,
    bool hasError = false,
  }) async {
    try {
      if (!isOngoing && (newCount == null || newCount < syncBatchThreshold) && !hasError) {
        await _plugin.cancel(id: notificationId);
        return;
      }

      final String title;
      final String body;
      final Importance importance;
      final bool showProgress;

      if (isOngoing) {
        title = 'Syncing transactions';
        body = 'Checking for new messages\u2026';
        importance = Importance.low;
        showProgress = true;
      } else if (hasError) {
        title = 'Sync failed';
        body = 'Something went wrong. Tap to retry.';
        importance = Importance.defaultImportance;
        showProgress = false;
      } else {
        title = '$newCount New Transaction${newCount == 1 ? '' : 's'}';
        body = 'Tap to view your latest spending activity.';
        importance = Importance.defaultImportance;
        showProgress = false;
      }

      final androidDetails = AndroidNotificationDetails(
        'sync_progress',
        'Sync Progress',
        channelDescription: 'Background sync progress notifications',
        importance: importance,
        priority: isOngoing ? Priority.low : Priority.defaultPriority,
        showWhen: true,
        onlyAlertOnce: true,
        showProgress: showProgress,
        indeterminate: isOngoing,
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('showSyncProgressNotification failed: $e');
    }
  }

  Future<void> cancelSyncProgressNotification(int notificationId) async {
    try {
      await _plugin.cancel(id: notificationId);
    } catch (e) {
      debugPrint('cancelSyncProgressNotification failed: $e');
    }
  }

  Future<void> showBatchTransactionNotification(int count) async {
    final title = '$count New Transaction${count == 1 ? '' : 's'}';
    final body = 'Tap to view your latest spending activity.';

    final androidDetails = AndroidNotificationDetails(
      'transaction_alerts',
      'Transaction Alerts',
      channelDescription: 'Notifications for each new transaction',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> showTransactionNotification({
    double amount = 0,
    String category = '',
    required String bankName,
  }) async {
    final currency = 'ETB';
    final parts = <String>[];
    if (amount > 0) {
      parts.add('$currency ${_numberFormatter().format(amount)}');
    }
    if (category.isNotEmpty) parts.add(category);
    parts.add(bankName);

    final title = 'New Transaction';
    final body = parts.join(' \u00b7 ');

    final androidDetails = AndroidNotificationDetails(
      'transaction_alerts',
      'Transaction Alerts',
      channelDescription: 'Notifications for each new transaction',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> showBudgetAlert({
    required int budgetId,
    required String budgetName,
    required String period,
    required double spent,
    required double limit,
    required int threshold,
  }) async {
    final currency = 'ETB';
    final spentFormatted = _numberFormatter().format(spent);
    final limitFormatted = _numberFormatter().format(limit);
    final isOverrun = threshold >= 100;

    final title = isOverrun
        ? 'Budget Exceeded: $budgetName'
        : 'Budget Alert: $budgetName';

    final body = isOverrun
        ? '$budgetName — $currency $spentFormatted spent of $currency $limitFormatted ($period)'
        : '$threshold% used · $currency $spentFormatted of $currency $limitFormatted ($period)';

    final bigLines = StringBuffer();
    bigLines.writeln('Budget: $budgetName');
    bigLines.writeln('Period: $period');
    bigLines.writeln('');
    bigLines.writeln('Limit: $currency $limitFormatted');
    bigLines.writeln('Spent: $currency $spentFormatted');
    bigLines.writeln('Usage: ${((spent / limit) * 100).toStringAsFixed(0)}%');

    if (isOverrun) {
      final overAmount = _numberFormatter().format(spent - limit);
      bigLines.writeln('Over by: $currency $overAmount');
    } else {
      final remaining = _numberFormatter().format(limit - spent);
      bigLines.writeln('Remaining: $currency $remaining');
    }

    bigLines.writeln('');
    bigLines.writeln('Tap to view budget details');

    final androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription:
          'Notifications when budgets approach or exceed their limits',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(bigLines.toString()),
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload =
        BudgetAlertPayload(budgetId: budgetId, threshold: threshold).encode();

    await _plugin.show(
      id: budgetId, // unique per budget, so each budget can have its own alert
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
