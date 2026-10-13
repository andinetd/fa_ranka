import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final int versionCode;
  final String versionName;
  final String releaseNotes;
  final String apkUrl;
  final bool hasUpdate;

  AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.releaseNotes,
    required this.apkUrl,
    required this.hasUpdate,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json, int currentCode) {
    final remoteCode = (json['version_code'] as num?)?.toInt() ?? 0;
    return AppUpdateInfo(
      versionCode: remoteCode,
      versionName: json['version_name']?.toString() ?? '',
      releaseNotes: json['release_notes']?.toString() ?? '',
      apkUrl: json['apk_url']?.toString() ?? '',
      hasUpdate: remoteCode > currentCode,
    );
  }
}

class AppUpdateService {
  static const String updateJsonUrl =
      'https://raw.githubusercontent.com/andinetd/genze-eb-web/main/update.json';
  static const String keyLastCheckTimestamp = 'app_update_last_check_ms';
  static const String keyLastIgnoredVersion = 'app_update_last_ignored_code';

  static ValueNotifier<AppUpdateInfo?> latestUpdateNotifier = ValueNotifier(null);

  /// Checks for an update. Set [force] to true for manual checks from Settings.
  static Future<AppUpdateInfo?> checkForUpdate({
    http.Client? client,
    bool force = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!force) {
        final lastCheck = prefs.getInt(keyLastCheckTimestamp) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        // Check at most once every 12 hours automatically
        if (now - lastCheck < const Duration(hours: 12).inMilliseconds) {
          return latestUpdateNotifier.value;
        }
      }

      final httpClient = client ?? http.Client();
      final response = await httpClient
          .get(Uri.parse(updateJsonUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      final info = AppUpdateInfo.fromJson(data, currentCode);
      latestUpdateNotifier.value = info.hasUpdate ? info : null;

      await prefs.setInt(
        keyLastCheckTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );

      return info;
    } catch (e) {
      debugPrint('AppUpdateService error: $e');
      return null;
    }
  }

  /// Prompts the user to update if a newer version is available.
  static Future<void> showUpdateDialog(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              const Text('Update Available'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version (${updateInfo.versionName}) is available.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (updateInfo.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  updateInfo.releaseNotes,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final uri = Uri.parse(updateInfo.apkUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Download & Update'),
            ),
          ],
        );
      },
    );
  }
}
