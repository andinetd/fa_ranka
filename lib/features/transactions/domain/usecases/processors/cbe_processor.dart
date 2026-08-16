import 'package:faranka/database/database.dart';
import 'package:faranka/features/receipts/data/parsers/cbe_sms_parser.dart';
import 'package:faranka/features/receipts/data/services/cbe_receipt_service.dart';
import 'package:faranka/app/core/services/network_status_service.dart';
import 'package:faranka/features/receipts/data/services/receipt_fetch_session.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'bank_processing_support.dart';
import 'bank_processor.dart';

class CbeProcessor extends BankProcessingSupport implements BankProcessor {
  CbeProcessor(super.db, super.session);

  @override
  Future<void> process(SmsInboxData sms) async {
    final smsData = CbeSmsParser.parseAll(sms.body);
    final String? url = smsData['url']?.toString();

    final String? txnId = smsData['transactionId']?.toString();
    final double amount = toDouble(smsData['amount']) ?? 0.0;
    final dir = smsData['direction'] == 'Credit'
        ? TransactionDirection.credit
        : smsData['direction'] == 'Debit'
        ? TransactionDirection.debit
        : TransactionDirection.unknown;
    final String? cName = smsData['counterparty']?.toString();

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
          fallbackTransactionType(smsData['direction']?.toString()) ??
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

    if (url != null && url.isNotEmpty) {
      final fetchDecision = await session.decide(url);
      session.recordDecision(fetchDecision);

      if (fetchDecision == ReceiptFetchDecision.fetch) {
        final online = await NetworkStatusService.hasInternet();
        if (!online) {
          throw Exception('No internet connection. Deep scan skipped.');
        }

        try {
          final deepData = await CbeReceiptService.fetchAndParseReceipt(
            url,
            smsText: sms.body,
          );
          finalData = {...finalData, ...deepData};
          final statusCode = deepData['api_status_code'] ?? deepData['pdf_status_code'];
          if (statusCode != null && statusCode >= 500) {
            receiptFetchFailed = true;
            finalData['source'] = 'cbe_server_error_$statusCode';
          } else if (deepData['source'] == 'cbe_v2_api_error_page') {
            receiptFetchFailed = true;
          }
        } on TimeoutException catch (e) {
          debugPrint('[CbeProcessor] Fetch timeout for URL $url: $e. Keeping SMS-only parse.');
          finalData['source'] = 'sms_parse_fetch_timeout';
        } catch (e) {
          debugPrint('[CbeProcessor] Fetch error for URL $url: $e. Keeping SMS-only parse.');
          finalData['source'] = 'sms_parse_fetch_error';
        }
      } else {
        finalData['source'] = 'sms_parse_link_unavailable';
      }
    } else {
      session.recordDecision(ReceiptFetchDecision.smsOnlyNoLink);
    }

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
        finalData['payerName'] ?? finalData['payerAccount'] ?? smsData['account'];
    finalData['to_account'] ??=
        finalData['receiverName'] ??
        finalData['receiverAccount'] ??
        (url == null ? smsData['counterparty'] : null);
    finalData['direction'] ??= smsData['direction'];
    finalData['balance'] ??= smsData['balance'];
    finalData['counterparty'] ??= finalData['to_account'];
    finalData['transaction_type'] ??=
        fallbackTransactionType(finalData['direction']?.toString()) ??
        'Bank Transfer';
    finalData['source'] ??= 'sms_parse';

    final isGenericDebitAlert = looksLikeCbeGenericDebitAlert(sms.body);
    applyCbeCategoryHints(finalData, sms.body);
    finalData['reason'] = BankProcessingSupport.normalizeBusinessReason(
      finalData['reason']?.toString(),
    );
    if (isGenericDebitAlert && !hasMeaningfulCbeReason(finalData['reason'])) {
      finalData['reason'] = '';
    }

    if (url != null && url.isNotEmpty) {
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
          finalData['transaction_id']?.toString() ??
          finalData['transaction_ref']?.toString(),
      date: finalData['date']?.toString(),
      time: finalData['time']?.toString(),
      amount: toDouble(finalData['amount']),
      commission: toDouble(finalData['commission']),
      vat: toDouble(finalData['vat']),
      total: toDouble(finalData['total']),
      fromAccount: finalData['from_account']?.toString(),
      toAccount: finalData['to_account']?.toString(),
      beneficiaryAccount: finalData['beneficiary_account']?.toString(),
      beneficiaryBank: finalData['beneficiary_bank']?.toString(),
      transactionType: finalData['transaction_type']?.toString(),
      reason: reasonOrEmpty(finalData['reason']),
      tillNumber: null,
      tin: null,
      vatReg: null,
      parseSource: finalData['source']?.toString(),
    );

    final updatedSms = await (db.select(db.smsInbox)
          ..where((t) => t.id.equals(sms.id)))
        .getSingle();

    if (dir == TransactionDirection.unknown) {
      finalData['parsedCategory'] = 'Uncategorized';
    } else if (isExplicitlyEmptyReason(finalData)) {
      finalData['parsedCategory'] = 'Empty';
    } else {
      finalData['parsedCategory'] = 
          await categorizeReason(finalData['reason']?.toString());
      
      debugPrint('[CBE Categorize] smsId=${sms.id} txn=${finalData['transaction_id']} reason="${finalData['reason'] ?? ''}" parsedCategory="${finalData['parsedCategory']}"');
    }

    await db.importAwashToTransactions(
      parsedData: finalData,
      originalSms: updatedSms,
      bankName: 'CBE',
      defaultReason: 'CBE Transaction',
    );

    if (receiptFetchFailed) {
      final txn = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(sms.id)))
          .getSingleOrNull();
      if (txn != null) {
        final sourceStr = finalData['source']?.toString() ?? '';
        final codeMatch = RegExp(r'(\d+)').firstMatch(sourceStr);
        final errorMsg = codeMatch != null
            ? BankProcessingSupport.serverErrorMessage(int.parse(codeMatch.group(1)!))
            : sourceStr;
        await db.updateExtractionStatusWithRetry(
          txn.id,
          'attempted_failed',
          errorMsg,
        );
      }
    }
  }

  @override
  Future<Map<String, dynamic>> parseReceipt(
    String receiptUrl, {
    String? smsText,
  }) {
    return CbeReceiptService.fetchAndParseReceipt(
      receiptUrl,
      smsText: smsText,
    );
  }
}
