import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/database/database_sms_logic.dart';
import 'package:faranka/app/core/services/sms.dart';

class ImportStatus {
  final int awashDone;
  final int awashTotal;
  final int cbeDone;
  final int cbeTotal;
  final int telebirrDone;
  final int telebirrTotal;
  final int boaDone;
  final int boaTotal;

  const ImportStatus({
    required this.awashDone,
    required this.awashTotal,
    required this.cbeDone,
    required this.cbeTotal,
    this.telebirrDone = 0,
    this.telebirrTotal = 0,
    this.boaDone = 0,
    this.boaTotal = 0,
  });

  bool get isLoading =>
      awashTotal == 0 && cbeTotal == 0 && telebirrTotal == 0 && boaTotal == 0;
}

final importStatusProvider = FutureProvider<ImportStatus>((ref) async {
  final db = ref.read(databaseProvider);
  final smsService = SmsService();

  final results = await Future.wait([
    db.getProcessedCountPerBank(),
    smsService.getAvailableBankMessageCounts(),
  ]);

  final processed = results[0] as Map<String, int>;
  final available = results[1] as SmsAvailabilitySummary;

  return ImportStatus(
    awashDone: processed['awash'] ?? 0,
    awashTotal: available.awash,
    cbeDone: processed['cbe'] ?? 0,
    cbeTotal: available.cbe,
    telebirrDone: processed['telebirr'] ?? 0,
    telebirrTotal: available.telebirr,
    boaDone: processed['boa'] ?? 0,
    boaTotal: available.boa,
  );
});
