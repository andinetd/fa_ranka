import 'package:faranka/features/transactions/models/transaction_tile_view.dart';

class TransactionRelativeGroup {
  const TransactionRelativeGroup({required this.label, required this.rows});

  final String label;
  final List<TransactionTileView> rows;
}

class TransactionRelativeBucket {
  const TransactionRelativeBucket({required this.key, required this.label});

  final String key;
  final String label;
}