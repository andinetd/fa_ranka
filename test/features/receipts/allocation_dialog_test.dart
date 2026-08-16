import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/services/sms.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/receipts/presentation/pages/setup_page.dart';

void main() {
  Future<AppDatabase> buildDb() async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    initDatabase(db);
    return db;
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        dimensionsProvider.overrideWithValue(AppDimensions(1.0)),
      ],
      child: MaterialApp(home: child),
    );
  }

  const availability = SmsAvailabilitySummary(
    awash: 30,
    cbe: 20,
    telebirr: 10,
    boa: 5,
  );

  Widget buildHost() {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AllocationDialog(
                availability: availability,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('all banks with messages are selected by default and fields enabled',
      (tester) async {
    final db = await buildDb();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(buildHost()));
    await openDialog(tester);

    expect(find.text('Which banks do you want to track?'), findsOneWidget);
    Finder chip(String label) => find.descendant(
          of: find.byType(Wrap),
          matching: find.text(label),
        );
    expect(chip('Awash Bank'), findsOneWidget);
    expect(chip('CBE'), findsOneWidget);
    expect(chip('Telebirr'), findsOneWidget);
    expect(chip('BoA'), findsOneWidget);
    expect(find.text('4 banks selected.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
    expect(find.byType(TextFormField), findsNWidgets(4));
    for (final t in tester.widgetList<TextFormField>(find.byType(TextFormField))) {
      expect(t.enabled, isTrue);
    }
  });

  testWidgets('deselecting a bank disables its allocation field', (tester) async {
    final db = await buildDb();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(buildHost()));
    await openDialog(tester);

    await tester.tap(find.text('BoA'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    expect(find.text('3 banks selected.'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'AWASH'),
          )
          .enabled,
      isTrue,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'BOA'),
          )
          .enabled,
      isFalse,
    );
  });

  testWidgets('reselecting a bank re-enables its allocation field', (tester) async {
    final db = await buildDb();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(buildHost()));
    await openDialog(tester);

    await tester.tap(find.text('BoA'));
    await tester.pumpAndSettle();
    expect(find.text('3 banks selected.'), findsOneWidget);

    await tester.tap(find.text('BoA'));
    await tester.pumpAndSettle();

    expect(find.text('4 banks selected.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'BOA'),
          )
          .enabled,
      isTrue,
    );
  });

  testWidgets('import button disabled when no banks selected', (tester) async {
    final db = await buildDb();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(buildHost()));
    await openDialog(tester);

    for (final label in ['Awash Bank', 'CBE', 'Telebirr', 'BoA']) {
      await tester.tap(
        find.descendant(
          of: find.byType(Wrap),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text('Select at least one bank to import messages.'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Import messages'),
    );
    expect(button.onPressed, isNull);
  });
}