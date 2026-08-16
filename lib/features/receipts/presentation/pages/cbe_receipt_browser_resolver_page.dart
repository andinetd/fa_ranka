import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/receipts/data/services/cbe_receipt_browser_resolver.dart';

class CbeReceiptBrowserResolverPage extends ConsumerStatefulWidget {
  final String receiptUrl;

  const CbeReceiptBrowserResolverPage({
    super.key,
    required this.receiptUrl,
  });

  @override
  ConsumerState<CbeReceiptBrowserResolverPage> createState() =>
      _CbeReceiptBrowserResolverPageState();
}

class _CbeReceiptBrowserResolverPageState
    extends ConsumerState<CbeReceiptBrowserResolverPage> {
  late final WebViewController _controller;

  String? _currentUrl;
  String? _pageTitle;
  String? _bodySnippet;
  bool _isLoading = true;
  bool _sawDenied = false;
  bool _looksLikeReceipt = false;
  bool _looksLikePdf = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.receiptUrl;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.homeCardBackground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) async {
            await _inspectPage(url);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Page error: ${error.description}'),
              ),
            );
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            setState(() {
              _currentUrl = url;
              _looksLikePdf = CbeReceiptBrowserHeuristics.looksLikePdfUrl(url);
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.receiptUrl));
  }

  Future<void> _inspectPage(String url) async {
    String? title;
    String? bodySnippet;

    try {
      title = await _controller.getTitle();
      final rawBody = await _controller.runJavaScriptReturningResult(
        "document.body ? document.body.innerText.substring(0, 500) : ''",
      );
      bodySnippet = _unwrapJsString(rawBody);
    } catch (_) {
      // Page inspection is best-effort.
    }

    if (!mounted) return;

    final denied = CbeReceiptBrowserHeuristics.looksDenied(
      bodySnippet: bodySnippet,
      title: title,
    );
    final pdf = CbeReceiptBrowserHeuristics.looksLikePdfUrl(url);
    final receipt = CbeReceiptBrowserHeuristics.looksLikeReceiptPage(
      url,
      bodySnippet: bodySnippet,
    );

    setState(() {
      _isLoading = false;
      _currentUrl = url;
      _pageTitle = title;
      _bodySnippet = bodySnippet;
      _sawDenied = denied;
      _looksLikePdf = pdf;
      _looksLikeReceipt = receipt;
    });

    if (pdf) {
      _popWith(CbeBrowserResolutionStatus.resolvedPdfUrl);
    } else if (denied) {
      _popWith(CbeBrowserResolutionStatus.denied);
    }
  }

  String? _unwrapJsString(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  void _popWith(CbeBrowserResolutionStatus status) {
    if (!mounted) return;
    Navigator.of(context).pop(
      CbeBrowserResolutionResult(
        status: status,
        resolvedUrl: _currentUrl,
        pageTitle: _pageTitle,
        bodySnippet: _bodySnippet,
        error: status == CbeBrowserResolutionStatus.denied
            ? 'CBE denied access in browser session'
            : null,
      ),
    );
  }

  void _confirmReceiptPage() {
    _popWith(
      _looksLikePdf
          ? CbeBrowserResolutionStatus.resolvedPdfUrl
          : _looksLikeReceipt
          ? CbeBrowserResolutionStatus.resolvedReceiptPage
          : CbeBrowserResolutionStatus.openedButUnextractable,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dims = ref.watch(dimensionsProvider);
    final isDark = AppColors.isDark(context);
    final canConfirm = !_isLoading && !_sawDenied && _currentUrl != null;

    _controller.setBackgroundColor(
      isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
    );

    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Resolve CBE Receipt'),
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
        foregroundColor: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop(
              const CbeBrowserResolutionResult(
                status: CbeBrowserResolutionStatus.cancelled,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: canConfirm ? _confirmReceiptPage : null,
            child: Text(
              'Use this page',
              style: TextStyle(
                color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeSeed,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeSeed,
            ),
          Padding(
            padding: dims.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_sawDenied)
                  Text(
                    'CBE denied access. This link may be expired or restricted.',
                    style: TextStyle(
                      color: isDark ? DarkAppColors.homeAccentGreen : Colors.orange,
                      fontSize: 13,
                    ),
                  )
                else if (_looksLikeReceipt || _looksLikePdf)
                  Text(
                    'Receipt page detected. Tap "Use this page" to continue.',
                    style: TextStyle(
                      color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
                      fontSize: 13,
                    ),
                  )
                else
                  Text(
                    'Loading receipt in browser session. Confirm when the receipt appears.',
                    style: TextStyle(
                      color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                      fontSize: 13,
                    ),
                  ),
                if (_currentUrl != null) ...[
                  SizedBox(height: dims(6)),
                  Text(
                    _currentUrl!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
