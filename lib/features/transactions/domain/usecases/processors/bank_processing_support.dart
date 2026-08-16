import 'package:faranka/database/database.dart';
import 'package:string_similarity/string_similarity.dart';

import 'package:faranka/features/transactions/domain/services/category_engine.dart';
import 'package:faranka/features/receipts/data/services/receipt_fetch_session.dart';
import 'package:flutter/foundation.dart';

class BankProcessingSupport {
  BankProcessingSupport(this.db, this.session);

  final AppDatabase db;
  final ReceiptFetchSession session;

  static String normalizeBusinessReason(String? reason) {
    final cleaned = _cleanBusinessReasonCandidate(reason);
    if (cleaned == null) return '';

    final lower = cleaned.toLowerCase();
    if (_isGenericBusinessReason(lower)) return '';

    return cleaned;
  }

  Future<bool> isDuplicateFuzzy({
    required double amount,
    required DateTime time,
    required TransactionDirection dir,
    String? counterpartyName,
    String? counterpartyNumber,
  }) async {
    final windowStart = time
        .subtract(const Duration(minutes: 5))
        .millisecondsSinceEpoch;
    final windowEnd = time
        .add(const Duration(minutes: 5))
        .millisecondsSinceEpoch;

    final query = db.select(db.transactions)
      ..where((t) => t.amount.equals(amount))
      ..where((t) => t.direction.equalsValue(dir));

    final potentialMatches = await query.get();
    if (potentialMatches.isEmpty) return false;

    for (final existing in potentialMatches) {
      if (existing.smsTimestamp < windowStart ||
          existing.smsTimestamp > windowEnd) {
        continue;
      }

      var isMatch = false;

      if (counterpartyNumber != null && existing.counterpartyNumber != null) {
        if (counterpartyNumber == existing.counterpartyNumber) {
          isMatch = true;
        }
      }

      if (!isMatch &&
          counterpartyName != null &&
          existing.counterpartyName != null) {
        final normalizedIncoming = normalize(counterpartyName);
        final normalizedExisting = normalize(existing.counterpartyName!);
        if (normalizedIncoming.similarityTo(normalizedExisting) > 0.85) {
          isMatch = true;
        }
      }

      if (!isMatch &&
          counterpartyName == null &&
          existing.counterpartyName == null) {
        isMatch = true;
      }

      if (isMatch) return true;
    }

    return false;
  }

  String normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  static String? cleanCandidate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final cleaned = raw
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'^[\s\-,:;./]+|[\s\-,:;./]+$'), '')
        .trim();

    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  /// Resolves the categorization reason for BoA transactions.
  ///
  /// Uses the receipt's transaction type verbatim. Generic boilerplate labels
  /// are filtered downstream by [normalizeBusinessReason].
  static String? resolveBoaCategoryReason(Map<String, dynamic> data) {
    return cleanCandidate(data['transaction_type']);
  }

  bool isExplicitlyEmptyReason(Map<String, dynamic> data) {
    if (!data.containsKey('reason')) return false;

    final reason = data['reason'];
    if (reason is String) {
      return reason.trim().isEmpty;
    }

    return reason == null;
  }

  String resolveFallbackReason(
    Map<String, dynamic> data, {
    String? directionHint,
    required String bankFallback,
  }) {
    final directReason = normalizeBusinessReason(data['reason']?.toString());
    if (directReason.isNotEmpty) return directReason;

    return '';
  }

  String? fallbackTransactionType(String? directionHint) {
    final direction = (directionHint ?? '').toLowerCase();
    if (direction.contains('debit')) return 'Debit';
    if (direction.contains('credit')) return 'Credit Alert';
    return null;
  }

  void applyAwashCategoryHints(Map<String, dynamic> data, String smsBody) {
    if (looksLikeAwashAirtimeSms(smsBody)) {
      data['transaction_type'] = 'Airtime Purchase';
      data['reason'] = 'Airtime';
      return;
    }
    if (data['transaction_type'] == 'Mobile Cashout') {
      data['reason'] = 'Mobile Cashout';
      return;
    }
  }

  bool looksLikeAwashAirtimeSms(String smsBody) {
    final normalized = smsBody.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = normalized.toLowerCase();
    final hasAirtimeMarker =
        lower.contains('bought airtime') ||
        lower.contains('airtime worth') ||
        lower.contains('airtime purchase');

    if (hasAirtimeMarker) return true;

    final hasSentToBankPattern = RegExp(
      r'\byou\s+have\s+sent\s+etb\s*-?\s*[\d,]+(?:\.\d+)?\s+to\s+\d{8,}/bank\b',
      caseSensitive: false,
    ).hasMatch(normalized);

    if (!hasSentToBankPattern) return false;

    final hasReceiptLink = lower.contains('awashpay.awashbank.com');
    final hasProcoinMarker = lower.contains('procoin');
    return hasReceiptLink || hasProcoinMarker;
  }

  void applyCbeCategoryHints(Map<String, dynamic> data, String smsBody) {
    if (!looksLikeCbeGenericDebitAlert(smsBody)) return;

    final existingReason = cleanCandidate(data['reason'])?.toLowerCase();
    final existingType = cleanCandidate(
      data['transaction_type'],
    )?.toLowerCase();
    final transferCounterparty =
        cleanCandidate(data['to_account']) ??
        cleanCandidate(data['counterparty']);
    final looksLikeTransferToPerson =
        transferCounterparty != null &&
        smsBody.toLowerCase().contains('transferred') &&
        !smsBody.toLowerCase().contains('service fee');

    final hasNoisyReceiptReason =
        existingReason != null &&
        (existingReason.startsWith('transferred amount') ||
            existingReason.startsWith('commission') ||
            existingReason.startsWith('total amount debited') ||
            existingReason.startsWith('vat') ||
            existingReason.startsWith('15 vat') ||
            existingReason.contains('transferred amount etb'));

    if (existingReason == null ||
        existingReason == 'cbe transaction' ||
        hasNoisyReceiptReason) {
      data['reason'] = looksLikeTransferToPerson
          ? transferCounterparty
          : 'Debit';
    }

    if (existingType == null || existingType == 'bank transfer') {
      data['transaction_type'] = 'Debit';
    }
  }

  bool looksLikeCbeGenericDebitAlert(String smsBody) {
    final normalized = smsBody.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = normalized.toLowerCase();

    final hasDebitSignal =
        lower.contains('has been debited') ||
        lower.contains('debited with etb');
    final hasBalanceSignal = lower.contains('current balance');
    final hasReceiptSignal = lower.contains('apps.cbe.com.et');

    return hasDebitSignal && hasBalanceSignal && hasReceiptSignal;
  }

  bool hasMeaningfulCbeReason(dynamic value) {
    final cleaned = cleanCandidate(value);
    if (cleaned == null) return false;

    final lower = cleaned.toLowerCase();
    if (lower == 'debit alert' || lower == 'cbe transaction') return false;

    return true;
  }

  String sanitizeCbeReason(String? reason, {required String fallback}) {
    return normalizeBusinessReason(reason);
  }

  bool shouldForceUncategorizedCategory({
    required String? source,
    required bool hadDeepParseAttempt,
  }) {
    if (!hadDeepParseAttempt) return false;

    final normalized = (source ?? '').toLowerCase().trim();
    if (normalized.isEmpty) return true;

    if (normalized.contains('fallback') ||
        normalized.contains('error') ||
        normalized.contains('unavailable')) {
      return true;
    }

    return false;
  }

  String reasonOrEmpty(dynamic value) {
    final raw = value?.toString() ?? '';
    return raw.trim();
  }

  static String serverErrorMessage(int statusCode) {
    switch (statusCode) {
      case 502:
        return 'CBE server temporarily unavailable (502 Bad Gateway)';
      case 503:
        return 'CBE server busy (503 Service Unavailable)';
      case 504:
        return 'CBE server timed out (504 Gateway Timeout)';
      case 500:
        return 'CBE internal server error (500)';
      case 403:
        return 'CBE server access denied (403)';
      case 404:
        return 'CBE receipt not found (404)';
      default:
        if (statusCode >= 500) {
          return 'CBE server error ($statusCode)';
        }
        return 'CBE HTTP error ($statusCode)';
    }
  }

  double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', ''));
  }

  Future<String> categorizeReason(String? reason) async {
    final categoryEngine = CategoryEngine(db);
    final candidate = cleanCandidate(reason) ?? 'General';
    debugPrint('[Categorize] candidate="$candidate" raw="${reason ?? ''}"');
    final result = await categoryEngine.findOrCreateCategory(candidate);
    debugPrint('[Categorize] result="$result" for candidate="$candidate"');
    return result;
  }

  static final RegExp _trailingReasonNoise = RegExp(
    r'\.\s*(?:for\s+(?:enquiries|any\s+complaint)|please\s+call|contact\s+center|thank\s+you|thanks\s+for|for\s+feedback)\b.*$',
    caseSensitive: false,
  );

  static String? _cleanBusinessReasonCandidate(String? value) {
    if (value == null) return null;
    final raw = value.trim();
    if (raw.isEmpty) return null;

    var cleaned = raw
        .replaceAll(
          RegExp(r'\bdone\s+via\s+mobile\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'^[\s\-,:;./]+|[\s\-,:;./]+$'), '')
        .trim();

    // Boilerplate sentences that sometimes trail a reason field (e.g. Awash
    // "Reason: d. For enquiries, please call 8980."). They are not part of the
    // narration, so cut everything from the first such clause onwards.
    cleaned = cleaned.replaceFirst(_trailingReasonNoise, '').trim();

    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  static bool _isGenericBusinessReason(String lower) {
    final exact = <String>{
      'mobile money',
      'bank transfer',
      'debit alert',
      'credit alert',
      'cbe transaction',
      'awash transaction',
      'transaction',
      'transfer',
      'general',
    };
    if (exact.contains(lower)) return true;

    if (lower.startsWith('mobile money ') ||
        lower.startsWith('bank transfer ') ||
        lower.startsWith('debit alert ') ||
        lower.startsWith('credit alert ') ||
        lower.startsWith('cbe transaction ') ||
        lower.startsWith('awash transaction ') ||
        lower.startsWith('txn#')) {
      return true;
    }

    if (lower.contains('mobile money') ||
        lower.contains('debit alert') ||
        lower.contains('credit alert') ||
        lower.contains('bank transfer') ||
        lower.contains('cbe transaction') ||
        lower.contains('awash transaction')) {
      return true;
    }

    return false;
  }
}
