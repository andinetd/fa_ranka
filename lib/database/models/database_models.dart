enum TransactionDirection { debit, credit, unknown }

class CategorySum {
  final String name;
  final double total;
  final int count;

  CategorySum({required this.name, required this.total, required this.count});
}

class CategoryMessageCount {
  final String name;
  final int messageCount;

  CategoryMessageCount({required this.name, required this.messageCount});
}

class TransactionDateRange {
  final DateTime start;
  final DateTime end;

  TransactionDateRange({required this.start, required this.end});
}

class TransactionSplit {
  final int? id;
  final int transactionId;
  final String category;
  final double amount;
  final int sortOrder;

  TransactionSplit({
    this.id,
    required this.transactionId,
    required this.category,
    required this.amount,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
    'transaction_id': transactionId,
    'category': category,
    'amount': amount,
    'sort_order': sortOrder,
  };

  factory TransactionSplit.fromMap(
    Map<String, dynamic> map,
    int txnId, {
    int? id,
  }) => TransactionSplit(
    id: id ?? map['id'] as int?,
    transactionId: txnId,
    category: map['category'] as String,
    amount: (map['amount'] as num).toDouble(),
    sortOrder: map['sort_order'] as int? ?? 0,
  );
}

class BudgetConfigRow {
  final int id;
  final String name;
  final String period;
  final double amount;
  final List<String> categories;
  final String account;
  final int startAt;
  final int endAt;
  final int createdAt;
  final int updatedAt;

  BudgetConfigRow({
    required this.id,
    required this.name,
    required this.period,
    required this.amount,
    required this.categories,
    required this.account,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });
}

class GoalRow {
  final int id;
  final String name;
  final String type; // 'income_target' | 'balance_target'
  final double targetAmount;
  final String currency;
  final String? period; // null = one-time, 'Weekly', 'Monthly', 'Yearly'
  final int startDate;
  final int endDate;
  final String accountFilter;
  final bool isCompleted;
  final int? completedAt;
  final int createdAt;
  final int updatedAt;
  final bool growthMode;
  final double startingBalance;

  GoalRow({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.currency,
    this.period,
    required this.startDate,
    required this.endDate,
    required this.accountFilter,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.growthMode = false,
    this.startingBalance = 0.0,
  });
}
