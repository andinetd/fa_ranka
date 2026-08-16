import 'package:faranka/features/transactions/models/transaction_group.dart';
import 'package:faranka/features/transactions/models/transaction_tile_view.dart';

List<TransactionRelativeGroup> groupTransactionsByRelativeBucket(
  List<TransactionTileView> rows,
) {
  final groups = <TransactionRelativeGroup>[];
  String? currentBucketKey;
  List<TransactionTileView> currentRows = [];

  for (final row in rows) {
    final bucket = bucketFor(
      DateTime.fromMillisecondsSinceEpoch(row.smsTimestamp),
    );

    if (currentBucketKey == null || bucket.key != currentBucketKey) {
      if (currentRows.isNotEmpty && currentBucketKey != null) {
        groups.add(
          TransactionRelativeGroup(
            label: labelForBucket(currentBucketKey),
            rows: List<TransactionTileView>.from(currentRows),
          ),
        );
      }
      currentBucketKey = bucket.key;
      currentRows = [row];
    } else {
      currentRows.add(row);
    }
  }

  if (currentRows.isNotEmpty && currentBucketKey != null) {
    groups.add(
      TransactionRelativeGroup(
        label: labelForBucket(currentBucketKey),
        rows: List<TransactionTileView>.from(currentRows),
      ),
    );
  }

  return groups;
}

TransactionRelativeBucket bucketFor(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final diff = today.difference(targetDay).inDays;

  if (diff <= 0) {
    return const TransactionRelativeBucket(key: 'today', label: 'Today');
  }
  if (diff == 1) {
    return const TransactionRelativeBucket(
      key: 'yesterday',
      label: 'Yesterday',
    );
  }
  if (diff <= 7) {
    return TransactionRelativeBucket(
      key: 'days-$diff',
      label: '$diff days ago',
    );
  }
  if (diff <= 13) {
    return const TransactionRelativeBucket(
      key: 'weeks-1',
      label: '1 week ago',
    );
  }
  if (diff <= 29) {
    return const TransactionRelativeBucket(
      key: 'weeks-2',
      label: '2 weeks ago',
    );
  }
  if (diff <= 44) {
    return const TransactionRelativeBucket(
      key: 'months-1',
      label: '1 month ago',
    );
  }
  if (diff <= 89) {
    return const TransactionRelativeBucket(
      key: 'months-2',
      label: '2 months ago',
    );
  }
  if (diff <= 179) {
    return const TransactionRelativeBucket(
      key: 'months-3',
      label: '3 months ago',
    );
  }
  if (diff <= 364) {
    return const TransactionRelativeBucket(
      key: 'months-6',
      label: '6 months ago',
    );
  }
  return const TransactionRelativeBucket(
    key: 'years-1',
    label: 'a year ago',
  );
}

String labelForBucket(String bucketKey) {
  if (bucketKey == 'today') return 'Today';
  if (bucketKey == 'yesterday') return 'Yesterday';
  if (bucketKey.startsWith('days-')) {
    final days = int.tryParse(bucketKey.substring('days-'.length)) ?? 0;
    return '$days days ago';
  }
  if (bucketKey.startsWith('weeks-')) {
    final weeks = int.tryParse(bucketKey.substring('weeks-'.length)) ?? 0;
    return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
  }
  if (bucketKey.startsWith('months-')) {
    final months = int.tryParse(bucketKey.substring('months-'.length)) ?? 0;
    if (months == 1) return '1 month ago';
    if (months == 2) return '2 months ago';
    if (months == 3) return '3 months ago';
    if (months == 6) return '6 months ago';
    return '$months months ago';
  }
  if (bucketKey.startsWith('years-')) return 'a year ago';
  return bucketKey;
}