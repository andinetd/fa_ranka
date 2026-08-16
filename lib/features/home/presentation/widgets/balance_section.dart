import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/features/home/presentation/providers/balance_providers.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/sensitive_hide_provider.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/app/core/widgets/sensitive_text.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

import 'home_types.dart';

const double _balanceCornerRadius = 6.0;

class BalanceSummaryCard extends ConsumerStatefulWidget {
  const BalanceSummaryCard({
    super.key,
    required this.selectedBankFilter,
    required this.onBankFilterChanged,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final BankBalanceFilter selectedBankFilter;
  final ValueChanged<BankBalanceFilter> onBankFilterChanged;
  final FilterPeriod selectedPeriod;
  final ValueChanged<FilterPeriod> onPeriodChanged;

  @override
  ConsumerState<BalanceSummaryCard> createState() => _BalanceSummaryCardState();
}

class _BalanceSummaryCardState extends ConsumerState<BalanceSummaryCard> {
  List<BankBalanceFilter> _bankPages = [BankBalanceFilter.all];

  int _activePageIndex = 0;

  @override
  void initState() {
    super.initState();
    _activePageIndex = _indexForFilter(widget.selectedBankFilter);
  }

  @override
  void didUpdateWidget(covariant BalanceSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBankFilter == widget.selectedBankFilter) return;
    _activePageIndex = _indexForFilter(widget.selectedBankFilter);
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _bankPages.length) return;
    setState(() => _activePageIndex = index);
    widget.onBankFilterChanged(_bankPages[index]);
  }

  int _indexForFilter(BankBalanceFilter filter) {
    final i = _bankPages.indexOf(filter);
    return i >= 0 ? i : 0;
  }

  // Provide a small themed palette per-bank to subtly brand the balance card.
  Map<String, Color> _bankColors(BankBalanceFilter bank, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (bank) {
      case BankBalanceFilter.awash:
        if (isDark) {
          return {
            'bg': const Color(0xFF1E1510),
            'fg': const Color(0xFFCCD6E8),
            'muted': const Color(0xFF9CAAB8),
            'accent': const Color(0xFFF5A623),
            'grid': const Color(0x1ACCD6E8),
            'shadow': const Color(0x14000000),
          };
        }
        return {
          'bg': const Color(0xFFFFF4E6),
          'fg': const Color(0xFF1A2A44),
          'muted': const Color(0xFF6C7A89),
          'accent': const Color(0xFFF58220),
          'grid': const Color(0x1A1A2A44),
          'shadow': const Color(0x14000000),
        };

      case BankBalanceFilter.cbe:
        if (isDark) {
          return {
            'bg': const Color(0xFF0D1B2A),
            'fg': const Color(0xFF8AB4F8),
            'muted': const Color(0xFF9CAAB8),
            'accent': const Color.fromARGB(255, 200, 120, 240),
            'grid': const Color(0x1A8AB4F8),
            'shadow': const Color(0x14000000),
          };
        }
        return {
          'bg': const Color(0xFFF2F6FB),
          'fg': const Color(0xFF003A8F),
          'muted': const Color(0xFF6B7A99),
          'accent': const Color.fromARGB(255, 179, 40, 222),
          'grid': const Color(0x1A003A8F),
          'shadow': const Color(0x14000000),
        };
      case BankBalanceFilter.all:
        return {
          'bg': isDark ? DarkAppColors.balanceCardBackground : AppColors.balanceCardBackground,
          'fg': isDark ? DarkAppColors.balanceCardForeground : AppColors.balanceCardForeground,
          'muted': isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
          'accent': isDark ? DarkAppColors.balanceCardAccent : AppColors.balanceCardAccent,
          'grid': isDark ? DarkAppColors.balanceCardGrid : AppColors.balanceCardGrid,
          'shadow': isDark ? DarkAppColors.balanceCardShadow : AppColors.balanceCardShadow,
        };
      case BankBalanceFilter.boa:
        if (isDark) {
          return {
            'bg': const Color(0xFF10151D),
            'fg': const Color(0xFF9FC6FF),
            'muted': const Color(0xFF9CAAB8),
            'accent': const Color(0xFF2E7CF6),
            'grid': const Color(0x1A9FC6FF),
            'shadow': const Color(0x14000000),
          };
        }
        return {
          'bg': const Color(0xFFEAF1FB),
          'fg': const Color(0xFF0455A6),
          'muted': const Color(0xFF5F6B85),
          'accent': const Color(0xFF2E7CF6),
          'grid': const Color(0x1A0455A6),
          'shadow': const Color(0x14000000),
        };
      case BankBalanceFilter.telebirr:
        if (isDark) {
          return {
            'bg': const Color(0xFF150F24),
            'fg': const Color(0xFFD5C8F5),
            'muted': const Color(0xFF9CAAB8),
            'accent': const Color(0xFF8C4FF5),
            'grid': const Color(0x1AD5C8F5),
            'shadow': const Color(0x14000000),
          };
        }
        return {
          'bg': const Color(0xFFF3EDFC),
          'fg': const Color(0xFF4A148C),
          'muted': const Color(0xFF7A678F),
          'accent': const Color(0xFF8C4FF5),
          'grid': const Color(0x1A4A148C),
          'shadow': const Color(0x14000000),
        };
    }
  }

  String _balanceTitle(BankBalanceFilter bank) {
    switch (bank) {
      case BankBalanceFilter.all:
        return 'Total balance';
      case BankBalanceFilter.awash:
        return 'Awash balance';
      case BankBalanceFilter.cbe:
        return 'CBE balance';
      case BankBalanceFilter.boa:
        return 'BoA balance';
      case BankBalanceFilter.telebirr:
        return 'Telebirr balance';
    }
  }

  String _periodDropdownLabel(FilterPeriod period) {
    switch (period) {
      case FilterPeriod.weekly:
        return 'This week';
      case FilterPeriod.monthly:
        return 'This month';
      case FilterPeriod.quarterly:
        return 'Last 3 months';
      case FilterPeriod.yearly:
        return 'This year';
    }
  }

  int _daysForPeriod(FilterPeriod period) {
    switch (period) {
      case FilterPeriod.weekly:
        return 7;
      case FilterPeriod.monthly:
        return 30;
      case FilterPeriod.quarterly:
        return 90;
      case FilterPeriod.yearly:
        return 365;
    }
  }

  String _compactEtb(double value) {
    final useCompact = AppSettingsService.getBoolSync(
      AppSettingsService.keyCompactNumbers,
      fallback: true,
    );
    if (!useCompact) {
      return NumberFormat('#,###.##').format(value);
    }
    return NumberFormat.compact().format(value);
  }

  String _netCashflowLabel({
    required double sent,
    required double received,
    required int days,
  }) {
    final period = 'last ${days}d';
    if (received <= 0) {
      if (sent <= 0) return '→ No cashflow in $period';
      return '↓ Outflow only in $period';
    }

    final netPercent = ((received - sent) / received) * 100;
    final formatted = '${netPercent.abs().toStringAsFixed(1)}%';
    if (netPercent > 0) {
      return '↑ $formatted net cashflow in $period';
    }
    if (netPercent < 0) {
      return '↓ $formatted net cashflow in $period';
    }
    return '→ 0.0% net cashflow in $period';
  }

  Widget _buildChartSummary(List<double> points, AppDimensions dims) {
    final safePoints = points.isEmpty ? const [0.0] : points;
    final peak = safePoints.reduce((a, b) => a > b ? a : b);
    final total = safePoints.fold<double>(0.0, (sum, v) => sum + v);
    final average = total / safePoints.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInsightChip('avg/day', _compactEtb(average), dims),
        _buildInsightChip('peak', _compactEtb(peak), dims),
      ],
    );
  }

  Widget _buildInsightChip(String label, String value, AppDimensions dims) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: dims.symmetric(h: 10, v: 6),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.balanceCardChipBackground : AppColors.balanceCardChipBackground,
        borderRadius: BorderRadius.circular(_balanceCornerRadius),
        border: Border.all(
          color: isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SensitiveText(
            '$value etb',
            style: TextStyle(
              color: isDark ? DarkAppColors.balanceCardForeground : AppColors.balanceCardForeground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dims = ref.watch(dimensionsProvider);
    final textScale = ref.watch(textScaleProvider);
    final screenSize = MediaQuery.of(context).size;
    final chartHeight = ((screenSize.height * 0.30).clamp(140.0, 280.0) * dims.spacingScale)
        .clamp(140.0, double.infinity);
    final maxCardHeight = (screenSize.height * 0.40 * dims.spacingScale * textScale)
        .clamp(280.0, screenSize.height * 0.75);

    final days = _daysForPeriod(widget.selectedPeriod);

    final sortedBanks = [BankBalanceFilter.all];
    final activityMap = <(BankBalanceFilter, double)>[];
    final tracked =
        ref.watch(trackedBankFiltersProvider).value ?? const <BankBalanceFilter>[];
    for (final bank in tracked) {
      if (bank == BankBalanceFilter.all) continue;
      final stats =
          ref.watch(statsProvider((days, bank))).value ??
          const {'sent': 0.0, 'received': 0.0};
      final activity = (stats['sent'] ?? 0.0) + (stats['received'] ?? 0.0);
      activityMap.add((bank, activity));
    }
    activityMap.sort((a, b) => b.$2.compareTo(a.$2));
    sortedBanks.addAll(activityMap.map((e) => e.$1));

    if (_bankPages.length != sortedBanks.length ||
        _bankPages.asMap().entries.any((e) => e.value != sortedBanks[e.key])) {
      _bankPages = sortedBanks;
    }
    final activeIndex = _activePageIndex.clamp(0, _bankPages.length - 1);

    return Column(
      children: [
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 200) return;
            _goToPage(_activePageIndex + (velocity < 0 ? 1 : -1));
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxCardHeight,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _buildBalanceCard(
                _bankPages[activeIndex],
                chartHeight: chartHeight,
                dims: dims,
              ),
            ),
          ),
        ),
        SizedBox(height: dims(12)),
        _buildPageIndicator(activeIndex, dims),
      ],
    );
  }

  Widget _buildBalanceCard(
    BankBalanceFilter bank, {
    required double chartHeight,
    required AppDimensions dims,
  }) {
    final days = _daysForPeriod(widget.selectedPeriod);
    final colors = _bankColors(bank, Theme.of(context).brightness);
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    final formatter = useCompact ? NumberFormat.compact() : NumberFormat('#,###.00');

    return Consumer(
      builder: (context, ref, _) {
        final hidden = ref.watch(sensitiveHideProvider);
        final calMode = ref.watch(calendarModeProvider);
        final balance =
            ref.watch(totalBalanceProvider(bank)).value ?? 0.0;
        final stats = ref
                .watch(statsProvider((days, bank)))
                .value ??
            {'sent': 0.0, 'received': 0.0};
        final sent = stats['sent'] ?? 0.0;
        final received = stats['received'] ?? 0.0;
        final points =
            ref.watch(dailySpendingProvider((days, bank))).value ?? [];

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenSize = MediaQuery.of(context).size;
        final smallScreen = screenSize.width < 360 || screenSize.height < 700;
        final horizontalMargin = dims(smallScreen ? 10.0 : 14.0);
        final cardHPadding = dims(smallScreen ? 14.0 : 20.0);
        final cardVPadding = dims(smallScreen ? 12.0 : 16.0);
        final balanceFontSize = smallScreen ? 30.0 : 36.0;
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: dims(6),
          ),
          padding: EdgeInsets.fromLTRB(cardHPadding, cardVPadding, cardHPadding, cardVPadding),
          decoration: BoxDecoration(
            color: colors['bg'],
            borderRadius: homeCardBorderRadius,
            boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : homeCardShadow,
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontFamily: AppTypography.balanceSectionFontFamily,
              fontWeight: FontWeight.w700,
              color: colors['fg'],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Transform.translate(
                    offset: const Offset(0, -2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _balanceTitle(bank),
                                style: TextStyle(
                                  color: colors['muted'],
                                  fontSize: 14,
                                  height: 0.95,
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      'ETB ',
                                      style: TextStyle(
                                        color: colors['fg'],
                                        fontSize: 18,
                                      ),
                                    ),
                                    Flexible(
                                      child: SensitiveText(
                                        formatter.format(balance),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: balanceFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: colors['fg'],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: dims(10)),
                      _buildPeriodDropdown(
                        colors,
                        dims: dims,
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: SensitiveText(
                    _netCashflowLabel(
                      sent: sent,
                      received: received,
                      days: days,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: colors['muted'],
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: dims(6)),
                _buildChartSummary(points, dims),
                SizedBox(height: dims(8)),
                Flexible(
                  fit: FlexFit.loose,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: chartHeight,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: _InteractiveSpendingChart(
                        points: points,
                        accent: colors['accent']!,
                        grid: colors['grid']!,
                        dims: dims,
                        hidden: hidden,
                        calMode: calMode,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: dims(14)),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn('sent', sent, colors, dims),
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        'received',
                        received,
                        colors,
                        dims,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(
    String label,
    double value,
    Map<String, Color> colors,
    AppDimensions dims,
  ) {
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    final fmt = useCompact ? NumberFormat.compact() : NumberFormat('#,###');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            color: colors['muted'],
            letterSpacing: 1,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SensitiveText(
              fmt.format(value),
              style: TextStyle(
                fontSize: 18,
                color: colors['fg'],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: dims(2)),
            Text('etb', style: TextStyle(fontSize: 10, color: colors['muted'])),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodDropdown(
    Map<String, Color> colors, {
    required AppDimensions dims,
  }) {
    final isDark = AppColors.isDark(context);
    return PopupMenuButton<FilterPeriod>(
      onSelected: widget.onPeriodChanged,
      tooltip: 'Select time range',
      color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: homeCardBorderRadius),
      itemBuilder: (context) => FilterPeriod.values.map((period) {
        final isSelected = period == widget.selectedPeriod;
        return PopupMenuItem<FilterPeriod>(
          value: period,
          child: Text(
            _periodDropdownLabel(period),
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: colors['fg'],
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: dims.symmetric(h: 10, v: 6),
        decoration: BoxDecoration(
          color: isDark ? DarkAppColors.balancePeriodPickerBackground : AppColors.balancePeriodPickerBackground,
          borderRadius: BorderRadius.circular(_balanceCornerRadius),
          boxShadow: [
            BoxShadow(
              color: isDark ? DarkAppColors.balancePeriodPickerShadow : AppColors.balancePeriodPickerShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.date_range,
          size: dims.icon(18),
          color: isDark ? Colors.black : AppColors.balancePeriodPickerIcon,
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int currentIndex, AppDimensions dims) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _bankPages.length,
        (i) => Container(
          width: 6,
          height: 6,
          margin: dims.symmetric(h: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == currentIndex
                ? _bankColors(_bankPages[i], Theme.of(context).brightness)['accent']
                : (AppColors.isDark(context)
                    ? Colors.grey.shade700
                    : Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}

class _InteractiveSpendingChart extends StatelessWidget {
  const _InteractiveSpendingChart({
    required this.points,
    required this.accent,
    required this.grid,
    required this.dims,
    required this.hidden,
    required this.calMode,
  });

  final List<double> points;
  final Color accent;
  final Color grid;
  final AppDimensions dims;
  final bool hidden;
  final CalendarMode calMode;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No spending data yet',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.white70,
            fontSize: 12,
          ),
        ),
      );
    }

    final safePoints = points.map((v) => v.isFinite ? v : 0.0).toList();
    final maxY = safePoints.reduce((a, b) => a > b ? a : b);
    final avgY =
        safePoints.fold<double>(0.0, (sum, v) => sum + v) / safePoints.length;
    final topY = maxY <= 0 ? 1.0 : maxY * 1.25;
    final tooltipPattern = 'MMM d';
    final axisPattern = safePoints.length <= 8
        ? 'MMM d'
        : safePoints.length <= 31
        ? 'd MMM'
        : 'MMM';
    final startDate = DateTime.now().subtract(
      Duration(days: safePoints.length - 1),
    );

    String yLabel(double value) {
      final useCompact = AppSettingsService.getBoolSync(
        AppSettingsService.keyCompactNumbers,
        fallback: true,
      );
      if (!useCompact) {
        return NumberFormat('#,###').format(value);
      }
      return NumberFormat.compact().format(value);
    }

    final barWidth = safePoints.length > 90
        ? 2.0
        : safePoints.length > 30
        ? 4.0
        : 6.0;

    final barGroups = List.generate(safePoints.length, (i) {
      final value = safePoints[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            width: barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_balanceCornerRadius),
              topRight: Radius.circular(_balanceCornerRadius),
            ),
            color: accent,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: topY,
              color: grid,
            ),
          ),
        ],
      );
    });

    final maxBottomLabels = safePoints.length <= 8
        ? safePoints.length
        : safePoints.length <= 31
        ? 6
        : 5;
    final step = safePoints.length <= maxBottomLabels
        ? 1
        : (safePoints.length / (maxBottomLabels - 1)).ceil();
    final xInterval = step.toDouble();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: topY,
        barGroups: barGroups,
        alignment: BarChartAlignment.spaceBetween,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: grid, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: topY / 3,
              getTitlesWidget: (value, meta) => SensitiveText(
                yLabel(value),
                style: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= safePoints.length) {
                  return const SizedBox.shrink();
                }

                final isFirst = i == 0;
                final isLast = i == safePoints.length - 1;
                if (!isFirst && !isLast && i % step != 0) {
                  return const SizedBox.shrink();
                }

                final date = startDate.add(Duration(days: i));
                return Padding(
                  padding: dims.only(t: 6),
                  child: SizedBox(
                    width: 36,
                    child: Text(
                      date.fmt(axisPattern, calMode),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: avgY,
              color: grid,
              strokeWidth: 1,
              dashArray: [6, 6],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                labelResolver: (_) => 'avg',
              ),
            ),
          ],
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: _balanceCornerRadius,
            tooltipPadding: dims.symmetric(
              h: 10,
              v: 6,
            ),
            tooltipBorder: BorderSide(
              color: isDark ? DarkAppColors.balanceCardGrid : AppColors.balanceCardGrid,
            ),
            tooltipBgColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x.clamp(0, safePoints.length - 1);
              final date = startDate.add(Duration(days: index));
              final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
              final prefix = hidden ? '****' : '${useCompact ? NumberFormat.compact() : NumberFormat('#,###').format(rod.toY)} etb';
              return BarTooltipItem(
                '${date.fmt(tooltipPattern, calMode)}\n',
                TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: prefix,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
          touchCallback: (event, response) {},
        ),
      ),
    );
  }
}
