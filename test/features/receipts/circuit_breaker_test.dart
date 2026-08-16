import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/domain/usecases/transaction_processor.dart';
import 'package:faranka/features/transactions/domain/services/category_engine.dart';
import 'package:faranka/features/receipts/data/services/receipt_fetch_session.dart';
import 'package:faranka/features/receipts/data/services/receipt_link_checker.dart';

class _FakeChecker extends ReceiptLinkChecker {
  int calls = 0;
  final ReceiptLinkStatus status;

  _FakeChecker(this.status);

  @override
  Future<ReceiptLinkStatus> checkLink(String url) async {
    calls++;
    return status;
  }
}

class _MutableChecker extends ReceiptLinkChecker {
  ReceiptLinkStatus status;
  int calls = 0;

  _MutableChecker(this.status);

  @override
  Future<ReceiptLinkStatus> checkLink(String url) async {
    calls++;
    return status;
  }
}

class _SequenceChecker extends ReceiptLinkChecker {
  final List<ReceiptLinkStatus> statuses;
  int calls = 0;

  _SequenceChecker(this.statuses);

  @override
  Future<ReceiptLinkStatus> checkLink(String url) async {
    final status = calls < statuses.length ? statuses[calls] : statuses.last;
    calls++;
    return status;
  }
}

const _telebirrSmsUrl = 'https://transactioninfo.ethiotelecom.et/receipt/DETSTPRO99';

const _telebirrSmsBody =
    'Dear Customer, you have transferred ETB 99.00 to MILLIONE ZEKE '
    '(0912345678) on 01/08/2026 10:15:00. Your transaction number is '
    'TB202608000001. Your balance is ETB 5000.00. Service fee is ETB 0.87. '
    'Receipt: $_telebirrSmsUrl';

const _telebirrPackageSmsUrl =
    'https://transactioninfo.ethiotelecom.et/receipt/DETPKGPRO02';

const _telebirrPackageSmsBody =
    'Dear KIDIST: You have paid ETB 25.00 for package Weekly Birr 25 for '
    '84Min+42 Min Night bonus purchase made for 251942014271 on 10/08/2026 '
    '08:25:46. Your transaction number is DHA5NXMVQF. Your current balance is '
    'ETB 218.78. To download your payment information please click this link: '
    '$_telebirrPackageSmsUrl';

const _cbeSmsBody =
    'Dear Andinet Dereje Mengist You have received ETB 3,000.00 from account '
    '1**5276 (Amanuel Aleme Mengist) to your account 1**5039. Your current '
    'balance is ETB24,821.11. Thanks for Banking with CBE. '
    'https://mbreciept.cbe.com.et/v2-hfHCxzyBiOaoJKf5qQDj';

const _boaSmsUrl =
    'https://cs.bankofabyssinia.com/slip/?trx=FT26149FW94903776';

const _boaSmsBody =
    'Dear ANDINET, your account 1**5039 has been credited with ETB 2,500.00 '
    'by AMANUEL ALEME. Available Balance : ETB 12,000.00. Receipt: $_boaSmsUrl';

Future<SmsInboxData> _insertSms(
  AppDatabase db, {
  required String id,
  required String address,
  required String body,
}) async {
  await db.into(db.smsInbox).insert(
        SmsInboxCompanion.insert(
          id: id,
          address: address,
          body: body,
          date: DateTime(2026, 8, 1, 10, 0),
        ),
      );
  return (db.select(db.smsInbox)..where((t) => t.id.equals(id))).getSingle();
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ReceiptFetchSession', () {
    test('decide short-circuits after markServerUnavailable (no re-probe)', () async {
      final checker = _FakeChecker(ReceiptLinkStatus.available);
      final session = ReceiptFetchSession(
        checker: checker,
        failureThreshold: 1,
      );

      session.markServerUnavailable('cbe.com.et');

      final decision = await session.decide('https://cbe.com.et/rt_123');

      expect(decision, ReceiptFetchDecision.smsOnlyDomainBlocked);
      expect(checker.calls, 0);
      expect(session.blockedDomains, contains('cbe.com.et'));
    });

    test('prefetchDomains blocks a down domain and decide respects it', () async {
      final checker = _FakeChecker(ReceiptLinkStatus.serverDown);
      final session = ReceiptFetchSession(
        checker: checker,
        failureThreshold: 1,
      );

      final sms = await _insertSms(
        db,
        id: 'rt_prefetch',
        address: '127',
        body: _telebirrSmsBody,
      );

      await session.prefetchDomains([sms]);

      expect(session.blockedDomains, contains('transactioninfo.ethiotelecom.et'));
      expect(checker.calls, 1);

      final second = await session.decide(_telebirrSmsUrl);
      expect(second, ReceiptFetchDecision.smsOnlyDomainBlocked);
      // No extra probe after the domain was already marked blocked.
      expect(checker.calls, 1);
    });

    test('decide allows fetch when server is available', () async {
      final checker = _FakeChecker(ReceiptLinkStatus.available);
      final session = ReceiptFetchSession(checker: checker);

      final decision = await session.decide(_telebirrSmsUrl);

      expect(decision, ReceiptFetchDecision.fetch);
      expect(checker.calls, 1);
      expect(session.blockedDomains, isEmpty);
    });

    test('tolerates transient failures and recovers without ever blocking', () async {
      final checker = _SequenceChecker([
        ReceiptLinkStatus.serverDown,
        ReceiptLinkStatus.serverDown,
        ReceiptLinkStatus.available,
      ]);
      final session = ReceiptFetchSession(
        checker: checker,
        failureThreshold: 10,
        probeCooldown: Duration.zero,
      );

      final first = await session.decide(_telebirrSmsUrl);
      expect(first, ReceiptFetchDecision.smsOnlySuspect);
      expect(session.blockedDomains, isEmpty);

      final second = await session.decide(_telebirrSmsUrl);
      expect(second, ReceiptFetchDecision.smsOnlySuspect);
      expect(session.blockedDomains, isEmpty);

      // Server recovers: the failure counter resets and full fetch resumes.
      final third = await session.decide(_telebirrSmsUrl);
      expect(third, ReceiptFetchDecision.fetch);
      expect(session.blockedDomains, isEmpty);
    });

    test('blocks after the threshold then short-circuits without extra probes', () async {
      final checker = _MutableChecker(ReceiptLinkStatus.serverDown);
      final session = ReceiptFetchSession(
        checker: checker,
        failureThreshold: 3,
        probeCooldown: Duration.zero,
      );

      final d1 = await session.decide(_telebirrSmsUrl);
      expect(d1, ReceiptFetchDecision.smsOnlySuspect);
      final d2 = await session.decide(_telebirrSmsUrl);
      expect(d2, ReceiptFetchDecision.smsOnlySuspect);
      final d3 = await session.decide(_telebirrSmsUrl);
      expect(d3, ReceiptFetchDecision.smsOnlyDomainBlocked);
      expect(session.blockedDomains, contains('transactioninfo.ethiotelecom.et'));

      // Confirmed down: remaining messages short-circuit during the cooldown.
      final probesBefore = checker.calls;
      final d4 = await session.decide(_telebirrSmsUrl);
      expect(d4, ReceiptFetchDecision.smsOnlyDomainBlocked);
      expect(checker.calls, probesBefore);
    });

    test('half-open re-probe recovers a blocked domain', () async {
      final checker = _MutableChecker(ReceiptLinkStatus.serverDown);
      final session = ReceiptFetchSession(
        checker: checker,
        failureThreshold: 1,
        probeCooldown: Duration.zero,
        recoveryCooldown: const Duration(milliseconds: 5),
      );

      final d1 = await session.decide(_telebirrSmsUrl);
      expect(d1, ReceiptFetchDecision.smsOnlyDomainBlocked);
      expect(session.blockedDomains, contains('transactioninfo.ethiotelecom.et'));

      // Server comes back before the half-open window.
      checker.status = ReceiptLinkStatus.available;
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final d2 = await session.decide(_telebirrSmsUrl);
      expect(d2, ReceiptFetchDecision.fetch);
      expect(session.blockedDomains, isEmpty);
    });

    test('a bad link for one URL does not poison a different URL on the same host',
        () async {
      final checker = _MutableChecker(ReceiptLinkStatus.available);
      final session = ReceiptFetchSession(
        checker: checker,
        failureThreshold: 10,
        probeCooldown: const Duration(seconds: 10),
      );

      const urlDead = 'https://cbe.com.et/rt_dead';
      const urlAlive = 'https://cbe.com.et/rt_alive';

      checker.status = ReceiptLinkStatus.serverDown;
      final dDead = await session.decide(urlDead);
      expect(dDead, ReceiptFetchDecision.smsOnlySuspect);
      expect(session.blockedDomains, isEmpty);

      // A different link on the same host must be re-probed (and succeed)
      // rather than reusing urlDead's cached failure.
      checker.status = ReceiptLinkStatus.available;
      final dAlive = await session.decide(urlAlive);
      expect(dAlive, ReceiptFetchDecision.fetch);
      expect(session.blockedDomains, isEmpty);

      // Re-deciding the *same* URL as the last probe reuses the cached status
      // without an extra probe.
      final probesBefore = checker.calls;
      final dAliveAgain = await session.decide(urlAlive);
      expect(dAliveAgain, ReceiptFetchDecision.fetch);
      expect(checker.calls, probesBefore);
    });
  });

  group('TransactionProcessor server-down import', () {
    test('imports from SMS and schedules a retry when the server is down',
        () async {
      final checker = _FakeChecker(ReceiptLinkStatus.serverDown);
      final session = ReceiptFetchSession(
        checker: checker,
        failureThreshold: 1,
      );

      final sms = await _insertSms(
        db,
        id: 'rt_pro_down',
        address: '127',
        body: _telebirrSmsBody,
      );

      final processor = TransactionProcessor(db, session: session);
      try {
        await processor.processTelebirrSms(sms);
      } on OfflineDeepParseException {
        // Test machine without internet exercises the offline path instead.
        return;
      }

      expect(session.blockedDomains, contains('transactioninfo.ethiotelecom.et'));

      final txns = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(sms.id)))
          .get();
      expect(txns, hasLength(1));

      final txn = txns.first;
      // Imported from SMS even though the receipt server is unreachable.
      expect(txn.amount, closeTo(99.0, 0.01));
      expect(txn.counterpartyName, 'MILLIONE ZEKE');
      // Retry scheduled through the existing backoff machinery.
      expect(txn.receiptExtractionStatus, 'attempted_failed');
      expect(txn.receiptExtractionError, contains('server is down'));
      expect(txn.extractionRetryAttempts, 1);
      expect(txn.extractionNextRetryAt != null, isTrue);
    });

    test('BoA imports from SMS with bankName BoA', () async {
      final checker = _FakeChecker(ReceiptLinkStatus.serverDown);
      final session = ReceiptFetchSession(
        checker: checker,
        failureThreshold: 1,
      );

      final sms = await _insertSms(
        db,
        id: 'boa_pro_down',
        address: 'BoA',
        body: _boaSmsBody,
      );

      final processor = TransactionProcessor(db, session: session);
      try {
        await processor.processBoaSms(sms);
      } on OfflineDeepParseException {
        return;
      }

      final txns = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(sms.id)))
          .get();
      expect(txns, hasLength(1));

      final txn = txns.first;
      expect(txn.amount, closeTo(2500.0, 0.01));
      expect(txn.bankName, 'BoA');
      expect(txn.direction, TransactionDirection.credit);
      expect(txn.bankTransactionId, 'FT26149FW94903776');
      expect(txn.balanceAfter, closeTo(12000.0, 0.01));
    });

    test('processSms dispatches BoA messages to the BoA path', () async {
      final checker = _FakeChecker(ReceiptLinkStatus.serverDown);
      final session = ReceiptFetchSession(
        checker: checker,
        failureThreshold: 1,
      );

      final sms = await _insertSms(
        db,
        id: 'boa_dispatch',
        address: 'abyssinia',
        body: _boaSmsBody,
      );

      final processor = TransactionProcessor(db, session: session);
      try {
        await processor.processSms(sms);
      } on OfflineDeepParseException {
        return;
      }

      final txns = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(sms.id)))
          .get();
      expect(txns, hasLength(1));
      expect(txns.first.bankName, 'BoA');
      expect(txns.first.amount, closeTo(2500.0, 0.01));
    });

    test('transient failure imports from SMS without scheduling a retry',
        () async {
      final checker = _FakeChecker(ReceiptLinkStatus.serverDown);
      // Default threshold (10): a single failure is only "suspect".
      final session = ReceiptFetchSession(checker: checker);

      final sms = await _insertSms(
        db,
        id: 'rt_pro_transient',
        address: '127',
        body: _telebirrSmsBody,
      );

      final processor = TransactionProcessor(db, session: session);
      try {
        await processor.processTelebirrSms(sms);
      } on OfflineDeepParseException {
        return;
      }

      final txns = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(sms.id)))
          .get();
      expect(txns, hasLength(1));
      // Below the threshold: no confirmed block, no deferred retry.
      expect(session.blockedDomains, isEmpty);
      expect(txns.first.receiptExtractionStatus, isNot('attempted_failed'));
    });

    test('CBE suspect failure imports from SMS and still schedules a retry',
        () async {
      final checker = _FakeChecker(ReceiptLinkStatus.serverDown);
      // Default threshold (10): a single failure is only "suspect".
      final session = ReceiptFetchSession(checker: checker);

      final sms = await _insertSms(
        db,
        id: 'cbe_pro_suspect',
        address: 'CBE',
        body: _cbeSmsBody,
      );

      final processor = TransactionProcessor(db, session: session);
      try {
        await processor.processCbeSms(sms);
      } on OfflineDeepParseException {
        return;
      }

      final txns = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(sms.id)))
          .get();
      expect(txns, hasLength(1));
      // Below the threshold it is only "suspect", but the row is still marked
      // for a deferred retry so a slow-but-alive server can re-parse it later.
      expect(session.blockedDomains, isEmpty);
      expect(txns.first.receiptExtractionStatus, 'attempted_failed');
      expect(txns.first.extractionRetryAttempts, 1);
      expect(txns.first.extractionNextRetryAt != null, isTrue);
    });

    test('expired link imports from SMS without a server-down retry', () async {
      final checker = _FakeChecker(ReceiptLinkStatus.expired);
      final session = ReceiptFetchSession(checker: checker);

      final sms = await _insertSms(
        db,
        id: 'rt_pro_expired',
        address: '127',
        body: _telebirrSmsBody,
      );

      final processor = TransactionProcessor(db, session: session);
      try {
        await processor.processTelebirrSms(sms);
      } on OfflineDeepParseException {
        return;
      }

      final txns = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(sms.id)))
          .get();
      expect(txns, hasLength(1));
      // Expired links are not a server outage, so no auto-retry is scheduled.
      expect(txns.first.receiptExtractionStatus, isNot('attempted_failed'));
      expect(session.blockedDomains, isEmpty);
    });

    test(
        'package purchase is labeled Package Purchase when no receipt fetches',
        () async {
      final checker = _FakeChecker(ReceiptLinkStatus.expired);
      final session = ReceiptFetchSession(checker: checker);

      final sms = await _insertSms(
        db,
        id: 'rt_pro_package',
        address: '127',
        body: _telebirrPackageSmsBody,
      );

      final processor = TransactionProcessor(db, session: session);
      try {
        await processor.processTelebirrSms(sms);
      } on OfflineDeepParseException {
        // Offline machines skip the fetch path; fall through with no check.
        return;
      }

      final txns = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(sms.id)))
          .get();
      expect(txns, hasLength(1));
      // No usable receipt was merged, so the package purchase is classified.
      final stored = await (db.select(db.smsInbox)
            ..where((t) => t.id.equals(sms.id)))
          .getSingle();
      expect(stored.transactionType, 'Package Purchase');
      expect(session.blockedDomains, isEmpty);
    });

    test('Telebirr imports from SMS with bankName Telebirr', () async {
      final checker = _FakeChecker(ReceiptLinkStatus.expired);
      final session = ReceiptFetchSession(checker: checker);

      final sms = await _insertSms(
        db,
        id: 'telebirr_bankname',
        address: '127',
        body: _telebirrSmsBody,
      );

      final processor = TransactionProcessor(db, session: session);
      try {
        await processor.processTelebirrSms(sms);
      } on OfflineDeepParseException {
        return;
      }

      final txns = await (db.select(db.transactions)
            ..where((t) => t.smsId.equals(sms.id)))
          .get();
      expect(txns, hasLength(1));
      expect(txns.first.bankName, 'Telebirr');
    });
  });

  group('Categorization derives from reason', () {
    test('a single-character reason becomes its own category', () async {
      final engine = CategoryEngine(db);
      final category = await engine.findOrCreateCategory('d');
      expect(category, 'D');

      final rows = await (db.select(db.categories)).get();
      expect(rows.map((c) => c.name), contains('D'));
    });

    test('an empty reason maps to Uncategorized (no fallback needed)', () async {
      final engine = CategoryEngine(db);
      expect(await engine.findOrCreateCategory(''), 'Uncategorized');
    });
  });
}
