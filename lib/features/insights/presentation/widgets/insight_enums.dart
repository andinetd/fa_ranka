enum CalendarMetric { spending, income }

enum PeriodOption { followGlobal, month, threeMonths, year, all }

enum BalanceTrendPeriod {
  sevenDays('7D', 7),
  thirtyDays('30D', 30),
  ninetyDays('90D', 90),
  oneYear('1Y', 365);

  final String label;
  final int days;
  const BalanceTrendPeriod(this.label, this.days);
}
