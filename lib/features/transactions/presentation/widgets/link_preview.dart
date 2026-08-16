import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/features/transactions/presentation/widgets/receipt_web_view.dart';

enum ReceiptPreviewBank { cbe, awash, telebirr, boa }

class LinkPreview extends ConsumerWidget {
  final String url;
  final String? localReceiptPath;
  final bool forcePdf;
  final bool compactPdf;
  final ReceiptPreviewBank bank;

  const LinkPreview({
    super.key,
    required this.url,
    this.localReceiptPath,
    this.forcePdf = false,
    this.compactPdf = false,
    this.bank = ReceiptPreviewBank.awash,
  });

  static double _maxWidthFor(ReceiptPreviewBank bank, double screenWidth) {
    return screenWidth;
  }

  Future<Map<String, String?>> _fetchMeta(String url) async {
    try {
      if (forcePdf) {
        return {'kind': 'pdf'};
      }

      final head = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      final contentType = (head.headers['content-type'] ?? '').toLowerCase();
      final isPdf =
          url.toLowerCase().contains('.pdf') ||
          contentType.contains('application/pdf');
      if (isPdf) {
        return {'kind': 'pdf'};
      }

      return {'kind': 'web'};
    } catch (e) {
      debugPrint('Receipt URL HEAD failed for $url: $e');
      return {'kind': 'web'};
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = _maxWidthFor(bank, screenWidth);
    final previewHeight = MediaQuery.of(context).size.height * 0.78;
    final compactPreviewHeight = MediaQuery.of(context).size.height * 0.56;

    if (localReceiptPath != null) {
      final file = File(localReceiptPath!);
      if (file.existsSync()) {
        final isPdf = localReceiptPath!.toLowerCase().endsWith('.pdf');
        if (isPdf) {
          return _withMaxWidth(
            maxWidth,
            Card(
              color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
              margin: dims.symmetric(v: compactPdf ? 0 : 8),
              child: SizedBox(
                height: compactPdf ? compactPreviewHeight : previewHeight,
                child: SfPdfViewer.file(
                  file,
                  canShowPaginationDialog: true,
                  canShowScrollHead: true,
                  onDocumentLoadFailed: (details) {
                    debugPrint('Local PDF load failed: ${details.description}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to load PDF preview')),
                    );
                  },
                ),
              ),
            ),
          );
        }
        return _buildWebView(context, isDark, dims, previewHeight,
            maxWidth: maxWidth, file: file);
      }
    }

    return FutureBuilder<Map<String, String?>>(
      future: _fetchMeta(url),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          final loadH = compactPdf ? compactPreviewHeight : previewHeight;
          return _withMaxWidth(
            maxWidth,
            Card(
              color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
              margin: dims.symmetric(v: compactPdf ? 0 : 8),
              child: SizedBox(
                height: loadH,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeSeed),
                      SizedBox(width: dims(12)),
                      Text(
                        'Loading preview...',
                        style: TextStyle(color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final data = snap.data ?? {};
        final kind = data['kind'];

        if (kind == 'pdf') {
          return _withMaxWidth(
            maxWidth,
            Card(
              color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
              margin: dims.symmetric(v: compactPdf ? 0 : 8),
              child: SizedBox(
                height: compactPdf ? compactPreviewHeight : previewHeight,
                child: SfPdfViewer.network(
                  url,
                  canShowPaginationDialog: true,
                  canShowScrollHead: true,
                  onDocumentLoadFailed: (details) {
                    debugPrint('Receipt PDF load failed: ${details.description}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to load PDF preview: ${details.description}')),
                    );
                  },
                ),
              ),
            ),
          );
        }

        if (kind == 'web') {
          return _buildWebView(context, isDark, dims, previewHeight,
              maxWidth: maxWidth);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWebView(BuildContext context, bool isDark, AppDimensions dims,
      double previewHeight,
      {File? file, required double maxWidth}) {
    return _withMaxWidth(
      maxWidth,
      Card(
        color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
        margin: dims.symmetric(v: 8),
        child: SizedBox(
          height: previewHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ReceiptWebView(
              url: file == null ? url : null,
              htmlContent: file?.readAsStringSync(),
              isDark: isDark,
              dims: dims,
            ),
          ),
        ),
      ),
    );
  }

  Widget _withMaxWidth(double maxWidth, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
