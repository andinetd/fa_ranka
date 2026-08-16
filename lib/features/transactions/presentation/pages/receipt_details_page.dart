import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/tutorial/tutorial_content.dart';
import 'package:faranka/app/core/tutorial/tutorial_widget.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/receipts/data/parsers/awash_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/boa_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/cbe_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/telebirr_sms_parser.dart';

import 'package:faranka/features/transactions/models/awash_transaction.dart';
import 'package:faranka/features/transactions/presentation/widgets/link_preview.dart';
import 'package:faranka/features/transactions/presentation/widgets/receipt_preview.dart';
import 'package:faranka/features/transactions/presentation/widgets/edit_category_sheet.dart';
import 'package:faranka/features/transactions/presentation/widgets/split_category_sheet.dart';
import 'package:faranka/features/transactions/presentation/widgets/transaction_insights_card.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_processor.dart';

class ReceiptDetailsPage extends ConsumerStatefulWidget {
  const ReceiptDetailsPage({super.key, required this.sms});

  final SmsInboxData sms;

  @override
  ConsumerState<ReceiptDetailsPage> createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends ConsumerState<ReceiptDetailsPage> {
  late AwashTransaction transaction;
  final _splitKey = GlobalKey();
  String? _localReceiptPath;
  bool _isReparsing = false;

  String? _extractFirstUrl(String text) {
    final urlRegex = RegExp(r"https?://[^\s)>,]+", caseSensitive: false);
    final matches = urlRegex
        .allMatches(text)
        .map((m) => m.group(0))
        .whereType<String>()
        .where((url) => !_isFeedbackUrl(url))
        .toList();
    if (matches.isEmpty) return null;

    for (final u in matches) {
      final lower = u.toLowerCase();
      if (lower.contains('apps.cbe.com.et') ||
          lower.contains('branchreceipt') ||
          lower.contains('mbreceipt') ||
          lower.contains('mbreciept')) {
        return u;
      }
    }

    return matches.last;
  }

  bool _isFeedbackUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('forms.gle') ||
        lower.contains('docs.google.com/forms') ||
        lower.contains('google.com/forms');
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final addressLower = widget.sms.address.toLowerCase();
    final isCbe = _bankForAddress(addressLower) == ReceiptPreviewBank.cbe;
    final isTelebirr = _bankForAddress(addressLower) == ReceiptPreviewBank.telebirr;
    final isBoa = _bankForAddress(addressLower) == ReceiptPreviewBank.boa;
    final data = isCbe
        ? CbeSmsParser.parseAll(widget.sms.body)
        : isTelebirr
            ? TelebirrSmsParser.parseAll(widget.sms.body)
            : isBoa
                ? BoaSmsParser.parseAll(widget.sms.body)
                : AwashSmsParser.parseAll(widget.sms.body);

    transaction = AwashTransaction(
      direction: data['direction'],
      smsAmount: data['amount']?.toString(),
      smsTxnId: data['transactionId'],
      counterparty: data['counterparty'],
      date: data['date'],
      time: data['time'],
      url: data['url'],
    );

    transaction.parseSource = widget.sms.parseSource;
    transaction.parsedTxnId = widget.sms.transactionId;
    transaction.receiptDate = widget.sms.parsedDate;
    transaction.receiptTime = widget.sms.parsedTime;
    transaction.amount = widget.sms.amount;
    transaction.commission = widget.sms.commission;
    transaction.vat = widget.sms.vat;
    transaction.total = widget.sms.total;
    transaction.fromAccount = widget.sms.fromAccount;
    transaction.toAccount = widget.sms.toAccount;
    transaction.beneficiaryAccount = widget.sms.beneficiaryAccount;
    transaction.beneficiaryBank = widget.sms.beneficiaryBank;
    transaction.txnType = widget.sms.transactionType;
    transaction.reason = widget.sms.reason;
    transaction.tillNumber = widget.sms.tillNumber;
    transaction.tin = widget.sms.tin;
    transaction.vatReg = widget.sms.vatReg;

    _loadLocalReceiptPath();
  }

  ReceiptPreviewBank _bankForAddress(String addressLower) {
    if (addressLower.contains('cbe')) return ReceiptPreviewBank.cbe;
    if (addressLower == '127' ||
        addressLower.contains('telebirr') ||
        addressLower.contains('ethio telecom')) {
      return ReceiptPreviewBank.telebirr;
    }
    if (addressLower.contains('boa') || addressLower.contains('abyssinia')) {
      return ReceiptPreviewBank.boa;
    }
    return ReceiptPreviewBank.awash;
  }

  Future<void> _loadLocalReceiptPath() async {
    try {
      final db = ref.read(databaseProvider);
      final txn = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(widget.sms.id)))
          .getSingleOrNull();
      if (mounted) {
        setState(() => _localReceiptPath = txn?.localReceiptPath);
      }
    } catch (_) {}
  }

  Future<void> _showSplitDialog(TransactionData txn) async {
    if (!mounted) return;
    final db = ref.read(databaseProvider);
    List<TransactionSplit> existing;
    List<Category> categories;
    try {
      existing = await db.getSplitsForTransaction(txn.id);
      categories = await db.select(db.categories).get();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load split data: $e')),
      );
      return;
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      builder: (_) => SplitCategorySheet(
        txn: txn,
        existingSplits: existing,
        allCategories: categories.map((c) => c.name).toList(),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showEditCategoryDialog(TransactionData txn) async {
    if (!mounted) return;
    final db = ref.read(databaseProvider);
    List<Category> categories;
    try {
      categories = await db.select(db.categories).get();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
      return;
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditCategorySheet(
        txn: txn,
        parentContext: context,
        categories: categories,
      ),
    );
  }

  Future<void> _reparseTransaction() async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reparse transaction?'),
        content: const Text(
          'This will re-parse the original SMS and re-fetch the receipt '
          'to update all transaction fields including amount, category, '
          'and counterparty.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reparse'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final db = ref.read(databaseProvider);
    final transactions = await db.select(db.transactions).get();
    final txn = transactions.cast<TransactionData?>().firstWhere(
          (t) => t?.smsId == widget.sms.id,
          orElse: () => null,
        );
    if (txn == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction not found')),
      );
      return;
    }

    setState(() => _isReparsing = true);
    try {
      final processor = TransactionProcessor(db);
      final result = await processor.reparseTransaction(txn.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reparse failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isReparsing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final narrowScreen = MediaQuery.of(context).size.width < 360;
    final db = ref.watch(databaseProvider);
    final previewKey = GlobalKey();

    final link = transaction.url?.isNotEmpty == true
        ? transaction.url
        : _extractFirstUrl(widget.sms.body);
    final isCbeReceived =
        widget.sms.address.toLowerCase().contains('cbe') &&
        transaction.direction.toLowerCase() == 'credit';
    final previewBank =
        _bankForAddress(widget.sms.address.toLowerCase());

    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
        foregroundColor: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
        actions: [
          IconButton(
            tooltip: _isReparsing ? 'Reparsing…' : 'Reparse transaction',
            onPressed: _isReparsing ? null : _reparseTransaction,
            icon: _isReparsing
                ? SizedBox(
                    width: dims.icon(18),
                    height: dims.icon(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark
                          ? DarkAppColors.homeAccentGreen
                          : AppColors.homeSeed,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: dims.all(narrowScreen ? 10 : 16),
        child: TutorialWrapper(
          pageName: 'receipt',
          targets: receiptTutorial(
            splitKey: _splitKey,
            isDark: isDark,
            dims: dims,
          ),
          onReady: () async {
            final db = ref.read(databaseProvider);
            await db.select(db.transactions).get();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: dims.only(b: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORIGINAL MESSAGE',
                    style: TextStyle(
                      color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeSeed,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: dims.spacingSm),
                  Container(
                    width: double.infinity,
                    padding: dims.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : AppColors.homeCardShadowStyle,
                    ),
                    child: Stack(
                      children: [
                        SelectableText(
                          widget.sms.body,
                          style: TextStyle(
                            color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: dims(6)),
                ],
              ),
            ),
            if (link != null)
              LinkPreview(
                url: link,
                localReceiptPath: _localReceiptPath,
                forcePdf:
                    transaction.parseSource == 'pdf_parse' && isCbeReceived,
                compactPdf: isCbeReceived,
                bank: previewBank,
              ),
            ReceiptPreview(
              previewKey: previewKey,
              sms: widget.sms,
              transaction: transaction,
            ),
            StreamBuilder<List<TransactionData>>(
              stream: db.select(db.transactions).watch(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }
                final transactions = snapshot.data ?? const <TransactionData>[];
                final matchedTxn = transactions
                    .cast<TransactionData?>()
                    .firstWhere(
                      (txn) => txn?.smsId == widget.sms.id,
                      orElse: () => null,
                    );
                if (matchedTxn == null) {
                  return const SizedBox.shrink();
                }

                return TransactionInsightsCard(
                  currentTxn: matchedTxn,
                  allTransactions: transactions,
                  splitButtonKey: _splitKey,
                  onEditCategory: () => _showEditCategoryDialog(matchedTxn),
                  onSplitTransaction: () => _showSplitDialog(matchedTxn),
                  onReparse: _reparseTransaction,
                );
              },
            ),
          ],
          ),
        ),
      ),
    );
  }
}
