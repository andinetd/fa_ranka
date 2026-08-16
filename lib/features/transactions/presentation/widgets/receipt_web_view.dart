import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';

class ReceiptWebView extends StatefulWidget {
  final String? url;
  final String? htmlContent;
  final bool isDark;
  final AppDimensions dims;

  const ReceiptWebView({
    super.key,
    this.url,
    this.htmlContent,
    required this.isDark,
    required this.dims,
  });

  @override
  State<ReceiptWebView> createState() => ReceiptWebViewState();
}

class ReceiptWebViewState extends State<ReceiptWebView> {
  String? _error;
  late final WebViewController _controller;

  static const _viewportZoomOverrideScript = '''
(function() {
  var deviceWidth = 0;
  function applyFit() {
    var doc = document.documentElement;
    var body = document.body;
    var contentWidth = Math.max(
      doc ? doc.scrollWidth : 0,
      body ? body.scrollWidth : 0,
      doc ? doc.clientWidth : 0
    );
    if (!deviceWidth) {
      var sw = window.screen ? window.screen.width : 0;
      if (sw && sw > 0) {
        deviceWidth = sw;
      } else {
        var vv = window.visualViewport;
        deviceWidth = vv && vv.width ? vv.width : (doc ? doc.clientWidth : 0);
      }
    }
    if (!contentWidth || !deviceWidth) return;
    var scale = Math.min(1, deviceWidth / contentWidth);
    var value = 'width=' + contentWidth +
        ', initial-scale=' + scale +
        ', minimum-scale=0.1, maximum-scale=5, user-scalable=yes';
    var meta = document.querySelector('meta[name="viewport"]');
    if (meta) {
      meta.setAttribute('content', value);
    } else {
      var m = document.createElement('meta');
      m.name = 'viewport';
      m.content = value;
      document.head && document.head.appendChild(m);
    }
  }
  applyFit();
  window.addEventListener('load', applyFit);
  setTimeout(applyFit, 300);
  setTimeout(applyFit, 800);
  setTimeout(applyFit, 1500);
})();
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setBackgroundColor(
          widget.isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            try {
              await _controller.runJavaScript(_viewportZoomOverrideScript);
            } catch (_) {}
          },
          onWebResourceError: (error) {
            debugPrint('Receipt WebView error: ${error.description}');
            if (!mounted) return;
            setState(() => _error = error.description);
          },
        ),
      );

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setUseWideViewPort(true);
    }

    if (widget.htmlContent != null) {
      _controller.loadHtmlString(widget.htmlContent!);
    } else if (widget.url != null) {
      _controller.loadRequest(Uri.parse(widget.url!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: widget.dims.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: widget.dims.icon(32),
                  color: widget.isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
              SizedBox(height: widget.dims(8)),
              Text('Could not load receipt',
                style: TextStyle(fontSize: 14,
                    color: widget.isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
              ),
            ],
          ),
        ),
      );
    }
    return WebViewWidget(controller: _controller);
  }
}
