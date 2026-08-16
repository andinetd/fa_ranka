class TelebirrSmsParser {
  static const String senderName = 'Ethio telecom';

  static String? extractReceiptUrl(String smsText) {
    final match = RegExp(
      r'https?://transactioninfo\.ethiotelecom\.et/receipt/[A-Z0-9]+',
      caseSensitive: false,
    ).firstMatch(smsText);
    return match?.group(0);
  }

  static String? extractTransactionNumber(String smsText) {
    final match = RegExp(
      r'transaction\s+number\s+is\s+([A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return match?.group(1)?.trim();
  }

  static String? extractTransactionFromUrl(String url) {
    if (url.isEmpty) return null;
    final match = RegExp(
      r'/receipt/([A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(url);
    return match?.group(1);
  }

  static double? extractAmount(String smsText) {
    final match = RegExp(
      r'ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return _toDouble(match?.group(1));
  }

  static String? extractCounterparty(String smsText) {
    final match = RegExp(
      r'(?:from|to)\s+([A-Za-z][A-Za-z .\-]+?)\s*\(',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (match != null) return match.group(1)?.trim();

    final airtime = RegExp(
      r'airtime\s+from\s+(\d{9,12})',
      caseSensitive: false,
    ).firstMatch(smsText);
    return airtime?.group(1)?.trim();
  }

  static String? extractCounterpartyNumber(String smsText) {
    final match = RegExp(r'\(([0-9*]+)\)').firstMatch(smsText);
    if (match != null) return match.group(1)?.trim();

    final airtime = RegExp(
      r'airtime\s+from\s+(\d{9,12})',
      caseSensitive: false,
    ).firstMatch(smsText);
    return airtime?.group(1)?.trim();
  }

  static String extractDirection(String smsText) {
    final textLower = smsText.toLowerCase();
    if (textLower.contains('airtime')) return 'Credit';
    if (textLower.contains('received')) return 'Credit';
    if (textLower.contains('transferred')) return 'Debit';
    if (textLower.contains('paid')) return 'Debit';
    return 'Unknown';
  }

  static bool isAirtime(String smsText) =>
      smsText.toLowerCase().contains('airtime');

  static String extractSmsType(String smsText) {
    final textLower = smsText.toLowerCase();
    if (textLower.contains('airtime')) return 'Airtime Purchase';
    if (textLower.contains('received')) return 'Money Received';
    if (textLower.contains('transferred')) return 'Money Sent';
    if (textLower.contains('package') || textLower.contains('bonus')) {
      return 'Package Purchase';
    }
    return 'Unknown';
  }

  static Map<String, String?> extractDateTime(String smsText) {
    final match = RegExp(
      r'on\s+(\d{1,2}/\d{1,2}/\d{4})\s+(\d{1,2}:\d{2}:\d{2})',
    ).firstMatch(smsText);
    return {'date': match?.group(1), 'time': match?.group(2)};
  }

  static double? extractBalance(String smsText) {
    final match = RegExp(
      r'balance\s+is\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return _toDouble(match?.group(1));
  }

  static double? extractServiceFee(String smsText) {
    final match = RegExp(
      r'service\s+fee\s+is\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return _toDouble(match?.group(1));
  }

  static double? extractVat(String smsText) {
    final match = RegExp(
      r'VAT\s+on\s+the\s+service\s+fee\s+is\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return _toDouble(match?.group(1));
  }

  static Map<String, dynamic> parseAll(String smsText) {
    final dateTime = extractDateTime(smsText);
    final transactionNumber = extractTransactionNumber(smsText);

    return {
      'source': 'sms_parse',
      'url': extractReceiptUrl(smsText),
      'transactionId': transactionNumber,
      'referenceNumber': transactionNumber,
      'amount': extractAmount(smsText),
      'direction': extractDirection(smsText),
      'transaction_type': extractSmsType(smsText),
      'counterparty': extractCounterparty(smsText),
      'counterpartyNumber': extractCounterpartyNumber(smsText),
      'receiverNumber': extractCounterpartyNumber(smsText),
      'date': dateTime['date'],
      'time': dateTime['time'],
      'balance': extractBalance(smsText),
      'commission': extractServiceFee(smsText),
      'vat': extractVat(smsText),
      'isAirtime': isAirtime(smsText),
    };
  }

  static double? _toDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(value.replaceAll(',', ''));
  }
}
