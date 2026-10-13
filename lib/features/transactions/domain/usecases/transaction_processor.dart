import 'package:flutter/foundation.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/receipts/data/parsers/awash_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/boa_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/cbe_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/telebirr_sms_parser.dart';
import 'package:faranka/features/receipts/data/services/awash_receipt_service.dart';
import 'package:faranka/features/receipts/data/services/boa_receipt_service.dart';
import 'package:faranka/features/receipts/data/services/cbe_receipt_service.dart';
import 'package:faranka/features/receipts/data/services/telebirr_receipt_service.dart';
import 'package:faranka/app/core/services/network_status_service.dart';
import 'package:faranka/features/receipts/data/services/receipt_fetch_session.dart';
import 'package:drift/drift.dart';
import 'package:faranka/features/transactions/domain/services/category_engine.dart';
import 'package:faranka/features/transactions/domain/usecases/processors/bank_processing_support.dart';
import 'package:faranka/features/transactions/domain/usecases/processors/awash_processor.dart';
import 'package:faranka/features/transactions/domain/usecases/processors/cbe_processor.dart';
import 'package:faranka/features/transactions/domain/usecases/processors/telebirr_processor.dart';
import 'package:faranka/features/transactions/domain/usecases/processors/boa_processor.dart';

export 'package:faranka/features/transactions/domain/usecases/processors/bank_processing_support.dart'
    show OfflineDeepParseException;

class ReparseResult {
  final bool updated;
  final String message;
  final String? newCategory;

  const ReparseResult({
    required this.updated,
    required this.message,
    this.newCategory,
  });
}

class TransactionProcessor {
  final AppDatabase db;
  final ReceiptFetchSession? session;

  late final AwashProcessor _awashProcessor;
  late final CbeProcessor _cbeProcessor;
  late final TelebirrProcessor _telebirrProcessor;
  late final BoaProcessor _boaProcessor;

  TransactionProcessor(this.db, {this.session}) {
    _awashProcessor = AwashProcessor(db, session);
    _cbeProcessor = CbeProcessor(db, session);
    _telebirrProcessor = TelebirrProcessor(db, session);
    _boaProcessor = BoaProcessor(db, session);
  }

  bool _isCbeSender(String address) {
    final lower = address.toLowerCase();
    return lower.contains('cbe');
  }

  bool _isTelebirrSender(String address) {
    final lower = address.toLowerCase();
    return lower == '127' ||
        lower.contains('telebirr') ||
        lower.contains('ethio telecom');
  }

  bool _isBoaSender(String address) {
    final lower = address.toLowerCase();
    return lower.contains('boa') || lower.contains('abyssinia');
  }

  /// 1. NEW METHOD: For the Background Worker (Wake-on-SMS)
  Future<TransactionData?> processIncomingSms(String body, String address) async {
    // Save raw message first so we can always retry from local state.
    final String tempId = _runtimeSmsId(address, body);

    await db
        .into(db.smsInbox)
        .insert(
          SmsInboxCompanion.insert(
            id: tempId,
            address: address,
            body: body,
            date: DateTime.now(),
            isProcessed: const Value(false),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // Fetch the record we just created and process it
    final smsRecord = await (db.select(
      db.smsInbox,
    )..where((t) => t.id.equals(tempId))).getSingle();
    await processSmsSafely(smsRecord);

    return (db.select(db.transactions)..where((t) => t.smsId.equals(tempId)))
        .getSingleOrNull();
  }

  Future<void> processSmsSafely(SmsInboxData sms) async {
    await db.markSmsProcessingStarted(sms.id);
    try {
      await processSms(sms);
    } catch (e) {
      await db.markSmsFailed(sms.id, e.toString());
      rethrow;
    }
  }

  Future<int> processPendingSms({int limit = 100, int maxAttempts = 5}) async {
    final pending = await db.getPendingSmsForProcessing(
      limit: limit,
      maxAttempts: maxAttempts,
    );
    int count = 0;
    for (final sms in pending) {
      try {
        await processSmsSafely(sms);
        count++;
      } catch (_) {
        // Keep going so a single bad message doesn't block the queue.
      }
    }
    return count;
  }

  Future<void> processAwashSms(SmsInboxData sms) => _awashProcessor.process(sms);
  Future<void> processCbeSms(SmsInboxData sms) => _cbeProcessor.process(sms);
  Future<void> processTelebirrSms(SmsInboxData sms) => _telebirrProcessor.process(sms);
  Future<void> processBoaSms(SmsInboxData sms) => _boaProcessor.process(sms);

  Future<void> processSms(SmsInboxData sms) async {
    if (_isCbeSender(sms.address)) {
      await processCbeSms(sms);
      return;
    }
    if (_isTelebirrSender(sms.address)) {
      await processTelebirrSms(sms);
      return;
    }
    if (_isBoaSender(sms.address)) {
      await processBoaSms(sms);
      return;
    }
    await processAwashSms(sms);
  }

  /// Reparse a single transaction from scratch.
  /// Re-runs SMS parsing + receipt re-fetch + categorization,
  /// then updates the existing TransactionData row in place with ALL fields.
  Future<ReparseResult> reparseTransaction(int transactionId) async {
    final txn = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (txn == null) {
      return const ReparseResult(
        updated: false,
        message: 'Transaction not found',
      );
    }

    final sms = await (db.select(
      db.smsInbox,
    )..where((s) => s.id.equals(txn.smsId))).getSingleOrNull();
    if (sms == null) {
      return const ReparseResult(
        updated: false,
        message: 'Original SMS not found',
      );
    }

    final isCbe = _isCbeSender(sms.address);
    final isTelebirr = _isTelebirrSender(sms.address);
    final isBoa = _isBoaSender(sms.address);
    final smsData = isCbe
        ? CbeSmsParser.parseAll(sms.body)
        : isTelebirr
        ? TelebirrSmsParser.parseAll(sms.body)
        : isBoa
        ? BoaSmsParser.parseAll(sms.body)
        : AwashSmsParser.parseAll(sms.body);

    final url = smsData['url']?.toString() ?? txn.receiptUrl;
    final dir = smsData['direction'] == 'Credit'
        ? TransactionDirection.credit
        : smsData['direction'] == 'Debit'
        ? TransactionDirection.debit
        : TransactionDirection.unknown;

    Map<String, dynamic> finalData;

    if (url != null && url.isNotEmpty) {
      final online = await NetworkStatusService.hasInternet();
      if (online) {
        try {
          if (isCbe) {
            final deepData = await CbeReceiptService.fetchAndParseReceipt(
              url,
              smsText: sms.body,
            );
            finalData = <String, dynamic>{...smsData, ...deepData};

            finalData['url'] ??= url;
            finalData['transaction_id'] ??=
                finalData['referenceNumber'] ?? smsData['transactionId'];
            finalData['transaction_ref'] ??=
                finalData['referenceNumber'] ?? smsData['transactionId'];
            finalData['date'] ??= finalData['paymentDate'] ?? smsData['date'];
            finalData['time'] ??= finalData['paymentTime'] ?? smsData['time'];
            finalData['amount'] ??=
                finalData['transferredAmount'] ?? smsData['amount'];
            finalData['commission'] ??= smsData['commission'];
            finalData['vat'] ??= smsData['vat'];
            finalData['total'] ??= finalData['totalAmount'] ?? smsData['total'];
            finalData['from_account'] ??=
                finalData['payerName'] ??
                finalData['payerAccount'] ??
                smsData['account'];
            finalData['to_account'] ??=
                finalData['receiverName'] ??
                finalData['receiverAccount'] ??
                smsData['counterparty'];
            finalData['direction'] ??= smsData['direction'];
            finalData['balance'] ??= smsData['balance'];
            finalData['counterparty'] ??= finalData['to_account'];
            finalData['transaction_type'] ??=
                BankProcessingSupport.fallbackTransactionType(finalData['direction']?.toString()) ??
                'Bank Transfer';
            finalData['source'] ??= 'sms_parse';
            _cbeProcessor.applyCbeCategoryHints(finalData, sms.body);
            finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
              finalData['reason']?.toString(),
            );
            if (_cbeProcessor.looksLikeCbeGenericDebitAlert(sms.body) &&
                !_cbeProcessor.hasMeaningfulCbeReason(finalData['reason'])) {
              finalData['reason'] = '';
            }
            if (finalData['reason']?.isEmpty == true) {
              finalData['reason'] = 'Empty';
            }
            finalData['counterparty'] = dir == TransactionDirection.credit
                ? (finalData['payerName'] ??
                      finalData['from_account'] ??
                      finalData['counterparty'] ??
                      smsData['counterparty'])
                : (finalData['receiverName'] ??
                      finalData['to_account'] ??
                      finalData['counterparty'] ??
                      smsData['counterparty']);
          } else if (isTelebirr) {
            final deepData = await TelebirrReceiptService.fetchAndParseReceipt(
              url,
              smsText: sms.body,
            );
            finalData = <String, dynamic>{...smsData, ...deepData};

            finalData['url'] ??= url;
            finalData['transaction_id'] ??=
                finalData['referenceNumber'] ?? smsData['transactionId'];
            finalData['transaction_ref'] ??=
                finalData['referenceNumber'] ?? smsData['transactionId'];
            finalData['date'] ??= finalData['paymentDate'] ?? smsData['date'];
            finalData['time'] ??= finalData['paymentTime'] ?? smsData['time'];
            finalData['amount'] ??=
                finalData['settledAmount'] ?? smsData['amount'];
            finalData['commission'] ??= smsData['commission'];
            finalData['vat'] ??= smsData['vat'];
            finalData['total'] ??=
                finalData['totalPaidAmount'] ?? smsData['total'];
            finalData['from_account'] ??=
                finalData['payerNumber'] ?? smsData['counterpartyNumber'];
            finalData['to_account'] ??=
                finalData['receiverNumber'] ?? smsData['counterparty'];
            finalData['direction'] ??= smsData['direction'];
            finalData['balance'] ??= smsData['balance'];
            finalData['counterparty'] ??= finalData['to_account'];
            finalData['transaction_type'] ??=
                BankProcessingSupport.fallbackTransactionType(finalData['direction']?.toString()) ??
                smsData['transaction_type'] ??
                'Bank Transfer';
            finalData['source'] ??= 'sms_parse';
            finalData['reason'] = BankProcessingSupport.resolveTelebirrCategoryReason(finalData);
            if (finalData['reason']?.isEmpty == true) {
              finalData['reason'] = 'Empty';
            }
            finalData['counterparty'] = dir == TransactionDirection.credit
                ? (finalData['payerName'] ??
                      finalData['receiverName'] ??
                      finalData['counterparty'] ??
                      smsData['counterparty'])
                : (finalData['receiverName'] ??
                      finalData['payerName'] ??
                      finalData['counterparty'] ??
                      smsData['counterparty']);
          } else if (isBoa) {
            final deepData = await BoaReceiptService.fetchAndParseReceipt(
              url,
              smsText: sms.body,
            );
            finalData = <String, dynamic>{...smsData, ...deepData};

            finalData['url'] ??= url;
            finalData['transaction_id'] ??=
                finalData['referenceNumber'] ?? smsData['transactionId'];
            finalData['transaction_ref'] ??=
                finalData['referenceNumber'] ?? smsData['transactionId'];
            finalData['date'] ??= finalData['paymentDate'] ?? smsData['date'];
            finalData['time'] ??= finalData['paymentTime'] ?? smsData['time'];
            finalData['amount'] ??=
                finalData['transferredAmount'] ?? smsData['amount'];
            finalData['commission'] ??=
                finalData['serviceFee'] ?? smsData['commission'];
            finalData['vat'] ??= smsData['vat'];
            finalData['total'] ??= finalData['totalAmount'] ?? smsData['total'];
            finalData['from_account'] ??=
                finalData['payerAccount'] ?? smsData['account'];
            finalData['to_account'] ??=
                finalData['receiverAccount'] ?? smsData['counterparty'];
            finalData['direction'] ??= smsData['direction'];
            finalData['balance'] ??= smsData['balance'];
            finalData['counterparty'] ??= finalData['to_account'];
            finalData['transaction_type'] ??=
                finalData['transactionType'] ??
                BankProcessingSupport.fallbackTransactionType(finalData['direction']?.toString()) ??
                'Bank Transfer';
            finalData['source'] ??= 'sms_parse';
            if (finalData['reason']?.isEmpty != false) {
              finalData['reason'] =
                  BankProcessingSupport.resolveBoaCategoryReason(finalData);
            }
            finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
              finalData['reason']?.toString(),
            );
            if (finalData['reason']?.isEmpty == true) {
              finalData['reason'] = 'Empty';
            }
            finalData['counterparty'] = dir == TransactionDirection.credit
                ? (smsData['counterparty'] ??
                      finalData['payerName'] ??
                      finalData['from_account'] ??
                      finalData['counterparty'])
                : (finalData['receiverName'] ??
                      finalData['to_account'] ??
                      finalData['counterparty'] ??
                      smsData['counterparty']);
          } else {
            finalData = await AwashReceiptService.fetchAndParseHtmlReceipt(
              url,
              smsText: sms.body,
            );
            finalData['direction'] ??= smsData['direction'];
            finalData['balance'] ??= smsData['balance'];
            finalData['transaction_type'] ??= BankProcessingSupport.fallbackTransactionType(
              finalData['direction']?.toString(),
            );
            finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
              finalData['reason']?.toString(),
            );
            _awashProcessor.applyAwashCategoryHints(finalData, sms.body);
            finalData['counterparty'] = dir == TransactionDirection.credit
                ? (finalData['payerName'] ??
                      finalData['from_account'] ??
                      finalData['counterparty'] ??
                      smsData['counterparty'])
                : (finalData['receiverName'] ??
                      finalData['to_account'] ??
                      finalData['counterparty'] ??
                      smsData['counterparty']);
          }
        } catch (_) {
          finalData = Map<String, dynamic>.from(smsData);
        }
      } else {
        finalData = Map<String, dynamic>.from(smsData);
      }
    } else {
      if (isCbe) {
        finalData = <String, dynamic>{
          'source': smsData['source'] ?? 'sms_parse',
          'transaction_id': smsData['transactionId'],
          'date': smsData['date'],
          'time': smsData['time'],
          'amount': smsData['amount'],
          'commission': smsData['commission'],
          'vat': smsData['vat'],
          'total': smsData['total'],
          'from_account': smsData['account'],
          'to_account': smsData['counterparty'],
          'transaction_type':
              BankProcessingSupport.fallbackTransactionType(smsData['direction']?.toString()) ??
              'Bank Transfer',
          'reason': smsData['counterparty'],
          'url': smsData['url'],
          'direction': smsData['direction'],
          'balance': smsData['balance'],
          'counterparty': smsData['counterparty'],
          'transaction_ref': smsData['transactionId'],
        };
        _cbeProcessor.applyCbeCategoryHints(finalData, sms.body);
        if (_cbeProcessor.looksLikeCbeGenericDebitAlert(sms.body) &&
            !_cbeProcessor.hasMeaningfulCbeReason(finalData['reason'])) {
          finalData['reason'] = '';
        }
      } else if (isTelebirr) {
        finalData = <String, dynamic>{
          'source': smsData['source'] ?? 'sms_parse',
          'transaction_id': smsData['transactionId'],
          'date': smsData['date'],
          'time': smsData['time'],
          'amount': smsData['amount'],
          'commission': smsData['commission'],
          'vat': smsData['vat'],
          'total': smsData['total'],
          'from_account': smsData['counterpartyNumber'],
          'to_account': smsData['counterparty'],
          'transaction_type':
              BankProcessingSupport.fallbackTransactionType(smsData['direction']?.toString()) ??
              smsData['transaction_type'] ??
              'Bank Transfer',
          'reason': smsData['counterparty'],
          'url': smsData['url'],
          'direction': smsData['direction'],
          'balance': smsData['balance'],
          'counterparty': smsData['counterparty'],
          'transaction_ref': smsData['transactionId'],
        };
      } else if (isBoa) {
        finalData = <String, dynamic>{
          'source': smsData['source'] ?? 'sms_parse',
          'transaction_id': smsData['transactionId'],
          'date': smsData['date'],
          'time': smsData['time'],
          'amount': smsData['amount'],
          'commission': smsData['commission'],
          'vat': smsData['vat'],
          'total': smsData['total'],
          'from_account': smsData['account'],
          'to_account': smsData['counterparty'],
          'transaction_type':
              BankProcessingSupport.fallbackTransactionType(smsData['direction']?.toString()) ??
              'Bank Transfer',
          'reason': smsData['counterparty'],
          'url': smsData['url'],
          'direction': smsData['direction'],
          'balance': smsData['balance'],
          'counterparty': smsData['counterparty'],
          'transaction_ref': smsData['transactionId'],
        };
      } else {
        finalData = AwashReceiptService.parseSmsForReceiptFields(sms.body);
        finalData['direction'] ??= smsData['direction'];
        finalData['balance'] ??= smsData['balance'];
        finalData['transaction_type'] ??= BankProcessingSupport.fallbackTransactionType(
          finalData['direction']?.toString(),
        );
        _awashProcessor.applyAwashCategoryHints(finalData, sms.body);
      }
      finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
        finalData['reason']?.toString(),
      );
    }

    await db.updateSmsParsedFields(
      smsId: sms.id,
      transactionId:
          finalData['transaction_id']?.toString() ??
          finalData['transaction_ref']?.toString() ??
          smsData['transactionId'],
      date: finalData['date']?.toString(),
      time: finalData['time']?.toString(),
      amount: BankProcessingSupport.toDouble(finalData['amount']),
      commission: BankProcessingSupport.toDouble(finalData['commission']),
      vat: BankProcessingSupport.toDouble(finalData['vat']),
      total: BankProcessingSupport.toDouble(finalData['total']),
      fromAccount: finalData['from_account']?.toString(),
      toAccount: finalData['to_account']?.toString(),
      beneficiaryAccount: finalData['beneficiary_account']?.toString(),
      beneficiaryBank: finalData['beneficiary_bank']?.toString(),
      transactionType: finalData['transaction_type']?.toString(),
      reason: BankProcessingSupport.reasonOrEmpty(finalData['reason']),
      tillNumber: finalData['till_number']?.toString(),
      tin: finalData['tin']?.toString(),
      vatReg: finalData['vat_reg']?.toString(),
      parseSource: finalData['source']?.toString(),
    );

    final reason =
        BankProcessingSupport.cleanCandidate(finalData['reason']) ??
        BankProcessingSupport.cleanCandidate(finalData['transaction_type']) ??
        'General';
    final categoryEngine = CategoryEngine(db);
    String newCategory;
    if (dir == TransactionDirection.unknown) {
      newCategory = 'Uncategorized';
    } else if (BankProcessingSupport.isExplicitlyEmptyReason(finalData)) {
      newCategory = 'Empty';
    } else {
      newCategory = await categoryEngine.findOrCreateCategory(reason);
    }

    final newReason = finalData['reason']?.toString() ?? txn.reasonRawText;
    final amount = BankProcessingSupport.toDouble(finalData['amount']) ?? txn.amount;

    await (db.update(
      db.transactions,
    )..where((t) => t.id.equals(transactionId))).write(
      TransactionsCompanion(
        amount: Value(amount),
        counterpartyName: Value(finalData['counterparty']?.toString()),
        bankTransactionId: Value(finalData['transactionId']?.toString()),
        referenceNumber: Value(finalData['referenceNumber']?.toString()),
        balanceAfter: Value(
          BankProcessingSupport.toDouble(finalData['balance']) ??
              BankProcessingSupport.toDouble(finalData['balance_after']),
        ),
        receiptUrl: Value(url),
        reasonRawText: Value(newReason),
        normalizedReason: Value(newReason.toLowerCase().trim()),
        parsedCategory: Value(newCategory),
        commission: Value(BankProcessingSupport.toDouble(finalData['commission']) ?? 0.0),
        vat: Value(BankProcessingSupport.toDouble(finalData['vat']) ?? 0.0),
      ),
    );

    if (newCategory != txn.parsedCategory || newReason != txn.reasonRawText) {
      return ReparseResult(
        updated: true,
        message: 'Reparsed — category: $newCategory',
        newCategory: newCategory,
      );
    }
    return const ReparseResult(
      updated: false,
      message: 'No changes — data unchanged',
    );
  }

  String _runtimeSmsId(String address, String body) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seed = '$address|$body|$now';
    return 'rt_${seed.hashCode}_$now';
  }

  /// Retry failed extraction attempts for transactions
  /// Called automatically by background tasks or manually by UI
  Future<void> retryFailedExtractions({
    int limit = 50,
    int? transactionId,
  }) async {
    if (transactionId != null) {
      final txn = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
      if (txn == null) {
        debugPrint('[ExtractionRetry] Transaction $transactionId not found');
        return;
      }
      try {
        await _performExtractionRetry(txn);
      } catch (e) {
        debugPrint(
          '[ExtractionRetry] Error retrying transaction $transactionId: $e',
        );
      }
      return;
    }

    final readyForRetry = await db.getReadyForAutoRetry(limit: limit);

    for (final transaction in readyForRetry) {
      try {
        await _performExtractionRetry(transaction);
      } catch (e) {
        debugPrint(
          '[ExtractionRetry] Error retrying transaction ${transaction.id}: $e',
        );
      }
    }
  }

  /// Perform extraction retry for a single transaction
  Future<void> _performExtractionRetry(TransactionData transaction) async {
    final hasInternet = await NetworkStatusService.hasInternet();

    if (!hasInternet) {
      debugPrint(
        '[ExtractionRetry] No internet available, skipping retry for transaction ${transaction.id}',
      );
      return;
    }

    final bankLower = transaction.bankName?.toLowerCase() ?? '';
    final isCbe = bankLower.contains('cbe');
    final isTelebirr =
        bankLower.contains('telebirr') || bankLower.contains('ethio telecom');
    final isBoa = bankLower.contains('boa') || bankLower.contains('abyssinia');
    final receiptUrl = transaction.receiptUrl;

    if (receiptUrl == null || receiptUrl.isEmpty) {
      await db.updateExtractionStatusWithRetry(
        transaction.id,
        'no_receipt',
        null,
      );
      return;
    }

    try {
      final extractedData = isCbe
          ? await _cbeProcessor.parseReceipt(receiptUrl)
          : isTelebirr
          ? await _telebirrProcessor.parseReceipt(receiptUrl)
          : isBoa
          ? await _boaProcessor.parseReceipt(receiptUrl)
          : await _awashProcessor.parseReceipt(receiptUrl);

      if (extractedData.isEmpty) {
        await db.updateExtractionStatusWithRetry(
          transaction.id,
          'attempted_failed',
          'No data extracted from receipt',
        );
        return;
      }

      final newReason =
          (extractedData['reason']?.toString()) ?? transaction.reasonRawText;
      final categoryEngine = CategoryEngine(db);
      final newCategory = await categoryEngine.findOrCreateCategory(newReason);

      await (db.update(
        db.transactions,
      )..where((t) => t.id.equals(transaction.id))).write(
        TransactionsCompanion(
          reasonRawText: Value(newReason),
          normalizedReason: Value(newReason.toLowerCase().trim()),
          parsedCategory: Value(newCategory),
          receiptExtractionStatus: const Value('succeeded'),
          receiptExtractionError: const Value(null),
          receiptExtractionAttemptedAt: Value(
            DateTime.now().millisecondsSinceEpoch,
          ),
          extractionRetryAttempts: Value(
            transaction.extractionRetryAttempts + 1,
          ),
          extractionNextRetryAt: const Value(null),
        ),
      );
    } catch (e) {
      await db.updateExtractionStatusWithRetry(
        transaction.id,
        'attempted_failed',
        e.toString(),
      );
    }
  }
}
