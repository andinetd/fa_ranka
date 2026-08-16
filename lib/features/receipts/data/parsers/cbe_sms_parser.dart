class CbeSmsParser {
  static String? extractReceiptUrl(String smsText) {
    final normalized = smsText
        .replaceAll('\u200B', '')
        .replaceAll('\u200C', '')
        .replaceAll('\u200D', '')
        .replaceAll('\u2060', '')
        .replaceAll('\uFEFF', '')
        .trim();

    final patterns = [
      RegExp(
        r'(https?://apps\.cbe\.com\.et(?::\d+)?/[^\s)>,]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'(https?://apps\.cbe\.com\.et:100/BranchReceipt/[^\s)>,]+)',
        caseSensitive: false,
      ),
      RegExp(r'(apps\.cbe\.com\.et(?::\d+)?/[^\s)>,]+)', caseSensitive: false),
      RegExp(
        r'(apps\.cbe\.com\.et:100/BranchReceipt/[^\s)>,]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'(https?://(?:mbreciept|mbreceipt)\.cbe\.com\.et/[^\s)>,]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'((?:mbreciept|mbreceipt)\.cbe\.com\.et/[^\s)>,]+)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(normalized);
      if (match == null) continue;

      final raw = match.group(1)?.replaceFirst(RegExp(r'[\s)>,.;]+$'), '');
      if (raw == null || raw.isEmpty) continue;

      if (raw.toLowerCase().startsWith('http://') ||
          raw.toLowerCase().startsWith('https://')) {
        return raw;
      }

      return 'https://$raw';
    }

    return null;
  }

  static String? extractTransactionId(String smsText) {
    final url = extractReceiptUrl(smsText);
    if (url != null) {
      final inUrl = RegExp(
        r'(FT[A-Z0-9]+)',
        caseSensitive: false,
      ).firstMatch(url)?.group(1);
      if (inUrl != null) return inUrl;
    }

    final fromRefNo = RegExp(
      r'Ref\s*No\.?\s*(FT[A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return fromRefNo?.group(1);
  }

  static double? extractAmount(String smsText) {
    final transferred = RegExp(
      r'transfer(?:red|ed)?\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (transferred != null) {
      return _toDouble(transferred.group(1));
    }

    final credited = RegExp(
      r'credited\s+(?:by|with)\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (credited != null) {
      return _toDouble(credited.group(1));
    }

    final received = RegExp(
      r'received\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (received != null) {
      return _toDouble(received.group(1));
    }

    final total = RegExp(
      r'total\s+of\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (total != null) {
      return _toDouble(total.group(1));
    }

    final generic = RegExp(
      r'ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return _toDouble(generic?.group(1));
  }

  static double? extractTotal(String smsText) {
    final total = RegExp(
      r'total\s+of\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return _toDouble(total?.group(1));
  }

  static String? extractCounterparty(String smsText) {
    final toPattern = RegExp(r'to\s+([A-Za-z\s]+?)\s+on', caseSensitive: false);
    final toMatch = toPattern.firstMatch(smsText);
    if (toMatch != null) return toMatch.group(1)?.trim();

    final toParenPattern = RegExp(
      r'to\s+[^)]+\s*\(([^)]+)\)',
      caseSensitive: false,
    );
    final toParenMatch = toParenPattern.firstMatch(smsText);
    if (toParenMatch != null) return toParenMatch.group(1)?.trim();

    final fromAccountParenPattern = RegExp(
      r'from\s+account\s+[0-9*]+\s*\(([^)]+)\)',
      caseSensitive: false,
    );
    final fromAccountParenMatch = fromAccountParenPattern.firstMatch(smsText);
    if (fromAccountParenMatch != null) {
      return fromAccountParenMatch.group(1)?.trim();
    }

    final fromPattern = RegExp(r'from\s+([A-Za-z\s]+?),', caseSensitive: false);
    final fromMatch = fromPattern.firstMatch(smsText);
    return fromMatch?.group(1)?.trim();
  }

  static String extractDirection(String smsText) {
    final text = smsText.toLowerCase();
    if (text.contains('credited') ||
        text.contains('you have received') ||
        text.contains('received etb')) {
      return 'Credit';
    }
    if (text.contains('debited') ||
        text.contains('you have sent') ||
        text.contains('have sent') ||
        text.contains('sent etb') ||
        text.contains('debit transaction') ||
        text.contains('debit transaction of') ||
        text.contains('a debit transaction') ||
        text.contains('transferred') ||
        text.contains('transfered')) {
      return 'Debit';
    }
    return 'Unknown';
  }

  static Map<String, String?> extractDateTime(String smsText) {
    final first = RegExp(
      r'(\d{1,2}/\d{1,2}/\d{4})\s+at\s+(\d{1,2}:\d{2}:\d{2})',
    ).firstMatch(smsText);
    if (first != null) {
      return {'date': first.group(1), 'time': first.group(2)};
    }

    final second = RegExp(
      r'(\d{1,2}/\d{1,2}/\d{4}),\s*(\d{1,2}:\d{2}:\d{2})',
    ).firstMatch(smsText);
    return {'date': second?.group(1), 'time': second?.group(2)};
  }

  static String? extractAccount(String smsText) {
    final match = RegExp(
      r'account\s+([0-9*]+)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return match?.group(1);
  }

  static double? extractBalance(String smsText) {
    final match = RegExp(
      r'Current\s+Balance\s+(?:is\s+)?ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);
    return _toDouble(match?.group(1));
  }

  static Map<String, double?> extractCommissionVat(String smsText) {
    final commissionMatch = RegExp(
      r'S\.?charge\s+of\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);

    final vatMatch = RegExp(
      r'15%\s*VAT\s+of\s+ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(smsText);

    return {
      'commission': _toDouble(commissionMatch?.group(1)),
      'vat': _toDouble(vatMatch?.group(1)),
    };
  }

  static Map<String, dynamic> parseAll(String smsText) {
    final dateTime = extractDateTime(smsText);
    final charges = extractCommissionVat(smsText);

    return {
      'source': 'sms_parse',
      'url': extractReceiptUrl(smsText),
      'transactionId': extractTransactionId(smsText),
      'amount': extractAmount(smsText),
      'total': extractTotal(smsText),
      'direction': extractDirection(smsText),
      'counterparty': extractCounterparty(smsText),
      'date': dateTime['date'],
      'time': dateTime['time'],
      'account': extractAccount(smsText),
      'balance': extractBalance(smsText),
      'commission': charges['commission'],
      'vat': charges['vat'],
    };
  }

  static double? _toDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(value.replaceAll(',', ''));
  }
}
