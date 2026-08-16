import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/features/goals/presentation/providers/goals_providers.dart';

class GoalCard extends ConsumerWidget {
  final GoalRow goal;
  final VoidCallback? onTap;

  const GoalCard({super.key, required this.goal, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final progressAsync = ref.watch(goalProgressProvider(goal.id));

    final useCompact = AppSettingsService.getBoolSync(
      AppSettingsService.keyCompactNumbers,
      fallback: true,
    );
    final currency = useCompact
        ? NumberFormat.compactCurrency(symbol: 'ETB ')
        : NumberFormat.currency(symbol: 'ETB ');

    return Material(
      color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
      borderRadius: BorderRadius.circular(12),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: dims.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? DarkAppColors.appBarForeground : null,
                      ),
                    ),
                  ),
                  _buildTypeChip(goal, isDark),
                ],
              ),
              SizedBox(height: dims(8)),
              progressAsync.when(
                error: (e, _) => Text(
                  'Error loading progress',
                  style: TextStyle(color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280)),
                ),
                loading: () => const LinearProgressIndicator(),
                data: (progress) {
                  final current = progress['current'] ?? 0.0;
                  final target = progress['target'] ?? goal.targetAmount;
                  final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
                  final isMet = target > 0 && current >= target;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currency.format(current)} / ${currency.format(target)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? DarkAppColors.appBarForeground : null,
                        ),
                      ),
                      SizedBox(height: dims(6)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMet
                                ? const Color(0xFF3A8B3A)
                                : isDark
                                    ? DarkAppColors.homeAccentGreen
                                    : AppColors.homeAccentGreen,
                          ),
                        ),
                      ),
                      SizedBox(height: dims(6)),
                      Row(
                        children: [
                          if (goal.endDate > 0)
                            Text(
                              'Due ${_formatDate(DateTime.fromMillisecondsSinceEpoch(goal.endDate))}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
                              ),
                            ),
                          if (goal.endDate > 0 && goal.period != null)
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
                              ),
                            ),
                          if (goal.period != null)
                            Text(
                              goal.period!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isMet
                                  ? const Color(0xFF3A8B3A)
                                  : isDark
                                      ? DarkAppColors.appBarForeground
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(GoalRow goal, bool isDark) {
    final label = goal.type == 'income_target'
        ? 'Income'
        : goal.growthMode
            ? 'Growth'
            : 'Fixed';
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
