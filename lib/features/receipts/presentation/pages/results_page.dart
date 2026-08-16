import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faranka/features/receipts/presentation/providers/import_progress_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/features/receipts/presentation/notifiers/import_progress_notifier.dart';
import 'package:faranka/app/core/services/network_status_service.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

class ResultsPage extends ConsumerStatefulWidget {
  final Map<String, int> messageData;
  const ResultsPage({super.key, required this.messageData});

  @override
  ConsumerState<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends ConsumerState<ResultsPage> {
  StreamSubscription<bool>? _internetSubscription;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _bindInternetWatcher();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStarted) {
      _hasStarted = true;
      final notifier = ref.read(importProgressProvider.notifier);
      final state = ref.read(importProgressProvider);
      if (!state.isRunning && !state.isComplete && !state.isPaused) {
        Future.microtask(() => notifier.startImport(widget.messageData));
      }
    }
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    super.dispose();
  }

  void _bindInternetWatcher() {
    _internetSubscription?.cancel();
    _internetSubscription = NetworkStatusService.watchInternetStatus().listen((
      online,
    ) async {
      if (!mounted) return;
      if (!online) return;
      final notifier = ref.read(importProgressProvider.notifier);
      final state = ref.read(importProgressProvider);
      if (!state.isPaused) return;
      if (AppSettingsService.smsAlertsNotifier.value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection restored. Resuming import...'),
          ),
        );
      }
      await notifier.startImport(widget.messageData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final state = ref.watch(importProgressProvider);

    ref.listen(importProgressProvider, (previous, next) {
      if (!mounted) return;

      final showAlerts = AppSettingsService.smsAlertsNotifier.value;
      if (!showAlerts) return;

      if (next.isRunning && next.currentActivity == 'Importing messages...') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Starting import...')));
      }
      if (next.isComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.failedCount > 0
                  ? 'Import finished with ${next.failedCount} errors (${next.totalDone} processed).'
                  : 'Import complete — ${next.totalDone} messages processed.',
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: isDark
          ? DarkAppColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Importing Messages'),
        backgroundColor: isDark
            ? DarkAppColors.homeCardBackground
            : AppColors.homeCardBackground,
        foregroundColor: isDark
            ? DarkAppColors.appBarForeground
            : AppColors.appBarForeground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Close',
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (!state.isRunning && !state.isComplete)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref
                  .read(importProgressProvider.notifier)
                  .startImport(widget.messageData),
            ),
        ],
      ),
      body: _buildBody(state, isDark, dims),
    );
  }

  Widget _buildBody(ImportState state, bool isDark, AppDimensions dims) {
    final muted = isDark
        ? DarkAppColors.balanceCardMuted
        : AppColors.balanceCardMuted;
    final foreground = isDark
        ? DarkAppColors.balanceCardForeground
        : AppColors.balanceCardForeground;
    return SingleChildScrollView(
      padding: dims.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallProgress(state, isDark, dims),
          SizedBox(height: dims.spacingLg),
          ..._buildBankSections(state, isDark, dims),
          SizedBox(height: dims.spacingMd),
          if (state.currentActivity.isNotEmpty)
            Padding(
              padding: dims.only(b: 16),
              child: Text(
                state.currentActivity,
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ),
          if (state.skippedStatus.isNotEmpty)
            Padding(
              padding: dims.only(b: 16),
              child: Text(
                state.skippedStatus,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 13,
                ),
              ),
            ),
          if (state.isPaused) _buildOfflineBanner(isDark, dims),
          if (state.recentTransactions.isNotEmpty) ...[
            Text(
              'Recently Processed',
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: dims.spacingSm),
            _buildRecentFeed(state, isDark, dims),
          ],
          if (state.isComplete) ...[
            SizedBox(height: dims(32)),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF2E7D32)
                      : AppColors.homeNavigationSelected,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Continue to Home',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallProgress(
    ImportState state,
    bool isDark,
    AppDimensions dims,
  ) {
    final ratio = state.overallProgress;
    final muted = isDark
        ? DarkAppColors.balanceCardMuted
        : AppColors.balanceCardMuted;
    final foreground = isDark
        ? DarkAppColors.balanceCardForeground
        : AppColors.balanceCardForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (state.isRunning)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.amber,
                ),
              ),
            if (state.isRunning) SizedBox(width: dims.spacingSm),
            Flexible(
              child: Text(
                state.isComplete ? 'Import Complete' : 'Importing...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: dims.spacingMd),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 14,
            backgroundColor: isDark ? Colors.white12 : const Color(0x1F000000),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark
                  ? const Color(0xFF2E7D32)
                  : AppColors.homeNavigationSelected,
            ),
          ),
        ),
        SizedBox(height: dims(6)),
        Text(
          '${state.totalDone} / ${state.totalAll}',
          style: TextStyle(color: muted, fontSize: 13),
        ),
      ],
    );
  }

  /// Only banks the user chose (total > 0) show a progress section.
  List<Widget> _buildBankSections(
    ImportState state,
    bool isDark,
    AppDimensions dims,
  ) {
    final sections = <(String, int, int)>[
      ('Awash Bank', state.awashDone, state.awashTotal),
      ('CBE', state.cbeDone, state.cbeTotal),
      ('Telebirr', state.telebirrDone, state.telebirrTotal),
      ('BoA', state.boaDone, state.boaTotal),
    ];
    final widgets = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final (label, done, total) = sections[i];
      if (total <= 0) continue;
      if (widgets.isNotEmpty) {
        widgets.add(SizedBox(height: dims(12)));
      }
      widgets.add(
        _buildBankProgress(label, done, total, state.isComplete, isDark, dims),
      );
    }
    return widgets;
  }

  Widget _buildBankProgress(
    String label,
    int done,
    int total,
    bool isFinished,
    bool isDark,
    AppDimensions dims,
  ) {
    final ratio = total > 0 ? done / total : 0.0;
    final muted = isDark
        ? DarkAppColors.balanceCardMuted
        : AppColors.balanceCardMuted;
    final foreground = isDark
        ? DarkAppColors.balanceCardForeground
        : AppColors.balanceCardForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              isFinished ? '$done / $total ✓' : '$done / $total',
              style: TextStyle(
                color: isFinished ? Colors.greenAccent : muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        SizedBox(height: dims(6)),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: isDark ? Colors.white12 : const Color(0x1F000000),
            valueColor: AlwaysStoppedAnimation<Color>(
              isFinished
                  ? Colors.green
                  : isDark
                  ? const Color(0xFF2E7D32)
                  : AppColors.homeNavigationSelected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFeed(ImportState state, bool isDark, AppDimensions dims) {
    final cardBg = isDark
        ? DarkAppColors.homeCardBackground
        : AppColors.homeCardBackground;
    final dividerColor = isDark ? Colors.white10 : const Color(0x1A000000);
    return Container(
      width: double.infinity,
      padding: dims.all(12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? DarkAppColors.balanceCardChipBorder
              : AppColors.balanceCardChipBorder,
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: ListView.builder(
        itemCount: state.recentTransactions.length,
        itemBuilder: (context, i) {
          if (i == 0) {
            return _buildFeedRow(state, i, isDark, dims);
          }
          return Column(
            children: [
              Divider(height: 1, color: dividerColor),
              _buildFeedRow(state, i, isDark, dims),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedRow(
    ImportState state,
    int i,
    bool isDark,
    AppDimensions dims,
  ) {
    final event = state.recentTransactions[i];
    final foreground = isDark
        ? DarkAppColors.balanceCardForeground
        : AppColors.balanceCardForeground;
    final muted = isDark
        ? DarkAppColors.balanceCardMuted
        : AppColors.balanceCardMuted;
    final chipBg = isDark ? Colors.white10 : const Color(0x1A000000);
    return Padding(
      padding: dims.symmetric(v: 6),
      child: Row(
        children: [
          Icon(
            event.hasError
                ? Icons.error_outline
                : event.isComplete
                ? Icons.check_circle
                : Icons.hourglass_top,
            size: dims.icon(18),
            color: event.hasError
                ? Colors.redAccent
                : event.isComplete
                ? Colors.green
                : Colors.amber,
          ),
          SizedBox(width: dims(10)),
          Expanded(
            child: Text(
              event.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foreground, fontSize: 13),
            ),
          ),
          Container(
            padding: dims.symmetric(h: 6, v: 2),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.bank,
              style: TextStyle(color: muted, fontSize: 10),
            ),
          ),
          if (!event.isComplete && !event.hasError) ...[
            SizedBox(width: dims(6)),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.amber,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(bool isDark, AppDimensions dims) {
    final bg = isDark
        ? Colors.orange.withValues(alpha: 0.1)
        : const Color(0xFFFFF3E0);
    final borderColor = isDark
        ? Colors.orange.withValues(alpha: 0.3)
        : const Color(0xFFFFCC80);
    return Container(
      width: double.infinity,
      padding: dims.all(12),
      margin: dims.only(b: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange, size: dims.icon(18)),
          SizedBox(width: dims(10)),
          const Expanded(
            child: Text(
              'No internet. Deep scan paused. Auto-resume when online.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
