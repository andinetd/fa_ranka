import 'dart:developer' as dev;

import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/domain/services/category_engine.dart';
import 'package:faranka/features/receipts/data/parsers/awash_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/boa_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/cbe_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/telebirr_sms_parser.dart';
import 'package:faranka/features/receipts/data/services/awash_receipt_service.dart';
import 'package:faranka/features/receipts/data/services/cbe_receipt_service.dart';
import 'package:faranka/features/transactions/domain/usecases/processors/bank_processing_support.dart';
import 'package:faranka/app/core/services/network_status_service.dart';
import 'package:drift/drift.dart';

/// Recategorizes transactions that were marked as "Uncategorized"
/// by re-parsing their reason and applying the categorization logic.
class TransactionRecategorizer {
  final AppDatabase db;
  
  TransactionRecategorizer(this.db);

  /// Recategorizes all "Uncategorized" transactions from the last N days.
  /// Returns the number of transactions that were updated.
  /// Days defaults to 30 (matching the monthly view in UI)
  Future<int> recategorizeUncategorized({int days = 30}) async {
    // Calculate cutoff timestamp
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;

    // Find all uncategorized debit transactions from the specified periodre
    final uncategorizedTxns = await (db.select(db.transactions)
          ..where((t) => t.parsedCategory.equals('Uncategorized'))
          ..where((t) => t.direction.equals('debit'))
          ..where((t) => t.smsTimestamp.isBiggerOrEqualValue(cutoffTime)))
        .get();

    if (uncategorizedTxns.isEmpty) {
      return 0;
    }

    final categoryEngine = CategoryEngine(db);
    int updatedCount = 0;

    // Process each uncategorized transaction
    for (final txn in uncategorizedTxns) {
      // Skip if not a debit transaction (credits should stay uncategorized)
      if (txn.direction != TransactionDirection.debit) {
        continue;
      }

      // Only categorize from reasonRawText field
      if (txn.reasonRawText.isEmpty) {
        continue;
      }

      try {
        // Re-run categorization logic using reasonRawText
        final newCategory = await categoryEngine.findOrCreateCategory(txn.reasonRawText);

        // Only update if we found a better category (not "Uncategorized")
        if (newCategory != 'Uncategorized') {
          // Update the transaction with the new category
          await db.update(db.transactions).replace(
                txn.copyWith(parsedCategory: newCategory),
              );
          updatedCount++;
        }
      } catch (e) {
        // Log error but continue processing other transactions
        dev.log('Error recategorizing transaction ${txn.id}: $e');
      }
    }

    return updatedCount;
  }

  /// Recategorizes a specific transaction by ID.
  /// Returns true if the category was updated, false otherwise.
  Future<bool> recategorizeTransaction(int transactionId) async {
    final txn = await (db.select(db.transactions)
          ..where((t) => t.id.equals(transactionId))
          ..limit(1))
        .getSingleOrNull();

    if (txn == null) {
      return false;
    }

    // Skip if not a debit transaction
    if (txn.direction != TransactionDirection.debit) {
      return false;
    }

    // Only categorize from reasonRawText field
    if (txn.reasonRawText.isEmpty) {
      return false;
    }

    try {
      final categoryEngine = CategoryEngine(db);
      final newCategory = await categoryEngine.findOrCreateCategory(txn.reasonRawText);

      // Only update if we found a better category
      if (newCategory != 'Uncategorized' && newCategory != txn.parsedCategory) {
        await db.update(db.transactions).replace(
              txn.copyWith(parsedCategory: newCategory),
            );
        return true;
      }
    } catch (e) {
      dev.log('Error recategorizing transaction $transactionId: $e');
    }

    return false;
  }

  /// Recategorizes all transactions in a specific category.
  /// Returns the number of transactions that were updated.
  Future<int> recategorizeCategory(String categoryName) async {
    final txns = await (db.select(db.transactions)
          ..where((t) => t.parsedCategory.equals(categoryName)))
        .get();

    int updateCount = 0;

    for (final txn in txns) {
      // Only recategorize debits and transactions with reason text
      if (txn.direction != TransactionDirection.debit || txn.reasonRawText.isEmpty) {
        continue;
      }

      try {
        final categoryEngine = CategoryEngine(db);
        final newCategory = await categoryEngine.findOrCreateCategory(txn.reasonRawText);

        // Update if we found a different category
        if (newCategory != txn.parsedCategory) {
          await db.update(db.transactions).replace(
                txn.copyWith(parsedCategory: newCategory),
              );
          updateCount++;
        }
      } catch (e) {
        dev.log('Error recategorizing transaction ${txn.id}: $e');
      }
    }

    return updateCount;
  }

  /// Deep parses all transactions in a specific category by re-fetching receipts and extracting fields.
  /// Returns the number of transactions that were updated with new data.
  Future<int> deepParseCategory(String categoryName) async {
    final online = await NetworkStatusService.hasInternet();
    if (!online) {
      throw Exception('No internet connection. Deep parse requires online access.');
    }

    final txns = await (db.select(db.transactions)
          ..where((t) => t.parsedCategory.equals(categoryName)))
        .get();

    int updateCount = 0;

    for (final txn in txns) {
      // Only deep parse transactions with URLs
      if (txn.receiptUrl == null || txn.receiptUrl!.isEmpty) {
        continue;
      }

      try {
        Map<String, dynamic>? deepData;

        // Try to parse based on URL pattern - CBE typically has certain patterns
        if (txn.receiptUrl!.contains('cbe')) {
          deepData = await CbeReceiptService.fetchAndParseReceipt(
            txn.receiptUrl!,
            smsText: txn.reasonRawText,
          );
        } else {
          // Default to Awash for other patterns
          deepData = await AwashReceiptService.fetchAndParseHtmlReceipt(
            txn.receiptUrl!,
          );
        }

        if (deepData.isNotEmpty) {
          // Extract new values from deep parse
          final newReason = BankProcessingSupport.normalizeBusinessReason(
            deepData['reason']?.toString() ?? txn.reasonRawText,
          );
          final newAmount = _toDouble(deepData['amount']) ?? txn.amount;

          // Update transaction with new data
          await db.update(db.transactions).replace(
                txn.copyWith(
                  reasonRawText: newReason,
                  amount: newAmount,
                ),
              );

          // Recategorize based on new reason
          if (newReason.isNotEmpty && newReason != txn.reasonRawText) {
            try {
              final categoryEngine = CategoryEngine(db);
              final newCategory = await categoryEngine.findOrCreateCategory(newReason);
              
              // Update category if different
              if (newCategory != txn.parsedCategory) {
                final updated = await (db.select(db.transactions)
                      ..where((t) => t.id.equals(txn.id)))
                    .getSingle();
                
                await db.update(db.transactions).replace(
                      updated.copyWith(parsedCategory: newCategory),
                    );
              }
            } catch (e) {
              dev.log('Error recategorizing after deep parse: $e');
            }
          }

          updateCount++;
        }
      } catch (e) {
        dev.log('Error deep parsing transaction ${txn.id}: $e');
      }
    }

    return updateCount;
  }

  /// Helper to convert value to double
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', ''));
    }
    return null;
  }

  /// Gets count of uncategorized debit transactions from the last N days.
  /// Days defaults to 30 (matching the monthly view in UI)
  Future<int> getUncategorizedDebitCount({int days = 30}) async {
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;

    final result = await (db.selectOnly(db.transactions)
          ..addColumns([db.transactions.id.count()])
          ..where(db.transactions.parsedCategory.equals('Uncategorized'))
          ..where(db.transactions.direction.equals('debit'))
          ..where(db.transactions.smsTimestamp.isBiggerOrEqualValue(cutoffTime)))
        .map((row) => row.read(db.transactions.id.count()))
        .getSingleOrNull();

    return result ?? 0;
  }

  /// Retry extracting reason from original SMS for uncategorized transactions.
  /// This handles cases where extraction failed initially but might succeed on retry.
  /// Returns the number of transactions that were successfully re-extracted and recategorized.
  Future<int> retryReasonExtraction({int days = 30}) async {
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;

     // Find uncategorized transactions with empty/null reasonRawText
     final missingReasonTxns = await (db.select(db.transactions)
           ..where((t) => t.parsedCategory.equals('Uncategorized'))
           ..where((t) => t.reasonRawText.equals('') | t.reasonRawText.isNull())
           ..where((t) => t.smsTimestamp.isBiggerOrEqualValue(cutoffTime)))
         .get();

    if (missingReasonTxns.isEmpty) {
      return 0;
    }

    final categoryEngine = CategoryEngine(db);
    int updatedCount = 0;

    for (final txn in missingReasonTxns) {
      try {
        // Get original SMS from smsInbox
        final sms = await (db.select(db.smsInbox)
              ..where((s) => s.id.equals(txn.smsId)))
            .getSingleOrNull();

        if (sms == null || sms.body.isEmpty) {
          continue;
        }

        // Re-parse SMS to try extracting reason again
        final addressLower = sms.address.toLowerCase();
        final isCbe = addressLower.contains('cbe');
        final isTelebirr = addressLower == '127' ||
            addressLower.contains('telebirr') ||
            addressLower.contains('ethio telecom');
        final isBoa = addressLower.contains('boa') ||
            addressLower.contains('abyssinia');
        final reasonText = isCbe
            ? CbeSmsParser.parseAll(sms.body)['reason']?.toString()
            : isTelebirr
                ? TelebirrSmsParser.parseAll(sms.body)['reason']?.toString()
                : isBoa
                    ? BoaSmsParser.parseAll(sms.body)['reason']?.toString()
                    : AwashSmsParser.parseAll(sms.body)['reason']?.toString();

        final newReason = BankProcessingSupport.normalizeBusinessReason(
          reasonText,
        );

        // Only proceed if we found a non-empty reason
        if (newReason.isEmpty) {
          continue;
        }

        // Categorize using the newly extracted reason
        final newCategory = await categoryEngine.findOrCreateCategory(newReason);

        // Only update if we found a meaningful category (not "Uncategorized")
        if (newCategory != 'Uncategorized') {
          // Update transaction with both new reason and category
          await db.update(db.transactions).replace(
                txn.copyWith(
                  reasonRawText: newReason.trim(),
                  parsedCategory: newCategory,
                ),
              );
          updatedCount++;
        }
      } catch (e) {
        // Log error but continue processing other transactions
        dev.log('Error re-extracting reason for transaction ${txn.id}: $e');
      }
    }

    return updatedCount;
  }

  /// Retry extracting reason for transactions marked as 'Empty'.
  /// Transactions marked as 'Empty' have the reason field extracted but it was blank.
  /// This attempts to find a better reason using counterparty/beneficiary info.
  /// Returns the number of transactions that were successfully recategorized from 'Empty'.
  Future<int> retryEmptyTransactions({int days = 30}) async {
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;

    // Find transactions marked as 'Empty' - these had reason field but it was blank
    final emptyTxns = await (db.select(db.transactions)
          ..where((t) => t.parsedCategory.equals('Empty'))
          ..where((t) => t.smsTimestamp.isBiggerOrEqualValue(cutoffTime)))
        .get();

    if (emptyTxns.isEmpty) {
      return 0;
    }

    final categoryEngine = CategoryEngine(db);
    int updatedCount = 0;

    for (final txn in emptyTxns) {
      try {
        // Try to find a category from counterparty, bank, or branch information
        final betterReason = BankProcessingSupport.normalizeBusinessReason(
          txn.counterpartyName ?? txn.bankName ?? txn.branchName,
        );

        if (betterReason.isEmpty) {
          continue; // No alternative reason found
        }

        // Categorize using the discovered reason
        final newCategory = await categoryEngine.findOrCreateCategory(betterReason);

        // Only update if we found a meaningful category (not "Uncategorized" or "Empty")
        if (newCategory != 'Uncategorized' && newCategory != 'Empty') {
          await db.update(db.transactions).replace(
                txn.copyWith(
                  reasonRawText: betterReason,
                  parsedCategory: newCategory,
                ),
              );
          updatedCount++;
        }
      } catch (e) {
        dev.log('Error recategorizing empty transaction ${txn.id}: $e');
      }
    }

    return updatedCount;
  }
}
