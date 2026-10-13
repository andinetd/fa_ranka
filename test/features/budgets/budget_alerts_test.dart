import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/features/budgets/domain/usecases/check_budget_alerts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({
      AppSettingsService.keyBudgetAlerts: true,
    });
    AppSettingsService.budgetAlertsNotifier.value = true;
  });

  tearDown(() async {
    await db.close();
  });

  test('BudgetAlertChecker respects calendar monthly boundary and splits', () async {
    final now = DateTime.now();

    // 1. Create a monthly budget for Food with limit 1000 ETB
    await db.saveBudgetConfig(
      name: 'Food Budget',
      period: 'Monthly',
      amount: 1000,
      categories: ['Food'],
      account: 'All Accounts',
    );

    // 2. Insert debit transaction inside current month
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        transactionHash: 'txn_current_month',
        amount: 800,
        direction: TransactionDirection.debit,
        reasonRawText: 'Dinner',
        normalizedReason: 'dinner',
        smsId: 'sms_1',
        threadId: 't1',
        senderAddress: 'CBE',
        rawSmsBody: 'body',
        smsTimestamp: now.millisecondsSinceEpoch,
        importedAt: now.millisecondsSinceEpoch,
        parserVersion: 1,
        parsedCategory: const Value('Food'),
      ),
    );

    // 3. Insert debit transaction in previous month (should NOT count towards current month's budget)
    final prevMonthDate = DateTime(now.year, now.month - 1, 15);
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        transactionHash: 'txn_prev_month',
        amount: 500,
        direction: TransactionDirection.debit,
        reasonRawText: 'Old groceries',
        normalizedReason: 'old groceries',
        smsId: 'sms_2',
        threadId: 't2',
        senderAddress: 'CBE',
        rawSmsBody: 'body',
        smsTimestamp: prevMonthDate.millisecondsSinceEpoch,
        importedAt: prevMonthDate.millisecondsSinceEpoch,
        parserVersion: 1,
        parsedCategory: const Value('Food'),
      ),
    );

    // Check alerts: 800 spent of 1000 is 80%, crossing threshold 75%
    final alerts = await BudgetAlertChecker.checkAlerts(db);
    expect(alerts.length, 1);
    expect(alerts.first.spent, 800);
    expect(alerts.first.limit, 1000);
    expect(alerts.first.threshold, 75);
  });

  test('BudgetAlertChecker calculates split categories accurately without double counting', () async {
    final now = DateTime.now();

    // Budget for Groceries (limit 500)
    await db.saveBudgetConfig(
      name: 'Groceries',
      period: 'Monthly',
      amount: 500,
      categories: ['Groceries'],
      account: 'All Accounts',
    );

    // Transaction of 1000 total, split: 400 Groceries, 600 Electronics
    final txnId = await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        transactionHash: 'txn_split',
        amount: 1000,
        direction: TransactionDirection.debit,
        reasonRawText: 'Supermarket',
        normalizedReason: 'supermarket',
        smsId: 'sms_split',
        threadId: 't3',
        senderAddress: 'CBE',
        rawSmsBody: 'body',
        smsTimestamp: now.millisecondsSinceEpoch,
        importedAt: now.millisecondsSinceEpoch,
        parserVersion: 1,
        parsedCategory: const Value('General'),
      ),
    );

    // Insert splits
    await db.saveSplits(txnId, [
      TransactionSplit(transactionId: txnId, category: 'Groceries', amount: 400),
      TransactionSplit(transactionId: txnId, category: 'Electronics', amount: 600),
    ]);

    // 400 spent of 500 is 80% (crosses 75%)
    final alerts = await BudgetAlertChecker.checkAlerts(db);
    expect(alerts.length, 1);
    expect(alerts.first.spent, 400); // Exactly 400, not 1000!
    expect(alerts.first.threshold, 75);
  });

  test('BudgetAlertChecker respects category exclusion mode (All Except chosen categories)', () async {
    final now = DateTime.now();

    // Budget: 1000 ETB, All spending EXCEPT 'Rent'
    await db.saveBudgetConfig(
      name: 'All Except Rent',
      period: 'Monthly',
      amount: 1000,
      categories: ['Rent'],
      categoryMode: 'exclude',
      account: 'All Accounts',
    );

    // 1. Transaction in Rent (5000 ETB) -> should be EXCLUDED
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        transactionHash: 'txn_rent',
        amount: 5000,
        direction: TransactionDirection.debit,
        reasonRawText: 'House Rent',
        normalizedReason: 'house rent',
        smsId: 'sms_rent',
        threadId: 't4',
        senderAddress: 'CBE',
        rawSmsBody: 'body',
        smsTimestamp: now.millisecondsSinceEpoch,
        importedAt: now.millisecondsSinceEpoch,
        parserVersion: 1,
        parsedCategory: const Value('Rent'),
      ),
    );

    // 2. Transaction in Food (850 ETB) -> should be INCLUDED
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        transactionHash: 'txn_food',
        amount: 850,
        direction: TransactionDirection.debit,
        reasonRawText: 'Dinner with friends',
        normalizedReason: 'dinner',
        smsId: 'sms_food',
        threadId: 't5',
        senderAddress: 'CBE',
        rawSmsBody: 'body',
        smsTimestamp: now.millisecondsSinceEpoch,
        importedAt: now.millisecondsSinceEpoch,
        parserVersion: 1,
        parsedCategory: const Value('Food'),
      ),
    );

    // 850 of 1000 is 85% (crosses 75% threshold, ignores 5000 Rent)
    final alerts = await BudgetAlertChecker.checkAlerts(db);
    expect(alerts.length, 1);
    expect(alerts.first.budgetName, 'All Except Rent');
    expect(alerts.first.spent, 850);
    expect(alerts.first.threshold, 75);
  });
}
