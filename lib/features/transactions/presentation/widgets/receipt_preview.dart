import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/models/awash_transaction.dart';

class ReceiptPreview extends ConsumerWidget {
  final SmsInboxData sms;
  final AwashTransaction transaction;
  final GlobalKey? previewKey;

  const ReceiptPreview({
    super.key,
    required this.sms,
    required this.transaction,
    this.previewKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final horizontalPad = MediaQuery.of(context).size.width < 360 ? 14.0 : 20.0;
    final previewAmount = transaction.total ?? transaction.amount;
    return RepaintBoundary(
      key: previewKey,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(horizontalPad),
        decoration: BoxDecoration(
          color: isDark ? DarkAppColors.homeCardBackground : AppColors.homeCardBackground,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isDark ? DarkAppColors.homeCardShadowStyle : AppColors.homeCardShadowStyle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              previewAmount != null
                  ? 'ETB ${previewAmount.toStringAsFixed(2)}'
                  : transaction.smsAmount ?? 'N/A',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            SizedBox(height: dims.spacingSm),
            Text(
              transaction.txnType ?? transaction.direction,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
            ),
            const SizedBox.shrink(),
            SizedBox(height: dims(12)),
          ],
        ),
      ),
    );
  }

  static Future<Uint8List?> exportAsPng(
    GlobalKey key, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
}
