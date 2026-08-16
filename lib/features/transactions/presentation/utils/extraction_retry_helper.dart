import 'package:faranka/database/database.dart';

/// Helper class for managing receipt extraction retry UI state
class ExtractionRetryHelper {
  /// Check if a transaction can be manually retried
  static bool canManuallyRetry(TransactionData transaction) {
    return transaction.receiptExtractionStatus == 'attempted_failed' &&
        transaction.receiptUrl != null &&
        transaction.receiptUrl!.isNotEmpty;
  }

  /// Get user-friendly error message
  static String getErrorMessage(TransactionData transaction) {
    if (transaction.receiptExtractionStatus != 'attempted_failed') {
      return '';
    }

    final error = transaction.receiptExtractionError ?? 'Unknown error';
    
    // Make common errors more user-friendly
    if (error.contains('server is down')) {
      return 'Bank receipt server is down. Will retry automatically.';
    } else if (error.contains('No internet')) {
      return 'No internet connection. Will retry automatically.';
    } else if (error.contains('timeout')) {
      return 'Connection timeout. Will retry automatically.';
    } else if (error.contains('not found') || error.contains('404')) {
      return 'Receipt page not found. May have expired.';
    } else if (error.contains('parsing') || error.contains('parse')) {
      return 'Failed to extract receipt data. Parser being improved.';
    }
    
    return 'Extraction failed: $error';
  }

  /// Get next retry time as human-readable string
  static String getNextRetryTime(TransactionData transaction) {
    if (transaction.extractionNextRetryAt == null) {
      return 'No retry scheduled';
    }

    final nextRetry = DateTime.fromMillisecondsSinceEpoch(
      transaction.extractionNextRetryAt!,
    );
    final now = DateTime.now();

    if (nextRetry.isBefore(now)) {
      return 'Retrying now...';
    }

    final duration = nextRetry.difference(now);

    if (duration.inMinutes < 1) {
      return 'In ${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return 'In ${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      return 'In ${duration.inHours}h';
    } else {
      return 'In ${duration.inDays}d';
    }
  }

  /// Get status badge text
  static String getStatusBadgeText(TransactionData transaction) {
    switch (transaction.receiptExtractionStatus) {
      case 'succeeded':
        return 'Extracted';
      case 'attempted_failed':
        return 'Extraction Failed';
      case 'no_receipt':
        return 'No Receipt';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  /// Get status badge color (for UI)
  static String getStatusBadgeColor(TransactionData transaction) {
    switch (transaction.receiptExtractionStatus) {
      case 'succeeded':
        return '#4CAF50'; // Green
      case 'attempted_failed':
        return '#FF9800'; // Orange
      case 'no_receipt':
        return '#9E9E9E'; // Gray
      case 'pending':
        return '#2196F3'; // Blue
      default:
        return '#757575'; // Dark gray
    }
  }

  /// Determine if automatic retry will happen
  static bool willAutoRetry(TransactionData transaction) {
    return transaction.receiptExtractionStatus == 'attempted_failed' &&
        transaction.extractionNextRetryAt != null &&
        transaction.extractionRetryAttempts < 5; // Stop retrying after 5 attempts
  }

  /// Get retry attempt count display
  static String getRetryAttemptCount(TransactionData transaction) {
    final attempts = transaction.extractionRetryAttempts;
    if (attempts == 0) return '';
    if (attempts >= 5) return 'Max retries reached';
    return 'Attempt $attempts/5';
  }

  /// Check if manual retry will bypass time delay (immediately available)
  static bool isReadyForImmediateRetry(TransactionData transaction) {
    if (transaction.receiptExtractionStatus != 'attempted_failed') {
      return false;
    }

    final nextRetryAt = transaction.extractionNextRetryAt;
    if (nextRetryAt == null) {
      return true; // No scheduled retry, can try immediately
    }

    return DateTime.fromMillisecondsSinceEpoch(nextRetryAt)
        .isBefore(DateTime.now());
  }
}

/// Extension on TransactionData for convenient access to retry helpers
extension ExtractionRetryExt on TransactionData {
  bool get canRetry => ExtractionRetryHelper.canManuallyRetry(this);

  String get extractionErrorMessage =>
      ExtractionRetryHelper.getErrorMessage(this);

  String get nextRetryTimeDisplay =>
      ExtractionRetryHelper.getNextRetryTime(this);

  String get statusBadgeText =>
      ExtractionRetryHelper.getStatusBadgeText(this);

  String get statusBadgeColor =>
      ExtractionRetryHelper.getStatusBadgeColor(this);

  bool get willAutoRetry => ExtractionRetryHelper.willAutoRetry(this);

  String get retryAttemptDisplay =>
      ExtractionRetryHelper.getRetryAttemptCount(this);

  bool get isReadyForImmediateRetry =>
      ExtractionRetryHelper.isReadyForImmediateRetry(this);
}
