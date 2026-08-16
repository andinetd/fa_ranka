import 'package:faranka/features/receipts/data/parsers/boa_sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoaSmsParser', () {
    test('parses debit SMS', () {
      const sms =
          'Dear Dereje, your account 1*76 was debited with ETB 9,793.75. '
          'Available Balance: ETB 186.11.\n'
          'Receipt: https://cs.bankofabyssinia.com/slip/?trx=FT26149FW94903776\n'
          'Link your Fayda: https://cs.bankofabyssinia.com/fayda_connect \n'
          'For help, call 8397 (24/7 Toll-Free). Bank of Abyssinia.\n'
          'ይጠንቀቁ !';

      final parsed = BoaSmsParser.parseAll(sms);

      expect(parsed['transactionId'], 'FT26149FW94903776');
      expect(parsed['referenceNumber'], 'FT26149FW94903776');
      expect(parsed['url'],
          'https://cs.bankofabyssinia.com/slip/?trx=FT26149FW94903776');
      expect(parsed['amount'], 9793.75);
      expect(parsed['direction'], 'Debit');
      expect(parsed['balance'], 186.11);
      expect(parsed['account'], '1*76');
      expect(parsed['counterparty'], isNull);
    });

    test('parses credit SMS with counterparty', () {
      const sms =
          'Dear Dereje, your account 1*76 was credited with ETB 9,900.00 by  '
          'Dereje Mengist Defersha . Available Balance: ETB 9,979.86.\n'
          'Receipt: https://cs.bankofabyssinia.com/slip/?trx=FT26148XS9G510104\n'
          'Link your Fayda: https://cs.bankofabyssinia.com/fayda_connect \n'
          'For help, call 8397 (24/7 Toll-Free). Bank of Abyssinia.';

      final parsed = BoaSmsParser.parseAll(sms);

      expect(parsed['transactionId'], 'FT26148XS9G510104');
      expect(parsed['amount'], 9900.00);
      expect(parsed['direction'], 'Credit');
      expect(parsed['balance'], 9979.86);
      expect(parsed['account'], '1*76');
      expect(parsed['counterparty'], 'Dereje Mengist Defersha');
    });

    test('parses masked sender credit SMS prefixed with forward header', () {
      const sms =
          '[12/08/2026 3:25 ከሰዓት] Aba: Dear DEREJE, your account 1*76 was '
          'credited with ETB 500.00 by A/R - P2P incoming settlement accou. '
          'Available Balance:  ETB 689.34. Receipt: '
          'https://cs.bankofabyssinia.com/slip/?trx=FT260426H4YR10104\n'
          'Feedback: https://cs.bankofabyssinia.com/cs/?trx=CFT260426H4YR '
          'For help, call 8397 (24/7 Toll-Free). Bank of Abyssinia.';

      final parsed = BoaSmsParser.parseAll(sms);

      expect(parsed['transactionId'], 'FT260426H4YR10104');
      expect(parsed['amount'], 500.00);
      expect(parsed['direction'], 'Credit');
      expect(parsed['balance'], 689.34);
      expect(parsed['account'], '1*76');
      expect(parsed['counterparty'], 'A/R - P2P incoming settlement accou');
    });

    test('parses small debit with no counterparty', () {
      const sms =
          'Dear Dereje, your account 1*76 was debited with ETB 50.00. '
          'Available Balance: ETB 79.45.\n'
          'Receipt: https://cs.bankofabyssinia.com/slip/?trx=FT26119X97VP03776\n'
          'Link your Fayda: https://cs.bankofabyssinia.com/fayda_connect \n'
          'For help, call 8397 (24/7 Toll-Free). Bank of Abyssinia.';

      final parsed = BoaSmsParser.parseAll(sms);

      expect(parsed['amount'], 50.00);
      expect(parsed['direction'], 'Debit');
      expect(parsed['balance'], 79.45);
      expect(parsed['account'], '1*76');
    });

    test('non-transaction marketing SMS returns nulls', () {
      const sms =
          '2ተኛ ዙር ሽልማት በአቢሲንያ ቪዛ ካርድ!\n'
          'ከ100 ብር ጀምሮ በአቢሲንያ ቪዛ ካርድ እየተገበያዩ፣ ለዕድል ጨዋታ የሚያበቃዎትን ነጥብ ያግኙ!';

      final parsed = BoaSmsParser.parseAll(sms);

      expect(parsed['transactionId'], isNull);
      expect(parsed['amount'], isNull);
      expect(parsed['direction'], 'Unknown');
      expect(parsed['url'], isEmpty);
    });

    test('extracts transaction token from receipt URL', () {
      expect(
        BoaSmsParser.extractTransactionTokenFromUrl(
          'https://cs.bankofabyssinia.com/slip/?trx=FT26148XS9G510104',
        ),
        'FT26148XS9G510104',
      );
      expect(
        BoaSmsParser.extractTransactionTokenFromUrl(''),
        isNull,
      );
    });

    test('no date/time embedded in SMS', () {
      expect(BoaSmsParser.extractDateTime('body'), {'date': null, 'time': null});
    });
  });
}