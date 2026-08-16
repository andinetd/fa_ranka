import 'package:faranka/database/database.dart';

class TxnBundle {
  final List<TransactionData> txns;
  final Map<int, List<TransactionSplit>> splits;
  TxnBundle({required this.txns, required this.splits});
}
