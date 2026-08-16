import 'package:faranka/features/receipts/data/services/boa_receipt_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mirrors the real structure served at
  // https://cs.bankofabyssinia.com/api/onlineSlip/getDetails/?id=<token>.
  const receiptJson = '''
{
  "header": {
    "audit": {"T24_time": 72, "responseParse_time": 4, "requestParse_time": 8},
    "page_start": 1,
    "page_token": "202608131570476905.01,99",
    "total_size": 1,
    "page_size": 99,
    "status": "success"
  },
  "body": [
    {
      "Source Account Name": "DEREJE MENGIST DEFERSHA",
      "VAT (15%)": "0.75",
      "Transferred Amount in word": "NINE THOUSAND SEVEN HUNDRED AND NINETY THREE ETB AND SEVENTY FIVE CENTS ONLY",
      "Address": "ADDIS ABABA, ETH",
      "Transaction Type": "Tuition Fee",
      "Service Charge": "5",
      "Vat Sequence Number": "0000000189682808",
      "Source Account": "1******76",
      "Payment Reference": "MIHRET DEREJE MENGIST",
      "Tel.": "+251911993069",
      "Payer's Name": "DEREJE MENGIST DEFERSHA",
      "Narrative": "ግንቦት-ሰኔ",
      "Transferred Amount": "9788.00",
      "currency": "ETB",
      "Transaction Reference": "FT26149FW949",
      "Transaction Date": "29/05/26 16:09",
      "Total Amount including VAT": "9793.75"
    }
  ]
}
''';

  group('BoaReceiptService', () {
    test('parses receipt JSON fields', () {
      final result = BoaReceiptService.parseReceiptJson(receiptJson);

      expect(result['source'], 'boa_html_parse');
      expect(result['bankName'], 'BoA');
      expect(result['referenceNumber'], 'FT26149FW949');
      expect(result['payerName'], 'DEREJE MENGIST DEFERSHA');
      expect(result['payerAccount'], '1******76');
      expect(result['transferredAmount'], 9788.00);
      expect(result['serviceFee'], 5.00);
      expect(result['vat'], 0.75);
      expect(result['totalAmount'], 9793.75);
      expect(result['transactionType'], 'Tuition Fee');
      expect(result['paymentReference'], 'MIHRET DEREJE MENGIST');
      expect(result['narrative'], 'ግንቦት-ሰኔ');
      expect(result['paymentDate'], '29/05/26');
      expect(result['paymentTime'], '16:09');
      expect(result['error'], isNull);
    });

    test('empty body returns missing-token error', () {
      final result = BoaReceiptService.parseReceiptJson('');
      expect(result['error'], isNotNull);
    });

    test('invalid JSON returns error', () {
      final result = BoaReceiptService.parseReceiptJson(
        'not valid json at all and long enough to pass the length guard here',
      );
      expect(result['error'], contains('Invalid JSON'));
    });

    test('JSON without body rows returns error', () {
      const json =
          '{"header":{"audit":{"T24_time":72},"page_start":1,"page_token":'
          '"abc123","total_size":0,"page_size":99,"status":"success"},'
          '"body":[]}';
      final result = BoaReceiptService.parseReceiptJson(json);
      expect(result['error'], contains('No transaction rows'));
    });

    test('missing token in URL returns fallback source', () async {
      final result = await BoaReceiptService.fetchAndParseReceipt(
        'https://cs.bankofabyssinia.com/slip/',
      );
      expect(result['source'], 'boa_receipt_missing_token_fallback');
    });
  });
}