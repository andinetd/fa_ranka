import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'models/database_models.dart';
export 'models/database_models.dart';
export 'database_sms_logic.dart';
export 'database_retry.dart';

part 'database.g.dart';

@DataClassName('TransactionData')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get transactionHash => text().unique()();

  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get direction => textEnum<TransactionDirection>()();

  TextColumn get counterpartyName => text().nullable()();
  TextColumn get counterpartyNumber => text().nullable()();
  TextColumn get bankName => text().nullable()();

  TextColumn get bankTransactionId => text().nullable().unique()();

  TextColumn get referenceNumber => text().nullable()();
  TextColumn get channel => text().nullable()();
  TextColumn get location => text().nullable()();
  RealColumn get balanceAfter => real().nullable()();

  TextColumn get receiptUrl => text().nullable()();
  TextColumn get localReceiptPath => text().nullable()();

  TextColumn get reasonRawText => text()();
  TextColumn get normalizedReason => text()();
  TextColumn get parsedCategory =>
      text().withDefault(const Constant('Uncategorized'))();

  RealColumn get commission => real().withDefault(const Constant(0.0))();
  RealColumn get vat => real().withDefault(const Constant(0.0))();
  TextColumn get branchName => text().nullable()();

  TextColumn get smsId => text()();
  TextColumn get threadId => text()();
  TextColumn get senderAddress => text()();
  TextColumn get rawSmsBody => text()();
  IntColumn get smsTimestamp => integer()();
  IntColumn get importedAt => integer()();

  BoolColumn get smsRead => boolean().withDefault(const Constant(false))();

  IntColumn get parserVersion => integer()();

  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringPattern => text().nullable()();

  // Receipt extraction retry fields
  TextColumn get receiptExtractionStatus =>
      text().withDefault(const Constant('pending'))();
  TextColumn get receiptExtractionError => text().nullable()();
  IntColumn get receiptExtractionAttemptedAt => integer().nullable()();
  IntColumn get extractionRetryAttempts =>
      integer().withDefault(const Constant(0))();
  IntColumn get extractionNextRetryAt => integer().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().unique()();
  TextColumn get normalizedName => text().unique()();
}

class SmsInbox extends Table {
  TextColumn get id => text()();
  TextColumn get threadId => text().nullable()();
  TextColumn get address => text()();
  TextColumn get body => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isProcessed => boolean().withDefault(const Constant(false))();
  IntColumn get processingAttempts =>
      integer().withDefault(const Constant(0))();
  IntColumn get lastTriedAt => integer().nullable()();
  IntColumn get processedAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();

  // Parsed fields (populated during import)
  TextColumn get transactionId => text().nullable()();
  TextColumn get parsedDate => text().nullable()();
  TextColumn get parsedTime => text().nullable()();
  RealColumn get amount => real().nullable()();
  RealColumn get commission => real().nullable()();
  RealColumn get vat => real().nullable()();
  RealColumn get total => real().nullable()();
  TextColumn get fromAccount => text().nullable()();
  TextColumn get toAccount => text().nullable()();
  TextColumn get beneficiaryAccount => text().nullable()();
  TextColumn get beneficiaryBank => text().nullable()();
  TextColumn get transactionType => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get tillNumber => text().nullable()();
  TextColumn get tin => text().nullable()();
  TextColumn get vatReg => text().nullable()();
  TextColumn get parseSource => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Transactions,
    Categories,
    SmsInbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 15;

  // 2. Migration strategy for schema upgrades
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await customStatement('''
          CREATE TABLE IF NOT EXISTS budget_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            period TEXT NOT NULL,
            amount REAL NOT NULL,
            categories_json TEXT NOT NULL,
            account TEXT NOT NULL,
            start_at INTEGER NOT NULL DEFAULT 0,
            end_at INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS transaction_splits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id INTEGER NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await _createPerformanceIndexes();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) await m.createTable(smsInbox);
        if (from < 3) {
          await m.addColumn(smsInbox, smsInbox.threadId);
        }
        if (from < 4) {
          // Add parsed fields columns to smsInbox
          await m.addColumn(smsInbox, smsInbox.transactionId);
          await m.addColumn(smsInbox, smsInbox.parsedDate);
          await m.addColumn(smsInbox, smsInbox.parsedTime);
          await m.addColumn(smsInbox, smsInbox.amount);
          await m.addColumn(smsInbox, smsInbox.commission);
          await m.addColumn(smsInbox, smsInbox.vat);
          await m.addColumn(smsInbox, smsInbox.total);
          await m.addColumn(smsInbox, smsInbox.fromAccount);
          await m.addColumn(smsInbox, smsInbox.toAccount);
          await m.addColumn(smsInbox, smsInbox.beneficiaryAccount);
          await m.addColumn(smsInbox, smsInbox.beneficiaryBank);
          await m.addColumn(smsInbox, smsInbox.transactionType);
          await m.addColumn(smsInbox, smsInbox.reason);
          await m.addColumn(smsInbox, smsInbox.tillNumber);
          await m.addColumn(smsInbox, smsInbox.tin);
          await m.addColumn(smsInbox, smsInbox.vatReg);
          await m.addColumn(smsInbox, smsInbox.parseSource);
        }
        if (from < 5) {
          await m.addColumn(smsInbox, smsInbox.processingAttempts);
          await m.addColumn(smsInbox, smsInbox.lastTriedAt);
          await m.addColumn(smsInbox, smsInbox.processedAt);
          await m.addColumn(smsInbox, smsInbox.lastError);
        }
        if (from < 6) {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS budget_configs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              period TEXT NOT NULL,
              amount REAL NOT NULL,
              categories_json TEXT NOT NULL,
              account TEXT NOT NULL,
              start_at INTEGER NOT NULL DEFAULT 0,
              end_at INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
        }
        if (from < 7) {
          try {
            await customStatement(
              'ALTER TABLE budget_configs ADD COLUMN start_at INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE budget_configs ADD COLUMN end_at INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
        }
        if (from < 8) {
          // Add receipt extraction retry fields to Transactions table
          try {
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN receipt_extraction_status TEXT NOT NULL DEFAULT "pending"',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN receipt_extraction_error TEXT',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN receipt_extraction_attempted_at INTEGER',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN extraction_retry_attempts INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN extraction_next_retry_at INTEGER',
            );
          } catch (_) {}
        }
        if (from < 9) {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS transaction_splits (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id INTEGER NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
              category TEXT NOT NULL,
              amount REAL NOT NULL,
              sort_order INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        if (from < 10) {
          // v10 was savings goals — tables removed, migration slot preserved for numbering
        }
        if (from < 11) {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS goals (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              target_amount REAL NOT NULL,
              currency TEXT NOT NULL DEFAULT 'ETB',
              period TEXT NOT NULL DEFAULT '',
              start_date INTEGER NOT NULL DEFAULT 0,
              end_date INTEGER NOT NULL DEFAULT 0,
              account_filter TEXT NOT NULL DEFAULT 'All Accounts',
              is_completed INTEGER NOT NULL DEFAULT 0,
              completed_at INTEGER,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              growth_mode INTEGER NOT NULL DEFAULT 0,
              starting_balance REAL NOT NULL DEFAULT 0.0
            )
          ''');
        }
        if (from < 12) {
          // v12 was subscription tables — removed, migration slot preserved
        }
        if (from < 13) {
          await _createPerformanceIndexes();
        }
        if (from < 14) {
          await customStatement('''
            UPDATE transactions
            SET bank_name = 'Telebirr'
            WHERE TRIM(LOWER(bank_name)) = 'ethio telecom'
          ''');
        }
        if (from < 15) {
          // v15 removed subscriptions/subscription_payments tables and the
          // transactions.subscription_id column.
          try {
            await customStatement(
              'ALTER TABLE transactions DROP COLUMN subscription_id',
            );
          } catch (_) {}
          try {
            await customStatement('DROP TABLE IF EXISTS subscription_payments');
          } catch (_) {}
          try {
            await customStatement('DROP TABLE IF EXISTS subscriptions');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createPerformanceIndexes() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_transactions_recent
      ON transactions (sms_timestamp DESC, imported_at DESC)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_transactions_direction_timestamp
      ON transactions (direction, sms_timestamp)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_transactions_bank_timestamp
      ON transactions (bank_name, sms_timestamp)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_transaction_splits_transaction_order
      ON transaction_splits (transaction_id, sort_order)
    ''');
  }

  Future<void> wipeAllData() async {
    await delete(transactions).go();
    await delete(categories).go();
    await delete(smsInbox).go();
    await customStatement('DELETE FROM budget_configs');
    await customStatement('DELETE FROM transaction_splits');
    await customStatement('DELETE FROM goals');

    final dir = await getApplicationDocumentsDirectory();
    final receiptDir = Directory('${dir.path}/receipts');
    if (await receiptDir.exists()) {
      await receiptDir.delete(recursive: true);
    }
    notifyUpdates({const TableUpdate('budget_configs')});
    notifyUpdates({const TableUpdate('transactions')});
    notifyUpdates({const TableUpdate('goals')});
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finance_db.sqlite'));
    return NativeDatabase(file);
  });
}
