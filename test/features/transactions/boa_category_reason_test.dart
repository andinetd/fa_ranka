import 'package:faranka/features/transactions/domain/usecases/processors/bank_processing_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankProcessingSupport.resolveBoaCategoryReason', () {
    test('uses a meaningful receipt transaction type', () {
      expect(
        BankProcessingSupport.resolveBoaCategoryReason({
          'transaction_type': 'Tuition Fee',
          'paymentReference': 'MIHRET DEREJE MENGIST',
          'narrative': 'ግንቦት-ሰኔ',
        }),
        'Tuition Fee',
      );
    });

    test('uses Mobile Top Up transaction type', () {
      expect(
        BankProcessingSupport.resolveBoaCategoryReason({
          'transaction_type': 'Mobile Top Up',
          'paymentReference': '911993069',
        }),
        'Mobile Top Up',
      );
    });

    test('uses EthSwitch transfer type verbatim', () {
      expect(
        BankProcessingSupport.resolveBoaCategoryReason({
          'transaction_type': 'EthSwitch Transfer For inc via IPS',
          'paymentReference': 'MIHRET DEREJE MENGIST',
          'narrative': '260528171877968',
        }),
        'EthSwitch Transfer For inc via IPS',
      );
    });

    test(
      'uses transaction type even when payment reference is a phone number',
      () {
        expect(
          BankProcessingSupport.resolveBoaCategoryReason({
            'transaction_type': 'EthSwitch Transfer For inc via IPS',
            'paymentReference': '911993069',
            'narrative': 'Transfer',
          }),
          'EthSwitch Transfer For inc via IPS',
        );
      },
    );

    test('uses transaction type even with reference-looking narratives', () {
      expect(
        BankProcessingSupport.resolveBoaCategoryReason({
          'transaction_type': 'EthSwitch Transfer For inc via IPS',
          'narrative': 'FT261182TVN5',
        }),
        'EthSwitch Transfer For inc via IPS',
      );
    });

    test('uses transaction type even with mostly-numeric narratives', () {
      expect(
        BankProcessingSupport.resolveBoaCategoryReason({
          'transaction_type': 'EthSwitch Transfer For inc via IPS',
          'narrative': '260211051211875',
        }),
        'EthSwitch Transfer For inc via IPS',
      );
    });

    test('keeps Bank Transfer as-is', () {
      expect(
        BankProcessingSupport.resolveBoaCategoryReason({
          'transaction_type': 'Bank Transfer',
          'paymentReference': '911993069',
        }),
        'Bank Transfer',
      );
    });

    test('uses transaction type over payment reference name', () {
      expect(
        BankProcessingSupport.resolveBoaCategoryReason({
          'transaction_type': 'EthSwitch Transfer For inc via IPS',
          'paymentReference': 'EYUATAM DEREJE MENGIST',
          'narrative': 'ሚያዝያ',
        }),
        'EthSwitch Transfer For inc via IPS',
      );
    });

    test('returns null when transaction type is absent', () {
      expect(
        BankProcessingSupport.resolveBoaCategoryReason({
          'transaction_type': null,
          'paymentReference': null,
          'narrative': null,
        }),
        isNull,
      );
    });
  });
}
