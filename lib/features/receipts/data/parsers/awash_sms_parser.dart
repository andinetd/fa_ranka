class AwashSmsParser {
  /// Extract receipt URL from Awash SMS
  static String? extractReceiptUrl(String smsText) {
    final normalizedText = _normalizeSmsText(smsText);

    // Parser-GUI style strict pattern (http(s) + port + path).
    final guiStylePattern = RegExp(
      r'(https?://awashpay\.awashbank\.com:\d+/[A-Za-z0-9\-/_]+)',
      caseSensitive: false,
    );
    final guiMatch = guiStylePattern.firstMatch(normalizedText);
    if (guiMatch != null) {
      return _cleanAndNormalizeUrl(guiMatch.group(1));
    }

    // Match the most common full URL format first.
    final fullUrlPattern = RegExp(
      r'(https?://awashpay\.awashbank\.com(?::\d+)?/[^\s)>,]+)',
      caseSensitive: false,
    );
    final fullMatch = fullUrlPattern.firstMatch(normalizedText);
    if (fullMatch != null) {
      return _cleanAndNormalizeUrl(fullMatch.group(1));
    }

    // Fallback for SMS that omit scheme: awashpay.awashbank.com:9090/...
    final noSchemePattern = RegExp(
      r'(awashpay\.awashbank\.com(?::\d+)?/[^\s)>,]+)',
      caseSensitive: false,
    );
    final noSchemeMatch = noSchemePattern.firstMatch(normalizedText);
    if (noSchemeMatch != null) {
      return _cleanAndNormalizeUrl(noSchemeMatch.group(1));
    }

    // Last fallback: find any URL-like token that contains awashpay domain.
    final tokenPattern = RegExp(
      r'((?:https?://)?[^\s]*awashpay\.awashbank\.com[^\s]*)',
      caseSensitive: false,
    );
    final tokenMatch = tokenPattern.firstMatch(normalizedText);
    if (tokenMatch != null) {
      return _cleanAndNormalizeUrl(tokenMatch.group(1));
    }

    // Final fallback for messages that split the URL with spaces/newlines.
    final brokenUrlPattern = RegExp(
      r'((?:https?\s*:\s*\/\s*\/\s*)?awashpay\s*\.\s*awashbank\s*\.\s*com(?:\s*:\s*\d+)?(?:\s*\/\s*[A-Za-z0-9\-_/]+)+)',
      caseSensitive: false,
    );
    final brokenMatch = brokenUrlPattern.firstMatch(normalizedText);
    if (brokenMatch != null) {
      return _normalizeBrokenUrl(brokenMatch.group(1));
    }

    return null;
  }

  static String _normalizeSmsText(String smsText) {
    return smsText
        .replaceAll('\u200B', '')
        .replaceAll('\u200C', '')
        .replaceAll('\u200D', '')
        .replaceAll('\u2060', '')
        .replaceAll('\uFEFF', '')
        .trim();
  }

  static String? _cleanAndNormalizeUrl(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceFirst(RegExp(r'[\s)>,.;]+$'), '');
    if (cleaned.isEmpty) return null;
    if (cleaned.toLowerCase().startsWith('http://') ||
        cleaned.toLowerCase().startsWith('https://')) {
      return cleaned;
    }
    return 'https://$cleaned';
  }

  static String? _normalizeBrokenUrl(String? raw) {
    if (raw == null) return null;
    var compact = raw.replaceAll(RegExp(r'\s+'), '');
    compact = compact
        .replaceAll('awashpay.awashbank.com', 'awashpay.awashbank.com')
        .replaceAll('AWASHPAY.AWASHBANK.COM', 'awashpay.awashbank.com');
    if (compact.isEmpty) return null;

    if (compact.toLowerCase().startsWith('http://') ||
        compact.toLowerCase().startsWith('https://')) {
      return _cleanAndNormalizeUrl(compact);
    }

    return _cleanAndNormalizeUrl('https://$compact');
  }

  /// Extract amount from SMS and return as a double
  static double? extractAmount(String smsText) {
    // Pattern 1: "2000.00 ETB" (amount before ETB — preferred to avoid capturing balance)
    final pattern1 = RegExp(r'([\d,]+\.?\d*)\s*ETB', caseSensitive: false);
    // Pattern 2: "ETB 2,000" or "ETB-500.00"
    final pattern2 = RegExp(r'ETB[-]?\s*([\d,]+\.?\d*)', caseSensitive: false);

    var match = pattern1.firstMatch(smsText);
    if (match != null) {
      final clean = match.group(1)!.replaceAll(',', '');
      final parsed = double.tryParse(clean);
      if (parsed != null) return parsed;
    }

    match = pattern2.firstMatch(smsText);
    if (match != null) {
      final clean = match.group(1)!.replaceAll(',', '');
      final parsed = double.tryParse(clean);
      if (parsed != null) return parsed;
    }

    return null;
  }

  /// Extract transaction ID from SMS
  static String? extractTransactionId(String smsText) {
    // Pattern 1: "Txn ID: 251222074633844"
    final pattern1 = RegExp(r'Txn ID:\s*([0-9]+)', caseSensitive: false);
    // Pattern 2: "REF 260..."
    final pattern2 = RegExp(r'REF\s*([0-9]+)', caseSensitive: false);

    final match = pattern1.firstMatch(smsText) ?? pattern2.firstMatch(smsText);
    return match?.group(1);
  }

  /// Extract counterparty name from SMS
  static String? extractCounterparty(String smsText) {
    // Pattern 1: "from DEREJE MENGIST on"
    final pattern1 = RegExp(
      r'from\s+([A-Za-z\s]+?)\s+on',
      caseSensitive: false,
    );
    // Pattern 2: "To 1000581944776 (RIYAD SHERFA RESHID)"
    final pattern2 = RegExp(
      r'To\s+[0-9]+\s*\(([A-Za-z\s]+)\)',
      caseSensitive: false,
    );
    // Pattern 3: "To (01320271573900) - ARSEMA TESFAYE ADANE by Transaction ID ..."
    final pattern3 = RegExp(
      r'To\s*\([0-9]+\)\s*-\s*([A-Za-z\s]+?)(?=\s+by\s+Transaction\s+ID|\s+charge|\s+VAT|\s+Date|\.|$)',
      caseSensitive: false,
    );
    // Pattern 4: "transferred to COMMERCIAL BANK OF ETHIOPIA Amount ... To 1000258124581 (ABDELA YIBRIE ADEM)"
    // Extract name from parentheses
    final pattern4 = RegExp(
      r'\(([A-Z]+(?:\s+[A-Z]+)+)\)',
      caseSensitive: false,
    );
    // Pattern 5: "From 01335******300/BANK to 251930389756" — cashout destination phone
    final pattern5 = RegExp(
      r'From\s+[\d*]+/[A-Za-z]+\s+to\s+(\d+)',
      caseSensitive: false,
    );
    // Pattern 6: "From ANDINET DEREJE MENGIST." — name with period but no "on"
    final pattern6 = RegExp(
      r'From\s+([A-Za-z\s]+?)\.',
      caseSensitive: false,
    );

    var match =
        pattern1.firstMatch(smsText) ??
        pattern2.firstMatch(smsText) ??
        pattern3.firstMatch(smsText);
    match ??= pattern4.firstMatch(smsText);
    match ??= pattern5.firstMatch(smsText);
    match ??= pattern6.firstMatch(smsText);
    return match?.group(1)?.trim();
  }

  /// Extract a human-readable reason for categorization.
  /// For transfer alerts, this should usually be the recipient name.
  static String? extractReason(String smsText) {
    final counterparty = extractCounterparty(smsText);
    if (counterparty != null && counterparty.trim().isNotEmpty) {
      return counterparty.trim();
    }

    final reasonPattern = RegExp(
      r'(?:Reason|Narration|Description|Remark|Purpose)\s*[:\-]?\s*([A-Za-z0-9 ,./()\-_]+?)(?=\s+(?:Transaction\s*ID|Txn\s*ID|Ref(?:erence)?\b|Receipt\b|Date\b)|\.|$)',
      caseSensitive: false,
    );
    final reasonMatch = reasonPattern.firstMatch(smsText);
    return reasonMatch?.group(1)?.trim();
  }

  /// Determine if transaction is credit or debit
  static String extractDirection(String smsText) {
    final textLower = smsText.toLowerCase();
    if (textLower.contains('credited') || textLower.contains('received')) {
      return 'Credit';
    } else if (textLower.contains('debited') ||
        textLower.contains('sent') ||
        textLower.contains('you have sent') ||
        textLower.contains('you sent') ||
        textLower.contains('bought airtime') ||
        textLower.contains('airtime worth') ||
        textLower.contains('airtime purchase') ||
        textLower.contains('transferred') ||
        textLower.contains('merchant payment') ||
        textLower.contains('payment of')) {
      return 'Debit';
    }
    return 'Unknown';
  }

  /// Extract date and time from SMS
  /// Returns a Map with 'date' and 'time' keys
  static Map<String, String?> extractDateTime(String smsText) {
    // Pattern: "2025-12-22 07:46:29"
    final pattern = RegExp(r'(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})');
    final match = pattern.firstMatch(smsText);

    return {'date': match?.group(1), 'time': match?.group(2)};
  }

  /// Helper method to parse everything at once into a Map
  static Map<String, dynamic> parseAll(String smsText) {
    final dateTime = extractDateTime(smsText);
    return {
      'direction': extractDirection(smsText),
      'amount': extractAmount(smsText),
      'transactionId': extractTransactionId(smsText),
      'balance': extractBalance(smsText),
      'counterparty': extractCounterparty(smsText),
      'reason': extractReason(smsText),
      'date': dateTime['date'],
      'time': dateTime['time'],
      'url': extractReceiptUrl(smsText),
      'charge': extractCharge(smsText),
      'vat': extractVat(smsText),
    };
  }

  /// Extract charge/commission amount from SMS
  /// Matches "Charge: 0.90" or "S.charge of ETB X" or "Commission: X"
  static double? extractCharge(String smsText) {
    final patterns = [
      RegExp(r'Charge:\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'S\.?charge\s+of\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'Commission\s*:?\s*([\d,]+(?:\.\d+)?)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(smsText);
      if (match != null) {
        return double.tryParse(match.group(1)!.replaceAll(',', ''));
      }
    }
    return null;
  }

  /// Extract VAT amount from SMS
  /// Matches "VAT: 0.14" or "15% VAT of ETB X"
  static double? extractVat(String smsText) {
    final patterns = [
      RegExp(r'VAT:\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'15%\s*VAT\s+of\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'VAT\s*:?\s*([\d,]+(?:\.\d+)?)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(smsText);
      if (match != null) {
        return double.tryParse(match.group(1)!.replaceAll(',', ''));
      }
    }
    return null;
  }

  static double? extractBalance(String smsText) {
    final patterns = [
      RegExp(
        r'(?:Available|Current|Ledger|Account)?\s*Balance\s*[:\-]?\s*(?:ETB\s*)?([\d,]+(?:\.\d+)?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:Bal\.?|Balance)\s*[:\-]?\s*ETB?\s*([\d,]+(?:\.\d+)?)',
        caseSensitive: false,
      ),
      RegExp(
        r'ETB\s*([\d,]+(?:\.\d+)?)\s*(?:available|current)?\s*balance',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:available|current)?\s*balance\s+is\s+(?:now\s+)?ETB\s*([\d,]+(?:\.\d+)?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(smsText);
      if (match != null) {
        return double.tryParse(match.group(1)!.replaceAll(',', ''));
      }
    }
    return null;
  }
}
