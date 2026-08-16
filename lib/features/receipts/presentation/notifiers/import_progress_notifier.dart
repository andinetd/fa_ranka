import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/services/network_status_service.dart';
import 'package:faranka/features/receipts/data/services/receipt_fetch_session.dart';
import 'package:faranka/features/receipts/data/services/receipt_link_checker.dart';
import 'package:faranka/app/core/services/sms.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_processor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionEvent {
  final String label;
  final String bank;
  final bool isComplete;
  final bool hasError;

  const TransactionEvent({
    required this.label,
    required this.bank,
    this.isComplete = false,
    this.hasError = false,
  });
}

class ImportState {
  final bool isRunning;
  final bool isComplete;
  final bool isPaused;
  final int awashTotal;
  final int awashDone;
  final int cbeTotal;
  final int cbeDone;
  final int telebirrTotal;
  final int telebirrDone;
  final int boaTotal;
  final int boaDone;
  final int failedCount;
  final String currentActivity;
  final String skippedStatus;
  final List<TransactionEvent> recentTransactions;

  const ImportState({
    this.isRunning = false,
    this.isComplete = false,
    this.isPaused = false,
    this.awashTotal = 0,
    this.awashDone = 0,
    this.cbeTotal = 0,
    this.cbeDone = 0,
    this.telebirrTotal = 0,
    this.telebirrDone = 0,
    this.boaTotal = 0,
    this.boaDone = 0,
    this.failedCount = 0,
    this.currentActivity = '',
    this.skippedStatus = '',
    this.recentTransactions = const [],
  });

  int get totalDone => awashDone + cbeDone + telebirrDone + boaDone;
  int get totalAll => awashTotal + cbeTotal + telebirrTotal + boaTotal;
  double get overallProgress => totalAll > 0 ? totalDone / totalAll : 0.0;

}

class ImportProgressNotifier extends ValueNotifier<ImportState> {
  static final ImportProgressNotifier instance = ImportProgressNotifier._();
  ImportProgressNotifier._() : super(const ImportState());

  final SmsService _smsService = SmsService();
  List<SmsInboxData>? _pendingRows;
  int _nextIndex = 0;
  bool _isCancelled = false;
  final Set<String> _announcedBlockedDomains = {};
  final Set<String> _downServersThisRun = {};

  void cancel() {
    _isCancelled = true;
    value = ImportState(
      isRunning: false,
      currentActivity: 'Cancelled',
      recentTransactions: value.recentTransactions,
    );
  }

  void dismissComplete() {
    value = const ImportState();
  }

  Future<void> startImport(Map<String, int> counts) async {
    if (value.isRunning) return;

    _isCancelled = false;

    if (value.isPaused && _pendingRows != null && _nextIndex < _pendingRows!.length) {
      value = ImportState(
        isRunning: true,
        isPaused: false,
        awashTotal: value.awashTotal,
        cbeTotal: value.cbeTotal,
        telebirrTotal: value.telebirrTotal,
        boaTotal: value.boaTotal,
        awashDone: value.awashDone,
        cbeDone: value.cbeDone,
        telebirrDone: value.telebirrDone,
        boaDone: value.boaDone,
        failedCount: value.failedCount,
        currentActivity: 'Connection restored. Resuming...',
        recentTransactions: value.recentTransactions,
      );
      await _processLoop();
      await _finishIfNotPaused();
      return;
    }

    final awashLimit = counts['awash'] ?? 0;
    final cbeLimit = counts['cbe'] ?? 0;
    final telebirrLimit = counts['telebirr'] ?? 0;
    final boaLimit = counts['boa'] ?? 0;

    value = ImportState(
      isRunning: true,
      awashTotal: awashLimit,
      cbeTotal: cbeLimit,
      telebirrTotal: telebirrLimit,
      boaTotal: boaLimit,
      currentActivity: 'Accessing phone SMS...',
    );

    try {
      await _smsService.getAvailableBankMessageCounts();

      final List<SmsMessage> awashPhone = await _smsService.getBankMessages(
        senderName: 'Awash Bank',
        limit: awashLimit,
      );
      final List<SmsMessage> cbePhone = await _smsService.getBankMessages(
        senderName: 'CBE',
        limit: cbeLimit,
      );
      final List<SmsMessage> telebirrPhone = telebirrLimit > 0
          ? await _smsService.getBankMessages(
              senderName: '127',
              limit: telebirrLimit,
            )
          : <SmsMessage>[];
      final List<SmsMessage> boaPhone = boaLimit > 0
          ? await _smsService.getBankMessages(
              senderName: 'BoA',
              limit: boaLimit,
            )
          : <SmsMessage>[];

      final allPhone = [
        ...awashPhone,
        ...cbePhone,
        ...telebirrPhone,
        ...boaPhone,
      ];
      final phoneIds = allPhone.map((m) => m.id.toString()).toList();
      await database.syncRawMessages(allPhone);

      final toProcess = await (database.select(database.smsInbox)
            ..where((t) => t.id.isIn(phoneIds))
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ]))
          .get();

      _pendingRows = toProcess;
      _nextIndex = 0;

      final hasInternet = await NetworkStatusService.hasInternet();
      if (!hasInternet && toProcess.isNotEmpty) {
        value = ImportState(
          isRunning: false,
          isPaused: true,
          awashTotal: value.awashTotal,
          cbeTotal: value.cbeTotal,
          telebirrTotal: value.telebirrTotal,
          boaTotal: value.boaTotal,
          currentActivity: 'No internet. Paused — will resume when online.',
        );
        return;
      }

      value = ImportState(
        isRunning: true,
        awashTotal: value.awashTotal,
        cbeTotal: value.cbeTotal,
        telebirrTotal: value.telebirrTotal,
        boaTotal: value.boaTotal,
        currentActivity: 'Importing messages...',
        recentTransactions: value.recentTransactions,
      );

      await _processLoop();
      await _finishIfNotPaused();
    } catch (e) {
      debugPrint('Import error: $e');
      String msg;
      final s = e.toString();
      if (s.contains('permission') || s.contains('denied')) {
        msg = 'Permission denied. Check SMS and notification permissions.';
      } else if (s.contains('timeout') || s.contains('timed out')) {
        msg = 'Request timed out. Check your connection and try again.';
      } else if (s.contains('No internet')) {
        msg = 'No internet connection. Import will resume when online.';
      } else {
        msg = 'Something went wrong. Tap refresh to try again.';
      }
      value = ImportState(
        isRunning: false,
        awashTotal: value.awashTotal,
        cbeTotal: value.cbeTotal,
        telebirrTotal: value.telebirrTotal,
        boaTotal: value.boaTotal,
        awashDone: value.awashDone,
        cbeDone: value.cbeDone,
        telebirrDone: value.telebirrDone,
        boaDone: value.boaDone,
        failedCount: value.failedCount,
        currentActivity: msg,
        recentTransactions: value.recentTransactions,
      );
    }
  }

  Future<void> _processLoop() async {
    final session = ReceiptFetchSession();
    final processor = TransactionProcessor(database, session: session);

    _announcedBlockedDomains.clear();
    _downServersThisRun.clear();

    await session.prefetchDomains(_pendingRows ?? []);

    while (_nextIndex < (_pendingRows?.length ?? 0)) {
      if (_isCancelled) break;

      final sms = _pendingRows![_nextIndex];
      final addressLower = sms.address.toLowerCase();
      final isCbe = addressLower.contains('cbe');
      final isTelebirr = addressLower == '127' ||
          addressLower.contains('telebirr') ||
          addressLower.contains('ethio telecom');
      final isBoa = addressLower.contains('boa') ||
          addressLower.contains('abyssinia');
      final bank = isCbe
          ? 'CBE'
          : isTelebirr
              ? 'Telebirr'
              : isBoa
                  ? 'BoA'
                  : 'Awash';

      _addPendingEvent('Processing...', bank);

      final currentDone = isCbe
          ? value.cbeDone
          : isTelebirr
              ? value.telebirrDone
              : isBoa
                  ? value.boaDone
                  : value.awashDone;
      final currentTotal = isCbe
          ? value.cbeTotal
          : isTelebirr
              ? value.telebirrTotal
              : isBoa
                  ? value.boaTotal
                  : value.awashTotal;

      value = _copyWith(
        currentActivity: bank == 'CBE'
            ? 'CBE: ${currentDone + 1}/$currentTotal'
            : bank == 'Telebirr'
                ? 'Telebirr: ${currentDone + 1}/$currentTotal'
                : bank == 'BoA'
                    ? 'BoA: ${currentDone + 1}/$currentTotal'
                    : 'Awash: ${currentDone + 1}/$currentTotal',
      );

      try {
        await processor.processSms(sms);
        if (isCbe) {
          value = _copyWith(cbeDone: value.cbeDone + 1);
        } else if (isTelebirr) {
          value = _copyWith(telebirrDone: value.telebirrDone + 1);
        } else if (isBoa) {
          value = _copyWith(boaDone: value.boaDone + 1);
        } else {
          value = _copyWith(awashDone: value.awashDone + 1);
        }

        String actualLabel = 'Transaction';
        try {
          final updated = await (database.select(database.smsInbox)
                ..where((t) => t.id.equals(sms.id)))
              .getSingleOrNull();
          if (updated != null) {
            actualLabel = updated.reason ??
                updated.transactionType ??
                updated.parseSource ??
                'Transaction';
          }
        } catch (_) {}

        _resolveCurrentEvent(actualLabel: actualLabel);
      } on OfflineDeepParseException {
        value = _copyWith(
          isRunning: false,
          isPaused: true,
          currentActivity: 'No internet. Paused — will resume when online.',
        );
        _resolveCurrentEvent(hasError: true);
        break;
      } catch (e) {
        value = _copyWith(failedCount: value.failedCount + 1);
        _resolveCurrentEvent(hasError: true);
        debugPrint('Import error for message ${sms.id}: $e');
      }

      _announceDownServers(session);

      _nextIndex++;
    }
  }

  /// Surfaces a one-time notice the first time a bank becomes confirmed down
  /// during this run (consecutive failures >= threshold), without re-announcing
  /// on every subsequent message.
  void _announceDownServers(ReceiptFetchSession session) {
    final newlyBlocked = session.blockedDomains
        .where(_announcedBlockedDomains.add)
        .toList();
    if (newlyBlocked.isEmpty) return;

    _downServersThisRun.addAll(newlyBlocked);
    final labels =
        newlyBlocked.map(ReceiptLinkChecker.labelForDomain).join(', ');
    value = _copyWith(
      currentActivity:
          '$labels server is down right now — we\'ll import it automatically '
          'when it\'s available.',
    );
  }

  Future<void> _finishIfNotPaused() async {
    if (_isCancelled || value.isPaused) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);

    value = ImportState(
      isRunning: false,
      isComplete: true,
      awashTotal: value.awashTotal,
      cbeTotal: value.cbeTotal,
      telebirrTotal: value.telebirrTotal,
      boaTotal: value.boaTotal,
      awashDone: value.awashDone,
      cbeDone: value.cbeDone,
      telebirrDone: value.telebirrDone,
      boaDone: value.boaDone,
      failedCount: value.failedCount,
      currentActivity: 'Import complete',
      skippedStatus: _buildSkippedStatus(),
      recentTransactions: value.recentTransactions,
    );
  }

  String _buildSkippedStatus() {
    final parts = <String>[
      if (value.failedCount > 0) '${value.failedCount} message(s) had errors',
      if (_downServersThisRun.isNotEmpty)
        '${_downServersThisRun.map(ReceiptLinkChecker.labelForDomain).join(', ')} '
            'server was down — will import automatically when available.',
    ];
    return parts.join('. ');
  }

  ImportState _copyWith({
    bool? isRunning,
    bool? isComplete,
    bool? isPaused,
    int? awashDone,
    int? cbeDone,
    int? telebirrDone,
    int? boaDone,
    int? failedCount,
    String? currentActivity,
    String? skippedStatus,
    List<TransactionEvent>? recentTransactions,
  }) {
    return ImportState(
      isRunning: isRunning ?? value.isRunning,
      isComplete: isComplete ?? value.isComplete,
      isPaused: isPaused ?? value.isPaused,
      awashTotal: value.awashTotal,
      cbeTotal: value.cbeTotal,
      telebirrTotal: value.telebirrTotal,
      boaTotal: value.boaTotal,
      awashDone: awashDone ?? value.awashDone,
      cbeDone: cbeDone ?? value.cbeDone,
      telebirrDone: telebirrDone ?? value.telebirrDone,
      boaDone: boaDone ?? value.boaDone,
      failedCount: failedCount ?? value.failedCount,
      currentActivity: currentActivity ?? value.currentActivity,
      skippedStatus: skippedStatus ?? value.skippedStatus,
      recentTransactions: recentTransactions ?? value.recentTransactions,
    );
  }

  void _addPendingEvent(String label, String bank) {
    final events = List<TransactionEvent>.from(value.recentTransactions);
    events.insert(0, TransactionEvent(label: label, bank: bank));
    value = _copyWith(recentTransactions: events);
  }

  void _resolveCurrentEvent({bool hasError = false, String? actualLabel}) {
    final events = List<TransactionEvent>.from(value.recentTransactions);
    if (events.isEmpty) return;
    events[0] = TransactionEvent(
      label: actualLabel ?? events[0].label,
      bank: events[0].bank,
      isComplete: true,
      hasError: hasError,
    );
    value = _copyWith(recentTransactions: events);
  }
}
