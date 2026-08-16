import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_processor.dart';
import 'package:faranka/app/core/services/network_status_service.dart';
import 'package:faranka/features/transactions/presentation/utils/extraction_retry_helper.dart';

/// Background service for automatic receipt extraction retries.
/// 
/// This service periodically checks for transactions with failed extractions
/// that are ready to be retried based on their scheduled retry time.
/// 
/// Integration with WorkManager:
/// ```dart
/// Workmanager().registerPeriodicTask(
///   "extraction_retry_task",
///   "retryFailedExtractions",
///   frequency: Duration(hours: 1), // Check every hour
///   constraints: Constraints(
///     networkType: NetworkType.connected,
///   ),
/// );
/// ```
class ExtractionAutoRetryService {
  static const String taskName = 'retryFailedExtractions';
  static const String taskId = 'extraction_retry_task';

  /// Perform automatic retry for all ready transactions
  /// Call this from your WorkManager callback or periodic timer
  /// 
  /// This method ensures internet is available before attempting retries.
  /// If internet is unavailable, it waits for connectivity before proceeding.
  static Future<bool> performAutoRetry(AppDatabase db) async {
    try {
      debugPrint('[ExtractionAutoRetry] Starting auto-retry task');
      
      // Check if internet is available
      bool hasInternet = await NetworkStatusService.hasInternet();
      
      if (!hasInternet) {
        debugPrint(
          '[ExtractionAutoRetry] No internet available, waiting for connection...',
        );
        
        try {
          // Wait for internet to become available (max 24 hours)
          // If still no internet after timeout, skip this batch
          await NetworkStatusService.watchInternetStatus()
              .firstWhere((isOnline) => isOnline)
              .timeout(const Duration(hours: 24));
          
          debugPrint('[ExtractionAutoRetry] Internet connection restored');
        } on TimeoutException {
          debugPrint(
            '[ExtractionAutoRetry] Timeout waiting for internet (24h), '
            'will retry on next scheduled check',
          );
          return false;
        }
      }
      
      final processor = TransactionProcessor(db);
      
      // Get transactions ready for automatic retry
      final readyForRetry = await db.getReadyForAutoRetry(limit: 50);
      
      if (readyForRetry.isEmpty) {
        debugPrint('[ExtractionAutoRetry] No transactions ready for retry');
        return true;
      }

      debugPrint(
        '[ExtractionAutoRetry] Found ${readyForRetry.length} transactions ready for retry',
      );

      // Attempt retry for each transaction
      // The processor handles all error tracking and backoff logic
      await processor.retryFailedExtractions(limit: 50);

      debugPrint('[ExtractionAutoRetry] Auto-retry task completed successfully');
      return true;
    } catch (e) {
      debugPrint('[ExtractionAutoRetry] Error during auto-retry: $e');
      return false;
    }
  }

  /// Get count of transactions pending automatic retry
  /// Useful for showing badges/indicators in UI
  static Future<int> getPendingRetryCount(AppDatabase db) async {
    final ready = await db.getReadyForAutoRetry(limit: 1000);
    return ready.length;
  }

  /// Get count of all failed extractions (for manual retry)
  static Future<int> getFailedExtractionCount(AppDatabase db) async {
    final failed = await db.getManualRetryEligible(limit: 1000);
    return failed.length;
  }

  /// Setup periodic auto-retry task with WorkManager
  /// Call this in your app initialization
  /// 
  /// Note: Requires 'workmanager' or similar package
  static void setupPeriodicRetry({
    Duration interval = const Duration(hours: 1),
  }) {
    // This is a placeholder - actual implementation depends on your 
    // background task scheduler (workmanager, android_alarm_manager, etc.)
    
    debugPrint(
      '[ExtractionAutoRetry] Setup would register periodic task every $interval',
    );
    
    // Example with workmanager:
    // Workmanager().registerPeriodicTask(
    //   taskId,
    //   taskName,
    //   frequency: interval,
    //   constraints: Constraints(
    //     networkType: NetworkType.connected,
    //     requiresBatteryNotLow: false,
    //     requiresCharging: false,
    //     requiresDeviceIdle: false,
    //   ),
    // );
  }
}

/// Widget helper for showing extraction retry status in UI.
///
/// Compact single-row card shown when receipt extraction failed: a short
/// auto-retry countdown (or failure note) plus an optional manual retry button.
class ExtractionRetryStatusWidget extends ConsumerWidget {
  final TransactionData transaction;
  final VoidCallback? onRefreshPressed;

  const ExtractionRetryStatusWidget({
    super.key,
    required this.transaction,
    this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dims = ref.watch(dimensionsProvider);
    if (transaction.receiptExtractionStatus != 'attempted_failed') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: dims.symmetric(h: 12, v: 8),
      margin: dims.only(t: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECB3), // Warning orange
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFBC02D), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: Color(0xFF795548)),
          SizedBox(width: dims(6)),
          Expanded(
            child: Text(
              _retryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF795548),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRefreshPressed != null && transaction.canRetry) ...[
            SizedBox(width: dims.spacingSm),
            TextButton.icon(
              onPressed: onRefreshPressed,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF795548),
                padding: dims.symmetric(h: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  String get _retryLabel {
    if (transaction.willAutoRetry) {
      final display = transaction.nextRetryTimeDisplay;
      return display.startsWith('In ')
          ? 'Auto retry ${display.toLowerCase()}'
          : display;
    }
    if (transaction.extractionRetryAttempts >= 5) {
      return 'Retries exhausted';
    }
    return 'Receipt extraction failed';
  }
}

