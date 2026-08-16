import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/features/receipts/presentation/notifiers/import_progress_notifier.dart';
import 'package:faranka/features/receipts/presentation/pages/results_page.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        dimensionsProvider.overrideWithValue(AppDimensions(1.0)),
      ],
      child: MaterialApp(home: child),
    );
  }

  tearDown(() {
    ImportProgressNotifier.instance.dismissComplete();
  });

  testWidgets('only chosen banks show a progress section', (tester) async {
    // CBE + Telebirr chosen; Awash and BoA are not (total 0).
    ImportProgressNotifier.instance.value = const ImportState(
      isRunning: true,
      awashTotal: 0,
      awashDone: 0,
      cbeTotal: 20,
      cbeDone: 5,
      telebirrTotal: 10,
      telebirrDone: 2,
      boaTotal: 0,
      boaDone: 0,
      currentActivity: 'Importing messages...',
    );

    await tester.pumpWidget(wrap(const ResultsPage(messageData: {})));
    await tester.pump();

    expect(find.text('CBE'), findsOneWidget);
    expect(find.text('Telebirr'), findsOneWidget);
    expect(find.text('Awash Bank'), findsNothing);
    expect(find.text('BoA'), findsNothing);

    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('no bank sections render when nothing was chosen', (tester) async {
    ImportProgressNotifier.instance.value = const ImportState(
      isRunning: true,
      awashTotal: 0,
      cbeTotal: 0,
      telebirrTotal: 0,
      boaTotal: 0,
      currentActivity: 'Importing messages...',
    );

    await tester.pumpWidget(wrap(const ResultsPage(messageData: {})));
    await tester.pump();

    expect(find.text('Awash Bank'), findsNothing);
    expect(find.text('CBE'), findsNothing);
    expect(find.text('Telebirr'), findsNothing);
    expect(find.text('BoA'), findsNothing);

    await tester.pump(const Duration(minutes: 1));
  });
}