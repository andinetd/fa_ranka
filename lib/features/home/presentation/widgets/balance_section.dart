import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/features/home/presentation/providers/balance_providers.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/sensitive_hide_provider.dart';
import 'package:faranka/app/core/widgets/sensitive_text.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

import 'balance_card_theme.dart';
import 'home_types.dart';
import 'interactive_spending_chart.dart';

export 'balance_card_theme.dart';
export 'interactive_spending_chart.dart';

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
        color: isDark
            ? DarkAppColors.balanceCardChipBackground
            : AppColors.balanceCardChipBackground,
        borderRadius: BorderRadius.circular(BalanceCardTheme.cornerRadius),
        border: Border.all(
          color: isDark
              ? DarkAppColors.balanceCardChipBorder
              : AppColors.balanceCardChipBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: isDark
                  ? DarkAppColors.balanceCardMuted
                  : AppColors.balanceCardMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SensitiveText(
            '$value etb',
            style: TextStyle(
              color: isDark
                  ? DarkAppColors.balanceCardForeground
                  : AppColors.balanceCardForeground,
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
    final chartHeight =
        ((screenSize.height * 0.30).clamp(140.0, 280.0) * dims.spacingScale)
            .clamp(140.0, double.infinity);
    final maxCardHeight =
        (screenSize.height * 0.40 * dims.spacingScale * textScale)
            .clamp(280.0, screenSize.height * 0.75);

    final days = BalanceCardTheme.daysForPeriod(widget.selectedPeriod);

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
    final days = BalanceCardTheme.daysForPeriod(widget.selectedPeriod);
    final colors = BalanceCardTheme.bankColors(bank, Theme.of(context).brightness);
    final useCompact = AppSettingsService.getBoolSync(
      AppSettingsService.keyCompactNumbers,
      fallback: true,
    );
    final formatter =
        useCompact ? NumberFormat.compact() : NumberFormat('#,###.00');

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
          padding: EdgeInsets.fromLTRB(
            cardHPadding,
            cardVPadding,
            cardHPadding,
            cardVPadding,
          ),
          decoration: BoxDecoration(
            color: colors['bg'],
            borderRadius: homeCardBorderRadius,
            boxShadow:
                isDark ? DarkAppColors.homeCardShadowStyle : homeCardShadow,
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
                              BalanceCardTheme.balanceTitle(bank),
                              style: TextStyle(
                                color: colors['muted'],
                                fontSize: 14,
                                height: 0.95,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
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
                      child: InteractiveSpendingChart(
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
    final useCompact = AppSettingsService.getBoolSync(
      AppSettingsService.keyCompactNumbers,
      fallback: true,
    );
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
            BalanceCardTheme.periodDropdownLabel(period),
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
          color: isDark
              ? DarkAppColors.balancePeriodPickerBackground
              : AppColors.balancePeriodPickerBackground,
          borderRadius: BorderRadius.circular(BalanceCardTheme.cornerRadius),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? DarkAppColors.balancePeriodPickerShadow
                  : AppColors.balancePeriodPickerShadow,
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
                ? BalanceCardTheme.bankColors(
                    _bankPages[i],
                    Theme.of(context).brightness,
                  )['accent']
                : (AppColors.isDark(context)
                    ? Colors.grey.shade700
                    : Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
