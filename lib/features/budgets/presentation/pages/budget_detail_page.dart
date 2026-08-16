import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/features/budgets/models/budget_models.dart';
import 'package:faranka/features/budgets/presentation/widgets/budget_widgets.dart';
import 'package:faranka/features/budgets/presentation/widgets/budget_edit_sheet.dart';

class BudgetDetailPage extends ConsumerStatefulWidget {
  const BudgetDetailPage({super.key, required this.budgetId});

  final int budgetId;

  @override
  ConsumerState<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends ConsumerState<BudgetDetailPage> {
  static const List<String> _timelineRanges = [
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
    'All time',
  ];
  String _timelineRange = 'Monthly';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant BudgetDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  int _daysForPeriod(BudgetConfigRow budget) {
    if (budget.startAt > 0 && budget.endAt > 0) {
      final start = DateTime.fromMillisecondsSinceEpoch(budget.startAt);
      final end = DateTime.fromMillisecondsSinceEpoch(budget.endAt);
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);
      return math.max(1, endDay.difference(startDay).inDays + 1);
    }

    switch (budget.period) {
      case 'Weekly':
        return 7;
      case 'Quarterly':
        return 90;
      case 'Yearly':
        return 365;
      case 'Monthly':
      default:
        return 30;
    }
  }

  String _formatDate(DateTime date, CalendarMode mode) {
    return date.fmt('MMM d, yyyy', mode);
  }

  String _dateRangeLabel(BudgetConfigRow budget, CalendarMode mode) {
    if (budget.startAt <= 0 || budget.endAt <= 0) return 'Not set';
    final start = DateTime.fromMillisecondsSinceEpoch(budget.startAt);
    final end = DateTime.fromMillisecondsSinceEpoch(budget.endAt);
    return '${_formatDate(start, mode)} - ${_formatDate(end, mode)}';
  }

  int _customDaysLeft(BudgetConfigRow budget, DateTime now) {
    if (budget.endAt <= 0) return 1;
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime.fromMillisecondsSinceEpoch(budget.endAt);
    final endDay = DateTime(end.year, end.month, end.day);
    return math.max(1, endDay.difference(today).inDays + 1);
  }

  int _customElapsedDays(BudgetConfigRow budget, DateTime now) {
    if (budget.startAt <= 0) return 1;
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime.fromMillisecondsSinceEpoch(budget.startAt);
    final startDay = DateTime(start.year, start.month, start.day);
    return math.max(1, today.difference(startDay).inDays + 1);
  }

  bool _matchesAccount(BudgetConfigRow budget, TransactionData txn) {
    if (budget.account == 'All Accounts') return true;
    final bank = (txn.bankName ?? '').toLowerCase();
    final selected = budget.account.toLowerCase();
    return bank.contains(selected);
  }

  int _timelineDaysForRange(String range) {
    switch (range) {
      case 'Weekly':
        return 7;
      case 'Quarterly':
        return 90;
      case 'Yearly':
        return 365;
      case 'Monthly':
      default:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final db = ref.watch(databaseProvider);
    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Budget details'),
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        foregroundColor: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: StreamBuilder<List<BudgetConfigRow>>(
        stream: db.watchBudgetConfigs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: dims.all(24),
                child: Text('Error loading budget: ${snapshot.error}'),
              ),
            );
          }
          final budgets = snapshot.data ?? const <BudgetConfigRow>[];
          final budget = budgets.cast<BudgetConfigRow?>().firstWhere(
            (item) => item?.id == widget.budgetId,
            orElse: () => null,
          );
          if (budget == null) {
            return Center(
              child: Text(
                'Budget not found',
                style: TextStyle(
                  color: isDark ? DarkAppColors.appBarForeground : null,
                ),
              ),
            );
          }

          return StreamBuilder<TxnBundle>(
            stream: db.select(db.transactions).watch().asyncMap((txns) async {
              final ids = txns.map((t) => t.id).toList();
              final splits = await db.getSplitsByTransactionIds(ids);
              return TxnBundle(txns: txns, splits: splits);
            }),
            builder: (context, txnSnapshot) {
              if (txnSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (txnSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: dims.all(24),
                    child: const Text('Error loading transactions'),
                  ),
                );
              }
              final bundle = txnSnapshot.data;
              final allTxns = bundle?.txns ?? const <TransactionData>[];
              final splitMap = bundle?.splits ?? const {};
              final now = DateTime.now();
              final days = _daysForPeriod(budget);
              final periodStart = budget.startAt > 0
                  ? DateTime.fromMillisecondsSinceEpoch(budget.startAt)
                  : DateTime(
                      now.year,
                      now.month,
                      now.day,
                    ).subtract(Duration(days: days - 1));
              final prevStart = periodStart.subtract(Duration(days: days));
              final currentStartMs = periodStart.millisecondsSinceEpoch;
              final prevStartMs = prevStart.millisecondsSinceEpoch;

              final filteredDebits = allTxns.where((txn) {
                if (txn.direction != TransactionDirection.debit) return false;
                if (!_matchesAccount(budget, txn)) return false;
                if (budget.categories.isNotEmpty &&
                    !budget.categories.contains(txn.parsedCategory) &&
                    !(splitMap[txn.id]
                        ?.any((s) => budget.categories.contains(s.category)) ??
                        false)) {
                  return false;
                }
                return true;
              }).toList();

              final currentTxns = filteredDebits
                  .where((txn) => txn.smsTimestamp >= currentStartMs)
                  .toList();
              final previousTxns = filteredDebits
                  .where(
                    (txn) =>
                        txn.smsTimestamp >= prevStartMs &&
                        txn.smsTimestamp < currentStartMs,
                  )
                  .toList();

              final spent = currentTxns.fold<double>(
                0,
                (sum, txn) => sum + txn.amount,
              );
              final previousSpent = previousTxns.fold<double>(
                0,
                (sum, txn) => sum + txn.amount,
              );
              final remaining = budget.amount - spent;
              final useCompact = AppSettingsService.getBoolSync(
                AppSettingsService.keyCompactNumbers,
                fallback: true,
              );
              final currency = useCompact
                  ? NumberFormat.compactCurrency(symbol: 'ETB ')
                  : NumberFormat.currency(symbol: 'ETB ');

              final elapsedDays = math.max(
                1,
                budget.startAt > 0
                    ? _customElapsedDays(budget, now)
                    : DateTime(
                            now.year,
                            now.month,
                            now.day,
                          ).difference(periodStart).inDays +
                          1,
              );
              final daysLeft = budget.endAt > 0
                  ? _customDaysLeft(budget, now)
                  : math.max(1, days - elapsedDays);
              final usage = budget.amount > 0 ? spent / budget.amount : 0.0;
              final clamped = usage.clamp(0.0, 1.0);
              final isOverrun = usage > 1;
              final isOverrunRisk = !isOverrun && usage >= 0.8;
              final progressColor = isOverrun
                  ? const Color(0xFFB85C5C)
                  : isOverrunRisk
                  ? const Color(0xFFC4975A)
                  : AppColors.homeNavigationSelected;
              final progressBg = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB);

              final nowDay = DateTime(now.year, now.month, now.day);
              final timelineBuckets = <double>[];
              String timelineCaption;

              if (_timelineRange == 'All time') {
                if (filteredDebits.isEmpty) {
                  timelineCaption = 'No historical spending data yet';
                } else {
                  filteredDebits.sort(
                    (a, b) => a.smsTimestamp.compareTo(b.smsTimestamp),
                  );
                  final first = DateTime.fromMillisecondsSinceEpoch(
                    filteredDebits.first.smsTimestamp,
                  );
                  final firstMonth = DateTime(first.year, first.month);
                  final currentMonth = DateTime(now.year, now.month);
                  final totalMonths =
                      (currentMonth.year - firstMonth.year) * 12 +
                      (currentMonth.month - firstMonth.month) +
                      1;

                  final windowMonths = math.min(totalMonths, 120);
                  final windowStart = DateTime(
                    currentMonth.year,
                    currentMonth.month - (windowMonths - 1),
                  );

                  timelineBuckets.addAll(
                    List<double>.filled(windowMonths, 0.0),
                  );

                  for (final txn in filteredDebits) {
                    final tx = DateTime.fromMillisecondsSinceEpoch(
                      txn.smsTimestamp,
                    );
                    final txMonth = DateTime(tx.year, tx.month);
                    final idx =
                        (txMonth.year - windowStart.year) * 12 +
                        (txMonth.month - windowStart.month);
                    if (idx >= 0 && idx < windowMonths) {
                      timelineBuckets[idx] += txn.amount;
                    }
                  }
                  timelineCaption =
                      'Monthly spend over ${windowMonths > 12 ? 'the last ${windowMonths ~/ 12} years' : 'the last $windowMonths months'}';
                }
              } else if (_timelineRange == 'Yearly') {
                final windowMonths = 12;
                final currentMonth = DateTime(now.year, now.month);
                final windowStart = DateTime(
                  currentMonth.year,
                  currentMonth.month - (windowMonths - 1),
                );

                timelineBuckets.addAll(List<double>.filled(windowMonths, 0.0));

                for (final txn in filteredDebits) {
                  final tx = DateTime.fromMillisecondsSinceEpoch(
                    txn.smsTimestamp,
                  );
                  final txMonth = DateTime(tx.year, tx.month);
                  final idx =
                      (txMonth.year - windowStart.year) * 12 +
                      (txMonth.month - windowStart.month);
                  if (idx >= 0 && idx < windowMonths) {
                    timelineBuckets[idx] += txn.amount;
                  }
                }

                timelineCaption = 'Monthly spend over yearly window';
              } else {
                final timelineDays = _timelineDaysForRange(_timelineRange);
                final timelineStart = nowDay.subtract(
                  Duration(days: timelineDays - 1),
                );
                timelineBuckets.addAll(List<double>.filled(timelineDays, 0.0));
                for (final txn in filteredDebits) {
                  final txDate = DateTime.fromMillisecondsSinceEpoch(
                    txn.smsTimestamp,
                  );
                  final txDay = DateTime(txDate.year, txDate.month, txDate.day);
                  final idx = txDay.difference(timelineStart).inDays;
                  if (idx >= 0 && idx < timelineDays) {
                    timelineBuckets[idx] += txn.amount;
                  }
                }
                timelineCaption =
                    'Daily spend over ${_timelineRange.toLowerCase()} window';
              }

              final compareDelta = spent - previousSpent;
              final comparePct = previousSpent <= 0
                  ? null
                  : (compareDelta / previousSpent) * 100;

              return SingleChildScrollView(
                child: Padding(
                  padding: dims.fromLTRB(14, 12, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionCard(
                        title: 'Overview',
                        isDark: isDark,
                        child: Column(
                          children: [
                            InsightRow(
                              label: budget.name,
                              value: currency.format(budget.amount),
                              isDark: isDark,
                              valueStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? DarkAppColors.appBarForeground : null,
                              ),
                            ),
                            SizedBox(height: dims.spacingSm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: clamped,
                                minHeight: 8,
                                backgroundColor: progressBg,
                                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                              ),
                            ),
                            SizedBox(height: dims.spacingSm),
                            InsightRow(
                              label: 'Spent',
                              value: currency.format(spent),
                              isDark: isDark,
                            ),
                            SizedBox(height: dims(6)),
                            InsightRow(
                              label: 'Remaining',
                              value: currency.format(math.max(0, remaining)),
                              isDark: isDark,
                            ),
                            if (budget.startAt > 0 && budget.endAt > 0) ...[
                              SizedBox(height: dims(6)),
                              InsightRow(
                                label: 'Date range',
                                value: _dateRangeLabel(budget, calMode),
                                isDark: isDark,
                              ),
                            ] else ...[
                              SizedBox(height: dims(6)),
                              InsightRow(
                                label: 'Days left',
                                value: '$daysLeft days',
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: dims(6)),
                            PaceIndicator(
                              spent: spent,
                              elapsedDays: elapsedDays,
                              daysLeft: daysLeft,
                              budgetAmount: budget.amount,
                              remaining: math.max(0, remaining),
                              isDark: isDark,
                              currency: currency,
                            ),
                            const Divider(height: 24),
                            InsightRow(
                              label: 'vs previous period',
                              value: '${currency.format(previousSpent)}  ${compareDelta >= 0 ? '+' : ''}${currency.format(compareDelta)}${comparePct == null ? '' : ' (${comparePct.toStringAsFixed(1)}%)'}',
                              isDark: isDark,
                              valueStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: remaining < 0
                                    ? const Color(0xFFB85C5C)
                                    : isDark ? DarkAppColors.appBarForeground : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: dims(14)),
                      SectionCard(
                        title: 'Spending Timeline',
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _timelineRanges.map((range) {
                                return ChoiceChip(
                                  label: Text(
                                    range,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selected: _timelineRange == range,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 0,
                                  ),
                                  visualDensity: const VisualDensity(
                                    horizontal: -3,
                                    vertical: -3,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onSelected: (_) {
                                    setState(() => _timelineRange = range);
                                  },
                                );
                              }).toList(),
                            ),
                            SizedBox(height: dims(10)),
                            SizedBox(
                              height: 90,
                              child: SpendingTimeline(points: timelineBuckets, isDark: isDark),
                            ),
                            SizedBox(height: dims.spacingSm),
                            Text(
                              timelineCaption,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? DarkAppColors.balanceCardMuted : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: dims(14)),
                      SectionCard(
                        title: 'Categories',
                        isDark: isDark,
                        child: budget.categories.isEmpty
                            ? Padding(
                                padding: dims.symmetric(v: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.public,
                                      size: dims.icon(18),
                                      color: isDark
                                          ? DarkAppColors.balanceCardMuted
                                          : const Color(0xFF6B7280),
                                    ),
                                    SizedBox(width: dims.spacingSm),
                                    Text(
                                      'All Spending',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? DarkAppColors.appBarForeground
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                          children: budget.categories.map((category) {
                            final spentForCategory = currentTxns
                                .where((txn) => txn.parsedCategory == category)
                                .fold<double>(
                                  0,
                                  (sum, txn) => sum + txn.amount,
                                );
                            return Chip(
                              label: Text(
                                '$category · ${currency.format(spentForCategory)}',
                                style: TextStyle(
                                  color: isDark ? Colors.black : null,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor:
                                  AppColors.homeNavigationIndicator,
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: dims(14)),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _showEditBudgetDialog(context, budget, isDark),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit budget'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditBudgetDialog(
    BuildContext context,
    BudgetConfigRow budget,
    bool isDark,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditBudgetSheet(
        budget: budget,
        isDark: isDark,
      ),
    );

    if (saved != true || !context.mounted) return;

    setState(() {});
  }
}
