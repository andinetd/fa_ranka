import 'package:faranka/features/receipts/data/parsers/telebirr_sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelebirrSmsParser', () {
    test('parses received (credit) SMS', () {
      const sms =
          'You have received ETB 190.00 from MILLIONE ZEKE(2519****5454)  on '
          '28/05/2026 11:27:48. Your transaction number is DES6EQBIAM. Your '
          'current E-Money Account balance is ETB 651.84.\n'
          'Thank you for using telebirr\nEthio telecom';

      final parsed = TelebirrSmsParser.parseAll(sms);

      expect(parsed['transactionId'], 'DES6EQBIAM');
      expect(parsed['referenceNumber'], 'DES6EQBIAM');
      expect(parsed['amount'], 190.00);
      expect(parsed['direction'], 'Credit');
      expect(parsed['transaction_type'], 'Money Received');
      expect(parsed['counterparty'], 'MILLIONE ZEKE');
      expect(parsed['counterpartyNumber'], '2519****5454');
      expect(parsed['date'], '28/05/2026');
      expect(parsed['time'], '11:27:48');
      expect(parsed['balance'], 651.84);
      expect(parsed['url'], isNull);
      expect(parsed['commission'], isNull);
      expect(parsed['vat'], isNull);
      expect(parsed['isAirtime'], false);
    });

    test('parses transferred (debit) SMS with fee and VAT', () {
      const sms =
          'You have transferred ETB 45.00 to Ayenew Yitayih (2519****8478) on '
          '27/05/2026 12:15:50. Your transaction number is DER0DV80P8. The '
          'service fee is  ETB 0.87 and  15% VAT on the service fee is ETB 0.13. '
          'Your current E-Money Account  balance is ETB 466.84. To download your '
          'payment information please click this link: '
          'https://transactioninfo.ethiotelecom.et/receipt/DER0DV80P8.\n'
          'Thank you for using telebirr\nEthio telecom';

      final parsed = TelebirrSmsParser.parseAll(sms);

      expect(parsed['transactionId'], 'DER0DV80P8');
      expect(parsed['amount'], 45.00);
      expect(parsed['direction'], 'Debit');
      expect(parsed['transaction_type'], 'Money Sent');
      expect(parsed['counterparty'], 'Ayenew Yitayih');
      expect(parsed['counterpartyNumber'], '2519****8478');
      expect(parsed['date'], '27/05/2026');
      expect(parsed['time'], '12:15:50');
      expect(parsed['balance'], 466.84);
      expect(parsed['commission'], 0.87);
      expect(parsed['vat'], 0.13);
      expect(
        parsed['url'],
        'https://transactioninfo.ethiotelecom.et/receipt/DER0DV80P8',
      );
      expect(parsed['isAirtime'], false);
    });

    test('parses airtime SMS', () {
      const sms =
          ' Dear Customer\n'
          'You have received ETB 5.00 airtime from 251972285268 on '
          '27/05/2026 18:44:44. Your transaction number is DER9E804IF.\n'
          'Thank you for using telebirr\nethio telecom';

      final parsed = TelebirrSmsParser.parseAll(sms);

      expect(parsed['transactionId'], 'DER9E804IF');
      expect(parsed['amount'], 5.00);
      expect(parsed['direction'], 'Credit');
      expect(parsed['transaction_type'], 'Airtime Purchase');
      expect(parsed['counterparty'], '251972285268');
      expect(parsed['counterpartyNumber'], '251972285268');
      expect(parsed['date'], '27/05/2026');
      expect(parsed['time'], '18:44:44');
      expect(parsed['isAirtime'], true);
    });

    test('parses package purchase SMS as debit', () {
      const sms =
          'Dear KIDIST\n'
          'You have paid ETB 25.00 for package Weekly Birr 25 for 84Min+42 Min '
          'Night bonus purchase made for 251942014271 on 10/08/2026 08:25:46. '
          'Your transaction number is DHA5NXMVQF. Your current balance is ETB '
          '218.78.To download your payment information please click this link: '
          'https://transactioninfo.ethiotelecom.et/receipt/DHA5NXMVQF\n'
          'Thank you for using telebirr\nEthio telecom';

      final parsed = TelebirrSmsParser.parseAll(sms);

      expect(parsed['transactionId'], 'DHA5NXMVQF');
      expect(parsed['amount'], 25.00);
      expect(parsed['direction'], 'Debit');
      expect(parsed['transaction_type'], 'Package Purchase');
      expect(parsed['balance'], 218.78);
      expect(parsed['isAirtime'], false);
      expect(
        parsed['url'],
        'https://transactioninfo.ethiotelecom.et/receipt/DHA5NXMVQF',
      );
    });

    test('extracts transaction token from receipt URL', () {
      expect(
        TelebirrSmsParser.extractTransactionFromUrl(
          'https://transactioninfo.ethiotelecom.et/receipt/DER0DV80P8',
        ),
        'DER0DV80P8',
      );
    });
  });
}
