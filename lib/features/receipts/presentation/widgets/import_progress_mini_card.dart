import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faranka/features/receipts/presentation/providers/import_progress_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/receipts/presentation/notifiers/import_progress_notifier.dart';

class ImportProgressMiniCard extends ConsumerStatefulWidget {
  const ImportProgressMiniCard({super.key});

  @override
  ConsumerState<ImportProgressMiniCard> createState() =>
      _ImportProgressMiniCardState();
}

class _ImportProgressMiniCardState
    extends ConsumerState<ImportProgressMiniCard> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _checkAutoDismiss(ref.read(importProgressProvider));
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _checkAutoDismiss(ImportState state) {
    if (state.isComplete) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(seconds: 4), () {
        ref.read(importProgressProvider.notifier).dismissComplete();
      });
    } else {
      _dismissTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final state = ref.watch(importProgressProvider);

    if (!state.isRunning && !state.isComplete && !state.isPaused) {
      return const SizedBox.shrink();
    }

    // Watch for complete transitions to start auto-dismiss
    ref.listen(importProgressProvider, (previous, next) {
      if (next.isComplete) {
        _checkAutoDismiss(next);
      } else {
        _dismissTimer?.cancel();
      }
    });

    final Color statusBg;
    final Color borderColor;
    final Color statusTextColor;
    final Color progressBg;
    final Color progressFill;
    final Color detailTextColor;
    final Color iconColor;
    final Color actionIconColor;

    if (state.isComplete) {
      statusBg = isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9);
      borderColor = isDark
          ? Colors.greenAccent.withValues(alpha: 0.3)
          : const Color(0xFFA5D6A7);
      statusTextColor = isDark ? Colors.greenAccent : const Color(0xFF2E7D32);
      progressBg = Colors.transparent;
      progressFill = Colors.transparent;
      detailTextColor = Colors.transparent;
      iconColor = isDark ? Colors.greenAccent : const Color(0xFF2E7D32);
      actionIconColor = isDark ? Colors.white38 : const Color(0xFF6B7280);
    } else if (state.isPaused) {
      statusBg = isDark ? const Color(0xFFE65100) : const Color(0xFFFFF3E0);
      borderColor = isDark
          ? Colors.orange.withValues(alpha: 0.3)
          : const Color(0xFFFFCC80);
      statusTextColor =
          isDark ? Colors.orangeAccent : const Color(0xFFE65100);
      progressBg = isDark ? Colors.white12 : const Color(0x1F000000);
      progressFill = const Color(0xFF2E7D32);
      detailTextColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
      iconColor = Colors.orange;
      actionIconColor = isDark ? Colors.white38 : const Color(0xFF6B7280);
    } else {
      statusBg = isDark ? const Color(0xFF1A1A1A) : AppColors.homeCardBackground;
      borderColor = isDark ? Colors.white12 : AppColors.balanceCardChipBorder;
      statusTextColor =
          isDark ? Colors.white : AppColors.balanceCardForeground;
      progressBg = isDark ? Colors.white12 : const Color(0x1F000000);
      progressFill = const Color(0xFF2E7D32);
      detailTextColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
      iconColor = Colors.amber;
      actionIconColor = isDark ? Colors.white38 : const Color(0xFF6B7280);
    }

    return GestureDetector(
      onTap: () {
        _dismissTimer?.cancel();
        context.push('/results');
      },
      child: Container(
        width: double.infinity,
        padding: dims.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: statusBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            if (state.isRunning)
              SizedBox(
                width: dims(14),
                height: dims(14),
                child: const CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.amber,
                ),
              ),
            if (state.isPaused)
              Icon(Icons.wifi_off, size: dims.icon(14), color: iconColor),
            if (state.isComplete)
              Icon(Icons.check_circle, size: dims.icon(14), color: iconColor),
            if (state.isRunning || state.isPaused || state.isComplete)
              SizedBox(width: dims(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.isComplete
                        ? 'Import complete'
                        : state.isPaused
                        ? 'Import paused'
                        : 'Importing...',
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (state.isRunning || state.isPaused) ...[
                    SizedBox(height: dims(4)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: state.overallProgress,
                        minHeight: 4,
                        backgroundColor: progressBg,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressFill),
                      ),
                    ),
                    SizedBox(height: dims(4)),
                    Text(
                      'Awash ${state.awashDone}/${state.awashTotal} · '
                      'CBE ${state.cbeDone}/${state.cbeTotal} · '
                      'Telebirr ${state.telebirrDone}/${state.telebirrTotal} · '
                      'BoA ${state.boaDone}/${state.boaTotal}',
                      style: TextStyle(
                        color: detailTextColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  if (state.isComplete && state.skippedStatus.isNotEmpty)
                    Padding(
                      padding: dims.only(t: 2),
                      child: Text(
                        state.skippedStatus,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                state.isComplete ? Icons.close : Icons.arrow_forward_ios,
                size: dims.icon(16),
                color: actionIconColor,
              ),
              onPressed: () {
                _dismissTimer?.cancel();
                if (state.isComplete) {
                  ref.read(importProgressProvider.notifier).dismissComplete();
                } else {
                  context.push('/results');
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
