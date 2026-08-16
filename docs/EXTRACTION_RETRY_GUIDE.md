# Receipt Extraction Retry Implementation Guide

## Overview

This guide explains how to implement receipt extraction retry functionality in your app UI. The system automatically retries failed extractions with exponential backoff, and users can manually refresh individual transactions.

## Database Fields

New fields added to `Transactions` table for tracking retries:

```dart
receiptExtractionStatus    // 'pending' | 'attempted_failed' | 'succeeded' | 'no_receipt'
receiptExtractionError     // Error message from failed extraction
receiptExtractionAttemptedAt  // Timestamp of last attempt
extractionRetryAttempts    // Count of retry attempts (0-5)
extractionNextRetryAt      // Timestamp when next automatic retry should occur
```

## Retry Strategy

**Exponential Backoff Schedule:**
- Attempt 1: Retry after 1 hour
- Attempt 2: Retry after 4 hours
- Attempt 3: Retry after 1 day
- Attempt 4: Retry after 3 days
- Attempt 5+: Retry after 1 week (max 5 retries)

## Using the Helper Classes

### 1. Quick Status Check with Extension

```dart
import 'package:faranka/features/transactions/presentation/utils/extraction_retry_helper.dart';

final txn = await db.getTransaction(txnId);

// Check if transaction can be manually retried
if (txn.canRetry) {
  // Show refresh button
}

// Get error message
final errorMsg = txn.extractionErrorMessage;

// Get next retry time
final nextRetry = txn.nextRetryTimeDisplay; // "In 2h 30m"

// Check if will auto-retry
if (txn.willAutoRetry) {
  // Show "automatic retry in progress" indicator
}
```

### 2. Display Retry Status Widget

```dart
import 'package:faranka/features/transactions/presentation/widgets/extraction_retry_status_widget.dart';

// In your transaction details page:
ExtractionRetryStatusWidget(
  transaction: transaction,
  onRefreshPressed: () async {
    final processor = TransactionProcessor(db);
    final success = await processor.manualRetryForTransaction(transaction.id);
    
    if (success) {
      // Refresh UI
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retrying extraction...')),
      );
    }
  },
  showNextRetryTime: true,
  showRetryAttempts: true,
)
```

### 3. Manual Retry Programmatically

```dart
final processor = TransactionProcessor(db);

// Single transaction - called when user clicks "Refresh" button
final success = await processor.manualRetryForTransaction(transactionId);

if (success) {
  // Refresh UI
  final updatedTxn = await db.getTransaction(transactionId);
}
```

### 4. Batch Automatic Retry (Background Task)

Call this from your WorkManager callback or periodic timer:

```dart
import 'package:faranka/features/transactions/presentation/widgets/extraction_retry_status_widget.dart';

// In your WorkManager callback:
Future<void> callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'retryFailedExtractions') {
      final db = AppDatabase();
      final success = await ExtractionAutoRetryService.performAutoRetry(db);
      return success;
    }
    return false;
  });
}

// Setup periodic task (call once during app initialization)
void setupBackgroundRetry() {
  ExtractionAutoRetryService.setupPeriodicRetry(
    interval: Duration(hours: 1), // Check every hour
  );
}
```

## UI Implementation Examples

### Example 1: Show Status in Transaction List

```dart
ListTile(
  title: Text(transaction.counterpartyName ?? 'Unknown'),
  subtitle: Text(transaction.normalizedReason),
  trailing: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(transaction.amount.toString()),
      if (transaction.receiptExtractionStatus == 'attempted_failed')
        Chip(
          label: const Text('⚠️ Extraction Failed'),
          backgroundColor: Colors.orange[200],
        ),
    ],
  ),
)
```

### Example 2: Show Status on Transaction Details Page

```dart
Column(
  children: [
    // ... existing transaction details ...
    
    // Show extraction status widget if extraction failed
    if (transaction.receiptExtractionStatus == 'attempted_failed')
      ExtractionRetryStatusWidget(
        transaction: transaction,
        onRefreshPressed: () async {
          _showRetryDialog(transaction);
        },
      ),
  ],
)
```

### Example 3: Retry Dialog with Progress

```dart
void _showRetryDialog(TransactionData transaction) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Retry Receipt Extraction?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Error: ${transaction.extractionErrorMessage}'),
          const SizedBox(height: 8),
          const Text('Would you like to try extracting again?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            _performManualRetry(transaction);
          },
          child: const Text('Retry Now'),
        ),
      ],
    ),
  );
}

Future<void> _performManualRetry(TransactionData transaction) async {
  final processor = TransactionProcessor(db);
  
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Retrying extraction...'),
        ],
      ),
    ),
  );
  
  try {
    final success = await processor.manualRetryForTransaction(transaction.id);
    Navigator.pop(context); // Close loading dialog
    
    if (success) {
      // Refresh the transaction
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Extraction retry started!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction not eligible for retry')),
      );
    }
  } catch (e) {
    Navigator.pop(context); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### Example 4: Show Pending Retry Count in App Bar Badge

```dart
AppBar(
  title: const Text('Transactions'),
  actions: [
    FutureBuilder<int>(
      future: ExtractionAutoRetryService.getFailedExtractionCount(db),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data! > 0) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Badge(
              label: Text(snapshot.data.toString()),
              child: const Icon(Icons.warning),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    ),
  ],
)
```

## Setting Up Automatic Retries

### Option 1: With WorkManager (Recommended)

```dart
// In main.dart or during app initialization:
import 'package:workmanager/workmanager.dart';

void setupWorkManager() {
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  Workmanager().registerPeriodicTask(
    'extraction_retry_task',
    'retryFailedExtractions',
    frequency: const Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
    ),
  );
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'retryFailedExtractions') {
      try {
        final db = AppDatabase();
        return await ExtractionAutoRetryService.performAutoRetry(db);
      } catch (e) {
        debugPrint('Auto-retry error: $e');
        return false;
      }
    }
    return false;
  });
}
```

### Option 2: With Timer (Simple Alternative)

```dart
// In your app state or main widget:
Timer? _retryTimer;

@override
void initState() {
  super.initState();
  // Check for retryable transactions every hour
  _retryTimer = Timer.periodic(
    const Duration(hours: 1),
    (_) async {
      await ExtractionAutoRetryService.performAutoRetry(db);
    },
  );
}

@override
void dispose() {
  _retryTimer?.cancel();
  super.dispose();
}
```

## Query Examples

### Get All Failed Extractions

```dart
final failed = await db.getManualRetryEligible(limit: 100);
for (final txn in failed) {
  print('${txn.id}: ${txn.extractionErrorMessage}');
}
```

### Get Ready for Auto-Retry

```dart
final ready = await db.getReadyForAutoRetry(limit: 50);
print('${ready.length} transactions ready for automatic retry');
```

### Monitor Extraction Status in Stream

```dart
Stream<List<TransactionData>> getFailedExtractions() {
  return db.select(db.transactions).watch().map((all) {
    return all
        .where((t) => t.receiptExtractionStatus == 'attempted_failed')
        .toList();
  });
}

// Use in StreamBuilder
StreamBuilder<List<TransactionData>>(
  stream: getFailedExtractions(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final failedCount = snapshot.data!.length;
      return Text('Failed extractions: $failedCount');
    }
    return const SizedBox.shrink();
  },
)
```

## Error Handling

The system gracefully handles various error scenarios:

- **No Internet**: Scheduled for retry with full backoff
- **Parsing Failure**: Tracked with error message for debugging
- **Timeout**: Retried with exponential backoff
- **Max Retries Reached**: Stops retrying but keeps transaction visible with full error context

User can always manually retry regardless of attempt count or time constraint.

## Database Cleanup

To reset a transaction's extraction status (for testing):

```dart
// Reset to first-time pending
await db.resetExtractionStatusForRetry(transactionId);

// Or directly update
await db.updateExtractionStatus(
  transactionId,
  status: 'pending',
  error: null,
);
```

## Monitoring & Debugging

Enable debug logging:

```dart
// The system logs to debugPrint with "[ExtractionAutoRetry]" prefix
// Set breakpoint in DB methods to trace execution

// Check current status
final txn = await db.getTransaction(txnId);
print('Status: ${txn.receiptExtractionStatus}');
print('Attempts: ${txn.extractionRetryAttempts}');
print('Next retry: ${DateTime.fromMillisecondsSinceEpoch(txn.extractionNextRetryAt ?? 0)}');
print('Error: ${txn.receiptExtractionError}');
```

## Summary

The implementation provides:
✅ Automatic retry with exponential backoff
✅ Manual refresh button for user control
✅ Clear error messages for debugging
✅ Retry scheduling based on time
✅ Easy UI integration with helper classes
✅ Background task integration ready
✅ Full tracking and audit trail
