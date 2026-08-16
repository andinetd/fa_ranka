import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

enum ReceiptLinkStatus {
  available,
  expired,
  serverDown,
  timeout,
  noInternet,
  unknown,
}

class ReceiptLinkChecker {
  static const _headers = {'User-Agent': 'Mozilla/5.0'};
  static const _timeout = Duration(seconds: 5);
  static const _cbeTimeout = Duration(seconds: 30);

  Future<ReceiptLinkStatus> checkLink(String url) async {
    final uri = Uri.parse(url);
    final timeout = _isCbeHost(uri) ? _cbeTimeout : _timeout;
    if (_shouldSkipHead(uri)) {
      return _checkWithGet(url, timeout);
    }

    try {
      final response = await http
          .head(uri, headers: _headers)
          .timeout(timeout);

      if (response.statusCode == 405) {
        return await _checkWithGet(url, timeout);
      }
      if (response.statusCode == 200) return ReceiptLinkStatus.available;
      if (response.statusCode == 404) return ReceiptLinkStatus.expired;
      if (response.statusCode >= 500) return ReceiptLinkStatus.serverDown;
      return ReceiptLinkStatus.unknown;
    } on TimeoutException {
      return ReceiptLinkStatus.timeout;
    } on SocketException {
      return ReceiptLinkStatus.noInternet;
    } catch (_) {
      return ReceiptLinkStatus.unknown;
    }
  }

  bool _shouldSkipHead(Uri uri) =>
      _isCbeHost(uri) || _isBoaHost(uri);

  bool _isCbeHost(Uri uri) => uri.host.toLowerCase().contains('cbe.com.et');

  bool _isBoaHost(Uri uri) =>
      uri.host.toLowerCase().contains('bankofabyssinia');

  Future<ReceiptLinkStatus> _checkWithGet(
    String url,
    Duration timeout,
  ) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(timeout);
      if (response.statusCode == 200) return ReceiptLinkStatus.available;
      if (response.statusCode == 404) return ReceiptLinkStatus.expired;
      if (response.statusCode >= 500) return ReceiptLinkStatus.serverDown;
      return ReceiptLinkStatus.unknown;
    } on TimeoutException {
      return ReceiptLinkStatus.timeout;
    } on SocketException {
      return ReceiptLinkStatus.noInternet;
    } catch (_) {
      return ReceiptLinkStatus.unknown;
    }
  }

  static String labelForDomain(String domain) {
    final lower = domain.toLowerCase();
    if (lower.contains('awash')) return 'Awash Bank';
    if (lower.contains('abyssinia')) return 'BoA';
    if (lower.contains('cbe')) return 'CBE';
    return domain;
  }

  static String statusMessage(ReceiptLinkStatus status) {
    switch (status) {
      case ReceiptLinkStatus.available:
        return 'Available';
      case ReceiptLinkStatus.expired:
        return 'Expired link';
      case ReceiptLinkStatus.serverDown:
        return 'Server unavailable';
      case ReceiptLinkStatus.timeout:
        return 'Timed out';
      case ReceiptLinkStatus.noInternet:
        return 'No internet';
      case ReceiptLinkStatus.unknown:
        return 'Unavailable';
    }
  }
}
