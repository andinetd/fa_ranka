import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';

import 'package:faranka/features/receipts/data/services/receipt_storage_service.dart';

class AwashReceiptService {
  /// Equivalent to parse_sms_for_receipt_fields
  static Map<String, dynamic> parseSmsForReceiptFields(String smsText) {
    Map<String, dynamic> result = {
      'source': 'sms_parse',
      'transaction_id': null,
      'date': null,
      'time': null,
      'from_account': null,
      'amount': null,
      'balance': null,
      'beneficiary_account': null,
      'beneficiary_bank': null,
      'to_account': null,
      'commission': null,
      'vat': null,
      'total': null,
      'transaction_type': null,
      'reason': null,
      'till_number': null,
      'tin': null,
      'vat_reg': null,
    };

    // Amount — try "X ETB" first (more specific to transaction amount), then "ETB X"
    var amountMatch = RegExp(
      r'(\d[\d,]*(?:\.\d+)?)\s*ETB',
      caseSensitive: false,
    ).firstMatch(smsText);
    amountMatch ??= RegExp(
      r'ETB\s*-?\s*([\d,]+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (amountMatch != null) {
      result['amount'] = double.tryParse(
        amountMatch.group(1)!.replaceAll(',', ''),
      );
    }

    // Transaction ID from URL
    final urlMatch = RegExp(
      r'awashpay\.awashbank\.com(?::\d+)?/([A-Za-z0-9\-]+)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (urlMatch != null) {
      result['transaction_id'] = urlMatch.group(1);
    }

    // Date and Time
    final dtMatch = RegExp(
      r'(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})',
    ).firstMatch(smsText);
    if (dtMatch != null) {
      result['date'] = dtMatch.group(1);
      result['time'] = dtMatch.group(2);
    }

    // Sender / Customer
    final senderMatch = RegExp(
      r'Sender\s*Name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Transaction|Sender|Beneficiary|Till|Number|Account)|$)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (senderMatch != null) {
      result['from_account'] = senderMatch.group(1)?.trim();
    }

    if (result['from_account'] == null) {
      final customerMatch = RegExp(
        r'Customer\s*Name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Account|Branch|City|VAT|TIN)|$)',
        caseSensitive: false,
      ).firstMatch(smsText);
      if (customerMatch != null) {
        result['from_account'] = customerMatch.group(1)?.trim();
      }
    }

    if (result['from_account'] == null) {
      final accountNoMatch = RegExp(
        r'Account\s*(?:No\.?|No/)?\s*:?\s*([0-9xX\*]+)',
        caseSensitive: false,
      ).firstMatch(smsText);
      if (accountNoMatch != null) {
        result['from_account'] = accountNoMatch.group(1)?.trim();
      }
    }

    // Beneficiary Account
    final benAccMatch = RegExp(
      r'To\s+([0-9]+)\s*\(',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (benAccMatch != null) {
      result['beneficiary_account'] = benAccMatch.group(1);
    }

    result['beneficiary_account'] ??= _extractField(smsText, [
      r'(?:Beneficiary|Receiver|Destination)\s*Account\s*:\s*([0-9xX\-*]+)',
    ]);

    // Beneficiary Bank
    final benBankMatch = RegExp(
      r'In\s+([A-Za-z][A-Za-z\s]+?)(?:\.|\s+Your|\s+VAT|\s+Receipt|\s+Contact|\s+Reason\b|\s+Narration\b|\s+Transaction\s*ID\b|\s+Txn\s*ID\b)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (benBankMatch != null) {
      result['beneficiary_bank'] = _cleanFieldValue(
        benBankMatch.group(1)?.trim(),
        stopPattern:
            r'\b(?:Reason|Narration|Description|Remark|Purpose|Transaction\s*ID|Txn\s*ID|Sender\s*Name|Receiver\s*Name|Beneficiary)\b',
      );
    }

    // To Account (Name)
    final toAccMatch = RegExp(
      r'To\s+[0-9]+\s*\(([A-Za-z\s]+?)(?:\s+Beneficiary)?\)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (toAccMatch != null) {
      result['to_account'] = _cleanFieldValue(
        toAccMatch.group(1)?.trim(),
        stopPattern: r'\b(?:Beneficiary|Receiver\s*Name|Sender\s*Name)\b',
      );
    }

    result['to_account'] ??= _extractField(smsText, [
      r'(?:Receiver|Beneficiary)\s*Name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Account|Bank|Reason|Till|Number)|$)',
      r'Merchant\s*:\s*([A-Za-z\s]+?)(?:\s+Till|\s+Number|$)',
      r'(?:Merchant\s+)?payment\s+(?:of\s+ETB\s+[\d,]+(?:\.\d+)?\s+)?to\s+([A-Za-z\s]+?)(?:\s+in\s+respect\s+to|\s+on\s+\d{4}-|\s+Ref|\.|$)',
    ]);

    if (smsText.toLowerCase().contains('other bank')) {
      result['transaction_type'] = 'Bank Transfer';
    }

    final walletToBankMatch = RegExp(
      r'\b(?:you\s+have\s+sent|you\s+sent|sent)\s+ETB\s*-?\s*[\d,]+(?:\.\d+)?\s+to\s+([0-9xX\*]+)(?:/([A-Za-z][A-Za-z\s&.-]*))?\b',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (walletToBankMatch != null) {
      result['transaction_type'] = 'Wallet to Main Account';
      result['reason'] ??= 'Wallet to Main Account';
      result['to_account'] ??= walletToBankMatch.group(1)?.trim();
      result['beneficiary_account'] ??= walletToBankMatch.group(1)?.trim();
      result['beneficiary_bank'] ??= walletToBankMatch.group(2)?.trim();
    }

    // Check for bank-to-bank transfers (transferred to another bank)
    final bankTransferMatch = RegExp(
      r'transferred\s+to\s+([A-Za-z\s]+?)\s+Amount',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (bankTransferMatch != null) {
      result['transaction_type'] = 'Bank Transfer';
      result['beneficiary_bank'] ??= bankTransferMatch.group(1)?.trim();
      // For bank transfers, use beneficiary bank name as reason if no reason found
      result['reason'] ??= bankTransferMatch.group(1)?.trim();
    }

    // Also check for "To X (NAME)" pattern and set to_account as counterparty
    final toAccountMatch = RegExp(
      r'To\s+[0-9]+\s*\(([A-Za-z\s]+)\)',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (toAccountMatch != null) {
      result['counterparty'] ??= toAccountMatch.group(1)?.trim();
      result['to_account'] ??= toAccountMatch.group(1)?.trim();
      // If no reason yet, use the person name as reason
      result['reason'] ??= toAccountMatch.group(1)?.trim();
    }

    if (result['transaction_type'] == null &&
        smsText.toLowerCase().contains('merchant')) {
      result['transaction_type'] = 'Merchant Payment';
    }

    final lowerText = smsText.toLowerCase();
    final looksLikeAtmWithdrawal =
        lowerText.contains('atm') ||
        lowerText.contains('cash withdrawal') ||
        lowerText.contains('cash out') ||
        (lowerText.contains('debited') &&
            lowerText.contains('commission') &&
            lowerText.contains('vat') &&
            result['to_account'] == null &&
            result['beneficiary_account'] == null);

    final looksLikeGenericDebitAlert =
        lowerText.contains('debited') &&
        (lowerText.contains('your balance now is') ||
            lowerText.contains('for any complaint or enquiry') ||
            lowerText.contains('for enquiries')) &&
        !lowerText.contains('transferred') &&
        !looksLikeAtmWithdrawal &&
        result['to_account'] == null &&
        result['beneficiary_account'] == null;

    if (looksLikeAtmWithdrawal) {
      result['transaction_type'] = 'ATM Withdrawal';
      result['reason'] = 'ATM Withdrawal';
    }

    if (looksLikeGenericDebitAlert) {
      // Generic debit alert with no recipient = ATM/cash withdrawal, not merchant payment
      result['transaction_type'] = 'ATM Withdrawal';
      result['reason'] = 'ATM Withdrawal';
    }

    // Mobile cashout debit: "You have sent X ETB From .../BANK to [phone]"
    // or "You have sent ETB X From .../BANK to [phone]"
    final looksLikeMobileCashout = RegExp(
      r'\byou\s+have\s+sent.+?from\s+[\d*]+/bank\s+to\s+\d+',
      caseSensitive: false,
    ).hasMatch(smsText);
    if (looksLikeMobileCashout) {
      result['transaction_type'] = 'Mobile Cashout';
      result['reason'] = 'Mobile Cashout';
      // Extract destination phone as counterparty
      final phoneMatch = RegExp(
        r'From\s+[\d*]+/[A-Za-z]+\s+to\s+(\d+)',
        caseSensitive: false,
      ).firstMatch(smsText);
      if (phoneMatch != null) {
        result['counterparty'] = phoneMatch.group(1)?.trim();
        result['to_account'] ??= phoneMatch.group(1)?.trim();
      }
      // Also extract source account
      final accMatch = RegExp(
        r'From\s+([\d*]+)/',
        caseSensitive: false,
      ).firstMatch(smsText);
      if (accMatch != null) {
        result['from_account'] = accMatch.group(1)?.trim();
      }
    }

    result['transaction_type'] ??= _extractField(smsText, [
      r'Transaction\s*Type\s*:\s*([A-Za-z\s\-/]+?)(?:\s+(?:Reason|Transaction\s*ID|Sender|Beneficiary|Amount|VAT|Commission|Total)|$)',
    ]);

    final smsReason = _extractField(smsText, [
      r'(?:Reason|Narration|Description|Remark|Purpose)\s*[:\-]?\s*([A-Za-z0-9 ,./()\-_]+?)(?=\s+(?:Transaction\s*ID|Txn\s*ID|Ref(?:erence)?\b|Receipt\b|Contact\b|\d{4}-\d{2}-\d{2})|$)',
    ]);
    final parsedSmsReason = _cleanFieldValue(
      smsReason,
      stopPattern:
          r'\b(?:Transaction\s*ID|Txn\s*ID|Sender\s*Name|Receiver\s*Name|Beneficiary|Reference|Ref)\b',
    );
    if (parsedSmsReason != null && parsedSmsReason.trim().isNotEmpty) {
      result['reason'] = parsedSmsReason;
    }
    final forPatternReason = _extractField(smsText, [
      r'\bfor\s+([A-Za-z0-9][A-Za-z0-9\s\-_/&()]+?)(?=\s+on\s+\d{4}-\d{2}-\d{2}|\s+with\b|\.\s*Your\b|\s+Txn\s*ID\b|\s+Transaction\s*ID\b|$)',
    ]);
    if ((result['reason'] == null ||
            (result['reason'] is String &&
                (result['reason'] as String).trim().length < 2)) &&
        forPatternReason != null &&
        forPatternReason.trim().length >= 2) {
      result['reason'] = forPatternReason.trim();
    }
    result['reason'] = _cleanFieldValue(
      result['reason'] as String?,
      stopPattern:
          r'\b(?:Transaction\s*ID|Txn\s*ID|Sender\s*Name|Receiver\s*Name|Beneficiary|Reference|Ref|with\s+Tip|credited\s+to|debited\s+from|your\s+wallet\s+account|by\b)\b',
    );

    result['commission'] = _extractAmount(
      smsText,
      r'Commission\s*:?\s*([\d,]+(?:\.\d+)?)',
    );
    result['charge'] = _extractAmount(
      smsText,
      r'Charge:\s*([\d,]+(?:\.\d+)?)',
    );
    result['vat'] = _extractAmount(smsText, r'VAT\s*:?\s*([\d,]+(?:\.\d+)?)');
    result['balance'] = _extractBalance(smsText);
    result['total'] = _extractAmount(
      smsText,
      r'Total\s*:?\s*([\d,]+(?:\.\d+)?)\s*ETB?',
    );

    result['till_number'] = _extractField(smsText, [
      r'Till\s*Number\s*:\s*([A-Za-z0-9\-]+)',
      r'Till\s*No\.?\s*:\s*([A-Za-z0-9\-]+)',
    ]);
    result['tin'] = _extractField(smsText, [
      r'TIN\s*:\s*([A-Za-z0-9\-]+)',
      r'(?:TIN|Tax)\s*(?:No|ID)\s*:\s*([A-Za-z0-9\-]+)',
    ]);
    result['vat_reg'] = _extractField(smsText, [
      r'VAT\s*Reg\s*:?\s*([0-9\-]+)',
      r'VAT\s*Reg\s*No\s*:\s*([0-9\-]+)',
      r'VAT\s*Registration\s*:?\s*([0-9\-]+)',
    ]);

    result = _deriveComputedValues(result);

    return result;
  }

  /// Equivalent to extract_text (HTML cleaner)
  static String _extractTextFromHtml(String htmlBody) {
    var document = parse(htmlBody);

    // Remove scripts and styles
    document.querySelectorAll('script, style').forEach((s) => s.remove());

    // The .text property in the html package handles most of the cleaning
    // Replace multiple spaces/newlines with single space
    return document.body?.text.replaceAll(RegExp(r'\s+'), ' ').trim() ?? "";
  }

  /// Equivalent to get_html_content + parse_receipt_html
  static Future<Map<String, dynamic>> fetchAndParseHtmlReceipt(
    String url, {
    String? smsText,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            },
          )
          .timeout(const Duration(seconds: 10));

      final contentType = response.headers['content-type'] ?? '';
      if (response.statusCode != 200 || !contentType.contains('text/html')) {
        return smsText != null
            ? {
                ...parseSmsForReceiptFields(smsText),
                'source': 'html_unavailable_fallback',
                'html_status_code': response.statusCode,
                'html_content_type': contentType,
              }
            : {'error': 'Invalid response'};
      }

      String text = _extractTextFromHtml(response.body);
      Map<String, dynamic> result = {'source': 'html_parse'};

      final localPath = await ReceiptStorageService.saveHtmlReceipt(
        transactionId: _receiptIdFromUrl(url),
        html: response.body,
      );
      result['localReceiptPath'] = localPath;

      // Transaction ID
      result['transaction_id'] = RegExp(
        r'Transaction\s*ID\s*:\s*([A-Za-z0-9\-]+)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1);
      result['transactionId'] = result['transaction_id'];

      // Date/Time supports both Transaction Time and Transaction Date formats.
      final dateTime = _extractDateTimeFromReceiptText(text);
      if (dateTime != null) {
        result['date'] = dateTime['date'];
        result['time'] = dateTime['time'];
      }

      // Amounts (Amount, Commission, VAT, Total)
      result['amount'] = _extractAmount(
        text,
        r'Amount\s*:\s*([\d,]+\.?\d*)\s*ETB',
      );
      result['commission'] = _extractAmount(
        text,
        r'Commission\s*:\s*([\d,]+\.?\d*)',
      );
      result['vat'] = _extractAmount(text, r'VAT\s*:\s*([\d,]+\.?\d*)');
      result['balance'] = _extractBalance(text);
      result['total'] = _extractAmount(
        text,
        r'Total\s*:\s*([\d,]+\.?\d*)\s*ETB',
      );

      // Names (Sender/Receiver)
      result['from_account'] = RegExp(
        r'(?:Sender|Customer)\s*Name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Transaction|Sender|Account|Branch|City|VAT|TIN)|$)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1)?.trim();

      // Direct pattern like Python: Receiver Name
      result['to_account'] ??= RegExp(
        r'Receiver\s*Name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Account|Beneficiary|Reason|Transaction)|\n|$)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1)?.trim();

      // Direct pattern for Beneficiary name
      result['to_account'] ??= RegExp(
        r'Beneficiary\s*name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Beneficiary|Account|Bank|Reason)|\n|$)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1)?.trim();

      // Direct pattern for Merchant
      result['to_account'] ??= RegExp(
        r'Merchant\s*:\s*([A-Za-z\s]+?)(?:\s+Till|\s+Number|\n|$)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1)?.trim();

      // Original pattern (fallback)
      result['to_account'] ??= RegExp(
        r'(?:Receiver|Beneficiary|Merchant)\s*(?:Name)?\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Account|Bank|Reason|Till|Number)|$)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1)?.trim();

      // Additional fields that were often missed during deep parsing.
      result['beneficiary_bank'] = _extractField(text, [
        r'(?:Beneficiary|Receiver|Destination)\s*Bank\s*:\s*([A-Za-z][A-Za-z\s&.-]{2,})',
        r'Bank\s*:\s*([A-Za-z][A-Za-z\s&.-]{2,})',
        r'In\s+([A-Za-z][A-Za-z\s]+?)(?:\.|\s+Your|\s+VAT|\s+Receipt|\s+Contact)',
      ]);

      // Direct pattern: Receiver Bank (like Python)
      result['beneficiary_bank'] ??= RegExp(
        r'Receiver\s*Bank\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Reason|Transaction|ID)|\n|$)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1)?.trim();

      result['transaction_type'] = _extractField(text, [
        r'(?:Transaction\s*Type|Type)\s*:\s*([A-Za-z\s\-/]+?)(?:\s{2,}|$)',
        r'(Bank\s*Transfer|Cash\s*Out|Cash\s*In|Purchase|Bill\s*Payment|Merchant\s*Payment|Send\s*To\s*Bank)',
      ]);

      // Prefer receipt-link fields over any SMS fallback for categorization.
      result['reason'] ??= result['to_account'] ?? result['counterparty'] ?? result['beneficiary_bank'];

      // Additional: Simple reason pattern (like Python)
      result['reason'] ??= RegExp(
        r'Reason\s*:\s*([A-Za-z0-9\s]+?)(?:\s+(?:Transaction|Sender|Beneficiary|Till|Number)|\n|$)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1)?.trim();

      final labeledReason = _extractLabeledValue(
        text,
        labels: const [
          'Reason',
          'Narration',
          'Description',
          'Remark',
          'Purpose',
          'Transaction Reason',
        ],
      );
      if (labeledReason != null && labeledReason.trim().isNotEmpty) {
        result['reason'] = labeledReason;
      }
      final forPatternReason = _extractField(text, [
        r'\bfor\s+([A-Za-z0-9][A-Za-z0-9\s\-_/&()]+?)(?=\s+on\s+\d{4}-\d{2}-\d{2}|\s+with\b|\.\s*Your\b|\s+Txn\s*ID\b|\s+Transaction\s*ID\b|$)',
      ]);
      if ((result['reason'] == null ||
              (result['reason'] is String &&
                  (result['reason'] as String).trim().length < 2)) &&
          forPatternReason != null &&
          forPatternReason.trim().length >= 2) {
        result['reason'] = forPatternReason.trim();
      }
      result['reason'] = _cleanFieldValue(
        result['reason'] as String?,
        stopPattern:
            r'\b(?:Transaction\s*ID|Txn\s*ID|Sender\s*Name|Receiver\s*Name|Beneficiary|Reference|Ref|with\s+Tip|credited\s+to|debited\s+from|your\s+wallet\s+account|by\b)\b',
      );

      result['till_number'] = _extractField(text, [
        r'Till\s*Number\s*:\s*([A-Za-z0-9\-]+)',
        r'Till\s*No\.?\s*:\s*([A-Za-z0-9\-]+)',
      ]);
      result['tin'] = _extractField(text, [r'TIN\s*:\s*([A-Za-z0-9\-]+)']);
      result['vat_reg'] = _extractField(text, [
        r'VAT\s*Reg\s*:?\s*([0-9\-]+)',
        r'VAT\s*Registration\s*:?\s*([0-9\-]+)',
      ]);

      result['from_account'] ??= _extractField(text, [
        r'Account\s*(?:No\.?|No/)?\s*:?\s*([0-9xX\*]+)',
      ]);

      result['transaction_type'] ??= _extractField(text, [
        r'Transaction\s*Type\s*:\s*([A-Za-z\s\-/]+?)(?:\s+(?:Reason|Transaction\s*ID|Sender|Beneficiary|Amount|VAT|Commission|Total)|$)',
      ]);

      final beneficiaryAccount = _extractField(text, [
        r'(?:Beneficiary|Receiver|Destination)\s*Account\s*:\s*([0-9xX\*\-]+)',
      ]);
      if (beneficiaryAccount != null) {
        result['beneficiary_account'] = beneficiaryAccount;
      }

      // Additional: Try Receiver Account directly (Python pattern)
      result['beneficiary_account'] ??= RegExp(
        r'Receiver\s*Account\s*:\s*([0-9xX*]+)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1)?.trim();

      // Keep SMS value if HTML parse couldn't find the field.
      if (smsText != null) {
        result = _preferExistingFallback(
          result,
          parseSmsForReceiptFields(smsText),
          excludedKeys: const {'reason', 'counterparty', 'to_account'},
        );
      }

      result = _deriveComputedValues(result);

      // Final sanitation pass to trim trailing label fragments from merged data.
      result['reason'] = _cleanFieldValue(
        result['reason'] as String?,
        stopPattern:
            r'\b(?:Transaction\s*ID|Txn\s*ID|Sender\s*Name|Receiver\s*Name|Beneficiary|Reference|Ref|Amount|Commission|VAT|Total)\b',
      );
      result['beneficiary_bank'] = _cleanFieldValue(
        result['beneficiary_bank'] as String?,
        stopPattern:
            r'\b(?:Reason|Narration|Description|Remark|Purpose|Transaction\s*ID|Txn\s*ID|Sender\s*Name|Receiver\s*Name|Beneficiary)\b',
      );
      result['to_account'] = _cleanFieldValue(
        result['to_account'] as String?,
        stopPattern: r'\b(?:Beneficiary|Receiver\s*Name|Sender\s*Name)\b',
      );

      return result;
    } catch (e) {
      debugPrint("HTML Parse Error: $e");
      return smsText != null
          ? {
              ...parseSmsForReceiptFields(smsText),
              'source': 'html_error_fallback',
              'html_error': e.toString(),
            }
          : {'error': e.toString()};
    }
  }

  // Helper for parsing numbers
  static double? _extractAmount(String text, String pattern) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  static double? _extractBalance(String text) {
    final patterns = [
      r'(?:Available|Current|Ledger|Account)?\s*Balance\s*(?:[:\-]\s*|is\s+now\s+|is\s+)?(?:ETB\s*)?([\d,]+(?:\.\d+)?)',
      r'(?:Bal\.?|Balance)\s*[:\-]?\s*ETB?\s*([\d,]+(?:\.\d+)?)',
      r'ETB\s*([\d,]+(?:\.\d+)?)\s*(?:available|current)?\s*balance',
    ];

    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1)!.replaceAll(',', ''));
      }
    }
    return null;
  }

  static Map<String, String>? _extractDateTimeFromReceiptText(String text) {
    final txnTime = RegExp(
      r'Transaction\s*Time\s*:\s*(\d{4}-\d{2}-\d{2})\s+(\d{1,2}:\d{2}:\d{2}\s*(?:AM|PM)?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (txnTime != null) {
      return {
        'date': txnTime.group(1)!.trim(),
        'time': txnTime.group(2)!.trim(),
      };
    }

    final txnDate = RegExp(
      r'Transaction\s*Date\s*:\s*(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})',
      caseSensitive: false,
    ).firstMatch(text);
    if (txnDate != null) {
      return {
        'date': txnDate.group(1)!.trim(),
        'time': txnDate.group(2)!.trim(),
      };
    }

    return null;
  }

  static String? _extractField(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static String? _extractLabeledValue(
    String text, {
    required List<String> labels,
  }) {
    for (final label in labels) {
      final escaped = RegExp.escape(label).replaceAll('\\ ', r'\s+');
      final pattern =
          '$escaped\\s*(?::|-)?\\s*(.+?)(?=\\s+(?:'
          r'Transaction(?:\s*ID|\s*Type|\s*Time|\s*Date)?|'
          r'Amount|Commission|VAT|Total|Sender|Receiver|Beneficiary|'
          r'Customer|Bank|Branch|City|TIN|Account|Reference|Ref|'
          r'Narration|Reason|Description|Remark|Purpose'
          r')\\s*:?|$)';

      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static Map<String, dynamic> _preferExistingFallback(
    Map<String, dynamic> parsed,
    Map<String, dynamic> fallback,
    {Set<String> excludedKeys = const {},}
  ) {
    final merged = <String, dynamic>{...parsed};
    fallback.forEach((key, value) {
      if (excludedKeys.contains(key)) return;
      final current = merged[key];
      if (current == null || (current is String && current.trim().isEmpty)) {
        merged[key] = value;
      }
    });
    if ((merged['transactionId'] == null ||
            (merged['transactionId'] is String &&
                (merged['transactionId'] as String).isEmpty)) &&
        merged['transaction_id'] != null) {
      merged['transactionId'] = merged['transaction_id'];
    }
    return merged;
  }

  static String? _cleanFieldValue(
    String? value, {
    required String stopPattern,
  }) {
    if (value == null) return null;
    final stop = RegExp(stopPattern, caseSensitive: false).firstMatch(value);
    String cleaned = stop != null
        ? value.substring(0, stop.start).trim()
        : value.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^[,.;:\-\s]+'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  static Map<String, dynamic> _deriveComputedValues(Map<String, dynamic> data) {
    final merged = <String, dynamic>{...data};
    final amount = _toDouble(merged['amount']);
    final charge = _toDouble(merged['charge']) ?? 0;
    final commission = _toDouble(merged['commission']) ?? 0;
    final vat = _toDouble(merged['vat']) ?? 0;

    if (merged['total'] == null && amount != null) {
      merged['total'] = amount + charge + commission + vat;
    }

    return merged;
  }

  /// Check if an Awash SMS is a mobile cashout notification (message 2)
  /// This is the second message received when cashing out via mobile banking:
  /// "Dear Customer, You have received X ETB From NAME. To withdraw the fund..."
  /// These messages describe how to complete the withdrawal at an ATM and should
  /// NOT be imported as a separate credit transaction.
  static bool isMobileCashoutNotification(String smsText) {
    final lower = smsText.toLowerCase();
    return lower.contains('to withdraw the fund') &&
        lower.contains('secret code') &&
        lower.contains('first 4 digits');
  }

  /// Extract the amount from a cashout notification message
  /// Returns null if no amount is found
  static double? extractCashoutNotificationAmount(String smsText) {
    final match = RegExp(
      r'you have received\s+([\d,]+\.?\d*)\s+ETB',
      caseSensitive: false,
    ).firstMatch(smsText);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', ''));
  }

  static String _receiptIdFromUrl(String url) {
    final hash = url.hashCode.toRadixString(36);
    return 'receipt_$hash';
  }
}
