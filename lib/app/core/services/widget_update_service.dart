import 'package:drift/drift.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

class WidgetUpdateService {
  static final _fmt = NumberFormat('#,###');

  static const _sensitiveKey = 'sensitive_hidden';

  static Future<void> pushAllWidgets(AppDatabase db) async {
    debugPrint('[WidgetUpdateService] pushAllWidgets called');
    try {
      final prefs = await SharedPreferences.getInstance();
      final hidden = prefs.getBool(_sensitiveKey) ?? false;

      debugPrint('[WidgetUpdateService] transactions in DB: ${(await db.select(db.transactions).get()).length}');
      await Future.wait([
        _pushBalanceWidget(db, hidden: hidden),
        _pushRecentWidget(db, hidden: hidden),
        _pushCategoryWidget(db, hidden: hidden),
      ]);
      debugPrint('[WidgetUpdateService] all widgets pushed');
    } catch (e, st) {
      debugPrint('[WidgetUpdateService] ERROR: $e\n$st');
    }
  }

  static Future<void> _pushBalanceWidget(AppDatabase db, {required bool hidden}) async {
    final transactions = await db.select(db.transactions).get();
    if (transactions.isEmpty) {
      debugPrint('[WidgetUpdateService] balance: no transactions, skipping');
      return;
    }

    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    final twoMonthsAgo = now.subtract(const Duration(days: 60));

    double sent = 0;
    double received = 0;
    double prevSent = 0;
    double prevReceived = 0;
    final latestBalances = <String?, double?>{};

    for (final txn in transactions.reversed) {
      if (txn.balanceAfter != null) {
        latestBalances[txn.bankName] = txn.balanceAfter;
      }
      if (txn.smsTimestamp >= monthAgo.millisecondsSinceEpoch) {
        if (txn.direction == TransactionDirection.debit) {
          sent += txn.amount;
        } else if (txn.direction == TransactionDirection.credit) {
          received += txn.amount;
        }
      } else if (txn.smsTimestamp >= twoMonthsAgo.millisecondsSinceEpoch) {
        if (txn.direction == TransactionDirection.debit) {
          prevSent += txn.amount;
        } else if (txn.direction == TransactionDirection.credit) {
          prevReceived += txn.amount;
        }
      }
    }

    final totalBalance = latestBalances.values.fold<double>(0, (sum, v) => sum + (v ?? 0));

    final netPercent = received > 0 ? ((received - sent) / received * 100) : 0;
    String cashflow;
    int cashflowColor = 0xFF10B981;  // Emerald for positive
    if (received <= 0 && sent <= 0) {
      cashflow = '';
    } else if (received <= 0) {
      cashflow = '↓ 100%';
      cashflowColor = 0xFFEF4444;  // Bright red for negative
    } else {
      cashflow = '↑ ${netPercent.toStringAsFixed(1)}%';
      cashflowColor = netPercent >= 0 ? 0xFF10B981 : 0xFFEF4444;  // Emerald or Coral
    }

    // Trend indicator: compare this month vs previous month
    final prevTotal = prevSent + prevReceived;
    final currTotal = sent + received;
    String trendIndicator = '';
    if (currTotal > prevTotal) {
      trendIndicator = '↑';  // Higher activity
    } else if (currTotal < prevTotal) {
      trendIndicator = '↓';  // Lower activity
    }

    final lastSync = _relativeTime(AppSettingsService.lastSyncNotifier.value);

    await HomeWidget.saveWidgetData('balance_title', 'Total Balance');
    await HomeWidget.saveWidgetData('balance_prefix', 'ETB ');
    final hiddenAmount = hidden ? '****' : null;
    await HomeWidget.saveWidgetData('balance_amount', hiddenAmount ?? _fmt.format(totalBalance));
    await HomeWidget.saveWidgetData('balance_sent', hiddenAmount ?? _fmt.format(sent));
    await HomeWidget.saveWidgetData('balance_received', hiddenAmount ?? _fmt.format(received));
    await HomeWidget.saveWidgetData('balance_cashflow', cashflow);
    await HomeWidget.saveWidgetData('balance_trend', trendIndicator);
    await HomeWidget.saveWidgetData('balance_last_sync', lastSync);
    await HomeWidget.saveWidgetData('balance_fg_color', 0xFF1A2A44);
    await HomeWidget.saveWidgetData('balance_muted_color', 0xFF6C7A89);
    await HomeWidget.saveWidgetData('balance_cashflow_color', cashflowColor);

    await HomeWidget.updateWidget(
      androidName: 'BalanceGlanceWidgetReceiver',
    );
  }

  static Future<void> _pushRecentWidget(AppDatabase db, {required bool hidden}) async {
    final query = db.select(db.transactions)
      ..orderBy([(t) => OrderingTerm(expression: t.smsTimestamp, mode: OrderingMode.desc)])
      ..limit(3);
    final recent = await query.get();

    // Vibrant color palette - matches new design
    final catColors = [
      0xFFF58220,  // Orange
      0xFF10B981,  // Emerald
      0xFF3B82F6,  // Blue
      0xFF8B5CF6,  // Purple
      0xFFEF4444,  // Red
      0xFF1ABC9C,  // Teal
      0xFFF59E0B,  // Amber
      0xFF6366F1,  // Indigo
    ];

    for (int i = 0; i < 3; i++) {
      if (i < recent.length) {
        final txn = recent[i];
        final isCredit = txn.direction == TransactionDirection.credit;
        final prefix = isCredit ? '+' : '-';
        await HomeWidget.saveWidgetData('recent_txn${i + 1}_cat', txn.parsedCategory);
        await HomeWidget.saveWidgetData(
          'recent_txn${i + 1}_amount',
          hidden ? '**** ETB' : '$prefix${_fmt.format(txn.amount)} ETB',
        );
        await HomeWidget.saveWidgetData(
          'recent_txn${i + 1}_direction',
          isCredit ? 'credit' : 'debit',
        );
        await HomeWidget.saveWidgetData(
          'recent_txn${i + 1}_dot_color',
          catColors[i % catColors.length],
        );
      } else {
        await HomeWidget.saveWidgetData<String?>('recent_txn${i + 1}_cat', null);
        await HomeWidget.saveWidgetData<String?>('recent_txn${i + 1}_amount', null);
        await HomeWidget.saveWidgetData<String?>('recent_txn${i + 1}_direction', null);
      }
    }

    await HomeWidget.saveWidgetData('recent_fg_color', 0xFF1A2A44);

    await HomeWidget.updateWidget(
      androidName: 'RecentGlanceWidgetReceiver',
    );
  }

  static Future<void> _pushCategoryWidget(AppDatabase db, {required bool hidden}) async {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    final twoMonthsAgo = now.subtract(const Duration(days: 60));
    final threshold = monthAgo.millisecondsSinceEpoch;
    final prevThreshold = twoMonthsAgo.millisecondsSinceEpoch;

    final transactions = await db.select(db.transactions).get();
    final debitTxns = transactions
        .where((t) =>
            t.direction == TransactionDirection.debit &&
            t.smsTimestamp >= threshold)
        .toList();
    
    // For trend calculation
    final prevDebitTxns = transactions
        .where((t) =>
            t.direction == TransactionDirection.debit &&
            t.smsTimestamp >= prevThreshold &&
            t.smsTimestamp < threshold)
        .toList();

    if (debitTxns.isEmpty) return;

    final catTotals = <String, double>{};
    final catPrevTotals = <String, double>{};
    
    for (final txn in debitTxns) {
      catTotals[txn.parsedCategory] =
          (catTotals[txn.parsedCategory] ?? 0) + txn.amount;
    }
    
    for (final txn in prevDebitTxns) {
      catPrevTotals[txn.parsedCategory] =
          (catPrevTotals[txn.parsedCategory] ?? 0) + txn.amount;
    }

    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top4 = sorted.take(4).toList();
    final totalSpending = catTotals.values.fold<double>(0, (a, b) => a + b);

    // Vibrant color palette - matches new design
    final catColors = [
      0xFFF58220,  // Orange
      0xFF10B981,  // Emerald
      0xFF3B82F6,  // Blue
      0xFF8B5CF6,  // Purple
    ];

    await HomeWidget.saveWidgetData('cat_total', hidden ? '**** ETB' : '${_fmt.format(totalSpending)} ETB');
    await HomeWidget.saveWidgetData(
      'cat_count',
      '${debitTxns.length} transaction${debitTxns.length == 1 ? '' : 's'}',
    );
    await HomeWidget.saveWidgetData('cat_fg_color', 0xFF1A2A44);
    await HomeWidget.saveWidgetData('cat_muted_color', 0xFF6C7A89);

    for (int i = 0; i < 4; i++) {
      if (i < top4.length) {
        final entry = top4[i];
        final pct = totalSpending > 0
            ? ((entry.value / totalSpending) * 1000).round().clamp(0, 1000)
            : 0;
        
        // Trend for this category: compare vs previous month
        final prevAmount = catPrevTotals[entry.key] ?? 0;
        final trend = entry.value > prevAmount ? '↑' : (entry.value < prevAmount ? '↓' : '→');
        
        await HomeWidget.saveWidgetData('cat${i + 1}_name', entry.key);
        await HomeWidget.saveWidgetData('cat${i + 1}_amount', hidden ? '**** ETB' : '${_fmt.format(entry.value)} ETB');
        await HomeWidget.saveWidgetData('cat${i + 1}_progress', pct);
        await HomeWidget.saveWidgetData('cat${i + 1}_percent', '${((pct / 10).round())}%');
        await HomeWidget.saveWidgetData('cat${i + 1}_trend', trend);
        await HomeWidget.saveWidgetData('cat${i + 1}_dot_color', catColors[i % catColors.length]);
      } else {
        await HomeWidget.saveWidgetData<String?>('cat${i + 1}_name', null);
        await HomeWidget.saveWidgetData<String?>('cat${i + 1}_amount', null);
        await HomeWidget.saveWidgetData<int>('cat${i + 1}_progress', 0);
      }
    }

    await HomeWidget.updateWidget(
      androidName: 'CategoryGlanceWidgetReceiver',
    );
  }

  static String _relativeTime(int? timestamp) {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
