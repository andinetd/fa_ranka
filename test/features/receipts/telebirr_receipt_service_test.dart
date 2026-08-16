import 'package:faranka/features/receipts/data/services/telebirr_receipt_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mirrors the real structure served at
  // https://transactioninfo.ethiotelecom.et/receipt/<token>.
  const receiptHtml = '''
<html><body>
<div>Ethio telecom Share Company</div>
<table>
  <tr><td>የከፋይ ስም/Payer Name</td><td>Amanuel Wonde Tessema</td></tr>
  <tr><td>የከፋይ ቴሌብር ቁ./Payer telebirr no.</td><td>2519****5268</td></tr>
  <tr><td>የገንዘብ ተቀባይ ስም/Credited Party name</td><td>Ayenew Yitayih Truneh</td></tr>
  <tr><td>የገንዘብ ተቀባይ ቴሌብር ቁ./Credited party account no</td><td>2519****8478</td></tr>
  <tr><td>የክፍያው ሁኔታ/transaction status Completed</td></tr>
  <tr><td>የክፍያ ቁጥር/Invoice No.</td><td>የክፍያ ቀን/Payment date</td><td>የተከፈለው መጠን/Settled Amount</td></tr>
  <tr><td>DER0DV80P8</td><td>27-05-2026 12:15:50</td><td>45 Birr</td></tr>
  <tr><td>የአገልግሎት ክፍያ/Service fee</td><td>0.87 Birr</td></tr>
  <tr><td>የአገልግሎት ክፍያ ተ.እ.ታ/Service fee VAT</td><td>0.13 Birr</td></tr>
  <tr><td>ጠቅላላ የተከፈለ/Total Paid Amount</td><td>46 Birr</td></tr>
  <tr><td>የክፍያ ዘዴ/Payment Mode</td><td>telebirr</td></tr>
  <tr><td>የክፍያ ምክንያት/Payment Reason</td><td>Send Money to Registered Customer</td></tr>
  <tr><td>የክፍያ መንገድ/Payment channel</td><td>API/App</td></tr>
  <tr><td>የደንበኛ መልዕክት/Customer Note</td></tr>
  <tr><td>Scan the QR using telebirr SuperApp to verify the payment</td></tr>
</table>
</body></html>
''';

  group('TelebirrReceiptService', () {
    test('parses receipt HTML fields', () {
      final result = TelebirrReceiptService.parseReceiptHtml(receiptHtml);

      expect(result['source'], 'telebirr_html_parse');
      expect(result['bankName'], 'Telebirr');
      expect(result['referenceNumber'], 'DER0DV80P8');
      expect(result['payerName'], 'Amanuel Wonde Tessema');
      expect(result['payerNumber'], '2519****5268');
      expect(result['receiverName'], 'Ayenew Yitayih Truneh');
      expect(result['receiverNumber'], '2519****8478');
      expect(result['transactionStatus'], 'Completed');
      expect(result['paymentDate'], '27-05-2026');
      expect(result['paymentTime'], '12:15:50');
      expect(result['settledAmount'], 45.00);
      expect(result['serviceFee'], 0.87);
      expect(result['serviceFeeVat'], 0.13);
      expect(result['totalPaidAmount'], 46.00);
      expect(result['paymentMode'], 'telebirr');
      expect(result['paymentReason'], 'Send Money to Registered Customer');
      expect(result['paymentChannel'], 'API/App');
      // The Customer Note value sits on a separate row and is boilerplate;
      // the parser must not capture it as a real note.
      expect(result['customerNote'], isNull);
    });
  });
}
