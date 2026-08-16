import 'package:html/parser.dart' show parse;

class CbeHtmlReceiptParser {
  static Map<String, dynamic> parseFromContent(String htmlContent) {
    final result = _createEmptyResult();

    if (htmlContent.trim().length < 50) {
      result['error'] = 'Empty HTML response';
      return result;
    }

    final text = _extractTextFromHtml(htmlContent);

    if (text.length < 30) {
      result['error'] = 'Insufficient text content after stripping HTML';
      return result;
    }

    _parseReferenceNumber(text, result);
    _parseCustomerName(text, result);
    _parsePayer(text, result);
    _parseReceiver(text, result);
    _parseDateTime(text, result);
    _parseReason(text, result);
    _parseAmounts(text, result);
    _parseAmountWords(text, result);

    return result;
  }

  static Map<String, dynamic> _createEmptyResult() {
    return {
      'source': 'html_parse',
      'referenceNumber': null,
      'customerName': null,
      'payerName': null,
      'payerAccount': null,
      'receiverName': null,
      'receiverAccount': null,
      'paymentDate': null,
      'paymentTime': null,
      'reason': null,
      'transferredAmount': null,
      'serviceCharge': null,
      'vat': null,
      'totalAmount': null,
      'amountWords': null,
      'bankName': 'Commercial Bank of Ethiopia',
    };
  }

  static String _extractTextFromHtml(String html) {
    var document = parse(html);
    document.querySelectorAll('script, style').forEach((s) => s.remove());

    String text = document.body?.text ?? '';
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  static void _parseReferenceNumber(String text, Map<String, dynamic> result) {
    final match = RegExp(
      r'(?:VAT\s*Receipt\s*No|Reference\s*No\.?\s*\(VAT\s*Invoice\s*No\)|VAT\s*Invoice\s*No)\s*[:\-]?\s*([A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['referenceNumber'] = match.group(1)?.trim();
    }
  }

  static void _parseCustomerName(String text, Map<String, dynamic> result) {
    final match = RegExp(
      r'Customer\s+Name\s*[:\-]\s*([^\n]+?)(?:\s+(?:Region|City|Sub\s*City|Wereda|VAT|TIN|Branch)\b|$)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['customerName'] = match.group(1)?.trim();
    }
  }

  static void _parsePayer(String text, Map<String, dynamic> result) {
    var match = RegExp(
      r'Payer\s*[:\-]\s*([^\n]+?)(?:\s+Account\b|\s+Receiver\b|\s+Payment\s+Date\b|$)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['payerName'] = match.group(1)?.trim();
    }

    match = RegExp(
      r'Account\s*[:\-]\s*([0-9*]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['payerAccount'] = match.group(1)?.trim();
    }
  }

  static void _parseReceiver(String text, Map<String, dynamic> result) {
    var match = RegExp(
      r'Receiver\s*[:\-]\s*([^\n]+?)(?:\s+Account\b|\s+Payment\s+Date\b|\s+Reason\b|$)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['receiverName'] = match.group(1)?.trim();
    }

    final accounts = RegExp(
      r'Account\s*[:\-]?\s*([0-9*]+)',
      caseSensitive: false,
    ).allMatches(text);
    final accountsList = accounts.map((m) => m.group(1)?.trim()).toList();
    if (accountsList.length >= 2 && accountsList[1] != null) {
      result['receiverAccount'] = accountsList[1];
    }
  }

  static void _parseDateTime(String text, Map<String, dynamic> result) {
    final match = RegExp(
      r'Payment\s*Date\s*&\s*Time\s*[:\-]?\s*([A-Za-z]{3}\s+\d{1,2},\s+\d{4}|\d{1,2}/\d{1,2}/\d{4})[,\s]+(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['paymentDate'] = match.group(1)?.trim();
      result['paymentTime'] = match.group(2)?.trim();
    }
  }

  static void _parseReason(String text, Map<String, dynamic> result) {
    final match = RegExp(
      r'Reason\s*/\s*Type\s*of\s*service\s*[:\-│\|票]\s*([^\n]+?)(?:\s+Transferred\b|\s+Service\s+Charge\b|\s+Total\s+amount\b|$)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['reason'] = match.group(1)?.trim();
    }
  }

  static void _parseAmounts(String text, Map<String, dynamic> result) {
    var match = RegExp(
      r'Transferred\s*Amount\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['transferredAmount'] = _parseDouble(match.group(1));
    }

    match = RegExp(
      r'Service\s*Charge(?:\s*\(.*?\))?\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['serviceCharge'] = _parseDouble(match.group(1));
    }

    match = RegExp(
      r'15%\s*VAT(?:\s*(?:and|of|on)\s*(?:Disaster\s+Recovery|Commission))?\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['vat'] = _parseDouble(match.group(1));
    }

    match = RegExp(
      r"Total\s*amount\s*debited\s*from\s*customer(?:'s|s)?\s*account\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB",
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['totalAmount'] = _parseDouble(match.group(1));
    } else {
      match = RegExp(
        r'Total\s*amount\s*debited\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB',
        caseSensitive: false,
      ).firstMatch(text);
      if (match != null) {
        result['totalAmount'] = _parseDouble(match.group(1));
      }
    }
  }

  static void _parseAmountWords(String text, Map<String, dynamic> result) {
    final match = RegExp(
      r'Amount\s+in\s+Word\s*[:\-]?\s*([^\n]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      result['amountWords'] = match.group(1)?.trim();
    }
  }

  static double? _parseDouble(String? value) {
    if (value == null) return null;
    final cleaned = value.replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }
}
