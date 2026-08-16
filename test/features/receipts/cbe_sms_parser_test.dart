import 'package:faranka/features/receipts/data/parsers/cbe_sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses CBE received v2 receipt SMS as credit', () {
    const sms =
        'Dear Andinet Dereje Mengist You have received ETB 3,000.00 from account 1**5276 '
        '(Amanuel Aleme Mengist) to your account 1**5039. Your current balance is ETB24,821.11. '
        'Thanks for Banking with CBE. https://mbreciept.cbe.com.et/v2-hfHCxzyBiOaoJKf5qQDj';

    final parsed = CbeSmsParser.parseAll(sms);

    expect(
      parsed['url'],
      'https://mbreciept.cbe.com.et/v2-hfHCxzyBiOaoJKf5qQDj',
    );
    expect(parsed['transactionId'], isNull);
    expect(parsed['amount'], 3000.00);
    expect(parsed['direction'], 'Credit');
    expect(parsed['counterparty'], 'Amanuel Aleme Mengist');
    expect(parsed['account'], '1**5276');
    expect(parsed['balance'], 24821.11);
  });
}
