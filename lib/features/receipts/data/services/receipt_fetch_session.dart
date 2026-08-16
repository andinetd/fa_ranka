import 'package:faranka/database/database.dart';
import 'package:faranka/features/receipts/data/parsers/awash_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/boa_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/cbe_sms_parser.dart';
import 'package:faranka/features/receipts/data/parsers/telebirr_sms_parser.dart';
import 'package:faranka/features/receipts/data/services/receipt_link_checker.dart';

enum ReceiptFetchDecision {
  fetch,
  smsOnlyNoLink,

  /// A transient failure (below the consecutive-failure threshold). Import
  /// from SMS only and keep trying on later messages — do not defer.
  smsOnlySuspect,

  /// The domain is confirmed down (consecutive failures >= threshold).
  /// Import from SMS and schedule a deferred retry.
  smsOnlyDomainBlocked,
  smsOnlyExpiredLink,
  smsOnlyOther,
}

class ReceiptImportStats {
  int withFullReceipt = 0;
  int smsOnlyNoLink = 0;
  int smsOnlySuspect = 0;
  int smsOnlyDomainBlocked = 0;
  int smsOnlyExpiredLink = 0;
  int smsOnlyOther = 0;

  int get total =>
      withFullReceipt +
      smsOnlyNoLink +
      smsOnlySuspect +
      smsOnlyDomainBlocked +
      smsOnlyExpiredLink +
      smsOnlyOther;
}

/// Per-run circuit breaker for bank receipt servers.
///
/// Tolerates transient blips: a single failure only makes a domain "suspect"
/// (import from SMS, keep trying). Only after [failureThreshold] consecutive
/// observed failures is the domain treated as "down", at which point remaining
/// SMS short-circuit to SMS-only and are scheduled for a deferred retry. A
/// "down" domain is re-probed after [recoveryCooldown] (half-open) so the
/// import resumes full receipts as soon as the server comes back. Each domain
/// is tracked independently, so one bank's outage never affects another.
class ReceiptFetchSession {
  ReceiptFetchSession({
    ReceiptLinkChecker? checker,
    this.failureThreshold = 10,
    this.probeCooldown = const Duration(seconds: 10),
    this.recoveryCooldown = const Duration(seconds: 30),
  }) : _checker = checker ?? ReceiptLinkChecker();

  final ReceiptLinkChecker _checker;

  /// Consecutive observed failures (probe or real fetch) before a domain is
  /// treated as confirmed down.
  final int failureThreshold;

  /// Minimum gap between probes for a non-blocked domain.
  final Duration probeCooldown;

  /// Minimum gap before a confirmed-down domain is re-probed to detect recovery.
  final Duration recoveryCooldown;

  final Map<String, ReceiptLinkStatus> _domainStatus = {};
  final Set<String> _sampledDomains = {};
  final Map<String, int> _consecutiveFailures = {};
  final Map<String, DateTime> _blockedAt = {};
  final Map<String, DateTime> _lastProbeAt = {};
  final Map<String, ReceiptLinkStatus> _lastProbeStatus = {};
  final Map<String, String?> _lastProbeUrl = {};

  final ReceiptImportStats stats = ReceiptImportStats();

  Map<String, ReceiptLinkStatus> get domainStatuses =>
      Map.unmodifiable(_domainStatus);

  /// Domains that are confirmed down (threshold reached) so callers can
  /// surface a "server is down" message.
  List<String> get blockedDomains => _domainStatus.entries
      .where((e) => _isDomainBlockingStatus(e.value))
      .map((e) => e.key)
      .toList();

  bool isDomainBlocked(String domain) => _blockedAt.containsKey(domain);

  /// Records a real fetch failure (socket/timeout/5xx even though a probe had
  /// passed). Counts toward the threshold and caches the failure so subsequent
  /// messages short-circuit without another slow fetch.
  void markServerUnavailable(String domain) {
    _sampledDomains.add(domain);
    _lastProbeAt[domain] = DateTime.now();
    _lastProbeStatus[domain] = ReceiptLinkStatus.serverDown;
    _lastProbeUrl[domain] = null;
    _recordFailure(domain, ReceiptLinkStatus.serverDown);
  }

  static String? extractReceiptUrl(SmsInboxData sms) {
    final addressLower = sms.address.toLowerCase();
    if (addressLower.contains('cbe')) {
      return CbeSmsParser.extractReceiptUrl(sms.body);
    }
    if (addressLower == '127' ||
        addressLower.contains('telebirr') ||
        addressLower.contains('ethio telecom')) {
      return TelebirrSmsParser.extractReceiptUrl(sms.body);
    }
    if (addressLower.contains('boa') || addressLower.contains('abyssinia')) {
      return BoaSmsParser.extractReceiptUrl(sms.body);
    }
    return AwashSmsParser.extractReceiptUrl(sms.body);
  }

  static Map<String, List<SmsInboxData>> groupByDomain(
    List<SmsInboxData> messages,
  ) {
    final groups = <String, List<SmsInboxData>>{};
    for (final sms in messages) {
      final url = extractReceiptUrl(sms);
      if (url == null) continue;
      final domain = Uri.parse(url).host;
      groups.putIfAbsent(domain, () => []).add(sms);
    }
    return groups;
  }

  /// Probes every distinct domain once, in parallel, so a slow or hanging
  /// server for one bank does not delay the other banks' imports. A single
  /// probe failure only counts as one strike (never an immediate block).
  Future<void> prefetchDomains(List<SmsInboxData> messages) async {
    final futures = groupByDomain(messages).entries
        .where((e) => !_sampledDomains.contains(e.key))
        .map((entry) async {
          final sampleUrl = extractReceiptUrl(entry.value.first);
          if (sampleUrl == null) return;

          final status = await _checker.checkLink(sampleUrl);
          final domain = entry.key;
          _sampledDomains.add(domain);
          _lastProbeAt[domain] = DateTime.now();
          _lastProbeStatus[domain] = status;
          _lastProbeUrl[domain] = sampleUrl;

          if (_isDomainBlockingStatus(status)) {
            _recordFailure(domain, status);
          } else {
            _consecutiveFailures[domain] = 0;
            _domainStatus[domain] = ReceiptLinkStatus.available;
          }
        });
    await Future.wait(futures);
  }

  String formatPreflightStatus() {
    if (_domainStatus.isEmpty) {
      return 'Checking receipt servers...';
    }

    final lines = _domainStatus.entries.map((entry) {
      final label = ReceiptLinkChecker.labelForDomain(entry.key);
      final message = entry.value == ReceiptLinkStatus.available
          ? '✓ Available'
          : '✗ ${ReceiptLinkChecker.statusMessage(entry.value)} (will parse from SMS)';
      return 'Checking $label server... $message';
    });

    return lines.join('\n');
  }

  String formatImportSummary() {
    final stats = this.stats;
    if (stats.total == 0) return 'Import complete';

    return [
      'Importing ${stats.total} transactions',
      '  ├─ ${stats.withFullReceipt} with full receipt detail',
      if (stats.smsOnlyDomainBlocked > 0)
        '  ├─ ${stats.smsOnlyDomainBlocked} from SMS only (server unavailable)',
      if (stats.smsOnlySuspect > 0)
        '  ├─ ${stats.smsOnlySuspect} from SMS only (server temporarily unreachable)',
      if (stats.smsOnlyExpiredLink > 0)
        '  ├─ ${stats.smsOnlyExpiredLink} expired links (SMS only)',
      if (stats.smsOnlyNoLink > 0)
        '  ├─ ${stats.smsOnlyNoLink} from SMS only (no receipt link)',
      if (stats.smsOnlyOther > 0)
        '  └─ ${stats.smsOnlyOther} from SMS only (other)',
      if (stats.smsOnlyOther == 0 &&
          stats.smsOnlyNoLink == 0 &&
          stats.smsOnlySuspect == 0 &&
          stats.smsOnlyDomainBlocked == 0 &&
          stats.smsOnlyExpiredLink == 0)
        '  └─ done',
    ].join('\n');
  }

  void recordDecision(ReceiptFetchDecision decision) {
    switch (decision) {
      case ReceiptFetchDecision.fetch:
        stats.withFullReceipt++;
      case ReceiptFetchDecision.smsOnlyNoLink:
        stats.smsOnlyNoLink++;
      case ReceiptFetchDecision.smsOnlySuspect:
        stats.smsOnlySuspect++;
      case ReceiptFetchDecision.smsOnlyDomainBlocked:
        stats.smsOnlyDomainBlocked++;
      case ReceiptFetchDecision.smsOnlyExpiredLink:
        stats.smsOnlyExpiredLink++;
      case ReceiptFetchDecision.smsOnlyOther:
        stats.smsOnlyOther++;
    }
  }

  Future<ReceiptFetchDecision> decide(String? url) async {
    if (url == null || url.isEmpty) {
      return ReceiptFetchDecision.smsOnlyNoLink;
    }

    final domain = Uri.parse(url).host;
    final now = DateTime.now();

    // Confirmed down: short-circuit during the recovery cooldown, then probe
    // half-open to detect recovery.
    if (_blockedAt.containsKey(domain)) {
      if (now.difference(_blockedAt[domain]!) < recoveryCooldown) {
        return ReceiptFetchDecision.smsOnlyDomainBlocked;
      }
      final status = await _checker.checkLink(url);
      _lastProbeAt[domain] = now;
      _lastProbeStatus[domain] = status;
      _lastProbeUrl[domain] = url;
      if (!_isDomainBlockingStatus(status)) {
        _unblock(domain);
        return _classify(status);
      }
      _blockedAt[domain] = now;
      return ReceiptFetchDecision.smsOnlyDomainBlocked;
    }

    // Reuse the last observation within the probe cooldown so a flaky server
    // is not hammered with a probe (or a slow fetch) for every single message.
    // Only reused when it belongs to the *same* link: one bad or slow receipt
    // URL must not poison the rest of the domain.
    final lastProbeAt = _lastProbeAt[domain];
    if (lastProbeAt != null &&
        now.difference(lastProbeAt) < probeCooldown &&
        _lastProbeUrl[domain] == url) {
      final cached = _lastProbeStatus[domain];
      if (cached != null) {
        if (_isDomainBlockingStatus(cached)) {
          return _recordFailure(domain, cached);
        }
        return _classify(cached);
      }
    }

    final status = await _checker.checkLink(url);
    _sampledDomains.add(domain);
    _lastProbeAt[domain] = now;
    _lastProbeStatus[domain] = status;
    _lastProbeUrl[domain] = url;

    if (_isDomainBlockingStatus(status)) {
      return _recordFailure(domain, status);
    }

    _consecutiveFailures[domain] = 0;
    _domainStatus[domain] = ReceiptLinkStatus.available;
    return _classify(status);
  }

  ReceiptFetchDecision _classify(ReceiptLinkStatus status) {
    switch (status) {
      case ReceiptLinkStatus.available:
        return ReceiptFetchDecision.fetch;
      case ReceiptLinkStatus.expired:
        return ReceiptFetchDecision.smsOnlyExpiredLink;
      case ReceiptLinkStatus.serverDown:
      case ReceiptLinkStatus.timeout:
      case ReceiptLinkStatus.noInternet:
        return ReceiptFetchDecision.smsOnlyDomainBlocked;
      case ReceiptLinkStatus.unknown:
        return ReceiptFetchDecision.smsOnlyOther;
    }
  }

  ReceiptFetchDecision _recordFailure(String domain, ReceiptLinkStatus status) {
    _consecutiveFailures[domain] = (_consecutiveFailures[domain] ?? 0) + 1;
    if (_consecutiveFailures[domain]! >= failureThreshold) {
      _block(domain, status);
      return ReceiptFetchDecision.smsOnlyDomainBlocked;
    }
    return ReceiptFetchDecision.smsOnlySuspect;
  }

  void _block(String domain, ReceiptLinkStatus status) {
    _blockedAt[domain] = DateTime.now();
    _domainStatus[domain] = status;
  }

  void _unblock(String domain) {
    _blockedAt.remove(domain);
    _domainStatus[domain] = ReceiptLinkStatus.available;
    _consecutiveFailures[domain] = 0;
  }

  bool _isDomainBlockingStatus(ReceiptLinkStatus status) {
    return status == ReceiptLinkStatus.serverDown ||
        status == ReceiptLinkStatus.timeout ||
        status == ReceiptLinkStatus.noInternet;
  }
}
