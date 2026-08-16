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
import 'package:string_similarity/string_similarity.dart';
import 'package:faranka/features/transactions/domain/services/category_engine.dart';
import 'package:faranka/features/transactions/domain/usecases/processors/bank_processing_support.dart';

class OfflineDeepParseException implements Exception {
  final String message;

  const OfflineDeepParseException(this.message);

  @override
  String toString() => message;
}

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
  TransactionProcessor(this.db, {this.session});

  /// Decide whether the deep receipt fetch should run for [url]. When no
  /// session is provided we keep the historical behaviour (always attempt).
  Future<ReceiptFetchDecision> _decideDeepFetch(String? url) async {
    if (url == null || url.isEmpty) {
      return ReceiptFetchDecision.smsOnlyNoLink;
    }
    final decision = session == null
        ? ReceiptFetchDecision.fetch
        : await session!.decide(url);
    session?.recordDecision(decision);
    return decision;
  }

  String? _domainOf(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return null;
    }
  }

  void _markServerUnavailable(String url) {
    final domain = _domainOf(url);
    if (domain != null) session?.markServerUnavailable(domain);
  }

  /// Whether a server-unavailable outcome should be deferred (retried later).
  /// With a breaker session this only happens once the domain is confirmed
  /// down (consecutive failures >= threshold); without a session we keep the
  /// historical always-defer-on-failure behaviour.
  bool _isConfirmedBlocked(String url) {
    final domain = _domainOf(url);
    if (domain == null) return false;
    if (session == null) return true;
    return session!.isDomainBlocked(domain);
  }

  static bool _isNetworkError(Object? e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketerror') ||
        msg.contains('clientexception') ||
        msg.contains('timeoutexception') ||
        msg.contains('no route to host') ||
        msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('handshake exception') ||
        msg.contains('failed host lookup');
  }

  /// Detect a server-unavailable result from a receipt service fallback map
  /// (5xx status or a socket/timeout error buried in the error field).
  static bool _serverUnavailableFromResult(Map<String, dynamic> result) {
    final error =
        result['error']?.toString() ??
        result['html_error']?.toString() ??
        result['status_message']?.toString() ??
        '';
    final status =
        result['api_status_code'] ??
        result['pdf_status_code'] ??
        result['status_code'];
    if (status is num && status >= 500) return true;
    return _isNetworkError(error);
  }

  /// Marks a transaction as `attempted_failed` with a friendly server-down
  /// message so the existing backoff auto-retry machinery picks it up.
  Future<void> _scheduleServerDownRetry(String smsId, String bankLabel) async {
    final txn = await (db.select(
      db.transactions,
    )..where((t) => t.smsId.equals(smsId))).getSingleOrNull();
    if (txn == null) return;
    await db.updateExtractionStatusWithRetry(
      txn.id,
      'attempted_failed',
      '$bankLabel receipt server is down. Will retry automatically.',
    );
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
  Future<void> processIncomingSms(String body, String address) async {
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
                _fallbackTransactionType(finalData['direction']?.toString()) ??
                'Bank Transfer';
            finalData['source'] ??= 'sms_parse';
            _applyCbeCategoryHints(finalData, sms.body);
            finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
              finalData['reason']?.toString(),
            );
            if (_looksLikeCbeGenericDebitAlert(sms.body) &&
                !_hasMeaningfulCbeReason(finalData['reason'])) {
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
                _fallbackTransactionType(finalData['direction']?.toString()) ??
                smsData['transaction_type'] ??
                'Bank Transfer';
            finalData['source'] ??= 'sms_parse';
            finalData['reason'] = _resolveTelebirrCategoryReason(finalData);
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
                _fallbackTransactionType(finalData['direction']?.toString()) ??
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
            // Real BoA credit receipts never return the sender ("Payer's Name"),
            // so the SMS "credited ... by <name>" is the source of the
            // counterparty and must win over receipt-derived values.
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
            finalData['transaction_type'] ??= _fallbackTransactionType(
              finalData['direction']?.toString(),
            );
            finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
              finalData['reason']?.toString(),
            );
            _applyAwashCategoryHints(finalData, sms.body);
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
              _fallbackTransactionType(smsData['direction']?.toString()) ??
              'Bank Transfer',
          'reason': smsData['counterparty'],
          'url': smsData['url'],
          'direction': smsData['direction'],
          'balance': smsData['balance'],
          'counterparty': smsData['counterparty'],
          'transaction_ref': smsData['transactionId'],
        };
        _applyCbeCategoryHints(finalData, sms.body);
        if (_looksLikeCbeGenericDebitAlert(sms.body) &&
            !_hasMeaningfulCbeReason(finalData['reason'])) {
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
              _fallbackTransactionType(smsData['direction']?.toString()) ??
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
              _fallbackTransactionType(smsData['direction']?.toString()) ??
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
        finalData['transaction_type'] ??= _fallbackTransactionType(
          finalData['direction']?.toString(),
        );
        _applyAwashCategoryHints(finalData, sms.body);
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
      amount: _toDouble(finalData['amount']),
      commission: _toDouble(finalData['commission']),
      vat: _toDouble(finalData['vat']),
      total: _toDouble(finalData['total']),
      fromAccount: finalData['from_account']?.toString(),
      toAccount: finalData['to_account']?.toString(),
      beneficiaryAccount: finalData['beneficiary_account']?.toString(),
      beneficiaryBank: finalData['beneficiary_bank']?.toString(),
      transactionType: finalData['transaction_type']?.toString(),
      reason: _reasonOrEmpty(finalData['reason']),
      tillNumber: finalData['till_number']?.toString(),
      tin: finalData['tin']?.toString(),
      vatReg: finalData['vat_reg']?.toString(),
      parseSource: finalData['source']?.toString(),
    );

    final reason =
        _cleanCandidate(finalData['reason']) ??
        _cleanCandidate(finalData['transaction_type']) ??
        'General';
    final categoryEngine = CategoryEngine(db);
    String newCategory;
    if (dir == TransactionDirection.unknown) {
      newCategory = 'Uncategorized';
    } else if (_isExplicitlyEmptyReason(finalData)) {
      newCategory = 'Empty';
    } else {
      newCategory = await categoryEngine.findOrCreateCategory(reason);
    }

    final newReason = finalData['reason']?.toString() ?? txn.reasonRawText;
    final amount = _toDouble(finalData['amount']) ?? txn.amount;

    await (db.update(
      db.transactions,
    )..where((t) => t.id.equals(transactionId))).write(
      TransactionsCompanion(
        amount: Value(amount),
        counterpartyName: Value(finalData['counterparty']?.toString()),
        bankTransactionId: Value(finalData['transactionId']?.toString()),
        referenceNumber: Value(finalData['referenceNumber']?.toString()),
        balanceAfter: Value(
          _toDouble(finalData['balance']) ??
              _toDouble(finalData['balance_after']),
        ),
        receiptUrl: Value(url),
        reasonRawText: Value(newReason),
        normalizedReason: Value(newReason.toLowerCase().trim()),
        parsedCategory: Value(newCategory),
        commission: Value(_toDouble(finalData['commission']) ?? 0.0),
        vat: Value(_toDouble(finalData['vat']) ?? 0.0),
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

  /// 2. UPDATED METHOD: For manual imports and internal logic
  Future<void> processAwashSms(SmsInboxData sms) async {
    if (!sms.body.contains('ETB')) {
      await db.markAsProcessed(sms.id);
      return;
    }

    // Mobile cashout notification (message 2): skip import, retroactively
    // update the matching debit transaction to "mobile cashout" category.
    if (AwashReceiptService.isMobileCashoutNotification(sms.body)) {
      await _handleCashoutNotification(sms);
      return;
    }

    // A. Basic SMS Parse
    final smsData = AwashSmsParser.parseAll(sms.body);
    final String? url = smsData['url'];

    final String? txnId = smsData['transactionId']?.toString();
    final double amount = _toDouble(smsData['amount']) ?? 0.0;
    final dir = smsData['direction'] == 'Credit'
        ? TransactionDirection.credit
        : smsData['direction'] == 'Debit'
        ? TransactionDirection.debit
        : TransactionDirection.unknown;
    final String? cName = smsData['counterparty']?.toString();
    final String? cNum = smsData['counterpartyNumber']?.toString();

    bool isDuplicate = false;

    if (txnId != null && txnId.isNotEmpty) {
      // Check exact ID
      final existing = await (db.select(
        db.transactions,
      )..where((t) => t.bankTransactionId.equals(txnId))).getSingleOrNull();
      isDuplicate = existing != null;
    } else {
      // Check fuzzy match when no transaction ID exists.
      isDuplicate = await _isDuplicateFuzzy(
        amount: amount,
        time: sms.date,
        dir: dir,
        counterpartyName: cName,
        counterpartyNumber: cNum,
      );
    }

    if (isDuplicate) {
      await db.markAsProcessed(sms.id);
      return;
    }
    Map<String, dynamic> finalData = {};
    bool serverDown = false;

    // B. Deep Scan (HTML Scrape)
    if (url != null && url.isNotEmpty) {
      final online = await NetworkStatusService.hasInternet();
      if (!online) {
        throw const OfflineDeepParseException(
          'No internet connection. Deep scan skipped.',
        );
      }
      final decision = await _decideDeepFetch(url);
      if (decision == ReceiptFetchDecision.fetch) {
        try {
          finalData = await AwashReceiptService.fetchAndParseHtmlReceipt(
            url,
            smsText: sms.body,
          );
          if (_serverUnavailableFromResult(finalData)) {
            _markServerUnavailable(url);
            serverDown = _isConfirmedBlocked(url);
          }
        } catch (e) {
          if (_isNetworkError(e)) {
            _markServerUnavailable(url);
            serverDown = _isConfirmedBlocked(url);
          }
          finalData = AwashReceiptService.parseSmsForReceiptFields(sms.body);
        }
      } else {
        finalData = AwashReceiptService.parseSmsForReceiptFields(sms.body);
        if (decision == ReceiptFetchDecision.smsOnlyDomainBlocked) {
          serverDown = true;
        }
      }
    }

    // Preserve direction from SMS parser when deep parser doesn't provide it.
    finalData['direction'] ??= smsData['direction'];
    finalData['balance'] ??= smsData['balance'];
    finalData['transaction_type'] ??= _fallbackTransactionType(
      finalData['direction']?.toString(),
    );
    finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
      finalData['reason']?.toString(),
    );
    _applyAwashCategoryHints(finalData, sms.body);

    // If we attempted a deep-parse (receipt URL present), prefer receipt
    // extracted counterparty/payer/receiver names over SMS-extracted values.
    if (url != null) {
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
    // C. Update SmsInbox Table using your extension method
    await db.updateSmsParsedFields(
      smsId: sms.id,
      transactionId:
          finalData['transaction_id']?.toString() ?? smsData['transactionId'],
      date: finalData['date']?.toString(),
      time: finalData['time']?.toString(),
      amount: _toDouble(finalData['amount']),
      commission:
          _toDouble(finalData['commission']) ?? _toDouble(finalData['charge']),
      vat: _toDouble(finalData['vat']),
      total: _toDouble(finalData['total']),
      fromAccount: finalData['from_account']?.toString(),
      toAccount: finalData['to_account']?.toString(),
      beneficiaryAccount:
          finalData['beneficiary_account']?.toString() ??
          finalData['beneficiary_acct']?.toString(),
      beneficiaryBank: finalData['beneficiary_bank']?.toString(),
      transactionType: finalData['transaction_type']?.toString(),
      reason: finalData['reason']?.toString(),
      tillNumber: finalData['till_number']?.toString(),
      tin: finalData['tin']?.toString(),
      vatReg: finalData['vat_reg']?.toString(),
      parseSource:
          finalData['source']?.toString() ?? (url != null ? 'HTML' : 'SMS'),
    );

    // D. Move to final Ledger (Transactions Table)
    // We re-fetch the updated record to ensure it has all the new fields
    final updatedSms = await (db.select(
      db.smsInbox,
    )..where((t) => t.id.equals(sms.id))).getSingle();

    final forceUncategorized = _shouldForceUncategorizedCategory(
      source: finalData['source']?.toString(),
      hadDeepParseAttempt: url != null,
    );

    // Categorize all transactions except unknown direction or hard failures.
    // Credits are categorized but filtered out from spending breakdown in UI.
    if (forceUncategorized || dir == TransactionDirection.unknown) {
      finalData['parsedCategory'] = 'Uncategorized';
    } else {
      // Check if reason field exists in receipt but is explicitly empty (user didn't fill it)
      if (_isExplicitlyEmptyReason(finalData)) {
        finalData['parsedCategory'] = 'Empty';
      } else {
        final categoryEngine = CategoryEngine(db);
        final reason =
            _cleanCandidate(finalData['reason']) ??
            _cleanCandidate(finalData['transaction_type']) ??
            'General';
        finalData['parsedCategory'] = await categoryEngine.findOrCreateCategory(
          reason,
        );
      }
    }

    final localPath = finalData['localReceiptPath'] as String?;
    await db.importAwashToTransactions(
      parsedData: finalData,
      originalSms: updatedSms,
      bankName: 'Awash Bank',
      defaultReason: 'Awash Bank Transaction',
      localImagePath: localPath,
    );

    if (serverDown) {
      await _scheduleServerDownRetry(sms.id, 'Awash Bank');
    }
  }

  Future<void> processCbeSms(SmsInboxData sms) async {
    if (!sms.body.contains('ETB')) {
      await db.markAsProcessed(sms.id);
      return;
    }
    final smsData = CbeSmsParser.parseAll(sms.body);
    final String? url = smsData['url']?.toString();

    final String? txnId = smsData['transactionId']?.toString();
    final double amount = _toDouble(smsData['amount']) ?? 0.0;
    final dir = smsData['direction'] == 'Credit'
        ? TransactionDirection.credit
        : smsData['direction'] == 'Debit'
        ? TransactionDirection.debit
        : TransactionDirection.unknown;
    final String? cName = smsData['counterparty']?.toString();

    bool isDuplicate = false;
    if (txnId != null && txnId.isNotEmpty) {
      final existing = await (db.select(
        db.transactions,
      )..where((t) => t.bankTransactionId.equals(txnId))).getSingleOrNull();
      isDuplicate = existing != null;
    } else {
      isDuplicate = await _isDuplicateFuzzy(
        amount: amount,
        time: sms.date,
        dir: dir,
        counterpartyName: cName,
      );
    }

    if (isDuplicate) {
      await db.markAsProcessed(sms.id);
      return;
    }

    Map<String, dynamic> finalData = <String, dynamic>{
      'source': smsData['source'] ?? 'sms_parse',
      'transaction_id': smsData['transactionId'],
      'date': smsData['date'],
      'time': smsData['time'],
      'amount': smsData['amount'],
      'commission': smsData['commission'],
      'vat': smsData['vat'],
      'total': smsData['total'],
      'from_account': smsData['account'],
      'to_account': url == null ? smsData['counterparty'] : null,
      'beneficiary_account': null,
      'beneficiary_bank': null,
      'transaction_type':
          _fallbackTransactionType(smsData['direction']?.toString()) ??
          'Bank Transfer',
      'reason': url == null ? smsData['counterparty'] : null,
      'till_number': null,
      'tin': null,
      'vat_reg': null,
      'url': smsData['url'],
      'direction': smsData['direction'],
      'balance': smsData['balance'],
      'counterparty': url == null ? smsData['counterparty'] : null,
      'transaction_ref': smsData['transactionId'],
    };

    bool receiptFetchFailed = false;
    bool serverDown = false;

    if (url != null && url.isNotEmpty) {
      final online = await NetworkStatusService.hasInternet();
      if (!online) {
        throw const OfflineDeepParseException(
          'No internet connection. Deep scan skipped.',
        );
      }
      final decision = await _decideDeepFetch(url);
      if (decision == ReceiptFetchDecision.fetch) {
        final deepData = await CbeReceiptService.fetchAndParseReceipt(
          url,
          smsText: sms.body,
        );

        finalData = {...finalData, ...deepData};

        if (_serverUnavailableFromResult(deepData)) {
          _markServerUnavailable(url);
          serverDown = _isConfirmedBlocked(url);
        }

        if (serverDown) {
          final statusCode =
              deepData['api_status_code'] ?? deepData['pdf_status_code'];
          if (statusCode != null && statusCode >= 500) {
            receiptFetchFailed = true;
            finalData['source'] = 'cbe_server_error_$statusCode';
          } else if (deepData['source'] == 'cbe_v2_api_error_page') {
            receiptFetchFailed = true;
          }
        }
      } else if (decision == ReceiptFetchDecision.smsOnlyDomainBlocked ||
          decision == ReceiptFetchDecision.smsOnlySuspect) {
        // A single suspect outage (below the circuit-breaker threshold) must
        // still import from SMS and schedule a retry so a slow-but-alive CBE
        // server can re-parse the link later.
        serverDown = true;
        finalData['counterparty'] ??= smsData['counterparty'];
        finalData['reason'] ??= smsData['counterparty'];
        finalData['to_account'] ??= smsData['counterparty'];
      }
    }

    // Keep SMS parse as fallback when PDF parse misses fields.
    finalData['url'] ??= url;
    finalData['transaction_id'] ??=
        finalData['referenceNumber'] ?? smsData['transactionId'];
    finalData['transaction_ref'] ??=
        finalData['referenceNumber'] ?? smsData['transactionId'];
    finalData['date'] ??= finalData['paymentDate'] ?? smsData['date'];
    finalData['time'] ??= finalData['paymentTime'] ?? smsData['time'];
    finalData['amount'] ??= finalData['transferredAmount'] ?? smsData['amount'];
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
        (url == null ? smsData['counterparty'] : null);
    finalData['direction'] ??= smsData['direction'];
    finalData['balance'] ??= smsData['balance'];
    finalData['counterparty'] ??= finalData['to_account'];
    finalData['transaction_type'] ??=
        _fallbackTransactionType(finalData['direction']?.toString()) ??
        'Bank Transfer';
    finalData['source'] ??= 'sms_parse';
    final isGenericDebitAlert = _looksLikeCbeGenericDebitAlert(sms.body);
    _applyCbeCategoryHints(finalData, sms.body);
    finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
      finalData['reason']?.toString(),
    );
    if (isGenericDebitAlert && !_hasMeaningfulCbeReason(finalData['reason'])) {
      finalData['reason'] = '';
    }
    if (finalData['reason']?.isEmpty == true && url != null) {
      finalData['reason'] = 'Empty';
    }

    // Prefer receipt (deep-parse) names when a receipt URL exists.
    if (url != null && url.isNotEmpty) {
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

    await db.updateSmsParsedFields(
      smsId: sms.id,
      transactionId:
          finalData['transaction_id']?.toString() ??
          finalData['transaction_ref']?.toString(),
      date: finalData['date']?.toString(),
      time: finalData['time']?.toString(),
      amount: _toDouble(finalData['amount']),
      commission: _toDouble(finalData['commission']),
      vat: _toDouble(finalData['vat']),
      total: _toDouble(finalData['total']),
      fromAccount: finalData['from_account']?.toString(),
      toAccount: finalData['to_account']?.toString(),
      beneficiaryAccount: finalData['beneficiary_account']?.toString(),
      beneficiaryBank: finalData['beneficiary_bank']?.toString(),
      transactionType: finalData['transaction_type']?.toString(),
      reason: _reasonOrEmpty(finalData['reason']),
      tillNumber: null,
      tin: null,
      vatReg: null,
      parseSource: finalData['source']?.toString(),
    );

    final updatedSms = await (db.select(
      db.smsInbox,
    )..where((t) => t.id.equals(sms.id))).getSingle();

    // Categorize all transactions except unknown direction.
    // Credits are categorized but filtered out from spending breakdown in UI.
    if (dir == TransactionDirection.unknown) {
      finalData['parsedCategory'] = 'Uncategorized';
    } else {
      // Check if reason field exists in receipt but is explicitly empty (user didn't fill it)
      if (_isExplicitlyEmptyReason(finalData)) {
        finalData['parsedCategory'] = 'Empty';
      } else {
        final categoryEngine = CategoryEngine(db);
        final reason =
            _cleanCandidate(finalData['reason']) ??
            _cleanCandidate(finalData['transaction_type']) ??
            'General';
        finalData['parsedCategory'] = await categoryEngine.findOrCreateCategory(
          reason,
        );
      }
    }

    final localPath = finalData['localReceiptPath'] as String?;
    await db.importAwashToTransactions(
      parsedData: finalData,
      originalSms: updatedSms,
      bankName: 'CBE',
      defaultReason: 'CBE Transaction',
      localImagePath: localPath,
    );

    if (receiptFetchFailed || serverDown) {
      final txn = await (db.select(
        db.transactions,
      )..where((t) => t.smsId.equals(sms.id))).getSingleOrNull();
      if (txn != null) {
        final sourceStr = finalData['source']?.toString() ?? '';
        final codeMatch = RegExp(r'(\d+)').firstMatch(sourceStr);
        final errorMsg = serverDown
            ? 'CBE receipt server is down. Will retry automatically.'
            : codeMatch != null
            ? BankProcessingSupport.serverErrorMessage(
                int.parse(codeMatch.group(1)!),
              )
            : sourceStr;
        await db.updateExtractionStatusWithRetry(
          txn.id,
          'attempted_failed',
          errorMsg,
        );
      }
    }
  }

  Future<void> processTelebirrSms(SmsInboxData sms) async {
    if (!sms.body.contains('ETB')) {
      await db.markAsProcessed(sms.id);
      return;
    }

    final smsData = TelebirrSmsParser.parseAll(sms.body);
    final String? url = smsData['url']?.toString();

    final String? txnId = smsData['transactionId']?.toString();
    final double amount = _toDouble(smsData['amount']) ?? 0.0;
    final dir = smsData['direction'] == 'Credit'
        ? TransactionDirection.credit
        : smsData['direction'] == 'Debit'
        ? TransactionDirection.debit
        : TransactionDirection.unknown;
    final String? cName = smsData['counterparty']?.toString();
    final String? cNum = smsData['counterpartyNumber']?.toString();

    bool isDuplicate = false;
    if (txnId != null && txnId.isNotEmpty) {
      final existing = await (db.select(
        db.transactions,
      )..where((t) => t.bankTransactionId.equals(txnId))).getSingleOrNull();
      isDuplicate = existing != null;
    } else {
      isDuplicate = await _isDuplicateFuzzy(
        amount: amount,
        time: sms.date,
        dir: dir,
        counterpartyName: cName,
        counterpartyNumber: cNum,
      );
    }

    if (isDuplicate) {
      await db.markAsProcessed(sms.id);
      return;
    }

    Map<String, dynamic> finalData = <String, dynamic>{
      'source': smsData['source'] ?? 'sms_parse',
      'transaction_id': smsData['transactionId'],
      'date': smsData['date'],
      'time': smsData['time'],
      'amount': smsData['amount'],
      'commission': smsData['commission'],
      'vat': smsData['vat'],
      'total': smsData['total'],
      'from_account': smsData['counterpartyNumber'],
      'to_account': url == null ? smsData['counterparty'] : null,
      'transaction_type':
          smsData['transaction_type'] != null &&
              smsData['transaction_type'] != 'Unknown'
          ? smsData['transaction_type']
          : _fallbackTransactionType(smsData['direction']?.toString()) ??
                'Bank Transfer',
      'reason': smsData['counterparty'],
      'url': smsData['url'],
      'direction': smsData['direction'],
      'balance': smsData['balance'],
      'counterparty': url == null ? smsData['counterparty'] : null,
      'isAirtime': smsData['isAirtime'],
      'transaction_ref': smsData['transactionId'],
    };

    bool serverDown = false;

    if (url != null && url.isNotEmpty) {
      final online = await NetworkStatusService.hasInternet();
      if (!online) {
        throw const OfflineDeepParseException(
          'No internet connection. Deep scan skipped.',
        );
      }
      final decision = await _decideDeepFetch(url);
      if (decision == ReceiptFetchDecision.fetch) {
        final deepData = await TelebirrReceiptService.fetchAndParseReceipt(
          url,
          smsText: sms.body,
        );

        finalData = {...finalData, ...deepData};

        if (_serverUnavailableFromResult(deepData)) {
          _markServerUnavailable(url);
          serverDown = _isConfirmedBlocked(url);
        }

        // Keep SMS parse as fallback when receipt parse misses fields.
        finalData['url'] ??= url;
        finalData['transaction_id'] ??=
            finalData['referenceNumber'] ?? smsData['transactionId'];
        finalData['transaction_ref'] ??=
            finalData['referenceNumber'] ?? smsData['transactionId'];
        finalData['date'] ??= finalData['paymentDate'] ?? smsData['date'];
        finalData['time'] ??= finalData['paymentTime'] ?? smsData['time'];
        finalData['amount'] ??= finalData['settledAmount'] ?? smsData['amount'];
        finalData['commission'] ??= smsData['commission'];
        finalData['vat'] ??= smsData['vat'];
        finalData['total'] ??= finalData['totalPaidAmount'] ?? smsData['total'];
        finalData['from_account'] ??=
            finalData['payerNumber'] ?? smsData['counterpartyNumber'];
        finalData['to_account'] ??=
            finalData['receiverNumber'] ?? smsData['counterparty'];
        finalData['direction'] ??= smsData['direction'];
        finalData['balance'] ??= smsData['balance'];
        finalData['counterparty'] ??= finalData['to_account'];
        finalData['transaction_type'] ??=
            _fallbackTransactionType(finalData['direction']?.toString()) ??
            smsData['transaction_type'] ??
            'Bank Transfer';
        finalData['source'] ??= 'sms_parse';
      } else if (decision == ReceiptFetchDecision.smsOnlyDomainBlocked) {
        serverDown = true;
        finalData['counterparty'] ??= smsData['counterparty'];
        finalData['to_account'] ??= smsData['counterparty'];
      }
    }

    // Categorization: customer note → payment reason → name → type → General.
    finalData['reason'] = _resolveTelebirrCategoryReason(finalData);
    if (finalData['reason']?.isEmpty == true) {
      finalData['reason'] = 'Empty';
    }

// Real BoA receipts name only the receiver (the account holder), never the
    // sender, so for credits the SMS "credited ... by <name>" is the only
    // source of the counterparty and must win over receipt-derived values.
    if (url != null && url.isNotEmpty) {
      finalData['counterparty'] = dir == TransactionDirection.credit
          ? (smsData['counterparty'] ??
                finalData['payerName'] ??
                finalData['from_account'] ??
                finalData['counterparty'])
          : (finalData['receiverName'] ??
                finalData['to_account'] ??
                finalData['counterparty'] ??
                smsData['counterparty']);
    }

    await db.updateSmsParsedFields(
      smsId: sms.id,
      transactionId:
          finalData['transaction_id']?.toString() ??
          finalData['transaction_ref']?.toString(),
      date: finalData['date']?.toString(),
      time: finalData['time']?.toString(),
      amount: _toDouble(finalData['amount']),
      commission: _toDouble(finalData['commission']),
      vat: _toDouble(finalData['vat']),
      total: _toDouble(finalData['total']),
      fromAccount: finalData['from_account']?.toString(),
      toAccount: finalData['to_account']?.toString(),
      beneficiaryAccount: finalData['beneficiary_account']?.toString(),
      beneficiaryBank: finalData['beneficiary_bank']?.toString(),
      transactionType: finalData['transaction_type']?.toString(),
      reason: _reasonOrEmpty(finalData['reason']),
      tillNumber: null,
      tin: null,
      vatReg: null,
      parseSource: finalData['source']?.toString(),
    );

    final updatedSms = await (db.select(
      db.smsInbox,
    )..where((t) => t.id.equals(sms.id))).getSingle();

    // Categorize all transactions except unknown direction.
    if (dir == TransactionDirection.unknown) {
      finalData['parsedCategory'] = 'Uncategorized';
    } else {
      if (_isExplicitlyEmptyReason(finalData)) {
        finalData['parsedCategory'] = 'Empty';
      } else {
        final categoryEngine = CategoryEngine(db);
        final reason =
            _cleanCandidate(finalData['reason']) ??
            _cleanCandidate(finalData['transaction_type']) ??
            'General';
        finalData['parsedCategory'] = await categoryEngine.findOrCreateCategory(
          reason,
        );
      }
    }

    final localPath = finalData['localReceiptPath'] as String?;
    await db.importAwashToTransactions(
      parsedData: finalData,
      originalSms: updatedSms,
      bankName: 'Telebirr',
      defaultReason: 'Telebirr Transaction',
      localImagePath: localPath,
    );

    if (serverDown) {
      await _scheduleServerDownRetry(sms.id, 'Telebirr');
    }
  }

  Future<void> processBoaSms(SmsInboxData sms) async {
    if (!sms.body.contains('ETB')) {
      await db.markAsProcessed(sms.id);
      return;
    }

    final smsData = BoaSmsParser.parseAll(sms.body);
    final String? url = smsData['url']?.toString();

    final String? txnId = smsData['transactionId']?.toString();
    final double amount = _toDouble(smsData['amount']) ?? 0.0;
    final dir = smsData['direction'] == 'Credit'
        ? TransactionDirection.credit
        : smsData['direction'] == 'Debit'
        ? TransactionDirection.debit
        : TransactionDirection.unknown;
    final String? cName = smsData['counterparty']?.toString();

    bool isDuplicate = false;
    if (txnId != null && txnId.isNotEmpty) {
      final existing = await (db.select(
        db.transactions,
      )..where((t) => t.bankTransactionId.equals(txnId))).getSingleOrNull();
      isDuplicate = existing != null;
    } else {
      isDuplicate = await _isDuplicateFuzzy(
        amount: amount,
        time: sms.date,
        dir: dir,
        counterpartyName: cName,
      );
    }

    if (isDuplicate) {
      await db.markAsProcessed(sms.id);
      return;
    }

    Map<String, dynamic> finalData = <String, dynamic>{
      'source': smsData['source'] ?? 'sms_parse',
      'transaction_id': smsData['transactionId'],
      'date': smsData['date'],
      'time': smsData['time'],
      'amount': smsData['amount'],
      'commission': smsData['commission'],
      'vat': smsData['vat'],
      'total': smsData['total'],
      'from_account': smsData['account'],
      'to_account': url == null ? smsData['counterparty'] : null,
      'transaction_type':
          _fallbackTransactionType(smsData['direction']?.toString()) ??
          'Bank Transfer',
      'reason': url == null ? smsData['counterparty'] : null,
      'url': smsData['url'],
      'direction': smsData['direction'],
      'balance': smsData['balance'],
      'counterparty': url == null ? smsData['counterparty'] : null,
      'transaction_ref': smsData['transactionId'],
    };

    bool serverDown = false;

    if (url != null && url.isNotEmpty) {
      final online = await NetworkStatusService.hasInternet();
      if (!online) {
        throw const OfflineDeepParseException(
          'No internet connection. Deep scan skipped.',
        );
      }
      final decision = await _decideDeepFetch(url);
      if (decision == ReceiptFetchDecision.fetch) {
        final deepData = await BoaReceiptService.fetchAndParseReceipt(
          url,
          smsText: sms.body,
        );

        finalData = {...finalData, ...deepData};

        if (_serverUnavailableFromResult(deepData)) {
          _markServerUnavailable(url);
          serverDown = _isConfirmedBlocked(url);
        }

        // Keep SMS parse as fallback when receipt parse misses fields.
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
        finalData['transaction_type'] =
            finalData['transactionType'] ??
            _fallbackTransactionType(finalData['direction']?.toString()) ??
            'Bank Transfer';
        finalData['source'] ??= 'sms_parse';
      } else if (decision == ReceiptFetchDecision.smsOnlyDomainBlocked) {
        serverDown = true;
        finalData['counterparty'] ??= smsData['counterparty'];
        finalData['reason'] ??= smsData['counterparty'];
        finalData['to_account'] ??= smsData['counterparty'];
      }
    }

    if (finalData['reason']?.isEmpty != false) {
      finalData['reason'] = BankProcessingSupport.resolveBoaCategoryReason(
        finalData,
      );
    }
    finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
      finalData['reason']?.toString(),
    );
    if (finalData['reason']?.isEmpty == true && url != null) {
      finalData['reason'] = 'Empty';
    }

    // Real BoA credit receipts never return the sender ("Payer's Name"), so
    // the SMS "credited ... by <name>" is the only source of the counterparty
    // and must win over receipt-derived values.
    if (url != null && url.isNotEmpty) {
      finalData['counterparty'] = dir == TransactionDirection.credit
          ? (smsData['counterparty'] ??
                finalData['payerName'] ??
                finalData['from_account'] ??
                finalData['counterparty'])
          : (finalData['receiverName'] ??
                finalData['to_account'] ??
                finalData['counterparty'] ??
                smsData['counterparty']);
    }

    await db.updateSmsParsedFields(
      smsId: sms.id,
      transactionId:
          finalData['transaction_id']?.toString() ??
          finalData['transaction_ref']?.toString(),
      date: finalData['date']?.toString(),
      time: finalData['time']?.toString(),
      amount: _toDouble(finalData['amount']),
      commission: _toDouble(finalData['commission']),
      vat: _toDouble(finalData['vat']),
      total: _toDouble(finalData['total']),
      fromAccount: finalData['from_account']?.toString(),
      toAccount: finalData['to_account']?.toString(),
      beneficiaryAccount: finalData['beneficiary_account']?.toString(),
      beneficiaryBank: finalData['beneficiary_bank']?.toString(),
      transactionType: finalData['transaction_type']?.toString(),
      reason: _reasonOrEmpty(finalData['reason']),
      tillNumber: null,
      tin: null,
      vatReg: null,
      parseSource: finalData['source']?.toString(),
    );

    final updatedSms = await (db.select(
      db.smsInbox,
    )..where((t) => t.id.equals(sms.id))).getSingle();

    // Categorize all transactions except unknown direction.
    if (dir == TransactionDirection.unknown) {
      finalData['parsedCategory'] = 'Uncategorized';
    } else {
      if (_isExplicitlyEmptyReason(finalData)) {
        finalData['parsedCategory'] = 'Empty';
      } else {
        final categoryEngine = CategoryEngine(db);
        final reason =
            _cleanCandidate(finalData['reason']) ??
            _cleanCandidate(finalData['transaction_type']) ??
            'General';
        finalData['parsedCategory'] = await categoryEngine.findOrCreateCategory(
          reason,
        );
      }
    }

    final localPath = finalData['localReceiptPath'] as String?;
    await db.importAwashToTransactions(
      parsedData: finalData,
      originalSms: updatedSms,
      bankName: 'BoA',
      defaultReason: 'Bank of Abyssinia Transaction',
      localImagePath: localPath,
    );

    if (serverDown) {
      await _scheduleServerDownRetry(sms.id, 'BoA');
    }
  }

  Future<bool> _isDuplicateFuzzy({
    required double amount,
    required DateTime time,
    required TransactionDirection dir,
    String? counterpartyName,
    String? counterpartyNumber,
  }) async {
    // 1. Time Window: 5 minutes before/after
    final windowStart = time
        .subtract(const Duration(minutes: 5))
        .millisecondsSinceEpoch;
    final windowEnd = time
        .add(const Duration(minutes: 5))
        .millisecondsSinceEpoch;

    // 2. Initial DB Query (Broad filters)
    final query = db.select(db.transactions)
      ..where((t) => t.amount.equals(amount))
      ..where((t) => t.direction.equalsValue(dir))
      ..where((t) => t.smsTimestamp.isBetweenValues(windowStart, windowEnd));

    final potentialMatches = await query.get();

    if (potentialMatches.isEmpty) return false;

    // 3. Fine-grained filtering (Meters)
    for (var existing in potentialMatches) {
      bool isMatch = false;

      // Meter A: Account Number Match (Very strong signal)
      if (counterpartyNumber != null && existing.counterpartyNumber != null) {
        if (counterpartyNumber == existing.counterpartyNumber) isMatch = true;
      }

      // Meter B: Normalized Name Match
      if (!isMatch &&
          counterpartyName != null &&
          existing.counterpartyName != null) {
        String n1 = _normalize(counterpartyName);
        String n2 = _normalize(existing.counterpartyName!);

        // If names are 85% similar, consider it the same person
        if (n1.similarityTo(n2) > 0.85) isMatch = true;
      }

      // Meter C: Fallback (if no name/number exists in both rows)
      if (!isMatch &&
          counterpartyName == null &&
          existing.counterpartyName == null) {
        isMatch = true;
      }

      if (isMatch) return true;
    }

    return false;
  }

  // Helper to normalize strings for comparison
  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

  String? _cleanCandidate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final cleaned = raw
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'^[\s\-,:;./]+|[\s\-,:;./]+$'), '')
        .trim();

    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  /// Detects if the reason field was explicitly extracted from receipt but is empty.
  /// This differentiates between:
  /// - Empty reason (field exists in receipt but user/system left it blank) → 'Empty' category
  /// - Missing reason (field doesn't exist in receipt format) → use fallback chain
  bool _isExplicitlyEmptyReason(Map<String, dynamic> data) {
    if (!data.containsKey('reason')) {
      return false; // Field doesn't exist in receipt format
    }

    final reason = data['reason'];
    if (reason is String) {
      return reason.trim().isEmpty; // Field exists but is empty/whitespace-only
    }

    return reason == null; // Field exists but is null
  }

  String? _fallbackTransactionType(String? directionHint) {
    final direction = (directionHint ?? '').toLowerCase();
    if (direction.contains('debit')) return 'Debit';
    if (direction.contains('credit')) return 'Credit Alert';
    return null;
  }

  void _applyAwashCategoryHints(Map<String, dynamic> data, String smsBody) {
    if (_looksLikeAwashAirtimeSms(smsBody)) {
      data['transaction_type'] = 'Airtime Purchase';
      data['reason'] = 'Airtime';
    }
  }

  bool _looksLikeAwashAirtimeSms(String smsBody) {
    final normalized = smsBody.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = normalized.toLowerCase();
    final hasAirtimeMarker =
        lower.contains('bought airtime') ||
        lower.contains('airtime worth') ||
        lower.contains('airtime purchase');

    if (hasAirtimeMarker) return true;

    final hasSentToBankPattern = RegExp(
      r'\byou\s+have\s+sent\s+etb\s*-?\s*[\d,]+(?:\.\d+)?\s+to\s+\d{8,}/bank\b',
      caseSensitive: false,
    ).hasMatch(normalized);

    if (!hasSentToBankPattern) return false;

    final hasReceiptLink = lower.contains('awashpay.awashbank.com');
    final hasProcoinMarker = lower.contains('procoin');
    return hasReceiptLink || hasProcoinMarker;
  }

  void _applyCbeCategoryHints(Map<String, dynamic> data, String smsBody) {
    if (!_looksLikeCbeGenericDebitAlert(smsBody)) return;

    final existingReason = _cleanCandidate(data['reason'])?.toLowerCase();
    final existingType = _cleanCandidate(
      data['transaction_type'],
    )?.toLowerCase();
    final transferCounterparty =
        _cleanCandidate(data['to_account']) ??
        _cleanCandidate(data['counterparty']);
    final looksLikeTransferToPerson =
        transferCounterparty != null &&
        smsBody.toLowerCase().contains('transferred') &&
        !smsBody.toLowerCase().contains('service fee');

    final hasNoisyReceiptReason =
        existingReason != null &&
        (existingReason.startsWith('transferred amount') ||
            existingReason.startsWith('commission') ||
            existingReason.startsWith('total amount debited') ||
            existingReason.startsWith('vat') ||
            existingReason.startsWith('15 vat') ||
            existingReason.contains('transferred amount etb'));

    // Keep PDF/SMS parsed semantics; only fill in missing generic values.
    if (existingReason == null ||
        existingReason == 'cbe transaction' ||
        hasNoisyReceiptReason) {
      data['reason'] = looksLikeTransferToPerson
          ? transferCounterparty
          : 'Debit';
    }

    if (existingType == null || existingType == 'bank transfer') {
      data['transaction_type'] = 'Debit';
    }
  }

  bool _looksLikeCbeGenericDebitAlert(String smsBody) {
    final normalized = smsBody.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = normalized.toLowerCase();

    final hasDebitSignal =
        lower.contains('has been debited') ||
        lower.contains('debited with etb');
    final hasBalanceSignal = lower.contains('current balance');
    final hasReceiptSignal = lower.contains('apps.cbe.com.et');

    return hasDebitSignal && hasBalanceSignal && hasReceiptSignal;
  }

  bool _hasMeaningfulCbeReason(dynamic value) {
    final cleaned = _cleanCandidate(value);
    if (cleaned == null) return false;

    final lower = cleaned.toLowerCase();
    if (lower == 'debit alert' || lower == 'cbe transaction') return false;

    return true;
  }

  /// Resolves the categorization string for Telebirr transactions.
  /// Priority: customer note (receipt) → payment reason (receipt) →
  /// reason (SMS counterparty) → transaction type → General.
  String? _resolveTelebirrCategoryReason(Map<String, dynamic> data) {
    final customerNote = _cleanCandidate(data['customerNote']);
    final noteIsReal =
        customerNote != null &&
        !customerNote.toLowerCase().contains('scan the qr');

    if (noteIsReal) {
      return customerNote;
    }

    final paymentReason = _cleanCandidate(data['paymentReason']);
    if (paymentReason != null) {
      return paymentReason;
    }

    final isAirtime =
        data['isAirtime'] == true ||
        (data['transaction_type']?.toString() ?? '').toLowerCase().contains(
          'airtime',
        );
    if (isAirtime) {
      return _cleanCandidate(data['transaction_type']) ?? 'Airtime';
    }

    return _cleanCandidate(data['reason']) ??
        _cleanCandidate(data['transaction_type']) ??
        'General';
  }

  String _reasonOrEmpty(dynamic value) {
    final raw = value?.toString() ?? '';
    return raw.trim();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', ''));
  }

  bool _shouldForceUncategorizedCategory({
    required String? source,
    required bool hadDeepParseAttempt,
  }) {
    if (!hadDeepParseAttempt) return false;

    final normalized = (source ?? '').toLowerCase().trim();
    if (normalized.isEmpty) return true;

    if (normalized.contains('fallback') ||
        normalized.contains('error') ||
        normalized.contains('unavailable')) {
      return true;
    }

    return false;
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
    // Check if internet is available before attempting
    final hasInternet = await NetworkStatusService.hasInternet();

    if (!hasInternet) {
      debugPrint(
        '[ExtractionRetry] No internet available, skipping retry for transaction ${transaction.id}',
      );
      return;
    }

    // Determine which parser/service to use based on the bank
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
          ? await CbeReceiptService.fetchAndParseReceipt(receiptUrl)
          : isTelebirr
          ? await TelebirrReceiptService.fetchAndParseReceipt(receiptUrl)
          : isBoa
          ? await BoaReceiptService.fetchAndParseReceipt(receiptUrl)
          : await AwashReceiptService.fetchAndParseHtmlReceipt(receiptUrl);

      if (extractedData.isEmpty) {
        await db.updateExtractionStatusWithRetry(
          transaction.id,
          'attempted_failed',
          'No data extracted from receipt',
        );
        return;
      }

      // Update transaction with extracted data
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

  /// Handle a mobile cashout notification (message 2).
  /// Extracts the amount, finds the matching recent debit transaction,
  /// updates its category to "mobile cashout", and marks the SMS as processed
  /// without importing a phantom credit transaction.
  Future<void> _handleCashoutNotification(SmsInboxData sms) async {
    final amount = AwashReceiptService.extractCashoutNotificationAmount(
      sms.body,
    );
    if (amount != null) {
      final windowStart = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
      final matches =
          await (db.select(db.transactions)
                ..where((t) => t.amount.equals(amount))
                ..where(
                  (t) => t.direction.equalsValue(TransactionDirection.debit),
                )
                ..where((t) => t.smsTimestamp.isBiggerThanValue(windowStart))
                ..orderBy([(t) => OrderingTerm.desc(t.smsTimestamp)]))
              .get();
      if (matches.isNotEmpty) {
        final txn = matches.first;
        await (db.update(
          db.transactions,
        )..where((t) => t.id.equals(txn.id))).write(
          TransactionsCompanion(
            parsedCategory: Value('mobile cashout'),
            reasonRawText: Value('Mobile Cashout'),
            normalizedReason: Value('mobile cashout'),
          ),
        );
      }
    }
    await db.markAsProcessed(sms.id);
  }
}
