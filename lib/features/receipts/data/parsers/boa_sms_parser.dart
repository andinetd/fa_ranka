class BoaSmsParser {
  static String extractReceiptUrl(String smsText) {
    final match = RegExp(
      r'https?://cs\.bankofabyssinia\.com/slip/\?trx=[A-Z0-9]+',
      caseSensitive: false,
    ).firstMatch(smsText);
    return match?.group(0) ?? '';
  }

  static String? extractTransactionTokenFromUrl(String url) {
    if (url.isEmpty) return null;
    final match = RegExp(
      r'trx=([A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(url);
    return match?.group(1);
  }

  static String? extractTransactionNumber(String smsText) {
    return extractTransactionTokenFromUrl(extractReceiptUrl(smsText));
  }

  static double? extractAmount(String smsText) {
    final match = RegExp(
      r'(?:debited|credited)\s+with\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return _toDouble(match?.group(1));
  }

  static String extractDirection(String smsText) {
    final textLower = smsText.toLowerCase();
    if (textLower.contains('credited')) return 'Credit';
    if (textLower.contains('debited')) return 'Debit';
    return 'Unknown';
  }

  static double? extractBalance(String smsText) {
    final match = RegExp(
      r'Available\s*Balance\s*:\s*ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return _toDouble(match?.group(1));
  }

  static String? extractAccount(String smsText) {
    final match = RegExp(
      r'account\s+([0-9*]+)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return match?.group(1)?.trim();
  }

  static String? extractCounterparty(String smsText) {
    final match = RegExp(
      r'credited\s+with\s+ETB\s*[\d,]+\.?\d*\s+by\s+([^.]+?)\s*\.\s*Available',
      caseSensitive: false,
    ).firstMatch(smsText);
    return match?.group(1)?.trim();
  }

  static Map<String, String?> extractDateTime(String smsText) {
    return {'date': null, 'time': null};
  }

  static Map<String, dynamic> parseAll(String smsText) {
    final dateTime = extractDateTime(smsText);
    final url = extractReceiptUrl(smsText);
    final transactionNumber = extractTransactionTokenFromUrl(url);

    return {
      'source': 'sms_parse',
      'url': url,
      'transactionId': transactionNumber,
      'referenceNumber': transactionNumber,
      'amount': extractAmount(smsText),
      'direction': extractDirection(smsText),
      'transaction_type': null,
      'counterparty': extractCounterparty(smsText),
      'account': extractAccount(smsText),
      'date': dateTime['date'],
      'time': dateTime['time'],
      'balance': extractBalance(smsText),
      'commission': null,
      'vat': null,
    };
  }

  static double? _toDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(value.replaceAll(',', ''));
  }
}