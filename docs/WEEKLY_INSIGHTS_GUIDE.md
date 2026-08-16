# Weekly Insights Card - Implementation Guide

## Overview

The Weekly Insights Card displays a beautiful summary of spending patterns for the current week, similar to Samsung's screen time summary. It provides users with:

- **Weekly total spending** with visual emphasis
- **Week-over-week comparison** showing percentage change and trend
- **Daily breakdown chart** visualizing spending across all days
- **Top spending category** identification
- **Category breakdown** showing top 3 categories with percentages

## Features

### 1. **Main Metrics**
- Current week's total spending amount
- Previous week's spending for comparison
- Percentage change indicator with visual trend (↑/↓)
- Change direction (Higher/Lower/Same)

### 2. **Visual Elements**
- **Gradient background** with purple/indigo theme matching modern design patterns
- **Daily bar chart** showing spending for each day (Mon-Sun)
- **Change indicator badge** with color coding:
  - 🔴 Red for increased spending
  - 🟢 Green for decreased spending
  - 🟡 Gray for same spending
- **Category cards** with progress bars

### 3. **Data Breakdown**
- Daily spending amounts
- Daily percentage of weekly total
- Top 3 categories with percentages
- Historical comparison with color-coded trends

## Component Structure

### `WeeklyInsightsSummary` (Model)
Holds all calculated data:
```dart
WeeklyInsightsSummary(
  weekStart: DateTime,
  weekEnd: DateTime,
  totalSpending: double,
  previousWeekSpending: double,
  topCategory: String,
  topCategoryAmount: double,
  dailySpending: Map<String, double>,
  categoryBreakdown: Map<String, double>,
  dailyData: List<WeeklyDailyData>,
)
```

### `WeeklyDailyData` (Model)
Represents daily spending data:
```dart
WeeklyDailyData(
  day: String,           // "Mon", "Tue", etc.
  amount: double,        // Spending amount
  date: DateTime,        // Full date
  percentageOfWeek: double, // % of weekly total
)
```

### `WeeklyInsightsCard` (Widget)
Main display widget showing the complete summary with:
- Header with week date range
- Main spending amount
- Change comparison box
- Daily breakdown chart
- Top category and category breakdown widgets

### `WeeklyInsightsService` (Service)
Calculates insights from database transactions:
```dart
// Get insights for specific date
static Future<WeeklyInsightsSummary> calculateWeeklyInsights(
  AppDatabase db,
  DateTime date,
)

// Stream for reactive updates
static Stream<WeeklyInsightsSummary> watchWeeklyInsights(
  AppDatabase db,
  DateTime date,
)
```

## Files Created

| File | Purpose |
|------|---------|
| `lib/features/insights/presentation/widgets/weekly_insights_card.dart` | Card widget and data models |
| `lib/features/insights/presentation/utils/weekly_insights_service.dart` | Data calculation service |
| **Modified**: `lib/features/insights/presentation/pages/insights_screen.dart` | Integrated weekly card |

## Integration in Insights Page

The weekly insights card appears at the **top** of the insights page, before:
- Calendar heatmap
- Radar comparison
- Counterparty leaders
- Anomalies

### Location in Code
```dart
// In _InsightsScreenState.build()
Column(
  children: [
    _buildWeeklyInsightsCard(),  // ← NEW: Added here
    const SizedBox(height: 16),
    _buildCalendarHeatmap(),
    // ... rest of cards
  ],
)
```

## How It Works

### Week Calculation
```dart
// Monday-based week (Monday = day 1)
getWeekStart(date)  // Returns Monday of that week
getWeekEnd(date)    // Returns following Monday (7 days later)
getPreviousWeekStart(date) // Returns previous Monday
```

### Data Processing
1. **Queries all transactions** from database
2. **Filters by date ranges**:
   - Current week (Monday-Sunday)
   - Previous week (for comparison)
3. **Aggregates by**:
   - Day of week (for daily chart)
   - Category (for breakdown)
4. **Calculates**:
   - Weekly totals
   - Daily percentages
   - Week-over-week change
   - Top categories

### Reactive Updates
Uses `watchWeeklyInsights()` stream that:
- Listens for transaction changes
- Automatically recalculates insights
- Updates UI via StreamBuilder

## Usage Example

### In Insights Page
Already integrated! The card appears automatically at the top:

```dart
// In InsightsScreen._buildWeeklyInsightsCard()
StreamBuilder<WeeklyInsightsSummary>(
  stream: WeeklyInsightsService.watchWeeklyInsights(
    database,
    DateTime.now(),
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return LoadingWidget();
    
    return WeeklyInsightsCard(
      insights: snapshot.data!,
      onTap: () {
        // Handle card interaction
      },
    );
  },
)
```

### Use Service Directly

```dart
import 'package:faranka/features/insights/presentation/utils/weekly_insights_service.dart';

// Get current week's insights
final insights = await WeeklyInsightsService.calculateWeeklyInsights(
  database,
  DateTime.now(),
);

print('This week: ETB ${insights.totalSpending}');
print('Last week: ETB ${insights.previousWeekSpending}');
print('Top category: ${insights.topCategory}');
```

## Customization

### Theme Colors
Update colors in `WeeklyInsightsCard`:
```dart
// Main gradient
LinearGradient(
  colors: [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Purple
  ],
)

// Change indicator colors
const Color(0xFFEF4444), // Red (higher)
const Color(0xFF10B981), // Green (lower)
const Color(0xFF6B7280), // Gray (same)
```

### Card Size & Padding
```dart
// In WeeklyInsightsCard build()
padding: const EdgeInsets.all(20),      // Card padding
BorderRadius.circular(16),              // Border radius
SizedBox(height: 60),                   // Chart height
```

### Daily Chart
```dart
// Bar width and spacing
width: 24,                              // Bar width
mainAxisAlignment: MainAxisAlignment.spaceAround,
```

## Performance Considerations

### Data Loading
- **Single database query**: Gets all transactions once
- **Lazy filtering**: Occurs during calculation
- **Efficient aggregation**: O(n) complexity

### Memory Usage
- **Caches daily data**: 7 entries max
- **Caches categories**: Typically 5-10 entries
- **Lightweight rebuild**: Only on transaction changes

### Optimization Tips
```dart
// For large datasets (1000+ transactions):
// 1. Consider pagination of chart display
// 2. Cache insights in local state
final _cachedInsights = <DateTime, WeeklyInsightsSummary>{};

// 3. Update less frequently
watchWeeklyInsights().throttleTime(Duration(seconds: 1))
```

## Testing

### Test Week Calculation
```dart
test('getWeekStart returns Monday', () {
  final wed = DateTime(2024, 5, 15); // Wednesday
  final monday = WeeklyInsightsService.getWeekStart(wed);
  expect(monday.weekday, 1); // Monday
});
```

### Test Insights Calculation
```dart
test('calculateWeeklyInsights aggregates correctly', () async {
  final insights = await WeeklyInsightsService.calculateWeeklyInsights(
    mockDatabase,
    DateTime.now(),
  );
  
  expect(insights.totalSpending, greaterThan(0));
  expect(insights.dailyData.length, equals(7));
  expect(insights.topCategory, isNotEmpty);
});
```

## Future Enhancements

### Possible Features
1. **Weekly goals** - Show spending vs budget
2. **Year-over-year** - Compare same week last year
3. **Trends** - Multiple weeks chart showing trend
4. **Predictive** - Estimate remaining week spending
5. **Insights AI** - Generate spending suggestions
6. **Share** - Export weekly summary as image
7. **Custom weeks** - User-defined week ranges
8. **Recurring patterns** - Identify spending patterns

### Implementation Example
```dart
// Add weekly budget tracking
class WeeklyBudgetInsights extends WeeklyInsightsSummary {
  final double weeklyBudget;
  
  double get budgetRemaining => weeklyBudget - totalSpending;
  double get budgetUsedPercent => (totalSpending / weeklyBudget) * 100;
  bool get isOverBudget => totalSpending > weeklyBudget;
}
```

## Troubleshooting

### Card Not Showing
1. Check if transactions exist
2. Verify database is initialized
3. Check date range filtering logic

### Incorrect Spending
1. Verify transaction direction filter (debit only)
2. Check category parsing
3. Confirm timestamp conversion

### Performance Issues
1. Check transaction count
2. Profile with DevTools
3. Consider caching for large datasets

## API Reference

### WeeklyInsightsService

```dart
// Static methods for week calculation
static DateTime getWeekStart(DateTime date)
static DateTime getWeekEnd(DateTime date)
static DateTime getPreviousWeekStart(DateTime date)

// Main calculation
static Future<WeeklyInsightsSummary> calculateWeeklyInsights(
  AppDatabase db,
  DateTime date,
)

// Reactive stream
static Stream<WeeklyInsightsSummary> watchWeeklyInsights(
  AppDatabase db,
  DateTime date,
)
```

### WeeklyInsightsSummary

```dart
// Properties
final double totalSpending
final double previousWeekSpending
final String topCategory
final double topCategoryAmount
final Map<String, double> categoryBreakdown
final List<WeeklyDailyData> dailyData

// Computed properties
double get weeklyChange
double get percentageChange
String get changeDirection
bool get isSpendingHigher
bool get isSpendingLower
```

### WeeklyInsightsCard

```dart
WeeklyInsightsCard(
  required WeeklyInsightsSummary insights,
  VoidCallback? onTap,
)
```

## Summary

The Weekly Insights Card provides an at-a-glance view of spending patterns with:
✅ Beautiful, modern UI design
✅ Week-over-week comparison
✅ Daily breakdown visualization
✅ Category analysis
✅ Responsive and performant
✅ Easy to customize
✅ Production-ready implementation
