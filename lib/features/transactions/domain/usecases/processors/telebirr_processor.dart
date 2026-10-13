import 'package:faranka/database/database.dart';
import 'package:faranka/features/receipts/data/parsers/telebirr_sms_parser.dart';
import 'package:faranka/features/receipts/data/services/telebirr_receipt_service.dart';
import 'package:faranka/app/core/services/network_status_service.dart';
import 'package:faranka/features/receipts/data/services/receipt_fetch_session.dart';
import 'package:faranka/features/transactions/domain/services/category_engine.dart';

import 'bank_processing_support.dart';
import 'bank_processor.dart';

class TelebirrProcessor extends BankProcessingSupport implements BankProcessor {
  TelebirrProcessor(super.db, super.session);

  @override
  Future<void> process(SmsInboxData sms) async {
    if (!sms.body.contains('ETB')) {
      await db.markAsProcessed(sms.id);
      return;
    }

    final smsData = TelebirrSmsParser.parseAll(sms.body);
    final String? url = smsData['url']?.toString();

    final String? txnId = smsData['transactionId']?.toString();
    final double amount = BankProcessingSupport.toDouble(smsData['amount']) ?? 0.0;
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
          : BankProcessingSupport.fallbackTransactionType(smsData['direction']?.toString()) ??
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
      final decision = await decideDeepFetch(url);
      if (decision == ReceiptFetchDecision.fetch) {
        final deepData = await TelebirrReceiptService.fetchAndParseReceipt(
          url,
          smsText: sms.body,
        );

        finalData = {...finalData, ...deepData};

        if (BankProcessingSupport.serverUnavailableFromResult(deepData)) {
          markServerUnavailable(url);
          serverDown = isConfirmedBlocked(url);
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
            BankProcessingSupport.fallbackTransactionType(finalData['direction']?.toString()) ??
            smsData['transaction_type'] ??
            'Bank Transfer';
        finalData['source'] ??= 'sms_parse';
      } else if (decision == ReceiptFetchDecision.smsOnlyDomainBlocked) {
        serverDown = true;
        finalData['counterparty'] ??= smsData['counterparty'];
        finalData['to_account'] ??= smsData['counterparty'];
      }
    }

    finalData['reason'] = BankProcessingSupport.resolveTelebirrCategoryReason(finalData);
    if (finalData['reason']?.isEmpty == true) {
      finalData['reason'] = 'Empty';
    }

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
      tillNumber: null,
      tin: null,
      vatReg: null,
      parseSource: finalData['source']?.toString(),
    );

    final updatedSms = await (db.select(
      db.smsInbox,
    )..where((t) => t.id.equals(sms.id))).getSingle();

    if (dir == TransactionDirection.unknown) {
      finalData['parsedCategory'] = 'Uncategorized';
    } else {
      if (BankProcessingSupport.isExplicitlyEmptyReason(finalData)) {
        finalData['parsedCategory'] = 'Empty';
      } else {
        final categoryEngine = CategoryEngine(db);
        final reason =
            BankProcessingSupport.cleanCandidate(finalData['reason']) ??
            BankProcessingSupport.cleanCandidate(finalData['transaction_type']) ??
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
      await scheduleServerDownRetry(sms.id, 'Telebirr');
    }
  }

  @override
  Future<Map<String, dynamic>> parseReceipt(
    String receiptUrl, {
    String? smsText,
  }) {
    return TelebirrReceiptService.fetchAndParseReceipt(
      receiptUrl,
      smsText: smsText,
    );
  }
}
