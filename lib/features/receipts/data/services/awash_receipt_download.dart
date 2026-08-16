import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AwashReceiptManager {
  /// Port of 'download_receipt'
  /// This looks for the actual receipt image inside the webpage
  Future<File?> downloadReceiptImage(String url) async {
    debugPrint('Downloading receipt from: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        },
      );

      debugPrint('Content-Type: ${response.headers['content-type']}');

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch URL: ${response.statusCode}');
        return null;
      }

      String? imageUrl;
      final contentType = response.headers['content-type'] ?? '';

      // If it's an HTML page, we must find the <img> or <a> tag
      if (contentType.contains('text/html')) {
        var document = parse(response.body);
        final htmlContent = response.body;

        // Method 1: Look for <img> tags
        final img = document.querySelector('img');
        if (img != null) {
          imageUrl = img.attributes['src'];
          debugPrint('Found image in <img> tag: $imageUrl');
        }

        // Method 2: Look for download links if <img> failed
        if (imageUrl == null) {
          final link = document.querySelector(
            'a[href*="download"], a[href*="receipt"]',
          );
          imageUrl = link?.attributes['href'];
          debugPrint('Found image in download link: $imageUrl');
        }

        // Method 3: Look for form action (POST download)
        if (imageUrl == null) {
          final formPattern = RegExp(
            r'<form[^>]+action=["'
            "'"
            r']([^"'
            "'"
            r']+)["'
            "'"
            r']',
            caseSensitive: false,
          );
          final formMatch = formPattern.firstMatch(htmlContent);
          if (formMatch != null) {
            imageUrl = formMatch.group(1);
            debugPrint('Found form action: $imageUrl');
          }
        }

        // Method 4: Look for base64 encoded image
        if (imageUrl == null) {
          final base64Pattern = RegExp(
            r'data:image/[^;]+;base64,([A-Za-z0-9+/=]+)',
          );
          final base64Match = base64Pattern.firstMatch(htmlContent);
          if (base64Match != null) {
            debugPrint('Found base64 encoded image');
            final base64Data = base64Match.group(1);
            if (base64Data != null) {
              final bytes = base64Decode(base64Data);
              return await _saveFile(bytes, url);
            }
          }
        }

        // Handle relative URLs
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          Uri baseUri = Uri.parse(url);
          imageUrl = baseUri.resolve(imageUrl).toString();
        }
      } else if (contentType.contains('image/')) {
        // Already an image
        debugPrint('Content is direct image');
        return await _saveFile(response.bodyBytes, url);
      }

      // Download the actual image if found
      if (imageUrl != null) {
        debugPrint('Fetching image from: $imageUrl');
        final imgRes = await http.get(
          Uri.parse(imageUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0',
          },
        );
        return await _saveFile(imgRes.bodyBytes, imageUrl);
      }

      debugPrint('Could not find image URL in HTML');
    } catch (e) {
      debugPrint("Download error: $e");
    }
    return null;
  }

  /// Port of 'parse_ocr_text'
  /// Since we aren't doing OCR, we run these Regexes on the HTML text content
  Map<String, dynamic> parseReceiptFields(String rawText) {
    Map<String, dynamic> result = {
      'transaction_id': null,
      'date': null,
      'time': null,
      'from_account': null,
      'to_account': null,
      'amount': null,
      'commission': null,
      'vat': null,
      'total': null,
      'reason': null,
    };

    // Transaction ID
    result['transaction_id'] = RegExp(
      r'(?:Transaction ID|Txn ID|Ref)[:\s]+([A-Za-z0-9\-]+)',
      caseSensitive: false,
    ).firstMatch(rawText)?.group(1);

    // Date (YYYY-MM-DD)
    result['date'] = RegExp(
      r'(\d{4}-\d{2}-\d{2})',
    ).firstMatch(rawText)?.group(1);

    // Time
    result['time'] = RegExp(
      r'(\d{1,2}:\d{2}:?\d{0,2}\s*(?:AM|PM)?)',
      caseSensitive: false,
    ).firstMatch(rawText)?.group(1);

    // From Account
    result['from_account'] = RegExp(
      r'(?:From|Payer|Source) Account[:\s]+([0-9xX]+)',
      caseSensitive: false,
    ).firstMatch(rawText)?.group(1);

    // To Account
    result['to_account'] = RegExp(
      r'(?:To|Receiver|Destination) Account[:\s]+([0-9xX]+)',
      caseSensitive: false,
    ).firstMatch(rawText)?.group(1);

    // Amounts
    result['amount'] = _parseAmount(
      rawText,
      r'Amount[:\s]*([\d,]+\.?\d*)\s*ETB',
    );
    result['commission'] = _parseAmount(
      rawText,
      r'(?:Commission|Fee)[:\s]*([\d,]+\.?\d*)\s*ETB',
    );
    result['vat'] = _parseAmount(rawText, r'VAT[:\s]*([\d,]+\.?\d*)\s*ETB');
    result['total'] = _parseAmount(
      rawText,
      r'(?:Total|Grand Total)[:\s]*([\d,]+\.?\d*)\s*ETB',
    );

    // Reason
    result['reason'] = RegExp(
      r'Transaction[\s/]Type[:\s]+(.+)',
      caseSensitive: false,
    ).firstMatch(rawText)?.group(1)?.trim();

    return result;
  }

  // Private Helper to save bytes to phone storage
  Future<File> _saveFile(List<int> bytes, String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = "receipt_${url.hashCode}.png";
    final file = File(p.join(dir.path, fileName));
    return await file.writeAsBytes(bytes);
  }

  // Private Helper to parse string numbers to double
  double? _parseAmount(String text, String pattern) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    return null;
  }
}
