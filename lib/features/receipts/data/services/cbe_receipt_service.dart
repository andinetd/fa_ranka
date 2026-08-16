import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:faranka/features/receipts/data/services/receipt_storage_service.dart';
import 'cbe_html_receipt_parser.dart';

class CbeReceiptService {
  static const _v2ApiHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Accept': 'application/json',
    'X-App-ID': 'd1292e42-7400-49de-a2d3-9731caa4c819',
    'X-App-Version': '0a01980b-9859-1369-8198-59f403820000',
  };

  static Future<Map<String, dynamic>> fetchAndParseReceipt(
    String url, {
    String? smsText,
  }) async {
    try {
      // 1) If this is a v2 token URL, try the v2 API first.
      if (_isV2TokenUrl(url)) {
        final v2Result = await _fetchAndParseV2Receipt(url);
        if (v2Result['source'] == 'cbe_v2_api_parse') {
          return v2Result;
        }
        // v2 failed -- fall through to the old-URL flow below.
      }

      // 2) Normalise to the old PDF/HTML URL format.
      url = _convertNewUrlToOld(url);

      // 3) Fetch the receipt content.
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            },
          )
          .timeout(const Duration(seconds: 10));

      final contentType = (response.headers['content-type'] ?? '')
          .toLowerCase();
      final bodyLooksPdf =
          response.bodyBytes.length >= 4 &&
          response.bodyBytes[0] == 0x25 && // %
          response.bodyBytes[1] == 0x50 && // P
          response.bodyBytes[2] == 0x44 && // D
          response.bodyBytes[3] == 0x46; // F
      final isPdf =
          contentType.contains('application/pdf') ||
          contentType.contains('application/octet-stream') ||
          bodyLooksPdf;

      // 4) If the response is a valid PDF, parse it.
      if (response.statusCode == 200 && isPdf) {
        return await _parsePdfResponse(response, receiptUrl: url);
      }

      // 5) Not a valid PDF -- try parsing the response body as an HTML receipt.
      if (response.body.length >= 50) {
        final htmlResult =
            CbeHtmlReceiptParser.parseFromContent(response.body);
        if (htmlResult['error'] == null &&
            htmlResult['referenceNumber'] != null) {
          final refNum = htmlResult['referenceNumber'] as String?;
          final localPath = await ReceiptStorageService.saveHtmlReceipt(
            transactionId: refNum ?? _receiptIdFromUrl(url),
            html: response.body,
          );
          final mapped = _mapHtmlResult(htmlResult);
          mapped['localReceiptPath'] = localPath;
          return mapped;
        }
      }

      // 6) Neither PDF nor parseable HTML receipt.
      return {
        'source': 'cbe_pdf_unavailable_fallback',
        'pdf_status_code': response.statusCode,
        'pdf_content_type': contentType,
      };
    } catch (e) {
      debugPrint('CBE receipt fetch/parse failed: $e');
      return {'source': 'cbe_pdf_parse_error_fallback', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _parsePdfResponse(http.Response response, {String? receiptUrl}) async {
    final doc = PdfDocument(inputBytes: response.bodyBytes);
    final extractor = PdfTextExtractor(doc);
    final rawText = extractor.extractText();
    doc.dispose();

    final text = rawText.trim();
    final flatText = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    final referenceNumber = _extractField(flatText, [
      r'Reference\s*No\.?\s*\(VAT\s*Invoice\s*No\)\s*([A-Z0-9]+)',
      r'VAT\s*Invoice\s*No\s*([A-Z0-9]+)',
      r'(FT[0-9A-Z]+)',
    ]);

    final payerName = _extractField(flatText, [
      r'Payer\s+([A-Za-z0-9\s]+?)(?=\s+Account|\s+Receiver|\s+Payment|$)',
      r'Customer\s*Name\s*:?\s*([A-Za-z\s]+?)(?=\s+Account|$)',
    ]);

    final receiverName = _extractField(flatText, [
      r'Receiver\s+([A-Za-z0-9\s]+?)(?=\s+Account|\s+Payment|$)',
    ]);

    final reason = _extractReason(text, flatText);

    final transferredAmount = _extractAmount(flatText, [
      r'Transferred\s*Amount\s+([\d,]+\.?\d*)\s*ETB',
    ]);

    final commission = _extractAmount(flatText, [
      r'Commission\s*or\s*Service\s*Charge\s+([\d,]+\.?\d*)\s*ETB',
      r'Commission\s*:?\s*([\d,]+\.?\d*)\s*ETB',
    ]);

    final vat = _extractAmount(flatText, [
      r'15%\s*VAT\s*on\s*Commission\s+([\d,]+\.?\d*)\s*ETB',
      r'VAT\s*:?\s*([\d,]+\.?\d*)\s*ETB',
    ]);

    final totalAmount = _extractAmount(flatText, [
      r'Total\s*amount\s*debited\s+from\s+customers?\s*account\s+([\d,]+\.?\d*)\s*ETB',
      r'Total\s*amount\s*debited\s+([\d,]+\.?\d*)\s*ETB',
    ]);

    final dt = _extractDateTime(flatText);

    final accounts =
        RegExp(r'Account\s*([A-Z\*0-9]{4,15})', caseSensitive: false)
            .allMatches(flatText)
            .map((m) => m.group(1))
            .whereType<String>()
            .toList();

    final payerAccount = accounts.isNotEmpty ? accounts.first : null;
    final receiverAccount = accounts.length >= 2 ? accounts[1] : null;

    final receiptId = referenceNumber ?? _receiptIdFromUrl(receiptUrl ?? '');
    final localPath = await ReceiptStorageService.savePdfReceipt(
      transactionId: receiptId,
      bytes: response.bodyBytes,
    );

    return {
      'source': 'pdf_parse',
      'referenceNumber': referenceNumber,
      'payerName': payerName,
      'payerAccount': payerAccount,
      'receiverName': receiverName,
      'receiverAccount': receiverAccount,
      'paymentDate': dt?['date'],
      'paymentTime': dt?['time'],
      'reason': reason,
      'transferredAmount': transferredAmount,
      'commission': commission,
      'vat': vat,
      'totalAmount': totalAmount,
      'transaction_id': referenceNumber,
      'date': dt?['date'],
      'time': dt?['time'],
      'amount': transferredAmount,
      'total': totalAmount,
      'from_account': payerName ?? payerAccount,
      'to_account': receiverName ?? receiverAccount,
      'localReceiptPath': localPath,
    };
  }

  static Map<String, dynamic> _mapHtmlResult(
    Map<String, dynamic> htmlResult,
  ) {
    final refNum = htmlResult['referenceNumber'] as String?;
    return {
      'source': 'html_parse',
      'referenceNumber': refNum,
      'customerName': htmlResult['customerName'],
      'payerName': htmlResult['payerName'],
      'payerAccount': htmlResult['payerAccount'],
      'receiverName': htmlResult['receiverName'],
      'receiverAccount': htmlResult['receiverAccount'],
      'paymentDate': htmlResult['paymentDate'],
      'paymentTime': htmlResult['paymentTime'],
      'reason': htmlResult['reason'],
      'transferredAmount': htmlResult['transferredAmount'],
      'serviceCharge': htmlResult['serviceCharge'],
      'vat': htmlResult['vat'],
      'totalAmount': htmlResult['totalAmount'],
      'amountWords': htmlResult['amountWords'],
      'transaction_id': refNum,
      'date': htmlResult['paymentDate'],
      'time': htmlResult['paymentTime'],
      'amount': htmlResult['transferredAmount'],
      'commission': htmlResult['serviceCharge'],
      'total': htmlResult['totalAmount'],
      'from_account': (htmlResult['payerName'] as String?) ??
          (htmlResult['payerAccount'] as String?),
      'to_account': (htmlResult['receiverName'] as String?) ??
          (htmlResult['receiverAccount'] as String?),
    };
  }

  static bool _isV2TokenUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    if (!host.contains('mbreciept.cbe.com.et') &&
        !host.contains('mbreceipt.cbe.com.et')) {
      return false;
    }

    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    return token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> _fetchAndParseV2Receipt(
    String url,
  ) async {
    final uri = Uri.parse(url);
    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final apiUri = Uri.https(
      'Mb.cbe.com.et',
      '/api/v1/transactions/public/transaction-detail/$token',
    );

    final response = await http
        .get(apiUri, headers: _v2ApiHeaders)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return {
        'source': 'cbe_v2_api_unavailable_fallback',
        'api_status_code': response.statusCode,
      };
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return {'source': 'cbe_v2_api_invalid_fallback'};
    }

    if (decoded['error'] != null || decoded['id'] == null) {
      return {
        'source': 'cbe_v2_api_error_page',
        'api_status_code': 200,
        'error_message': decoded['error']?.toString() ?? 'Missing receipt data',
      };
    }

    return _mapV2Receipt(decoded, originalUrl: url);
  }

  static Map<String, dynamic> _mapV2Receipt(
    Map<String, dynamic> data, {
    required String originalUrl,
  }) {
    final dt = _extractV2DateTime(data);
    final commission = _sumCommissionTypes(
      data['commissionTypes'],
      includeDisasterRecovery: false,
    );
    final disasterRecovery = _sumCommissionTypes(
      data['commissionTypes'],
      includeDisasterRecovery: true,
    );
    final vat = _sumTaxTypes(data['taxTypes']);
    final transferredAmount =
        _toAmount(data['amountCredited']) ??
        _toAmount(data['amountCreditedWithCurrency']);
    final totalAmount =
        _toAmount(data['amountDebited']) ??
        _toAmount(data['amountDebitedWithCurrency']);
    final totalChargeAmount =
        _toAmount(data['totalChargeAmount']) ??
        _toAmount(data['totalChargeAmountWithCurrency']);

    final referenceNumber = _toText(data['id']);
    final payerName = _toText(data['debitAccountHolder']);
    final payerAccount = _toText(data['debitAccountNo']);
    final receiverName = _toText(data['creditAccountHolder']);
    final receiverAccount = _toText(data['creditAccountNo']);
    final reason =
        _firstText(data['paymentDetails']) ??
        _toText(data['debitTheirRef']) ??
        _toText(data['creditTheirRef']);
    final currency =
        _toText(data['debitCurrency']) ?? _toText(data['creditCurrency']);

    return {
      // GUI/PDF-style keys
      'source': 'cbe_v2_api_parse',
      'referenceNumber': referenceNumber,
      'payerName': payerName,
      'payerAccount': payerAccount,
      'receiverName': receiverName,
      'receiverAccount': receiverAccount,
      'paymentDate': dt?['date'],
      'paymentTime': dt?['time'],
      'reason': reason,
      'transferredAmount': transferredAmount,
      'commission': commission,
      'vat': vat,
      'disasterRecovery': disasterRecovery,
      'totalChargeAmount': totalChargeAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'encodedReceipt': _toText(data['encodedReceipt']),

      // App-mapped keys
      'transaction_id': referenceNumber,
      'transaction_ref': referenceNumber,
      'date': dt?['date'],
      'time': dt?['time'],
      'amount': transferredAmount,
      'total': totalAmount,
      'from_account': payerName ?? payerAccount,
      'to_account': receiverName ?? receiverAccount,
      'counterparty': receiverName ?? receiverAccount,
      'url': originalUrl,
    };
  }

  static String? _extractReason(String text, String flatText) {
    final lineStyle = RegExp(
      r'Reason\s*/\s*Type\s*of\s*service\s+(.+?)(?:\nTransferred|\n$|\n_|\s+ETB)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(text);
    if (lineStyle != null) {
      final raw = lineStyle.group(1)?.replaceAll('\n', ' ').trim();
      if (raw != null && raw.isNotEmpty) return raw;
    }

    final fallback = RegExp(
      r'Reason\s*/\s*Type\s*of\s*service\s*:?\s*(.+?)(?=\s+Transferred|\s+Commission|\s+15%\s*VAT|\s+Total\s+amount|$)',
      caseSensitive: false,
    ).firstMatch(flatText);
    return fallback?.group(1)?.trim();
  }

  static Map<String, String>? _extractDateTime(String text) {
    final patterns = [
      RegExp(
        r'Payment\s*Date\s*&\s*Time\s+(\d{1,2}/\d{1,2}/\d{4}),\s*(\d{1,2}:\d{2}:\d{2}\s*[AP]M)',
        caseSensitive: false,
      ),
      RegExp(
        r'Payment\s*Date\s*&\s*Time\s+(\d{1,2}/\d{1,2}/\d{4})\s+(\d{1,2}:\d{2}:\d{2})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return {'date': match.group(1) ?? '', 'time': match.group(2) ?? ''};
      }
    }
    return null;
  }

  static String? _extractField(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  static double? _extractAmount(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        final value = match.group(1)?.replaceAll(',', '').trim();
        final parsed = value == null ? null : double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static Map<String, String>? _extractV2DateTime(Map<String, dynamic> data) {
    final rawDateTime = _firstText(data['dateTimes']);
    if (rawDateTime != null) {
      final parsed = DateTime.tryParse(rawDateTime);
      if (parsed != null) {
        final local = parsed.toLocal();
        return {'date': _formatDate(local), 'time': _formatTime(local)};
      }
    }

    final compactDate =
        _toText(data['processingDate']) ??
        _toText(data['debitValueDate']) ??
        _toText(data['creditValueDate']);
    if (compactDate == null || compactDate.length != 8) return null;

    final year = int.tryParse(compactDate.substring(0, 4));
    final month = int.tryParse(compactDate.substring(4, 6));
    final day = int.tryParse(compactDate.substring(6, 8));
    if (year == null || month == null || day == null) return null;

    return {'date': _formatDate(DateTime(year, month, day))};
  }

  static String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year.toString().padLeft(4, '0')}';
  }

  static String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }

  static double? _sumCommissionTypes(
    dynamic value, {
    required bool includeDisasterRecovery,
  }) {
    if (value is! List) return null;

    var total = 0.0;
    var found = false;
    for (final entry in value) {
      if (entry is! Map) continue;

      final type = entry['commissionType']?.toString().toLowerCase() ?? '';
      final isDisasterRecovery =
          type.contains('disas') || type.contains('recovery');
      if (isDisasterRecovery != includeDisasterRecovery) continue;

      final amount = _toAmount(entry['commissionAmt']);
      if (amount == null) continue;

      total += amount;
      found = true;
    }

    return found ? total : null;
  }

  static double? _sumTaxTypes(dynamic value) {
    if (value is! List) return null;

    var total = 0.0;
    var found = false;
    for (final entry in value) {
      if (entry is! Map) continue;

      final amount = _toAmount(entry['taxAmt']);
      if (amount == null) continue;

      total += amount;
      found = true;
    }

    return found ? total : null;
  }

  static double? _toAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    final normalized = value
        .toString()
        .replaceAll(',', '')
        .replaceFirst(RegExp(r'^\s*ETB\s*', caseSensitive: false), '')
        .trim();
    return double.tryParse(normalized);
  }

  static String? _firstText(dynamic value) {
    if (value is List) {
      for (final item in value) {
        final text = _toText(item);
        if (text != null) return text;
      }
      return null;
    }

    return _toText(value);
  }

  static String? _toText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _convertNewUrlToOld(String url) {
    final urlLower = url.toLowerCase();
    if (urlLower.contains('mbreciept.cbe.com.et/') ||
        urlLower.contains('mbreceipt.cbe.com.et/')) {
      final lastSegment = Uri.parse(url).pathSegments.isNotEmpty
          ? Uri.parse(url).pathSegments.last
          : '';
      final parts = lastSegment.split('-');
      if (parts.length >= 2) {
        final reference = parts[0];
        final account = parts[1];
        return 'https://apps.cbe.com.et:100/?id=$reference$account';
      }
    }

    if (urlLower.contains('branchreceipt')) {
      final match = RegExp(
        r'BranchReceipt/([^&]+)&(.+)',
        caseSensitive: false,
      ).firstMatch(url);
      if (match != null) {
        final reference = match.group(1);
        final account = match.group(2);
        if (reference != null && account != null) {
          return 'https://apps.cbe.com.et:100/?id=$reference$account';
        }
      }
    }

    return url;
  }

  static String _receiptIdFromUrl(String url) {
    final hash = url.hashCode.toRadixString(36);
    return 'receipt_$hash';
  }
}
