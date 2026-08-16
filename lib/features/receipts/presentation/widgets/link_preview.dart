import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/receipts/data/services/cbe_receipt_browser_resolver.dart';
import 'package:faranka/features/receipts/data/services/receipt_link_kind_detector.dart';

class LinkPreview extends ConsumerStatefulWidget {
  final String url;
  final bool forcePdf;
  final bool compactPdf;
  final bool showCbeBrowserResolver;
  final void Function(CbeBrowserResolutionResult result)? onBrowserResolution;

  const LinkPreview({
    super.key,
    required this.url,
    this.forcePdf = false,
    this.compactPdf = false,
    this.showCbeBrowserResolver = false,
    this.onBrowserResolution,
  });

  @override
  ConsumerState<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends ConsumerState<LinkPreview> {
  final _detector = ReceiptLinkKindDetector();
  late Future<ReceiptLinkKind> _kindFuture;
  String? _resolvedPreviewUrl;

  @override
  void initState() {
    super.initState();
    _kindFuture = _detectKind();
  }

  @override
  void didUpdateWidget(LinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.forcePdf != widget.forcePdf) {
      _resolvedPreviewUrl = null;
      _kindFuture = _detectKind();
    }
  }

  Future<ReceiptLinkKind> _detectKind() async {
    if (_resolvedPreviewUrl != null &&
        CbeReceiptBrowserHeuristics.looksLikePdfUrl(_resolvedPreviewUrl!)) {
      return ReceiptLinkKind.pdf;
    }
    return _detector.detect(widget.url, forcePdf: widget.forcePdf);
  }

  Future<void> _openBrowserResolver() async {
    final result = await CbeReceiptBrowserResolver().resolve(context, widget.url);
    if (!mounted || result == null) return;

    widget.onBrowserResolution?.call(result);

    if (result.isSuccess && result.resolvedUrl != null) {
      setState(() {
        _resolvedPreviewUrl = result.resolvedUrl;
        _kindFuture = _detectKind();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dims = ref.watch(dimensionsProvider);
    return FutureBuilder<ReceiptLinkKind>(
      future: _kindFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        final kind = snap.data ?? ReceiptLinkKind.unknown;
        final previewUrl = _resolvedPreviewUrl ?? widget.url;
        final previewHeight = MediaQuery.of(context).size.height * 0.78;
        final compactPreviewHeight = MediaQuery.of(context).size.height * 0.56;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showCbeBrowserResolver &&
                CbeReceiptBrowserHeuristics.isCbeReceiptUrl(widget.url))
              Padding(
                padding: dims.only(b: 8),
                child: OutlinedButton.icon(
                  onPressed: _openBrowserResolver,
                  icon: Icon(Icons.open_in_browser, size: dims.icon(18)),
                  label: const Text('Resolve in browser session'),
                ),
              ),
            if (kind == ReceiptLinkKind.pdf)
              Card(
                color: AppColors.homeCardBackground,
                margin: dims.symmetric(v: widget.compactPdf ? 0 : 8),
                child: SizedBox(
                  height: widget.compactPdf ? compactPreviewHeight : previewHeight,
                  child: SfPdfViewer.network(
                    previewUrl,
                    canShowPaginationDialog: true,
                    canShowScrollHead: true,
                    onDocumentLoadFailed: (details) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to load PDF preview: ${details.description}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (kind == ReceiptLinkKind.web)
              Card(
                color: AppColors.homeCardBackground,
                margin: dims.symmetric(v: 8),
                child: SizedBox(
                  height: previewHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _ReceiptWebPreview(url: previewUrl),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() {
    final dims = ref.watch(dimensionsProvider);
    return Container(
      padding: dims.all(12),
      decoration: BoxDecoration(
        color: AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(color: AppColors.homeSeed),
          SizedBox(width: dims(12)),
          const Text(
            'Loading preview...',
            style: TextStyle(color: AppColors.appBarForeground),
          ),
        ],
      ),
    );
  }
}

class _ReceiptWebPreview extends StatefulWidget {
  final String url;

  const _ReceiptWebPreview({required this.url});

  @override
  State<_ReceiptWebPreview> createState() => _ReceiptWebPreviewState();
}

class _ReceiptWebPreviewState extends State<_ReceiptWebPreview> {
  late final WebViewController _controller;

  static const _viewportZoomOverrideScript = '''
(function() {
  var meta = document.querySelector('meta[name="viewport"]');
  var value = 'width=device-width, initial-scale=1, maximum-scale=5, user-scalable=yes';
  if (meta) {
    meta.setAttribute('content', value);
  } else {
    var m = document.createElement('meta');
    m.name = 'viewport';
    m.content = value;
    document.head && document.head.appendChild(m);
  }
})();
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setBackgroundColor(AppColors.homeCardBackground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            try {
              await _controller.runJavaScript(_viewportZoomOverrideScript);
            } catch (_) {}
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to load receipt preview: ${error.description}',
                ),
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
