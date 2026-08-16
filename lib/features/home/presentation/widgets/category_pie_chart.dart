import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/sensitive_hide_provider.dart';
import 'package:faranka/database/database.dart';

class CategoryPieChart extends ConsumerStatefulWidget {
  final List<CategorySum> data;
  final ValueChanged<String>? onCategoryTap;

  const CategoryPieChart({super.key, required this.data, this.onCategoryTap});

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart> {
  int touchedIndex = -1;

  // Generate distinct colors for categories
  List<Color> get colors => [
    Colors.blue,
    Colors.orange,
    Colors.teal,
    Colors.purple,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text("No expenses found", style: TextStyle(color: Colors.grey)),
      );
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              if (event is FlTapUpEvent &&
                  pieTouchResponse?.touchedSection != null) {
                final index =
                    pieTouchResponse!.touchedSection!.touchedSectionIndex;
                widget.onCategoryTap?.call(widget.data[index].name);
              }

              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 4,
          centerSpaceRadius: 50, // Makes it a donut
          sections: _showingSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(widget.data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final category = widget.data[i];

      final hidden = ref.watch(sensitiveHideProvider);
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: category.total,
        title: isTouched
            ? '${category.name}\n${hidden ? '****' : category.total.toStringAsFixed(0)}'
            : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    });
  }
}
