import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsAvailabilitySummary {
  final int awash;
  final int cbe;
  final int telebirr;
  final int boa;

  const SmsAvailabilitySummary({
    required this.awash,
    required this.cbe,
    this.telebirr = 0,
    this.boa = 0,
  });

  int get total => awash + cbe + telebirr + boa;
}

class SmsService {
  final SmsQuery _query = SmsQuery();

  Future<bool> _hasSmsPermission() async {
    var permission = await Permission.sms.status;
    if (permission.isDenied) {
      permission = await Permission.sms.request();
    }
    return permission.isGranted;
  }

  bool _isSupportedBankSender(String sender) {
    final lower = sender.toLowerCase();
    return lower.contains('awash') ||
        lower.contains('cbe') ||
        _isBoaSender(lower) ||
        _isTelebirrSender(lower);
  }

  bool _isAwashSender(String sender) {
    return sender.toLowerCase().contains('awash');
  }

  bool _isCbeSender(String sender) {
    return sender.toLowerCase().contains('cbe');
  }

  bool _isBoaSender(String sender) {
    final lower = sender.toLowerCase();
    return lower.contains('boa') || lower.contains('abyssinia');
  }

  bool _isTelebirrSender(String sender) {
    final lower = sender.toLowerCase();
    return lower == '127' ||
        lower.contains('telebirr') ||
        lower.contains('ethio telecom');
  }

  /// Cap on how many inbox messages the availability scan reads. Reading the
  /// full inbox (which can be tens of thousands of messages on older phones)
  /// into memory at once causes native OOM crashes. A cap keeps the scan
  /// bounded; totals are estimates and the actual import is capped separately.
  static const int _availabilityScanCap = 3000;

  Future<List<SmsMessage>> getBankMessages({
    required String senderName, // e.g., "CBE" or "AwashBank"
    required int limit,
  }) async {
    if (!Platform.isAndroid || !await _hasSmsPermission()) {
      debugPrint("SMS Permission Denied");
      return [];
    }

    // `count` bounds how many rows the native side keeps in memory; the
    // plugin applies the address filter in Java, so the returned list is the
    // first `limit` matching messages (same ordering as before, but bounded).
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      address: senderName,
      count: limit,
    );

    return messages.take(limit).toList();
  }

  Future<SmsAvailabilitySummary> getAvailableBankMessageCounts() async {
    if (!Platform.isAndroid || !await _hasSmsPermission()) {
      return const SmsAvailabilitySummary(awash: 0, cbe: 0);
    }

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: _availabilityScanCap,
    );
    var awash = 0;
    var cbe = 0;
    var telebirr = 0;
    var boa = 0;

    for (final message in messages) {
      final sender = message.address ?? '';
      if (!_isSupportedBankSender(sender)) continue;

      if (_isAwashSender(sender)) {
        awash++;
      } else if (_isCbeSender(sender)) {
        cbe++;
      } else if (_isTelebirrSender(sender)) {
        telebirr++;
      } else if (_isBoaSender(sender)) {
        boa++;
      }
    }

    return SmsAvailabilitySummary(
      awash: awash,
      cbe: cbe,
      telebirr: telebirr,
      boa: boa,
    );
  }
}
