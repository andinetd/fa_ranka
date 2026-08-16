import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fetches and parses BoA receipts served at
/// `https://cs.bankofabyssinia.com/slip/?trx=<token>`.
///
/// The slip page itself is a JavaScript SPA (empty shell), so real data comes
/// from the JSON API:
/// `https://cs.bankofabyssinia.com/api/onlineSlip/getDetails/?id=<token>`.
class BoaReceiptService {
  static const String bankName = 'BoA';

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  };

  static const _timeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>> fetchAndParseReceipt(
    String url, {
    String? smsText,
  }) async {
    final token = _tokenFromUrl(url);
    if (token == null) {
      return {
        'source': 'boa_receipt_missing_token_fallback',
        'error': 'No trx token in receipt URL',
      };
    }

    try {
      final apiUrl =
          'https://cs.bankofabyssinia.com/api/onlineSlip/getDetails/?id=$token';
      final response = await http
          .get(Uri.parse(apiUrl), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return {
          'source': 'boa_receipt_unavailable_fallback',
          'status_code': response.statusCode,
        };
      }

      if (response.body.trim().length < 50) {
        return {
          'source': 'boa_empty_json_fallback',
          'error': 'Empty JSON response',
        };
      }

      final result = parseReceiptJson(response.body);
      if (result['error'] == null && result['referenceNumber'] != null) {
        return result;
      }

      return {
        'source': 'boa_json_parse_incomplete',
        'error': result['error'],
      };
    } catch (e) {
      debugPrint('BoA receipt fetch/parse failed: $e');
      return {'source': 'boa_receipt_parse_error_fallback', 'error': e.toString()};
    }
  }

  static String? _tokenFromUrl(String url) {
    if (url.isEmpty) return null;
    final match = RegExp(
      r'trx=([A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(url);
    return match?.group(1);
  }

  /// Parses the JSON body returned by the online slip API.
  ///
  /// The API wraps rows in `header`/`body`, with the first `body` element
  /// holding the transaction fields. Keys are bank-sent labels, e.g.
  /// `Transferred Amount`, `Service Charge`, `Transaction Type`,
  /// `Payer's Name` / `Receiver's Name`, `Transaction Date`.
  static Map<String, dynamic> parseReceiptJson(String jsonBody) {
    final result = <String, dynamic>{
      'source': 'boa_html_parse',
      'referenceNumber': null,
      'payerName': null,
      'receiverName': null,
      'payerAccount': null,
      'receiverAccount': null,
      'transferredAmount': null,
      'serviceFee': null,
      'vat': null,
      'totalAmount': null,
      'paymentDate': null,
      'paymentTime': null,
      'transactionType': null,
      'paymentReference': null,
      'narrative': null,
      'bankName': bankName,
    };

    if (jsonBody.trim().length < 50) {
      result['error'] = 'Empty JSON response';
      return result;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonBody);
    } catch (e) {
      result['error'] = 'Invalid JSON: $e';
      return result;
    }

    dynamic bodyRows = decoded is Map<String, dynamic> ? decoded['body'] : null;
    if (bodyRows is! List || bodyRows.isEmpty) {
      result['error'] = 'No transaction rows in response';
      return result;
    }

    final dynamic first = bodyRows.first;
    if (first is! Map<String, dynamic>) {
      result['error'] = 'Malformed transaction row';
      return result;
    }
    final Map<String, dynamic> fields = first;

    result['referenceNumber'] = _str(fields['Transaction Reference']);
    result['payerName'] = _str(fields["Payer's Name"]) ?? _str(fields['Source Account Name']);
    result['receiverName'] = _str(fields["Receiver's Name"]);
    result['payerAccount'] = _str(fields['Source Account']);
    result['receiverAccount'] = _str(fields["Receiver's Account"]);
    result['transferredAmount'] = _amount(fields['Transferred Amount']);
    result['serviceFee'] = _amount(fields['Service Charge']);
    result['vat'] = _amount(fields['VAT (15%)']);
    result['totalAmount'] = _amount(fields['Total Amount including VAT']);
    result['transactionType'] = _str(fields['Transaction Type']);
    result['paymentReference'] = _str(fields['Payment Reference']);
    result['narrative'] = _str(fields['Narrative']);

    final dateTime = _splitDateTime(_str(fields['Transaction Date']));
    result['paymentDate'] = dateTime[0];
    result['paymentTime'] = dateTime[1];

    return result;
  }

  static String? _str(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _amount(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    var s = raw.toString().trim();
    if (s.isEmpty) return null;
    s = s.replaceAll('ETB', '').replaceAll('Birr', '').replaceAll(',', '').trim();
    return double.tryParse(s);
  }

  /// `29/05/26 16:09` -> `29/05/26` and `16:09`.
  static List<String?> _splitDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return [null, null];
    final match = RegExp(r'\s*([\d\-/]+)\s+([\d:]+)').firstMatch(raw);
    if (match != null) return [match.group(1), match.group(2)];
    return [raw, null];
  }
}