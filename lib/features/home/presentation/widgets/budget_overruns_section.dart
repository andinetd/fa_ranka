import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

class BudgetOverrunsSection extends ConsumerWidget {
  const BudgetOverrunsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final db = ref.watch(databaseProvider);
    return StreamBuilder<List<BudgetConfigRow>>(
      stream: db.watchBudgetConfigs(),
      builder: (context, budgetSnapshot) {
        if (budgetSnapshot.hasError) {
          return _buildErrorCard(dims, isDark);
        }
        final budgets = budgetSnapshot.data ?? const <BudgetConfigRow>[];
        if (budgets.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<List<CategorySum>>(
          stream: db.watchCategorySummaryAllParsed(
            days: 30,
            direction: TransactionDirection.debit,
          ),
          builder: (context, categorySnapshot) {
            final categories =
                categorySnapshot.data ?? const <CategorySum>[];
            final spentByCategory = <String, double>{
              for (final item in categories) item.name: item.total,
            };
            final totalSpent = spentByCategory.values.fold<double>(
              0,
              (sum, v) => sum + v,
            );

            return Padding(
              padding: dims.symmetric(h: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Budgets',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pushNamed('budgets'),
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dims(10)),
                  ...budgets.take(5).map(
                    (budget) => _BudgetSummaryTile(
                      budget: budget,
                      spentByCategory: spentByCategory,
                      totalSpent: totalSpent,
                      currency: _getCurrency(context),
                      isDark: isDark,
                      dims: dims,
                    ),
                  ),
                  if (categorySnapshot.hasError)
                    Padding(
                      padding: dims.only(t: 4),
                      child: _buildErrorChip(dims, isDark),
                    ),
                  if (!categorySnapshot.hasError && budgets.length > 5)
                    Padding(
                      padding: dims.only(t: 4),
                      child: Text(
                        '+${budgets.length - 5} more budgets',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorCard(AppDimensions dims, bool isDark) {
    return Padding(
      padding: dims.symmetric(h: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budgets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          SizedBox(height: dims(10)),
          Container(
            padding: dims.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: isDark
                  ? DarkAppColors.homeCardBackground
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: dims.icon(16),
                  color: isDark
                      ? DarkAppColors.balanceCardMuted
                      : const Color(0xFF6B7280),
                ),
                SizedBox(width: dims(8)),
                Text(
                  'Could not load budgets',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? DarkAppColors.balanceCardMuted
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChip(AppDimensions dims, bool isDark) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: dims.icon(12),
          color: isDark
              ? DarkAppColors.balanceCardMuted
              : const Color(0xFF9CA3AF),
        ),
        SizedBox(width: dims(4)),
        Text(
          'Spending data unavailable',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? DarkAppColors.balanceCardMuted
                : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  NumberFormat _getCurrency(BuildContext context) {
    final useCompact = AppSettingsService.getBoolSync(
      AppSettingsService.keyCompactNumbers,
      fallback: true,
    );
    return useCompact
        ? NumberFormat.compactCurrency(symbol: 'ETB ')
        : NumberFormat.currency(symbol: 'ETB ');
  }
}

class _BudgetSummaryTile extends StatelessWidget {
  const _BudgetSummaryTile({
    required this.budget,
    required this.spentByCategory,
    required this.totalSpent,
    required this.currency,
    required this.isDark,
    required this.dims,
  });

  final BudgetConfigRow budget;
  final Map<String, double> spentByCategory;
  final double totalSpent;
  final NumberFormat currency;
  final bool isDark;
  final AppDimensions dims;

  @override
  Widget build(BuildContext context) {
    final spent = budget.categories.isEmpty
        ? totalSpent
        : budget.categories.fold<double>(
            0,
            (sum, cat) => sum + (spentByCategory[cat] ?? 0),
          );
    final usage = budget.amount > 0 ? spent / budget.amount : 0.0;
    final clamped = usage.clamp(0.0, 1.0);
    final isOverrun = usage > 1;
    final isRisk = !isOverrun && usage >= 0.8;

    final progressColor = isOverrun
        ? const Color(0xFFB85C5C)
        : isRisk
        ? const Color(0xFFC4975A)
        : const Color(0xFF8EA78F);
    final statusColor = isOverrun
        ? const Color(0xFFB85C5C)
        : isRisk
        ? const Color(0xFFC4975A)
        : const Color(0xFF8EA78F);

    return Padding(
      padding: dims.only(b: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pushNamed(
            'budget-detail',
            pathParameters: {'id': budget.id.toString()},
          ),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: dims.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: isDark
                  ? DarkAppColors.homeCardBackground
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? DarkAppColors.appBarForeground
                              : const Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: dims(6)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: clamped,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE5E7EB),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                      SizedBox(height: dims(4)),
                      Text(
                        '${(usage * 100).toStringAsFixed(0)}% · ${currency.format(spent)} of ${currency.format(budget.amount)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: dims(8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOverrun
                          ? '+${currency.format(spent - budget.amount)}'
                          : currency.format(budget.amount - spent),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      isOverrun ? 'over' : 'left',
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: dims(4)),
                Icon(
                  Icons.chevron_right,
                  size: dims.icon(18),
                  color: isDark
                      ? DarkAppColors.balanceCardMuted
                      : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
