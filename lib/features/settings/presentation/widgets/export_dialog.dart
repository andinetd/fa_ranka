import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/settings/utils/settings_export.dart';

Future<void> showExportTransactionsDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final db = ref.read(databaseProvider);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.isDark(ctx)
          ? DarkAppColors.scaffoldBackground
          : Colors.white,
      title: const Text('Export Transactions'),
      content: const Text(
        'Choose a format for exporting your transaction data.',
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(ctx).pop();
            exportTransactionsCsv(db, context);
          },
          icon: const Icon(Icons.table_chart_outlined),
          label: const Text('CSV'),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.of(ctx).pop();
            exportTransactionsJson(db, context);
          },
          icon: const Icon(Icons.data_object_outlined),
          label: const Text('JSON'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
