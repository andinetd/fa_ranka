import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as sms_inbox;
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/providers/sensitive_hide_provider.dart';
import 'package:faranka/app/core/widgets/sensitive_text.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/tutorial/tutorial_content.dart';
import 'package:faranka/app/core/tutorial/tutorial_widget.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/home/presentation/widgets/balance_section.dart';
import 'package:faranka/features/home/presentation/widgets/category_breakdown_section.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';
import 'package:faranka/features/home/presentation/widgets/recent_transactions_section.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_processor.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/app/core/services/widget_update_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  FilterPeriod _selectedPeriod = FilterPeriod.yearly;
  CategoryFilterPeriod _selectedCategoryPeriod = CategoryFilterPeriod.oneMonth;
  BankBalanceFilter _selectedBankFilter = BankBalanceFilter.all;
  bool _smsPermissionDenied = false;
  String? _refreshStatus;
  Timer? _resultTimer;

  final _balanceKey = GlobalKey();
  final _categoryKey = GlobalKey();
  final _recentTxnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkSmsPermission();
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkSmsPermission() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.sms.status;
    if (mounted) {
      setState(
        () => _smsPermissionDenied =
            status.isDenied || status.isPermanentlyDenied,
      );
    }
  }

  Future<void> _requestSmsPermission() async {
    final result = await Permission.sms.request();
    if (mounted) {
      setState(() => _smsPermissionDenied = !result.isGranted);
    }
  }

  void _setRefreshStatus(String? status) {
    if (mounted) setState(() => _refreshStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    return Scaffold(
      backgroundColor: isDark
          ? DarkAppColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      extendBody: true,
      appBar: _buildCustomAppBar(context),
      body: Stack(
        children: [
          TutorialWrapper(
            pageName: 'home',
            targets: homeTutorial(
              balanceKey: _balanceKey,
              categoryKey: _categoryKey,
              recentTxnKey: _recentTxnKey,
              isDark: isDark,
              dims: dims,
            ),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (_smsPermissionDenied) _buildSmsBanner(context, dims),
                    SizedBox(height: dims(12)),
                    BalanceSummaryCard(
                      key: _balanceKey,
                      selectedBankFilter: _selectedBankFilter,
                      onBankFilterChanged: (value) {
                        setState(() => _selectedBankFilter = value);
                      },
                      selectedPeriod: _selectedPeriod,
                      onPeriodChanged: (value) {
                        setState(() => _selectedPeriod = value);
                      },
                    ),
                    SizedBox(height: dims(12)),
                    CategoryBreakdownSection(
                      key: _categoryKey,
                      selectedPeriod: _selectedCategoryPeriod,
                      onPeriodChanged: (value) {
                        setState(() => _selectedCategoryPeriod = value);
                      },
                      onCategoryTap: _openCategoryMessages,
                      onSeeAllTap: () => context.push('/debug/categories'),
                    ),
                    SizedBox(height: dims(12)),
                    RecentTransactionsSection(key: _recentTxnKey),
                    SizedBox(height: dims(6)),
                  ],
                ),
              ),
            ),
          ),
          if (_refreshStatus != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildRefreshOverlay(isDark, dims),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshOverlay(bool isDark, AppDimensions dims) {
    final accent = isDark
        ? DarkAppColors.homeNavigationSelected
        : AppColors.homeNavigationSelected;
    return Material(
      elevation: 4,
      color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      child: Padding(
        padding: dims.symmetric(h: 16, v: 10),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            ),
            SizedBox(width: dims(10)),
            Expanded(
              child: Text(
                _refreshStatus!,
                style: TextStyle(
                  fontSize: 13,
                  color: accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsBanner(BuildContext context, AppDimensions dims) {
    final isDark = AppColors.isDark(context);
    final accent = isDark
        ? DarkAppColors.homeNavigationSelected
        : AppColors.homeNavigationSelected;
    return Padding(
      padding: dims.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _requestSmsPermission,
          child: Padding(
            padding: dims.symmetric(h: 14, v: 12),
            child: Row(
              children: [
                Icon(Icons.sms_outlined, size: dims.icon(20), color: accent),
                SizedBox(width: dims(10)),
                Expanded(
                  child: Text(
                    'Import bank messages to auto-track your spending',
                    style: TextStyle(
                      fontSize: 13,
                      color: accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: dims.icon(14),
                  color: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Hey night owl';
  }

  String _relativeTime(int? timestamp) {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  PreferredSizeWidget _buildCustomAppBar(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final greeting = _timeBasedGreeting();
    final calMode = ref.watch(calendarModeProvider);
    final today = DateTime.now().fmt('EEE, MMM d', calMode);
    final synced = _relativeTime(AppSettingsService.lastSyncNotifier.value);

    final hidden = ref.watch(sensitiveHideProvider);

    return AppBar(
      backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      foregroundColor: isDark
          ? DarkAppColors.appBarForeground
          : AppColors.appBarForeground,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleSpacing: 16,
      actions: [
        IconButton(
          icon: hidden ? const ClosedEyeIcon() : const Icon(Icons.visibility),
          onPressed: () => ref.read(sensitiveHideProvider.notifier).toggle(),
          tooltip: hidden ? 'Show amounts' : 'Hide amounts',
        ),
      ],
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            synced.isNotEmpty
                ? 'Faranka · $today · Synced $synced'
                : 'Faranka · $today',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color:
                  (isDark
                          ? DarkAppColors.appBarForeground
                          : AppColors.appBarForeground)
                      .withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    if (!Platform.isAndroid) return;

    _setRefreshStatus('Checking messages\u2026');
    try {
      final smsGranted = await Permission.sms.status.isGranted;
      if (!smsGranted) {
        _setRefreshStatus(null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SMS permission needed to sync bank messages'),
            ),
          );
        }
        return;
      }

      final lastSync = AppSettingsService.lastSyncNotifier.value;
      final minutesSinceLastSync = lastSync != null
          ? DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(lastSync))
                .inMinutes
          : 9999;
      final queryCount = minutesSinceLastSync < 60 ? 50 : 300;

      final query = sms_inbox.SmsQuery();
      final latestSms = await query.querySms(
        kinds: [sms_inbox.SmsQueryKind.inbox],
        count: queryCount,
      );
      final bankSms = latestSms.where((sms) {
        final sender = sms.address ?? '';
        return _isSupportedBankSender(sender);
      }).toList();

      final newBankSms = lastSync != null
          ? bankSms
                .where((s) => (s.date?.millisecondsSinceEpoch ?? 0) > lastSync)
                .toList()
          : bankSms;

      final db = ref.read(databaseProvider);
      final newCount = newBankSms.isNotEmpty
          ? await db.syncRawMessages(newBankSms)
          : 0;

      if (newCount > 0) {
        _setRefreshStatus(
          'Processing $newCount new message${newCount == 1 ? '' : 's'}\u2026',
        );
      }

      final processor = TransactionProcessor(db);
      if (newCount > 0) {
        await processor.processPendingSms(limit: 200, maxAttempts: 5);
      }
      try {
        await processor.retryFailedExtractions(limit: 50);
      } catch (e) {
        debugPrint('Refresh retryFailedExtractions failed: $e');
      }

      await AppSettingsService.setLastSyncTimestamp();
      unawaited(WidgetUpdateService.pushAllWidgets(db));

      if (mounted) {
        final result = newCount > 0
            ? 'Synced $newCount message${newCount == 1 ? '' : 's'}'
            : 'No new messages';
        _resultTimer?.cancel();
        _setRefreshStatus(result);
        _resultTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) _setRefreshStatus(null);
        });
      }
    } catch (e) {
      debugPrint('Pull-to-refresh sync failed: $e');
      _setRefreshStatus(null);
      if (mounted) {
        final msg = e.toString().contains('No internet')
            ? 'No internet connection'
            : 'Sync failed\u2014try again';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  bool _isSupportedBankSender(String sender) {
    final lower = sender.toLowerCase();
    return lower.contains('awash') ||
        lower.contains('cbe') ||
        lower == '127' ||
        lower.contains('telebirr') ||
        lower.contains('ethio telecom');
  }

  void _openCategoryMessages(String categoryName) {
    context.push('/category/${Uri.encodeComponent(categoryName)}');
  }
}
