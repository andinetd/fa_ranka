import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:faranka/features/budgets/presentation/providers/budget_providers.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/tutorial/tutorial_content.dart';
import 'package:faranka/app/core/tutorial/tutorial_widget.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/features/goals/presentation/pages/goals_screen.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final _fabKey = GlobalKey();
  final _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  NumberFormat _getCurrencyFormat() {
    final useCompact = AppSettingsService.getBoolSync(
      AppSettingsService.keyCompactNumbers,
      fallback: true,
    );
    return useCompact
        ? NumberFormat.compactCurrency(symbol: 'ETB ')
        : NumberFormat.currency(symbol: 'ETB ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final categoriesAsync = ref.watch(categorySummaryProvider);
    final budgetsAsync = ref.watch(budgetConfigsProvider);

    final isLoading = categoriesAsync.isLoading || budgetsAsync.isLoading;
    final error = categoriesAsync.error ?? budgetsAsync.error;

    return Scaffold(
      backgroundColor: isDark
          ? DarkAppColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Budget'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Budgets'),
            Tab(text: 'Goals'),
          ],
          labelColor: isDark ? DarkAppColors.appBarForeground : null,
          unselectedLabelColor: isDark ? DarkAppColors.balanceCardMuted : null,
          indicatorColor: isDark ? DarkAppColors.homeAccentGreen : null,
        ),
        backgroundColor: isDark
            ? DarkAppColors.homeCardBackground
            : Colors.white,
        foregroundColor: isDark
            ? DarkAppColors.appBarForeground
            : AppColors.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        key: _fabKey,
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_tabController.index == 0) {
              final categoryNames = categoriesAsync.hasValue
                  ? categoriesAsync.value!.map((c) => c.name).toList()
                  : ['General'];
              context.push('/create-budget', extra: categoryNames);
            } else {
              context.push('/create-goal');
            }
          },
          backgroundColor: isDark
              ? DarkAppColors.homeAccentGreen
              : const Color.fromARGB(255, 52, 125, 37),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(_tabController.index == 0 ? 'new budget' : 'new goal'),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: dims.all(24),
                child: Text('Failed to load data: $error'),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBudgetsTab(
                  categoriesAsync.value!,
                  budgetsAsync.value!,
                  isDark,
                  dims,
                ),
                const GoalsTab(),
              ],
            ),
    );
  }

  Widget _buildBudgetsTab(
    List<CategorySum> categories,
    List<BudgetConfigRow> savedBudgets,
    bool isDark,
    AppDimensions dims,
  ) {
    if (savedBudgets.isEmpty) {
      return TutorialWrapper(
        pageName: 'budgets',
        targets: budgetsTutorial(
          fabKey: _fabKey,
          cardKey: _cardKey,
          hasBudgets: savedBudgets.isNotEmpty,
          isDark: isDark,
          dims: dims,
        ),
        child: Center(
          child: categories.isEmpty
              ? _buildEmptyStateCard(isDark, dims)
              : _buildNoSavedBudgetsCard(isDark, dims),
        ),
      );
    }

    return TutorialWrapper(
      pageName: 'budgets',
      targets: budgetsTutorial(
        fabKey: _fabKey,
        cardKey: _cardKey,
        hasBudgets: savedBudgets.isNotEmpty,
        isDark: isDark,
        dims: dims,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: dims(14)),
            _buildSavedBudgetsSection(categories, savedBudgets, isDark, dims),
            SizedBox(height: dims(96)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(bool isDark, AppDimensions dims) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: dims.icon(52),
              color:
                  (isDark
                          ? DarkAppColors.balanceCardMuted
                          : AppColors.homeNavigationUnselected)
                      .withValues(alpha: 0.6),
            ),
            SizedBox(height: dims(12)),
            Text(
              'No spending data yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? DarkAppColors.appBarForeground : null,
              ),
            ),
            SizedBox(height: dims(6)),
            Text(
              'Import transactions and set category budgets to track spending.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? DarkAppColors.balanceCardMuted
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSavedBudgetsCard(bool isDark, AppDimensions dims) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: dims.icon(52),
              color:
                  (isDark
                          ? DarkAppColors.balanceCardMuted
                          : AppColors.homeNavigationUnselected)
                      .withValues(alpha: 0.6),
            ),
            SizedBox(height: dims(12)),
            Text(
              'No budgets yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? DarkAppColors.appBarForeground : null,
              ),
            ),
            SizedBox(height: dims(6)),
            Text(
              'Tap the button below to create your first budget.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? DarkAppColors.balanceCardMuted
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedBudgetsSection(
    List<CategorySum> categories,
    List<BudgetConfigRow> savedBudgets,
    bool isDark,
    AppDimensions dims,
  ) {
    final spentByCategory = <String, double>{
      for (final item in categories) item.name: item.total,
    };
    const periodOrder = [
      'Weekly',
      'Monthly',
      'Quarterly',
      'Yearly',
      'One time',
    ];
    final grouped = <String, List<BudgetConfigRow>>{
      for (final period in periodOrder) period: [],
    };
    for (final budget in savedBudgets) {
      grouped.putIfAbsent(budget.period, () => []).add(budget);
    }

    return Column(
      children: periodOrder
          .where((period) => grouped[period]?.isNotEmpty ?? false)
          .map(
            (period) => _buildPeriodBudgetsGroup(
              periodLabel: _periodTitle(period),
              budgets: grouped[period]!,
              spentByCategory: spentByCategory,
              isDark: isDark,
              dims: dims,
            ),
          )
          .toList(),
    );
  }

  String _periodTitle(String period) {
    switch (period) {
      case 'Weekly':
        return 'This week';
      case 'Monthly':
        return 'This month';
      case 'Quarterly':
        return 'This quarter';
      case 'Yearly':
        return 'This year';
      case 'One time':
        return 'One time';
      default:
        return period;
    }
  }

  Widget _buildPeriodBudgetsGroup({
    required String periodLabel,
    required List<BudgetConfigRow> budgets,
    required Map<String, double> spentByCategory,
    required bool isDark,
    required AppDimensions dims,
  }) {
    return Container(
      width: double.infinity,
      margin: dims.symmetric(h: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: dims.only(l: 2, b: 8),
            child: Text(
              periodLabel,
              style: TextStyle(
                fontSize: 28 / 1.4,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? DarkAppColors.appBarForeground
                    : const Color(0xFF111827),
              ),
            ),
          ),
          ...budgets.asMap().entries.map(
            (entry) => _buildSavedBudgetCard(
              budget: entry.value,
              spentByCategory: spentByCategory,
              isDark: isDark,
              dims: dims,
              cardKey: entry.key == 0 ? _cardKey : null,
            ),
          ),
          SizedBox(height: dims(10)),
        ],
      ),
    );
  }

  Widget _buildSavedBudgetCard({
    required BudgetConfigRow budget,
    required Map<String, double> spentByCategory,
    required bool isDark,
    required AppDimensions dims,
    Key? cardKey,
  }) {
    final spent = budget.categories.isEmpty
        ? spentByCategory.values.fold<double>(0, (sum, v) => sum + v)
        : budget.categories.fold<double>(
            0,
            (sum, category) => sum + (spentByCategory[category] ?? 0),
          );
    final usage = budget.amount > 0 ? spent / budget.amount : 0.0;
    final clamped = usage.clamp(0.0, 1.0);
    final isOverrun = usage > 1;
    final isOverrunRisk = !isOverrun && usage >= 0.8;
    final statusLabel = isOverrun
        ? 'LIMIT OVERRUN'
        : isOverrunRisk
        ? 'OVERRUN RISK'
        : 'IN LIMIT';
    final progressColor = isOverrun
        ? const Color(0xFFB85C5C)
        : isOverrunRisk
        ? const Color(0xFFC4975A)
        : (isDark ? DarkAppColors.homeAccentGreen : AppColors.homeAccentGreen);
    final statusColor = isOverrun
        ? const Color(0xFF8B3A3A)
        : isOverrunRisk
        ? const Color(0xFF8B6F3A)
        : (isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF4B5563));
    final textPrimary = isDark ? DarkAppColors.appBarForeground : null;
    final textSecondary = isDark
        ? DarkAppColors.balanceCardMuted
        : const Color(0xFF6B7280);
    final progressBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE5E7EB);

    return Container(
      key: cardKey,
      margin: dims.only(b: 10),
      child: Material(
        color: isDark
            ? DarkAppColors.homeCardBackground
            : AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(12),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.pushNamed(
            'budget-detail',
            pathParameters: {'id': budget.id.toString()},
          ),
          child: Padding(
            padding: dims.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        budget.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _getCurrencyFormat().format(budget.amount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(width: dims(6)),
                    Icon(
                      Icons.chevron_right,
                      size: dims.icon(20),
                      color: isDark
                          ? DarkAppColors.balanceCardMuted
                          : const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
                SizedBox(height: dims(10)),
                Text(
                  '${(usage * 100).toStringAsFixed(0)}% used',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                SizedBox(height: dims(6)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: clamped,
                    minHeight: 8,
                    backgroundColor: progressBg,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                SizedBox(height: dims(10)),
                Text(
                  budget.amount > 0
                      ? '${statusLabel.toLowerCase()} • Spent ${_getCurrencyFormat().format(spent)} • ${isOverrun ? 'Over by' : 'Remaining'} ${_getCurrencyFormat().format(isOverrun ? spent - budget.amount : budget.amount - spent)}'
                      : '${statusLabel.toLowerCase()} • Spent ${_getCurrencyFormat().format(spent)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
