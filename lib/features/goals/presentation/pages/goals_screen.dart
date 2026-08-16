import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faranka/features/budgets/presentation/providers/budget_providers.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/goals/presentation/widgets/goal_card.dart';

class GoalsTab extends ConsumerWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final goalsAsync = ref.watch(goalConfigsProvider);

    return goalsAsync.when(
      error: (e, _) => Center(
        child: Padding(
          padding: dims.all(24),
          child: Text(
            'Failed to load goals: $e',
            style: TextStyle(color: isDark ? DarkAppColors.appBarForeground : null),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      data: (goals) {
        if (goals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: dims.icon(52),
                    color: (isDark ? DarkAppColors.balanceCardMuted : AppColors.homeNavigationUnselected)
                        .withValues(alpha: 0.6),
                  ),
                  SizedBox(height: dims(12)),
                  Text(
                    'No goals yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? DarkAppColors.appBarForeground : null,
                    ),
                  ),
                  SizedBox(height: dims(6)),
                  Text(
                    'Set income targets or balance goals to track your progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: dims.symmetric(h: 14, v: 14),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            return Padding(
              padding: dims.only(b: 10),
              child: GoalCard(
                goal: goal,
                onTap: () => context.pushNamed(
                  'goal-detail',
                  pathParameters: {'id': goal.id.toString()},
                ),
              ),
            );
          },
        );
      },
    );
  }
}
