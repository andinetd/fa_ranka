import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';

class HelpFaqPage extends ConsumerWidget {
  const HelpFaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final ts = ref.watch(textScaleProvider);

    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: EdgeInsets.all(dims.spacingMd),
        children: [
          _faq(dims, ts, isDark, 'What is Faranka?',
            'Faranka is a spending tracker for Ethiopian bank users. It reads SMS messages from '
                'CBE and Awash, parses them into structured transactions, and categorizes your spending.'),
          _faq(dims, ts, isDark, 'How does SMS parsing work?',
            'The app scans your SMS inbox for messages from CBE (8455) and Awash (909090). '
                'It extracts the amount, counterparty name, date, and balance from each message '
                'and stores them as structured transactions.'),
          _faq(dims, ts, isDark, 'Why does the app need SMS permission?',
            'SMS permission is required to read bank transaction messages directly from your inbox. '
                'All parsing happens entirely on your device — your SMS data is never sent anywhere.'),
          _faq(dims, ts, isDark, 'Will my messages import automatically?',
            'Yes. After granting SMS permission, the app automatically imports bank messages '
                'in three ways:\n\n'
                '• Every hour, a background task scans the last 300 SMS and imports only the '
                'messages that arrived since the last check — so it stays fast even over time.\n'
                '• New bank messages are processed in real time as they arrive.\n'
                '• Pull down on the Home page to trigger an immediate scan.\n\n'
                'Skipping the manual import when you first open the app is fine — the background '
                'tasks will still catch your messages automatically. For a full import of all '
                'historical messages, use the dedicated flow from the import page.'),
          _faq(dims, ts, isDark, 'How do categories work?',
            'Each transaction is automatically categorized based on the SMS text. You can change '
                'a transaction\'s category by tapping on it and selecting a different category. '
                'You can also split a transaction across multiple categories.'),
          _faq(dims, ts, isDark, 'Can I create budgets?',
            'Yes. Tap the Budget tab in the bottom nav to view your budgets, or create a new one '
                'by tapping the + button. Budgets can be set to track spending across specific '
                'categories on a monthly or weekly basis.'),
          _faq(dims, ts, isDark, 'What are receipt enrichments?',
            'For transactions that contain a receipt link, Faranka can automatically fetch and '
                'display the PDF or HTML receipt. This happens in the background after the '
                'transaction is imported.'),
          _faq(dims, ts, isDark, 'How does the biometric lock work?',
            'Go to Settings → Security → Require biometric authentication. When enabled, you\'ll '
                'need to authenticate with your fingerprint or face to access the app after it has '
                'been in the background.'),
          _faq(dims, ts, isDark, 'How do I backup my data?',
            'Faranka stores everything locally on your device — there is no cloud account. '
                'To keep a portable copy of your data, use Settings → Export and export your '
                'transactions as CSV or JSON.'),
          _faq(dims, ts, isDark, 'How do I export my transactions?',
            'Go to Settings → scroll to the Export section → choose JSON or CSV. The file will '
                'be shared via your device\'s share sheet.'),
          _faq(dims, ts, isDark, 'How do I clear all data?',
            'Go to Settings → Wipe All Data. This deletes all transactions, budgets, and parsed '
                'data from the local database.'),
          _faq(dims, ts, isDark, 'Is my data private?',
            'Yes. All SMS data is processed locally on your device and is never sent anywhere. '
                'The app has no cloud storage and no account system. See the Privacy Policy for '
                'details.'),
          _faq(dims, ts, isDark, 'Where may the app be inaccurate?',
            'Faranka relies on automated SMS parsing, which has inherent limitations:\n\n'
                '- SMS format changes by banks may cause misread amounts, counterparty names, or fees.\n'
                '- Automatic categorisation may not always match the intended category.\n'
                '- Receipt enrichment depends on bank server availability and internet access.\n'
                '- Cash-out and mobile money transactions may not always be detected automatically.\n'
                '- Duplicate detection uses fuzzy matching and may occasionally miss duplicates.\n\n'
                'You can always correct any inaccuracies by editing the transaction or its category '
                'directly from the transaction detail screen.'),
        ],
      ),
    );
  }

  Widget _faq(AppDimensions dims, double ts, bool isDark, String question, String answer) {
    return Padding(
      padding: EdgeInsets.only(bottom: dims.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 16 * ts,
              fontWeight: FontWeight.w700,
              color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
            ),
          ),
          SizedBox(height: dims.spacingSm),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14 * ts,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
