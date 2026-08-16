import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

enum ReceiptLinkKind { pdf, web, unknown }

class ReceiptLinkKindDetector {
  static const _headers = {'User-Agent': 'Mozilla/5.0'};
  static const _timeout = Duration(seconds: 8);

  Future<ReceiptLinkKind> detect(String url, {bool forcePdf = false}) async {
    if (forcePdf) return ReceiptLinkKind.pdf;

    final lower = url.toLowerCase();
    if (lower.contains('.pdf')) return ReceiptLinkKind.pdf;

    final uri = Uri.tryParse(url);
    if (uri == null) return ReceiptLinkKind.unknown;

    if (_isCbeHost(uri.host)) {
      return _detectCbeKind(url, uri);
    }

    return _detectWithHead(url);
  }

  bool _isCbeHost(String host) {
    return host.toLowerCase().contains('cbe.com.et');
  }

  ReceiptLinkKind _detectCbeKind(String url, Uri uri) {
    final pathSegment =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    if (RegExp(r'^v2-?hf', caseSensitive: false).hasMatch(pathSegment)) {
      return ReceiptLinkKind.web;
    }

    final id = uri.queryParameters['id'] ?? '';
    if (RegExp(r'^FT[A-Z0-9]+\d{8,}$', caseSensitive: false).hasMatch(id)) {
      return ReceiptLinkKind.pdf;
    }
    if (id.toLowerCase().startsWith('v2hf') || id.length > 20) {
      return ReceiptLinkKind.web;
    }
    return ReceiptLinkKind.web;
  }

  Future<ReceiptLinkKind> _detectWithHead(String url) async {
    try {
      final response = await http
          .head(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 405) {
        return await _detectWithGet(url);
      }

      final contentType = (response.headers['content-type'] ?? '').toLowerCase();
      if (contentType.contains('application/pdf')) {
        return ReceiptLinkKind.pdf;
      }
      return ReceiptLinkKind.web;
    } on TimeoutException {
      return ReceiptLinkKind.web;
    } on SocketException {
      return ReceiptLinkKind.web;
    } catch (_) {
      return ReceiptLinkKind.web;
    }
  }

  Future<ReceiptLinkKind> _detectWithGet(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      final contentType = (response.headers['content-type'] ?? '').toLowerCase();
      if (contentType.contains('application/pdf')) {
        return ReceiptLinkKind.pdf;
      }

      final bytes = response.bodyBytes;
      if (bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46) {
        return ReceiptLinkKind.pdf;
      }

      return ReceiptLinkKind.web;
    } catch (_) {
      return ReceiptLinkKind.web;
    }
  }
}
