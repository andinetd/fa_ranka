import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ReceiptStorageService {
  static Future<String?> saveReceiptContent({
    required String transactionId,
    required List<int> bytes,
    required String extension,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final receiptDir = Directory('${dir.path}/receipts');
      if (!await receiptDir.exists()) {
        await receiptDir.create(recursive: true);
      }

      final fileName = '$transactionId.$extension';
      final file = File('${receiptDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Failed to save receipt content: $e');
      return null;
    }
  }

  static Future<String?> saveHtmlReceipt({
    required String transactionId,
    required String html,
  }) async {
    return saveReceiptContent(
      transactionId: transactionId,
      bytes: utf8.encode(html),
      extension: 'html',
    );
  }

  static Future<String?> savePdfReceipt({
    required String transactionId,
    required List<int> bytes,
  }) async {
    return saveReceiptContent(
      transactionId: transactionId,
      bytes: bytes,
      extension: 'pdf',
    );
  }

  static Future<bool> deleteReceiptFile(String? localPath) async {
    if (localPath == null) return false;
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Failed to delete receipt file: $e');
    }
    return false;
  }
}
