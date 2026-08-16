import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/features/receipts/presentation/pages/setup_page.dart';

void main() {
  testWidgets('Setup page renders import UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dimensionsProvider.overrideWithValue(AppDimensions(1.0)),
        ],
        child: const MaterialApp(
          home: SetupPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Faranka Setup'), findsOneWidget);
    expect(find.text('Review import settings'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
