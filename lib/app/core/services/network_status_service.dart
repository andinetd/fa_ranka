import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatusService {
  static final Connectivity _connectivity = Connectivity();

  static Future<bool> hasInternet({Duration timeout = const Duration(minutes: 1)}) async {
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Stream<bool> watchInternetStatus() async* {
    bool? lastEmitted;

    final initial = await hasInternet();
    lastEmitted = initial;
    yield initial;

    await for (final _ in _connectivity.onConnectivityChanged) {
      final current = await hasInternet();
      if (current == lastEmitted) continue;
      lastEmitted = current;
      yield current;
    }
  }
}
