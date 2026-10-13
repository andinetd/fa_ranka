import 'package:drift/drift.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/receipts/data/parsers/awash_sms_parser.dart';
import 'package:faranka/features/receipts/data/services/awash_receipt_service.dart';
import 'package:faranka/app/core/services/network_status_service.dart';
import 'package:faranka/features/receipts/data/services/receipt_fetch_session.dart';

import 'bank_processing_support.dart';
import 'bank_processor.dart';

class AwashProcessor extends BankProcessingSupport implements BankProcessor {
  AwashProcessor(super.db, super.session);

  @override
  Future<void> process(SmsInboxData sms) async {
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

    final smsData = AwashSmsParser.parseAll(sms.body);
    final String? url = smsData['url'];

    final String? txnId = smsData['transactionId']?.toString();
    final double amount = BankProcessingSupport.toDouble(smsData['amount']) ?? 0.0;
    final dir = smsData['direction'] == 'Credit'
        ? TransactionDirection.credit
        : smsData['direction'] == 'Debit'
        ? TransactionDirection.debit
        : TransactionDirection.unknown;
    final String? cName = smsData['counterparty']?.toString();
    final String? cNum = smsData['counterpartyNumber']?.toString();

    var isDuplicate = false;

    if (txnId != null && txnId.isNotEmpty) {
      final existing = await (db.select(db.transactions)
            ..where((t) => t.bankTransactionId.equals(txnId)))
          .getSingleOrNull();
      isDuplicate = existing != null;
    } else {
      isDuplicate = await isDuplicateFuzzy(
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

    if (url != null && url.isNotEmpty) {
      final online = await NetworkStatusService.hasInternet();
      if (!online) {
        throw const OfflineDeepParseException(
          'No internet connection. Deep scan skipped.',
        );
      }

      final decision = await decideDeepFetch(url);
      if (decision == ReceiptFetchDecision.fetch) {
        try {
          finalData = await AwashReceiptService.fetchAndParseHtmlReceipt(
            url,
            smsText: sms.body,
          );
          if (BankProcessingSupport.serverUnavailableFromResult(finalData)) {
            markServerUnavailable(url);
            serverDown = isConfirmedBlocked(url);
          }
        } catch (e) {
          if (BankProcessingSupport.isNetworkError(e)) {
            markServerUnavailable(url);
            serverDown = isConfirmedBlocked(url);
          }
          finalData = AwashReceiptService.parseSmsForReceiptFields(sms.body);
        }
      } else {
        finalData = AwashReceiptService.parseSmsForReceiptFields(sms.body);
        if (decision == ReceiptFetchDecision.smsOnlyDomainBlocked) {
          serverDown = true;
        }
      }
    } else {
      session?.recordDecision(ReceiptFetchDecision.smsOnlyNoLink);
      finalData = AwashReceiptService.parseSmsForReceiptFields(sms.body);
    }

    finalData['direction'] ??= smsData['direction'];
    finalData['balance'] ??= smsData['balance'];
    finalData['transaction_type'] ??= BankProcessingSupport.fallbackTransactionType(
      finalData['direction']?.toString(),
    );
    finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
      finalData['reason']?.toString(),
    );
    applyAwashCategoryHints(finalData, sms.body);

    if (url != null) {
      finalData['counterparty'] =
          dir == TransactionDirection.credit
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
          finalData['transaction_id']?.toString() ?? smsData['transactionId'],
      date: finalData['date']?.toString(),
      time: finalData['time']?.toString(),
      amount: BankProcessingSupport.toDouble(finalData['amount']),
      commission:
          BankProcessingSupport.toDouble(finalData['commission']) ??
          BankProcessingSupport.toDouble(finalData['charge']),
      vat: BankProcessingSupport.toDouble(finalData['vat']),
      total: BankProcessingSupport.toDouble(finalData['total']),
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
          finalData['source']?.toString() ??
          (url != null ? 'HTML' : 'SMS'),
    );

    final updatedSms = await (db.select(db.smsInbox)
          ..where((t) => t.id.equals(sms.id)))
        .getSingle();

    final forceUncategorized = shouldForceUncategorizedCategory(
      source: finalData['source']?.toString(),
      hadDeepParseAttempt: url != null,
    );

    if (forceUncategorized || dir == TransactionDirection.unknown) {
      finalData['parsedCategory'] = 'Uncategorized';
    } else if (BankProcessingSupport.isExplicitlyEmptyReason(finalData)) {
      finalData['parsedCategory'] = 'Empty';
    } else {
      finalData['parsedCategory'] =
          await categorizeReason(finalData['reason']?.toString() ?? finalData['transaction_type']?.toString());
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
      await scheduleServerDownRetry(sms.id, 'Awash Bank');
    }
  }

  @override
  Future<Map<String, dynamic>> parseReceipt(
    String receiptUrl, {
    String? smsText,
  }) {
    return AwashReceiptService.fetchAndParseHtmlReceipt(
      receiptUrl,
      smsText: smsText,
    );
  }

  /// Handle a mobile cashout notification (message 2).
  /// Extracts the amount, finds the matching recent debit transaction,
  /// updates its category to "mobile cashout", and marks the SMS as processed
  /// without importing a phantom credit transaction.
  Future<void> _handleCashoutNotification(SmsInboxData sms) async {
    final amount = AwashReceiptService.extractCashoutNotificationAmount(sms.body);
    if (amount != null) {
      final windowStart = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
      final matches = await (db.select(db.transactions)
            ..where((t) => t.amount.equals(amount))
            ..where((t) => t.direction.equalsValue(TransactionDirection.debit))
            ..where((t) => t.smsTimestamp.isBiggerThanValue(windowStart))
            ..orderBy([(t) => OrderingTerm.desc(t.smsTimestamp)]))
          .get();
      if (matches.isNotEmpty) {
        final txn = matches.first;
        await (db.update(db.transactions)
              ..where((t) => t.id.equals(txn.id)))
            .write(TransactionsCompanion(
              parsedCategory: Value('mobile cashout'),
              reasonRawText: Value('Mobile Cashout'),
              normalizedReason: Value('mobile cashout'),
            ));
      }
    }
    await db.markAsProcessed(sms.id);
  }
}
