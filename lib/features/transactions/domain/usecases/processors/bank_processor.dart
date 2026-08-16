import 'package:faranka/database/database.dart';

abstract class BankProcessor {
  Future<void> process(SmsInboxData sms);

  Future<Map<String, dynamic>> parseReceipt(
    String receiptUrl, {
    String? smsText,
  });
}