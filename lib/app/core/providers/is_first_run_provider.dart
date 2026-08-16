import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _isFirstRun = true;

final isFirstRunProvider = Provider<bool>((ref) => _isFirstRun);

bool get isFirstRun => _isFirstRun;

void setIsFirstRun(bool value) {
  _isFirstRun = value;
}
