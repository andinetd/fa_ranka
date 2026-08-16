import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_processor.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_recategorizer.dart';

import 'package:faranka/features/auth/presentation/providers/biometric_provider.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/features/settings/presentation/widgets/calendar_settings_sheet.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/features/auth/data/biometric_service.dart';

import 'package:faranka/features/settings/presentation/providers/import_status_provider.dart';
import 'package:faranka/features/settings/presentation/widgets/settings_card.dart';
import 'package:faranka/features/settings/presentation/widgets/display_settings_sheet.dart';
import 'package:faranka/features/settings/presentation/widgets/notification_settings_sheet.dart';
import 'package:faranka/features/settings/utils/settings_export.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _smsAlerts = true;
  bool _compactNumbers = true;
  bool _isDarkMode = false;
  bool _biometricLock = false;
  bool _biometricAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    if (!mounted) return;

    final sp = await SharedPreferences.getInstance();
    bool biometricAvailable = false;
    if (Platform.isAndroid || Platform.isIOS) {
      biometricAvailable = await BiometricService.canAuthenticate();
    }
    if (!mounted) return;

    setState(() {
      _smsAlerts = AppSettingsService.getBoolSync(
        AppSettingsService.keySmsAlerts,
        fallback: true,
      );
      _compactNumbers = AppSettingsService.getBoolSync(
        AppSettingsService.keyCompactNumbers,
        fallback: true,
      );
      _isDarkMode = AppSettingsService.getThemeModeSync() == ThemeMode.dark;
      _biometricLock = sp.getBool(AppSettingsService.keyBiometricLock) ?? false;
      _biometricAvailable = biometricAvailable;
      _isLoading = false;
    });
  }

  Future<void> _updateBool(String key, bool value) async {
    await AppSettingsService.setBool(key, value);
  }

  Future<void> _resetAndReimportAll() async {
    if (!mounted) return;

    final db = ref.read(databaseProvider);
    final txnCount = await db
        .select(db.transactions)
        .get()
        .then((rows) => rows.length);
    final smsCount = await db
        .select(db.smsInbox)
        .get()
        .then((rows) => rows.length);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(ctx) ? DarkAppColors.scaffoldBackground : Colors.white,
        title: const Text('Reset and Re-import All?'),
        content: Text(
          'This will permanently delete $txnCount transactions and $smsCount raw messages, then re-import everything from your SMS inbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Reset & Re-import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await db.wipeAllData();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('setup_complete');

    if (!mounted) return;
    context.go('/setup');
  }

  Future<void> _recategorizeUncategorized() async {
    if (!mounted) return;
      final recategorizer = TransactionRecategorizer(ref.read(databaseProvider));
    final uncategorizedCount = await recategorizer.getUncategorizedDebitCount();

    if (uncategorizedCount == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No uncategorized transactions found.')),
      );
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(ctx) ? DarkAppColors.scaffoldBackground : Colors.white,
        title: const Text('Recategorize Transactions?'),
        content: Text(
          'This will re-parse $uncategorizedCount uncategorized transactions and attempt to assign them to categories based on their reason text.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Recategorize'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recategorizing... this may take a moment.'),
      ),
    );

    try {
      final recategorized = await recategorizer.recategorizeUncategorized();
      final reextracted = await recategorizer.retryReasonExtraction();
      final emptyImproved = await recategorizer.retryEmptyTransactions();
      final totalUpdated = recategorized + reextracted + emptyImproved;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recategorized $recategorized, re-extracted $reextracted, improved $emptyImproved transactions (total: $totalUpdated).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error recategorizing: $e')));
    }
  }

  void _showDisplayDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.isDark(context) ? DarkAppColors.scaffoldBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DisplaySettingsSheet(
        initialTextScale: AppSettingsService.getTextScaleSync(),
        initialSpacingScale: AppSettingsService.getSpacingScaleSync(),
        onChanged: () => setState(() {}),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.isDark(context) ? DarkAppColors.scaffoldBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotificationSettingsSheet(
        onChanged: () => setState(() {}),
      ),
    );
  }

  void _showImportBreakdownSheet(BuildContext context, ImportStatus status) {
    final isDark = AppColors.isDark(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank SMS imported',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? DarkAppColors.appBarForeground
                      : AppColors.appBarForeground,
                ),
              ),
              const SizedBox(height: 8),
              _buildBankRow(
                  'Awash Bank', status.awashDone, status.awashTotal, isDark),
              const Divider(height: 8),
              _buildBankRow('CBE', status.cbeDone, status.cbeTotal, isDark),
              const Divider(height: 8),
              _buildBankRow(
                  'Telebirr', status.telebirrDone, status.telebirrTotal, isDark),
              const Divider(height: 8),
              _buildBankRow(
                  'BoA', status.boaDone, status.boaTotal, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankRow(String label, int done, int total, bool isDark,
      {VoidCallback? onTap, bool showChevron = false}) {
    final ratio = total > 0 ? done / total : 0.0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        total > 0 && done >= total ? Icons.check_circle : Icons.inbox_outlined,
        color: total > 0 && done >= total
            ? const Color(0xFF79AE6F)
            : isDark
                ? DarkAppColors.appBarForeground
                : AppColors.appBarForeground,
      ),
      title: Text(label),
      subtitle: Text('$done / $total imported'),
      trailing: showChevron
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? DarkAppColors.homeNavigationIndicator
                          : Colors.grey.shade200,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF79AE6F)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark
                      ? DarkAppColors.balanceCardMuted
                      : AppColors.balanceCardMuted,
                ),
              ],
            )
          : SizedBox(
              width: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? DarkAppColors.homeNavigationIndicator
                      : Colors.grey.shade200,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF79AE6F)),
                ),
              ),
            ),
    );
  }

  Widget _buildNotificationSubtitle() {
    final parts = <String>[];
    if (AppSettingsService.transactionNotificationsNotifier.value) {
      parts.add('Alerts');
    }

    String fmt(int h, int m) {
      final p = h >= 12 ? 'PM' : 'AM';
      return '${h == 0 ? 12 : (h > 12 ? h - 12 : h)}:${m.toString().padLeft(2, '0')} $p';
    }

    if (AppSettingsService.summaryDailyNotifier.value) {
      parts.add(
          'Daily ${fmt(AppSettingsService.summaryDailyHourNotifier.value, AppSettingsService.summaryDailyMinuteNotifier.value)}');
    }
    if (AppSettingsService.summaryWeeklyNotifier.value) {
      parts.add('Weekly');
    }
    if (AppSettingsService.summaryMonthlyNotifier.value) {
      parts.add('Monthly');
    }
    if (AppSettingsService.budgetAlertsNotifier.value) {
      parts.add('Budgets');
    }
    final text = parts.isEmpty ? 'All off' : parts.join(' \u00b7 ');
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Future<void> _wipeAllData() async {
    final db = ref.read(databaseProvider);
    final txnCount = await db
        .select(db.transactions)
        .get()
        .then((rows) => rows.length);
    final categoryCount = await db
        .select(db.categories)
        .get()
        .then((rows) => rows.length);
    final smsCount = await db
        .select(db.smsInbox)
        .get()
        .then((rows) => rows.length);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(ctx) ? DarkAppColors.scaffoldBackground : Colors.white,
        title: const Text('Wipe All Data?'),
        content: Text(
          'This will permanently delete $txnCount transactions, $categoryCount categories, and $smsCount imported messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Wipe Data'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await db.wipeAllData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data wiped successfully.')),
    );

  }

  Future<void> _openSmsPermissionSettings() async {
    await openAppSettings();
  }

  Future<void> _exportTransactionsJson() =>
      exportTransactionsJson(ref.read(databaseProvider), context);

  Future<void> _exportTransactionsCsv() =>
      exportTransactionsCsv(ref.read(databaseProvider), context);

  Future<void> _showReimportDialog() async {
    if (!mounted) return;

    final db = ref.read(databaseProvider);
    final totalCount = await (db.select(db.transactions)
          ..where((t) => t.smsId.isNotNull()))
        .get()
        .then((rows) => rows.length);

    if (totalCount == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to re-import.')),
      );
      return;
    }

    if (!mounted) return;
    final controller = TextEditingController(text: '50');
    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final isDark = AppColors.isDark(ctx);
        return AlertDialog(
          backgroundColor: isDark ? DarkAppColors.scaffoldBackground : Colors.white,
          title: const Text('Re-import Recent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will delete the N most recent transactions and re-process them from the original SMS messages.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of recent transactions',
                  border: const OutlineInputBorder(),
                  fillColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
                  filled: true,
                  labelStyle: TextStyle(
                    color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$totalCount total transactions available',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(controller.text);
                if (n == null || n <= 0) return;
                Navigator.of(ctx).pop(n.clamp(1, totalCount));
              },
              child: const Text('Re-import'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (confirmed == null || !mounted) return;

    final n = confirmed;
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(ctx) ? DarkAppColors.scaffoldBackground : Colors.white,
        title: Text('Re-import $n Transactions?'),
        content: Text('This will delete $n transactions and re-process them from the original SMS. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Delete & Re-import'),
          ),
        ],
      ),
    );

    if (confirm2 != true || !mounted) return;

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Re-importing...')),
    );

    try {
      final recent = await db.getRecentTransactions(n);
      final processor = TransactionProcessor(db);
      int succeeded = 0;

      for (final txn in recent) {
        try {
          await db.deleteSplitsForTransaction(txn.id);
          await (db.delete(db.transactions)..where((t) => t.id.equals(txn.id))).go();
          if (txn.smsId.isNotEmpty) {
            await db.resetSmsToUnprocessed(txn.smsId);
            final sms = await (db.select(db.smsInbox)
                  ..where((t) => t.id.equals(txn.smsId)))
                .getSingleOrNull();
            if (sms != null) {
              await processor.processSmsSafely(sms);
            }
          }
          succeeded++;
        } catch (_) {
          // Keep going on individual failures
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-processed $succeeded of $n messages.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-import failed: $e')),
      );
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(ctx) ? DarkAppColors.scaffoldBackground : Colors.white,
        title: const Text('Export Transactions'),
        content: const Text('Choose a format for exporting your transaction data.'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _exportTransactionsCsv();
            },
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('CSV'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _exportTransactionsJson();
            },
            icon: const Icon(Icons.data_object_outlined),
            label: const Text('JSON'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        foregroundColor: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                SettingsCard(
                  title: 'General',
                  subtitle: 'Appearance, calendar, and formatting.',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.settings_display_outlined),
                      title: const Text('Display'),
                      subtitle: Text(
                        'Text ${(AppSettingsService.getTextScaleSync() * 100).round()}% · Spacing ${(AppSettingsService.getSpacingScaleSync() * 100).round()}%',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showDisplayDialog,
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Calendar'),
                      subtitle: Text(
                        ref.watch(calendarModeProvider) == CalendarMode.gregorian
                            ? 'Gregorian'
                            : 'Ethiopian',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: isDark ? DarkAppColors.scaffoldBackground : Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => const CalendarSettingsSheet(),
                        );
                      },
                    ),
                    const Divider(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _compactNumbers,
                      title: const Text('Compact numbers'),
                      subtitle: const Text('Example: ETB 12.3K instead of ETB 12,300.'),
                      onChanged: (value) {
                        setState(() => _compactNumbers = value);
                        _updateBool(AppSettingsService.keyCompactNumbers, value);
                      },
                    ),
                    const Divider(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isDarkMode,
                      title: const Text('Dark mode'),
                      subtitle: const Text('Switch between light and dark appearance.'),
                      onChanged: (value) {
                        setState(() => _isDarkMode = value);
                        AppSettingsService.setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsCard(
                  title: 'Notifications',
                  subtitle: 'Transaction alerts, summaries, and app behavior.',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: _buildNotificationSubtitle(),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showNotificationSettings,
                    ),
                    const Divider(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _smsAlerts,
                      title: const Text('Show import alerts'),
                      subtitle: const Text('Display status messages for new imports.'),
                      onChanged: (value) {
                        setState(() => _smsAlerts = value);
                        _updateBool(AppSettingsService.keySmsAlerts, value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsCard(
                  title: 'Import & Data',
                  subtitle: 'SMS import, categorization, export, and storage.',
                  children: [
                    ref.watch(importStatusProvider).when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (status) {
                        final totalDone = status.awashDone +
                            status.cbeDone +
                            status.telebirrDone;
                        final totalAll = status.awashTotal +
                            status.cbeTotal +
                            status.telebirrTotal;
                        if (totalAll == 0) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            _buildBankRow(
                              'Bank SMS imported',
                              totalDone,
                              totalAll,
                              isDark,
                              onTap: () =>
                                  _showImportBreakdownSheet(context, status),
                              showChevron: true,
                            ),
                            const Divider(height: 8),
                          ],
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.settings_applications_outlined),
                      title: const Text('Open SMS Permission Settings'),
                      subtitle: const Text('Grant SMS access if imports are blocked.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _openSmsPermissionSettings,
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Recategorize Uncategorized'),
                      subtitle: const Text('Re-parse transactions stuck in Uncategorized.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _recategorizeUncategorized,
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.upload_file_outlined),
                      title: const Text('Open Import Screen'),
                      subtitle: const Text('Go to setup and import messages now.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/setup'),
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Export'),
                      subtitle: const Text('Save transactions as CSV or JSON.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showExportDialog,
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.restart_alt),
                      title: const Text('Reset and Re-import All'),
                      subtitle: const Text('Delete all data and re-import from SMS inbox.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _resetAndReimportAll,
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.replay_outlined),
                      title: const Text('Re-import Recent'),
                      subtitle: const Text('Re-process the N most recent transactions from SMS.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showReimportDialog,
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                      title: Text('Wipe All Data', style: TextStyle(color: Colors.red.shade700)),
                      subtitle: const Text('Delete transactions, categories, and messages.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _wipeAllData,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsCard(
                  title: 'Security',
                  subtitle: 'App lock.',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _biometricLock,
                      title: const Text('Require biometric authentication'),
                      subtitle: const Text('Lock the app behind fingerprint or face unlock.'),
                      onChanged: _biometricAvailable
                          ? (value) async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await BiometricService.authenticate(
                                reason: value
                                    ? 'Confirm your identity to enable biometric lock'
                                    : 'Confirm your identity to disable biometric lock',
                              );
                              if (!ok) return;
                              setState(() => _biometricLock = value);
                              final sp = await SharedPreferences.getInstance();
                              await sp.setBool(
                                AppSettingsService.keyBiometricLock,
                                value,
                              );
                              setBiometricEnabled(value);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value ? 'Biometric lock enabled' : 'Biometric lock disabled',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsCard(
                  title: 'Legal & Support',
                  subtitle: 'Privacy, help, and app info.',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      subtitle: const Text('How your data is handled.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/privacy-policy'),
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & FAQ'),
                      subtitle: const Text('Common questions and answers.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/help-faq'),
                    ),
                    const Divider(height: 8),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.data?.version ?? '--';
                        final build = snapshot.data?.buildNumber ?? '--';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.new_releases_outlined),
                          title: const Text('App Version'),
                          subtitle: Text('Version $version ($build)'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

