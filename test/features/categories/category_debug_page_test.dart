import 'package:flutter_test/flutter_test.dart';

import 'package:faranka/database/database.dart';
import 'package:faranka/features/categories/presentation/pages/category_debug_page.dart';

void main() {
  test('prepareCategorySummaries sorts a copy without mutating the source', () {
    final original = [
      CategorySum(name: 'B', total: 20, count: 2),
      CategorySum(name: 'A', total: 10, count: 1),
      CategorySum(name: 'C', total: 30, count: 3),
    ];

    final sorted = prepareCategorySummaries(
      original,
      sortBy: CategorySortBy.nameAsc,
    );

    expect(sorted.map((category) => category.name).toList(), ['A', 'B', 'C']);
    expect(original.map((category) => category.name).toList(), ['B', 'A', 'C']);
    expect(identical(sorted, original), isFalse);
  });
}
