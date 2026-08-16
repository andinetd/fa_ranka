import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fetches and parses Telebirr HTML receipts served at
/// `https://transactioninfo.ethiotelecom.et/receipt/<token>`.
class TelebirrReceiptService {
  static const String bankName = 'Telebirr';

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  };

  static const _timeout = Duration(seconds: 10);

  static Future<Map<String, dynamic>> fetchAndParseReceipt(
    String url, {
    String? smsText,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return {
          'source': 'telebirr_receipt_unavailable_fallback',
          'status_code': response.statusCode,
        };
      }

      if (response.body.trim().length < 50) {
        return {'source': 'telebirr_empty_html_fallback', 'error': 'Empty HTML response'};
      }

      final result = parseReceiptHtml(response.body);
      if (result['error'] == null && result['referenceNumber'] != null) {
        return result;
      }

      return {
        'source': 'telebirr_html_parse_incomplete',
        'error': result['error'],
      };
    } catch (e) {
      debugPrint('Telebirr receipt fetch/parse failed: $e');
      return {'source': 'telebirr_receipt_parse_error_fallback', 'error': e.toString()};
    }
  }

  /// Parses a Telebirr receipt page and extracts all transaction fields.
  /// Ported from faranka/telebirr_parser_gui.py (parse_telebirr_receipt_html).
  static Map<String, dynamic> parseReceiptHtml(String htmlContent) {
    final result = <String, dynamic>{
      'source': 'telebirr_html_parse',
      'referenceNumber': null,
      'payerName': null,
      'payerNumber': null,
      'payerAccountType': null,
      'payerTin': null,
      'payerVatRegNo': null,
      'payerVatRegDate': null,
      'receiverName': null,
      'receiverNumber': null,
      'transactionStatus': null,
      'paymentDate': null,
      'paymentTime': null,
      'settledAmount': null,
      'exciseTax': null,
      'stampDuty': null,
      'discountAmount': null,
      'serviceFee': null,
      'serviceFeeVat': null,
      'totalPaidAmount': null,
      'amountWords': null,
      'paymentMode': null,
      'paymentReason': null,
      'paymentChannel': null,
      'customerNote': null,
      'bankName': bankName,
    };

    if (htmlContent.trim().length < 50) {
      result['error'] = 'Empty HTML response';
      return result;
    }

    // Strip comments (the receipt sometimes contains commented-out rows).
    final cleaned =
        htmlContent.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

    // Split into rows of non-empty cell texts.
    final rows = <List<String>>[];
    for (final row in cleaned.split('</tr>')) {
      final tds = RegExp(r'<td[^>]*>(.*?)</td>', dotAll: true)
          .allMatches(row)
          .map((m) => m.group(1)!)
          .toList();
      final cells = <String>[];
      for (final cell in tds) {
        var t = cell.replaceAll(RegExp(r'<[^>]+>'), ' ');
        t = _unescapeHtml(t);
        t = t.replaceAll('\u00a0', ' ').replaceAll('\u200b', '');
        t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (t.isNotEmpty) cells.add(t);
      }
      if (cells.isNotEmpty) rows.add(cells);
    }

    // Start at the transaction table (Payer Name row onwards).
    var startIdx = rows.length;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].any((c) => c.contains('Payer Name'))) {
        startIdx = i;
        break;
      }
    }

    var i = startIdx;
    while (i < rows.length) {
      final cells = rows[i];
      final joined = cells.join(' | ');

      // Invoice details table: 3-column label row followed by value row.
      if (joined.contains('Invoice No') &&
          joined.contains('Payment date') &&
          joined.contains('Settled Amount')) {
        if (i + 1 < rows.length) {
          final vals = rows[i + 1];
          if (vals.isNotEmpty && !vals.any((c) => c.contains('Invoice'))) {
            result['referenceNumber'] = vals[0].trim().isEmpty
                ? null
                : vals[0].trim();
          }
          if (vals.length > 1) {
            final split = _splitDateTime(vals[1]);
            result['paymentDate'] = split[0];
            result['paymentTime'] = split[1];
          }
          if (vals.length > 2) {
            result['settledAmount'] = _toAmount(vals[2]);
          }
        }
        i += 2;
        continue;
      }

      // 1- or 2-cell rows: label [| value].
      final field = _matchReceiptLabel(cells[0]);
      if (field != null) {
        var value = cells.length > 1 ? cells[1].trim() : '';
        if (value.isEmpty) {
          value = _extractInlineValue(cells[0]) ?? '';
        }
        if (value.isEmpty) {
          result[field] = null;
        } else if (_amountFields.contains(field)) {
          result[field] = _toAmount(value);
        } else if (field == 'paymentDate') {
          final split = _splitDateTime(value);
          result['paymentDate'] = split[0];
          result['paymentTime'] = split[1];
        } else {
          result[field] = value;
        }
      }
      i++;
    }

    return result;
  }

  static double? _toAmount(dynamic raw) {    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    var s = raw.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    s = s.replaceAll('ETB', '').replaceAll('Birr', '').replaceAll(',', '').trim();
    return double.tryParse(s);
  }

  static List<String?> _splitDateTime(String raw) {
    if (raw.isEmpty) return [null, null];
    final match = RegExp(r'\s*([\d\-/]+)\s+([\d:]+)').firstMatch(raw);
    if (match != null) return [match.group(1), match.group(2)];
    return [raw, null];
  }

  // English label fragments (ordered longest-first so 'Service fee VAT' wins
  // over 'Service fee') used to map a receipt row label to a field key.
  static const _labelToField = <String, String>{
    'service fee vat': 'serviceFeeVat',
    'service fee': 'serviceFee',
    'payer telebirr no': 'payerNumber',
    'payer account type': 'payerAccountType',
    'payer name': 'payerName',
    'payer tin': 'payerTin',
    'vat reg. date': 'payerVatRegDate',
    'vat reg. no': 'payerVatRegNo',
    'credited party name': 'receiverName',
    'credited party account no': 'receiverNumber',
    'transaction status': 'transactionStatus',
    'excise tax': 'exciseTax',
    'stamp duty': 'stampDuty',
    'discount amount': 'discountAmount',
    'total paid amount': 'totalPaidAmount',
    'total amount in word': 'amountWords',
    'payment mode': 'paymentMode',
    'payment reason': 'paymentReason',
    'payment channel': 'paymentChannel',
    'customer note': 'customerNote',
  };

  static String? _matchReceiptLabel(String label) {
    final l = label.toLowerCase();
    for (final entry in _labelToField.entries) {
      if (l.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Extracts a value that sits in the same cell as its label, e.g.
  /// 'የክፍያው ሁኔታ/transaction status Completed'.
  static String? _extractInlineValue(String cellText) {
    final l = cellText.toLowerCase();
    for (final frag in _labelToField.keys) {
      final pos = l.indexOf(frag);
      if (pos >= 0) {
        final after = cellText.substring(pos + frag.length).trim();
        if (after.isNotEmpty) return after;
      }
    }
    return null;
  }

  static const _amountFields = <String>{
    'settledAmount',
    'exciseTax',
    'stampDuty',
    'discountAmount',
    'serviceFee',
    'serviceFeeVat',
    'totalPaidAmount',
  };

  static String _unescapeHtml(String input) {
    var result = input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)),
    );
    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
    return result;
  }
}
