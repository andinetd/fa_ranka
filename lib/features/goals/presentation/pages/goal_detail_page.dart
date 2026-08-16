import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/goals/presentation/providers/goals_providers.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/features/goals/presentation/widgets/goal_progress_ring.dart';
import 'package:faranka/features/goals/presentation/widgets/edit_goal_sheet.dart';

class GoalDetailPage extends ConsumerStatefulWidget {
  final int goalId;

  const GoalDetailPage({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends ConsumerState<GoalDetailPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Goal details'),
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        foregroundColor: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: StreamBuilder<List<GoalRow>>(
        stream: db.watchGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: dims.all(24),
                child: Text(
                  'Error loading goal: ${snapshot.error}',
                  style: TextStyle(color: isDark ? DarkAppColors.appBarForeground : null),
                ),
              ),
            );
          }
          final goals = snapshot.data ?? const <GoalRow>[];
          final goal = goals.cast<GoalRow?>().firstWhere(
            (item) => item?.id == widget.goalId,
            orElse: () => null,
          );
          if (goal == null) {
            return Center(
              child: Text(
                'Goal not found',
                style: TextStyle(
                  color: isDark ? DarkAppColors.appBarForeground : null,
                ),
              ),
            );
          }

          final useCompact = AppSettingsService.getBoolSync(
            AppSettingsService.keyCompactNumbers,
            fallback: true,
          );
          final currency = useCompact
              ? NumberFormat.compactCurrency(symbol: 'ETB ')
              : NumberFormat.currency(symbol: 'ETB ');

          return SingleChildScrollView(
            child: Padding(
              padding: dims.fromLTRB(14, 12, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressSection(goal, currency, isDark, dims),
                  SizedBox(height: dims(14)),
                  _buildInfoSection(goal, currency, isDark, dims, calMode),
                  SizedBox(height: dims(14)),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showEditGoalDialog(context, goal, isDark),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit goal'),
                    ),
                  ),
                  SizedBox(height: dims(8)),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, goal, isDark),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete goal'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB85C5C),
                        side: const BorderSide(color: Color(0xFFB85C5C)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressSection(
    GoalRow goal,
    NumberFormat currency,
    bool isDark,
    AppDimensions dims,
  ) {
    return ref.watch(goalProgressProvider(goal.id)).when(
      error: (e, _) => Text(
        'Error loading progress',
        style: TextStyle(color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280)),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      data: (progress) {
        final current = progress['current'] ?? 0.0;
        final target = progress['target'] ?? goal.targetAmount;
        final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
        final pctDisplay = target > 0 ? (current / target) * 100 : 0.0;
        final remaining = math.max(0.0, target - current);

        final progressColor = pct >= 1.0
            ? const Color(0xFF3A8B3A)
            : pct >= 0.75
                ? const Color(0xFFC4975A)
                : isDark
                    ? DarkAppColors.homeAccentGreen
                    : AppColors.homeAccentGreen;

        return Container(
          width: double.infinity,
          padding: dims.all(20),
          decoration: BoxDecoration(
            color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              GoalProgressRing(
                progress: pct,
                size: 140,
                strokeWidth: 12,
                progressColor: progressColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pctDisplay.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? DarkAppColors.appBarForeground : null,
                      ),
                    ),
                    Text(
                      goal.isCompleted ? 'Achieved!' : 'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: dims(16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('Current', currency.format(current), isDark, dims),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB),
                  ),
                  _buildStat('Target', currency.format(target), isDark, dims),
                  if (remaining > 0 && !goal.isCompleted) ...[
                    Container(
                      width: 1,
                      height: 40,
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB),
                    ),
                    _buildStat('Remaining', currency.format(remaining), isDark, dims),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value, bool isDark, AppDimensions dims) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? DarkAppColors.appBarForeground : null,
          ),
        ),
        SizedBox(height: dims(2)),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    GoalRow goal,
    NumberFormat currency,
    bool isDark,
    AppDimensions dims,
    CalendarMode calMode,
  ) {
    final typeLabel = goal.type == 'income_target' ? 'Income Target' : 'Balance Target';
    final periodLabel = goal.period ?? 'One time';

    return Container(
      width: double.infinity,
      padding: dims.all(14),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? DarkAppColors.appBarForeground : null,
            ),
          ),
          SizedBox(height: dims(8)),
          _infoRow('Name', goal.name, isDark),
          _infoRow('Type', typeLabel, isDark),
          if (goal.type == 'balance_target' && goal.period != null)
            _infoRow('Mode', goal.growthMode ? 'Incremental growth' : 'Fixed per period', isDark),
          _infoRow('Period', periodLabel, isDark),
          if (goal.startDate > 0)
            _infoRow(
              'Start date',
              _formatDate(DateTime.fromMillisecondsSinceEpoch(goal.startDate), calMode),
              isDark,
            ),
          if (goal.endDate > 0)
            _infoRow(
              'Deadline',
              _formatDate(DateTime.fromMillisecondsSinceEpoch(goal.endDate), calMode),
              isDark,
            ),
          if (goal.growthMode && goal.startingBalance > 0)
            _infoRow('Starting balance', currency.format(goal.startingBalance), isDark),
          _infoRow('Account', goal.accountFilter, isDark),
          if (goal.isCompleted && goal.completedAt != null)
            _infoRow(
              'Achieved on',
              _formatDate(DateTime.fromMillisecondsSinceEpoch(goal.completedAt!), calMode),
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? DarkAppColors.appBarForeground : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, CalendarMode mode) {
    return date.fmt('MMM d, yyyy', mode);
  }

  Future<void> _showEditGoalDialog(
    BuildContext context,
    GoalRow goal,
    bool isDark,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditGoalSheet(goal: goal),
    );

    if (saved != true || !context.mounted) return;
    setState(() {});
  }

  Future<void> _confirmDelete(
    BuildContext context,
    GoalRow goal,
    bool isDark,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        title: Text(
          'Delete goal?',
          style: TextStyle(
            color: isDark ? DarkAppColors.appBarForeground : null,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${goal.name}"?',
          style: TextStyle(
            color: isDark ? DarkAppColors.balanceCardMuted : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB85C5C)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final db = ref.read(databaseProvider);
    await db.deleteGoal(id: goal.id);
    if (context.mounted) Navigator.pop(context);
  }
}
