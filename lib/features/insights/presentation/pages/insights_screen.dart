import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:rxdart/rxdart.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_enums.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_data.dart';
import 'package:faranka/features/home/presentation/widgets/home_types.dart';
import 'package:faranka/features/insights/presentation/widgets/weekly_insights_card_wrapper.dart';
import 'package:faranka/features/insights/presentation/widgets/calendar_heatmap_card.dart';
import 'package:faranka/features/insights/presentation/widgets/radar_comparison_card.dart';
import 'package:faranka/features/insights/presentation/widgets/anomalies_card.dart';
import 'package:faranka/features/insights/presentation/widgets/balance_trend_card.dart';
import 'package:faranka/features/insights/presentation/widgets/counterparty_leaders_card.dart';
import 'package:faranka/features/insights/presentation/widgets/month_navigator.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late DateTime _selectedDate = DateTime.now();
  PeriodOption _counterpartyPeriod = PeriodOption.followGlobal;
  CalendarMetric _calendarMetric = CalendarMetric.spending;
  String _bankFilter = 'All Banks';
  BalanceTrendPeriod _balanceTrendPeriod = BalanceTrendPeriod.thirtyDays;
  BankBalanceFilter _balanceTrendBankFilter = BankBalanceFilter.all;

  final _refreshController = BehaviorSubject<void>.seeded(null);
  Stream<Map<DateTime, double>>? _dailyAmountsStream;
  Stream<Set<DateTime>>? _activityDatesStream;

  Stream<Map<DateTime, double>> _getDailyAmounts() {
    _dailyAmountsStream ??= _refreshController.stream.switchMap((_) {
      return ref
          .read(databaseProvider)
          .select(ref.read(databaseProvider).transactions)
          .watch()
          .map((rows) {
            final direction = _calendarMetric == CalendarMetric.spending
                ? TransactionDirection.debit
                : TransactionDirection.credit;
            final bankFilter = _bankFilter;
            final startDate = _monthStart(_selectedDate);
            final endDate = _monthEnd(
              _selectedDate,
            ).add(const Duration(days: 1));
            final dailyMap = <DateTime, double>{};

            for (final row in rows) {
              if (row.direction != direction) continue;
              if (bankFilter != 'All Banks') {
                final bn = row.bankName?.toLowerCase() ?? '';
                if (!bn.contains(bankFilter.toLowerCase())) continue;
              }

              final timestamp = DateTime.fromMillisecondsSinceEpoch(
                row.smsTimestamp,
              );
              if (timestamp.isBefore(startDate) ||
                  !timestamp.isBefore(endDate)) {
                continue;
              }

              final dayKey = DateTime(
                timestamp.year,
                timestamp.month,
                timestamp.day,
              );
              dailyMap[dayKey] = (dailyMap[dayKey] ?? 0) + row.amount;
            }

            return dailyMap;
          });
    });
    return _dailyAmountsStream!;
  }

  Stream<Set<DateTime>> _getDailyActivityDates() {
    _activityDatesStream ??= _refreshController.stream.switchMap((_) {
      return ref
          .read(databaseProvider)
          .select(ref.read(databaseProvider).transactions)
          .watch()
          .map((rows) {
            final bankFilter = _bankFilter;
            final startDate = _monthStart(_selectedDate);
            final endDate = _monthEnd(
              _selectedDate,
            ).add(const Duration(days: 1));
            final activityDates = <DateTime>{};

            for (final row in rows) {
              if (bankFilter != 'All Banks') {
                final bn = row.bankName?.toLowerCase() ?? '';
                if (!bn.contains(bankFilter.toLowerCase())) continue;
              }
              final timestamp = DateTime.fromMillisecondsSinceEpoch(
                row.smsTimestamp,
              );
              if (timestamp.isBefore(startDate) ||
                  !timestamp.isBefore(endDate)) {
                continue;
              }

              activityDates.add(
                DateTime(timestamp.year, timestamp.month, timestamp.day),
              );
            }

            return activityDates;
          });
    });
    return _activityDatesStream!;
  }

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _monthEnd(DateTime date) => DateTime(date.year, date.month + 1, 0);

  DateTime _clampSelectedMonth(
    DateTime date,
    DateTime minDate,
    DateTime maxDate,
  ) {
    final target = _monthStart(date);
    final minMonth = _monthStart(minDate);
    final maxMonth = _monthStart(maxDate);

    if (target.isBefore(minMonth)) return minMonth;
    if (target.isAfter(maxMonth)) return maxMonth;
    return target;
  }

  Stream<DateTimeRange?> _watchTransactionDateRange() {
    return ref.read(databaseProvider).watchTransactionDateRange().map((range) {
      if (range == null) return null;
      return DateTimeRange(start: range.start, end: range.end);
    });
  }

  void _addToCategoryTotals(
    Map<String, double> totals,
    TransactionData row,
    List<TransactionSplit>? splits,
  ) {
    if (splits != null && splits.isNotEmpty) {
      double splitSum = 0;
      for (final s in splits) {
        totals[s.category] = (totals[s.category] ?? 0) + s.amount;
        splitSum += s.amount;
      }
      final remainder = row.amount - splitSum;
      if (remainder > 0.009) {
        final cat = row.parsedCategory.trim().isEmpty
            ? 'Uncategorized'
            : row.parsedCategory;
        totals[cat] = (totals[cat] ?? 0) + remainder;
      }
    } else {
      final category = row.parsedCategory.trim().isEmpty
          ? 'Uncategorized'
          : row.parsedCategory;
      totals[category] = (totals[category] ?? 0) + row.amount;
    }
  }

  Stream<List<double>> _getBalanceHistory() {
    final db = ref.read(databaseProvider);
    return db.watchBalanceHistoryForDays(
      _balanceTrendPeriod.days,
      bankFilter: _balanceTrendBankFilter.dbFilter,
    );
  }

  Stream<CategoryRadarComparison?> _getCategoryRadarComparison() {
    final currentStart = _monthStart(_selectedDate);
    final currentEnd = _monthEnd(_selectedDate).add(const Duration(days: 1));
    final previousMonthDate = DateTime(
      _selectedDate.year,
      _selectedDate.month - 1,
      1,
    );
    final previousStart = _monthStart(previousMonthDate);
    final previousEnd = _monthEnd(
      previousMonthDate,
    ).add(const Duration(days: 1));

    final db = ref.read(databaseProvider);
    final base = db.select(db.transactions).watch();
    final splitsChanged = db
        .tableUpdates(TableUpdateQuery.onTableName('transaction_splits'))
        .asyncMap((_) => db.select(db.transactions).get());

    return Rx.merge([base, splitsChanged]).asyncMap((rows) async {
      final ids = rows.map((r) => r.id).toList();
      final splitMap = await db.getSplitsByTransactionIds(ids);
      final currentTotals = <String, double>{};
      final previousTotals = <String, double>{};

      for (final row in rows) {
        if (row.direction != TransactionDirection.debit) continue;

        final timestamp = DateTime.fromMillisecondsSinceEpoch(row.smsTimestamp);
        final dayStart = DateTime(
          timestamp.year,
          timestamp.month,
          timestamp.day,
        );

        if (!dayStart.isBefore(currentStart) && dayStart.isBefore(currentEnd)) {
          _addToCategoryTotals(currentTotals, row, splitMap[row.id]);
        } else if (!dayStart.isBefore(previousStart) &&
            dayStart.isBefore(previousEnd)) {
          _addToCategoryTotals(previousTotals, row, splitMap[row.id]);
        }
      }

      final categoryNames =
          <String>{...currentTotals.keys, ...previousTotals.keys}.toList()
            ..sort((a, b) {
              final aTotal = (currentTotals[a] ?? 0) + (previousTotals[a] ?? 0);
              final bTotal = (currentTotals[b] ?? 0) + (previousTotals[b] ?? 0);
              return bTotal.compareTo(aTotal);
            });

      if (categoryNames.isEmpty) {
        return null;
      }

      final topCategories = categoryNames.take(6).toList();

      final calMode = ref.read(calendarModeProvider);
      return CategoryRadarComparison(
        currentMonthLabel: _selectedDate.fmt('MMM yyyy', calMode),
        previousMonthLabel: previousMonthDate.fmt('MMM yyyy', calMode),
        labels: topCategories,
        currentValues: topCategories
            .map((name) => currentTotals[name] ?? 0)
            .toList(),
        previousValues: topCategories
            .map((name) => previousTotals[name] ?? 0)
            .toList(),
      );
    });
  }

  Stream<List<SpendingAnomaly>> _getAnomalies() {
    final currentMonthStart = _monthStart(_selectedDate);
    final twoMonthsBack = DateTime(
      _selectedDate.year,
      _selectedDate.month - 2,
      1,
    );

    final db = ref.read(databaseProvider);
    final base = db.select(db.transactions).watch();
    final splitsChanged = db
        .tableUpdates(TableUpdateQuery.onTableName('transaction_splits'))
        .asyncMap((_) => db.select(db.transactions).get());

    return Rx.merge([base, splitsChanged]).asyncMap((rows) async {
      final ids = rows.map((r) => r.id).toList();
      final splitMap = await db.getSplitsByTransactionIds(ids);
      final categoryTotals = <String, Map<DateTime, double>>{};

      for (final row in rows) {
        if (row.direction != TransactionDirection.debit) continue;

        final timestamp = DateTime.fromMillisecondsSinceEpoch(row.smsTimestamp);
        final monthKey = DateTime(timestamp.year, timestamp.month, 1);

        if (monthKey.isBefore(twoMonthsBack)) continue;

        final txnSplits = splitMap[row.id];
        if (txnSplits != null && txnSplits.isNotEmpty) {
          double splitSum = 0;
          for (final split in txnSplits) {
            categoryTotals.putIfAbsent(split.category, () => {});
            categoryTotals[split.category]![monthKey] =
                (categoryTotals[split.category]![monthKey] ?? 0) + split.amount;
            splitSum += split.amount;
          }
          final remainder = row.amount - splitSum;
          if (remainder > 0.009) {
            final cat = row.parsedCategory.trim().isEmpty
                ? 'Uncategorized'
                : row.parsedCategory;
            categoryTotals.putIfAbsent(cat, () => {});
            categoryTotals[cat]![monthKey] =
                (categoryTotals[cat]![monthKey] ?? 0) + remainder;
          }
        } else {
          final category = row.parsedCategory.trim().isEmpty
              ? 'Uncategorized'
              : row.parsedCategory;
          categoryTotals.putIfAbsent(category, () => {});
          categoryTotals[category]![monthKey] =
              (categoryTotals[category]![monthKey] ?? 0) + row.amount;
        }
      }

      final anomalies = <SpendingAnomaly>[];

      for (final category in categoryTotals.keys) {
        final monthlyTotals = categoryTotals[category]!;
        final currentTotal = monthlyTotals[currentMonthStart] ?? 0.0;
        if (currentTotal == 0) continue;

        final priorMonths = <double>[];
        var cursor = twoMonthsBack;
        while (!cursor.isAfter(
          DateTime(currentMonthStart.year, currentMonthStart.month - 1, 1),
        )) {
          priorMonths.add(monthlyTotals[cursor] ?? 0.0);
          cursor = DateTime(cursor.year, cursor.month + 1, 1);
        }

        if (priorMonths.isEmpty) continue;

        final historicalAverage =
            priorMonths.fold<double>(0, (sum, val) => sum + val) /
            priorMonths.length;

        if (historicalAverage <= 0) continue;

        final ratio = currentTotal / historicalAverage;

        if (ratio > 1.5 || ratio < 0.67) {
          anomalies.add(
            SpendingAnomaly(
              category: category,
              currentTotal: currentTotal,
              historicalAverage: historicalAverage,
              ratio: ratio,
            ),
          );
        }
      }

      anomalies.sort((a, b) {
        final aDiff = (a.ratio - 1.0).abs();
        final bDiff = (b.ratio - 1.0).abs();
        return bDiff.compareTo(aDiff);
      });

      return anomalies.take(3).toList();
    });
  }

  String _resolveCounterpartyLabel(TransactionData row) {
    final counterparty = row.counterpartyName?.trim();
    if (counterparty != null && counterparty.isNotEmpty) {
      return counterparty;
    }

    final number = row.counterpartyNumber?.trim();
    if (number != null && number.isNotEmpty) {
      return number;
    }

    final bank = row.bankName?.trim();
    if (bank != null && bank.isNotEmpty) {
      return bank;
    }

    return 'Unknown';
  }

  Stream<CounterpartyInsightsSnapshot> _getCounterpartyInsights({
    PeriodOption? period,
  }) {
    DateTime startDate;
    DateTime endDate;

    if (period == null || period == PeriodOption.followGlobal) {
      startDate = _monthStart(_selectedDate);
      endDate = _monthEnd(_selectedDate).add(const Duration(days: 1));
    } else if (period == PeriodOption.month) {
      startDate = _monthStart(_selectedDate);
      endDate = _monthEnd(_selectedDate).add(const Duration(days: 1));
    } else if (period == PeriodOption.threeMonths) {
      final startMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month - 2,
        1,
      );
      startDate = _monthStart(startMonth);
      endDate = _monthEnd(_selectedDate).add(const Duration(days: 1));
    } else if (period == PeriodOption.year) {
      startDate = DateTime(_selectedDate.year, 1, 1);
      endDate = DateTime(
        _selectedDate.year,
        12,
        31,
      ).add(const Duration(days: 1));
    } else {
      // all
      startDate = DateTime.fromMillisecondsSinceEpoch(0);
      endDate = DateTime.now().add(const Duration(days: 1));
    }

    return ref
        .read(databaseProvider)
        .select(ref.read(databaseProvider).transactions)
        .watch()
        .map((rows) {
          final sentTotals = <String, double>{};
          final sentCounts = <String, int>{};
          final receivedTotals = <String, double>{};
          final receivedCounts = <String, int>{};

          for (final row in rows) {
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
              row.smsTimestamp,
            );
            if (timestamp.isBefore(startDate) || !timestamp.isBefore(endDate)) {
              continue;
            }

            final counterparty = _resolveCounterpartyLabel(row);
            if (row.direction == TransactionDirection.debit) {
              sentTotals[counterparty] =
                  (sentTotals[counterparty] ?? 0) + row.amount;
              sentCounts[counterparty] = (sentCounts[counterparty] ?? 0) + 1;
            } else if (row.direction == TransactionDirection.credit) {
              receivedTotals[counterparty] =
                  (receivedTotals[counterparty] ?? 0) + row.amount;
              receivedCounts[counterparty] =
                  (receivedCounts[counterparty] ?? 0) + 1;
            }
          }

          List<CounterpartyInsightItem> buildTopItems(
            Map<String, double> totals,
            Map<String, int> counts,
          ) {
            final entries = totals.entries.toList()
              ..sort((a, b) {
                final amountComparison = b.value.compareTo(a.value);
                if (amountComparison != 0) return amountComparison;
                return (counts[b.key] ?? 0).compareTo(counts[a.key] ?? 0);
              });

            return entries
                .take(5)
                .map(
                  (entry) => CounterpartyInsightItem(
                    label: entry.key,
                    amount: entry.value,
                    count: counts[entry.key] ?? 0,
                  ),
                )
                .toList();
          }

          final calMode = ref.read(calendarModeProvider);
          return CounterpartyInsightsSnapshot(
            monthLabel: _selectedDate.fmt('MMM yyyy', calMode),
            topSentTo: buildTopItems(sentTotals, sentCounts),
            topReceivedFrom: buildTopItems(receivedTotals, receivedCounts),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    return Scaffold(
      backgroundColor: isDark
          ? DarkAppColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? DarkAppColors.homeCardBackground
            : Colors.white,
        foregroundColor: isDark
            ? DarkAppColors.appBarForeground
            : AppColors.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text('Insights'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: dims.fromLTRB(14, 14, 14, 12),
            child: StreamBuilder<DateTimeRange?>(
              stream: _watchTransactionDateRange(),
              builder: (context, snapshot) {
                final range = snapshot.data;
                final now = DateTime.now();
                final maxDate = range == null ? now : range.end;
                final minDate = range?.start;

                final effectiveSelected = minDate == null
                    ? _monthStart(_selectedDate)
                    : _clampSelectedMonth(_selectedDate, minDate, maxDate);

                if (minDate != null && effectiveSelected != _selectedDate) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _selectedDate = effectiveSelected;
                      _refreshController.add(null);
                    });
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WeeklyInsightsCardWrapper(),
                    SizedBox(height: dims(12)),
                    CalendarHeatmapCard(
                      metric: _calendarMetric,
                      selectedDate: _selectedDate,
                      activityDatesStream: _getDailyActivityDates(),
                      dailyAmountsStream: _getDailyAmounts(),
                      onMetricChanged: (m) => setState(() {
                        _calendarMetric = m;
                        _refreshController.add(null);
                      }),
                      onDateTap: (date) =>
                          _openTransactionsForDate(context, date),
                      bankFilter: _bankFilter,
                      onBankFilterChanged: (b) => setState(() {
                        _bankFilter = b;
                        _refreshController.add(null);
                      }),
                    ),
                    SizedBox(height: dims(12)),
                    Column(
                      children: [
                        RadarComparisonCard(
                          stream: _getCategoryRadarComparison(),
                        ),
                        SizedBox(height: dims(12)),
                        CounterpartyLeadersCard(
                          stream: _getCounterpartyInsights(
                            period: _counterpartyPeriod,
                          ),
                          period: _counterpartyPeriod,
                          selectedDate: _selectedDate,
                          onPeriodChanged: (v) =>
                              setState(() => _counterpartyPeriod = v),
                        ),
                        SizedBox(height: dims(12)),
                        AnomaliesCard(
                          stream: _getAnomalies(),
                          monthLabel: _selectedDate.fmt('MMM yyyy', calMode),
                        ),
                        SizedBox(height: dims(12)),
                        BalanceTrendCard(
                          period: _balanceTrendPeriod,
                          stream: _getBalanceHistory(),
                          bankFilter: _balanceTrendBankFilter,
                          onPeriodChanged: (v) => setState(() {
                            _balanceTrendPeriod = v;
                            _refreshController.add(null);
                          }),
                          onBankFilterChanged: (b) => setState(() {
                            _balanceTrendBankFilter = b;
                            _refreshController.add(null);
                          }),
                        ),
                        SizedBox(height: dims(64)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: dims.symmetric(h: 12, v: 8),
              decoration: BoxDecoration(
                color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? DarkAppColors.homeCardShadowStyle
                    : AppColors.homeCardShadowStyle,
              ),
              child: StreamBuilder<DateTimeRange?>(
                stream: _watchTransactionDateRange(),
                builder: (context, snapshot) {
                  final range = snapshot.data;
                  final now = DateTime.now();
                  final maxDate = range == null ? now : range.end;
                  final minDate = range?.start;

                  final effectiveSelected = minDate == null
                      ? _monthStart(_selectedDate)
                      : _clampSelectedMonth(_selectedDate, minDate, maxDate);

                  final canGoPrevious =
                      minDate != null &&
                      _monthStart(
                        effectiveSelected,
                      ).isAfter(_monthStart(minDate));
                  final canGoNext = _monthStart(
                    effectiveSelected,
                  ).isBefore(_monthStart(maxDate));

                  return MonthNavigator(
                    selectedDate: effectiveSelected,
                    canGoPrevious: canGoPrevious,
                    canGoNext: canGoNext,
                    onPrevious: () => setState(() {
                      _selectedDate = DateTime(
                        effectiveSelected.year,
                        effectiveSelected.month - 1,
                      );
                      _refreshController.add(null);
                    }),
                    onNext: () => setState(() {
                      _selectedDate = DateTime(
                        effectiveSelected.year,
                        effectiveSelected.month + 1,
                      );
                      _refreshController.add(null);
                    }),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  void _openTransactionsForDate(BuildContext context, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    context.push(
      '/transactions?source=insights&start=${Uri.encodeComponent(dayStart.toIso8601String())}&end=${Uri.encodeComponent(dayEnd.toIso8601String())}',
    );
  }
}
