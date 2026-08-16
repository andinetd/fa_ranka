import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/features/receipts/presentation/notifiers/import_progress_notifier.dart';

final importProgressProvider =
    NotifierProvider<ImportProgressController, ImportState>(
  ImportProgressController.new,
);

class ImportProgressController extends Notifier<ImportState> {
  @override
  ImportState build() {
    ImportProgressNotifier.instance.addListener(_sync);
    ref.onDispose(
      () => ImportProgressNotifier.instance.removeListener(_sync),
    );
    return ImportProgressNotifier.instance.value;
  }

  void _sync() {
    state = ImportProgressNotifier.instance.value;
  }

  Future<void> startImport(Map<String, int> counts) {
    return ImportProgressNotifier.instance.startImport(counts);
  }

  void cancel() {
    ImportProgressNotifier.instance.cancel();
  }

  void dismissComplete() {
    ImportProgressNotifier.instance.dismissComplete();
  }
}
