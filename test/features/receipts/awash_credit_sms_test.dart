import 'package:flutter_test/flutter_test.dart';

import 'package:faranka/features/receipts/data/parsers/awash_sms_parser.dart';
import 'package:faranka/features/receipts/data/services/awash_receipt_service.dart';
import 'package:faranka/features/transactions/domain/usecases/processors/bank_processing_support.dart';

void main() {
  const sms = 'Dear Customer, ETB 17,380 has been credited to your account '
      'from YODIT TESFAYE BEKELE on : 2026-07-24 21:03:34  with Txn ID: '
      '260724210334296 . Your available balance is now ETB 17,882.14. Receipt  '
      'Link: https://awashpay.awashbank.com:8225/-2KF31R4SWO-5CD2KQ. Contact '
      'center  8980.\n\n'
      'Alert: Awash Bank will never ask for your PIN, password, or OTP. Do not '
      'share your confidential information with anyone.';

  group('AwashSmsParser.parseAll', () {
    test('extracts direction as Credit', () {
      final parsed = AwashSmsParser.parseAll(sms);
      expect(parsed['direction'], 'Credit');
    });

    test('extracts amount', () {
      final parsed = AwashSmsParser.parseAll(sms);
      expect(parsed['amount'], 17380.0);
    });

    test('extracts transaction ID from Txn ID field', () {
      final parsed = AwashSmsParser.parseAll(sms);
      expect(parsed['transactionId'], '260724210334296');
    });

    test('extracts counterparty name', () {
      final parsed = AwashSmsParser.parseAll(sms);
      expect(parsed['counterparty'], 'YODIT TESFAYE BEKELE');
    });

    test('extracts balance', () {
      final parsed = AwashSmsParser.parseAll(sms);
      expect(parsed['balance'], 17882.14);
    });

    test('extracts receipt URL', () {
      final parsed = AwashSmsParser.parseAll(sms);
      expect(
        parsed['url'],
        'https://awashpay.awashbank.com:8225/-2KF31R4SWO-5CD2KQ',
      );
    });

    test('uses counterparty as reason', () {
      final parsed = AwashSmsParser.parseAll(sms);
      expect(parsed['reason'], 'YODIT TESFAYE BEKELE');
    });

    test('extracts date and time', () {
      final parsed = AwashSmsParser.parseAll(sms);
      expect(parsed['date'], '2026-07-24');
      expect(parsed['time'], '21:03:34');
    });

    test('charge and vat are null (not present in SMS)', () {
      final parsed = AwashSmsParser.parseAll(sms);
      expect(parsed['charge'], isNull);
      expect(parsed['vat'], isNull);
    });
  });

  group('AwashReceiptService.parseSmsForReceiptFields (fallback)', () {
    test('extracts amount correctly (first ETB amount)', () {
      final parsed = AwashReceiptService.parseSmsForReceiptFields(sms);
      expect(parsed['amount'], 17380.0);
    });

    test('extracts transaction_id from URL slug (not Txn ID)', () {
      final parsed = AwashReceiptService.parseSmsForReceiptFields(sms);
      expect(parsed['transaction_id'], '-2KF31R4SWO-5CD2KQ');
    });

    test('reason is null (no explicit Reason field in SMS)', () {
      final parsed = AwashReceiptService.parseSmsForReceiptFields(sms);
      expect(parsed['reason'], isNull);
    });

    test('balance is extracted from available balance', () {
      final parsed = AwashReceiptService.parseSmsForReceiptFields(sms);
      expect(parsed['balance'], 17882.14);
    });

    test('total equals amount (no fees)', () {
      final parsed = AwashReceiptService.parseSmsForReceiptFields(sms);
      expect(parsed['total'], 17380.0);
    });

    test('from_account is null (no Sender/Customer field in SMS)', () {
      final parsed = AwashReceiptService.parseSmsForReceiptFields(sms);
      expect(parsed['from_account'], isNull);
    });

    test('transaction_type is null', () {
      final parsed = AwashReceiptService.parseSmsForReceiptFields(sms);
      expect(parsed['transaction_type'], isNull);
    });
  });

  group('BankProcessingSupport.normalizeBusinessReason', () {
    test('null reason becomes empty string', () {
      expect(BankProcessingSupport.normalizeBusinessReason(null), '');
    });

    test('empty string becomes empty string', () {
      expect(BankProcessingSupport.normalizeBusinessReason(''), '');
    });

    test('counterparty name is NOT a generic reason', () {
      final result = BankProcessingSupport.normalizeBusinessReason(
        'YODIT TESFAYE BEKELE',
      );
      expect(result, isNot(''));
      expect(result, 'YODIT TESFAYE BEKELE');
    });

    test('single-letter reason is kept and normalized to itself', () {
      expect(BankProcessingSupport.normalizeBusinessReason('d'), 'd');
      expect(BankProcessingSupport.normalizeBusinessReason('a'), 'a');
    });

    test('one-letter reason with trailing boilerplate keeps the letter', () {
      expect(
        BankProcessingSupport.normalizeBusinessReason(
          'd. For enquiries, please call 8980.',
        ),
        'd',
      );
    });

    test('a two-letter reason is still kept', () {
      expect(BankProcessingSupport.normalizeBusinessReason('ok'), 'ok');
    });

    test('trailing boilerplate is trimmed off a real narration', () {
      expect(
        BankProcessingSupport.normalizeBusinessReason(
          'Salary. For any complaint or enquiry, please call 8980.',
        ),
        'Salary',
      );
    });
  });

  group('Pipeline integration: isExplicitlyEmptyReason simulation', () {
    test('reason from receipt fallback is null -> normalize returns "" -> isExplicitlyEmptyReason would be true', () {
      final receiptParsed = AwashReceiptService.parseSmsForReceiptFields(sms);
      final reason = receiptParsed['reason']; // null
      final normalized = BankProcessingSupport.normalizeBusinessReason(
        reason?.toString(),
      );
      // This is what _isExplicitlyEmptyReason checks:
      expect(receiptParsed.containsKey('reason'), isTrue);
      // reason key exists, value is null
      // After normalize: '' (empty string)
      expect(normalized, '');
      // null is not a non-null String with .trim().isEmpty,
      // but after normalization it becomes '' which would be caught
    });

    test('SMS parser reason is NOT carried forward to finalData in the processor pipeline', () {
      final smsParsed = AwashSmsParser.parseAll(sms);
      final receiptParsed = AwashReceiptService.parseSmsForReceiptFields(sms);

      // SMS parser extracts YODIT TESFAYE BEKELE as reason
      expect(smsParsed['reason'], 'YODIT TESFAYE BEKELE');

      // Receipt fallback does NOT extract it
      expect(receiptParsed['reason'], isNull);

      // The processor uses receiptParsed as finalData, overwriting smsParsed values
      final processorReason = receiptParsed['reason'];
      expect(processorReason, isNull);

      // After normalizeBusinessReason, it becomes ''
      final normalized = BankProcessingSupport.normalizeBusinessReason(
        processorReason?.toString(),
      );
      expect(normalized, '');
    });
  });
}
