import 'package:flutter/material.dart';

class CounterpartyInsightItem {
  final String label;
  final double amount;
  final int count;

  CounterpartyInsightItem({
    required this.label,
    required this.amount,
    required this.count,
  });
}

class CounterpartyInsightsSnapshot {
  final String monthLabel;
  final List<CounterpartyInsightItem> topSentTo;
  final List<CounterpartyInsightItem> topReceivedFrom;

  CounterpartyInsightsSnapshot({
    required this.monthLabel,
    required this.topSentTo,
    required this.topReceivedFrom,
  });
}

class CategoryRadarComparison {
  final String currentMonthLabel;
  final String previousMonthLabel;
  final List<String> labels;
  final List<double> currentValues;
  final List<double> previousValues;

  CategoryRadarComparison({
    required this.currentMonthLabel,
    required this.previousMonthLabel,
    required this.labels,
    required this.currentValues,
    required this.previousValues,
  });
}

class BurnRateSnapshot {
  final String currentMonthLabel;
  final double currentTotal;
  final double historicalAverage;
  final double ratio;

  BurnRateSnapshot({
    required this.currentMonthLabel,
    required this.currentTotal,
    required this.historicalAverage,
    required this.ratio,
  });
}

class SpendingAnomaly {
  final String category;
  final double currentTotal;
  final double historicalAverage;
  final double ratio;

  SpendingAnomaly({
    required this.category,
    required this.currentTotal,
    required this.historicalAverage,
    required this.ratio,
  });

  String get direction => ratio > 1.0 ? 'overspending' : 'underspending';

  Color get trendColor => ratio > 1.25
      ? const Color(0xFFB85C5C)
      : ratio > 1.0
      ? const Color(0xFFC4975A)
      : const Color(0xFF8EA78F);
}
