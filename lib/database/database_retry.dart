import 'package:drift/drift.dart';
import 'database.dart';

// Extension for receipt extraction retry management
extension ExtractionRetry on AppDatabase {
  /// Get transactions ready for automatic retry based on scheduled time
  Future<List<TransactionData>> getReadyForAutoRetry({int limit = 50}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (select(transactions)
          ..where((t) =>
              t.receiptExtractionStatus.equals('attempted_failed') &
              t.extractionNextRetryAt.isSmallerOrEqualValue(now) &
              t.extractionRetryAttempts.isSmallerThanValue(5))
          ..limit(limit)
          ..orderBy([
            (t) => OrderingTerm(expression: t.extractionNextRetryAt),
          ]))
        .get();
  }

  /// Get transactions eligible for manual retry (any failed extraction)
  Future<List<TransactionData>> getManualRetryEligible({int limit = 50}) {
    return (select(transactions)
          ..where((t) =>
              t.receiptExtractionStatus.equals('attempted_failed') &
              t.receiptUrl.isNotNull() &
              t.extractionRetryAttempts.isSmallerThanValue(5))
          ..limit(limit)
          ..orderBy([
            (t) => OrderingTerm(expression: t.smsTimestamp, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Update extraction status with retry backoff calculation
  Future<void> updateExtractionStatusWithRetry(
    int transactionId,
    String status,
    String? errorMessage,
  ) async {
    final transaction = await (select(transactions)
          ..where((t) => t.id.equals(transactionId)))
        .getSingleOrNull();

    if (transaction == null) return;

    final newAttempts = transaction.extractionRetryAttempts + 1;
    final nextRetryAt = newAttempts < 5
        ? DateTime.now()
            .add(_getRetryDelay(newAttempts))
            .millisecondsSinceEpoch
        : null;

    await (update(transactions)..where((t) => t.id.equals(transactionId)))
        .write(
      TransactionsCompanion(
        receiptExtractionStatus: Value(status),
        receiptExtractionError: errorMessage != null ? Value(errorMessage) : const Value(null),
        receiptExtractionAttemptedAt: Value(DateTime.now().millisecondsSinceEpoch),
        extractionRetryAttempts: Value(newAttempts),
        extractionNextRetryAt: nextRetryAt != null ? Value(nextRetryAt) : const Value(null),
      ),
    );
  }

  /// Calculate retry delay based on attempt number (exponential backoff)
  Duration _getRetryDelay(int attemptNumber) {
    // Delays: 1h, 4h, 1d, 3d, 7d for attempts 1-5
    switch (attemptNumber) {
      case 1:
        return const Duration(hours: 1);
      case 2:
        return const Duration(hours: 4);
      case 3:
        return const Duration(days: 1);
      case 4:
        return const Duration(days: 3);
      case 5:
        return const Duration(days: 7);
      default:
        return const Duration(hours: 1);
    }
  }
}
