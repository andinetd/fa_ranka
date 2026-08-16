import 'package:flutter/material.dart';

import 'package:faranka/features/receipts/presentation/pages/cbe_receipt_browser_resolver_page.dart';

enum CbeBrowserResolutionStatus {
  resolvedPdfUrl,
  resolvedReceiptPage,
  openedButUnextractable,
  denied,
  failed,
  cancelled,
}

class CbeBrowserResolutionResult {
  final CbeBrowserResolutionStatus status;
  final String? resolvedUrl;
  final String? pageTitle;
  final String? bodySnippet;
  final String? error;

  const CbeBrowserResolutionResult({
    required this.status,
    this.resolvedUrl,
    this.pageTitle,
    this.bodySnippet,
    this.error,
  });

  bool get isSuccess =>
      status == CbeBrowserResolutionStatus.resolvedPdfUrl ||
      status == CbeBrowserResolutionStatus.resolvedReceiptPage;
}

class CbeReceiptBrowserHeuristics {
  static bool looksLikePdfUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.pdf')) return true;
    return RegExp(
      r'id=FT[A-Z0-9]+\d{8,}',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  static bool looksDenied({String? bodySnippet, String? title}) {
    final combined = '${title ?? ''} ${bodySnippet ?? ''}'.toLowerCase();
    return combined.contains('not allowed') ||
        combined.contains('please check your link') ||
        combined.contains('access denied');
  }

  static bool looksLikeReceiptPage(String url, {String? bodySnippet}) {
    if (looksDenied(bodySnippet: bodySnippet)) return false;
    if (looksLikePdfUrl(url)) return true;

    final lower = url.toLowerCase();
    if (!lower.contains('cbe.com.et')) return false;

    final body = (bodySnippet ?? '').toLowerCase();
    return body.contains('reference') ||
        body.contains('transferred amount') ||
        body.contains('payer') ||
        body.contains('receiver') ||
        body.contains('payment date');
  }

  static bool isCbeReceiptUrl(String url) {
    return url.toLowerCase().contains('cbe.com.et');
  }

  static bool isMbrecieptV2TokenUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (!host.contains('mbreciept.cbe.com.et') &&
        !host.contains('mbreceipt.cbe.com.et')) {
      return false;
    }
    final segment =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    return segment.isNotEmpty;
  }

  static bool parseSourceNeedsBrowserResolution(String? parseSource) {
    if (parseSource == null || parseSource.isEmpty) return false;
    return parseSource.contains('cbe_html') ||
        parseSource.contains('cbe_pdf_unavailable') ||
        parseSource.contains('cbe_token_url_skipped') ||
        parseSource.contains('sms_parse_fetch') ||
        parseSource.contains('sms_parse_link_unavailable');
  }
}

class CbeReceiptBrowserResolver {
  Future<CbeBrowserResolutionResult?> resolve(
    BuildContext context,
    String receiptUrl,
  ) {
    return Navigator.of(context).push<CbeBrowserResolutionResult>(
      MaterialPageRoute(
        builder: (_) => CbeReceiptBrowserResolverPage(receiptUrl: receiptUrl),
      ),
    );
  }
}
