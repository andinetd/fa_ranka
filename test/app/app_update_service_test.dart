import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faranka/app/core/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Faranka',
      packageName: 'com.genzeb.faranka',
      version: '1.1.11',
      buildNumber: '88',
      buildSignature: '',
    );
    AppUpdateService.latestUpdateNotifier.value = null;
  });

  group('AppUpdateInfo', () {
    test('parses json correctly and marks hasUpdate when remote code is higher', () {
      final json = {
        'version_code': 89,
        'version_name': '1.1.12',
        'release_notes': 'New features added',
        'apk_url': 'https://example.com/faranka.apk',
      };

      final info = AppUpdateInfo.fromJson(json, 88);
      expect(info.versionCode, 89);
      expect(info.versionName, '1.1.12');
      expect(info.releaseNotes, 'New features added');
      expect(info.apkUrl, 'https://example.com/faranka.apk');
      expect(info.hasUpdate, isTrue);
    });

    test('marks hasUpdate false when remote code is equal or lower', () {
      final json = {
        'version_code': 88,
        'version_name': '1.1.11',
        'release_notes': '',
        'apk_url': 'https://example.com/faranka.apk',
      };

      final info = AppUpdateInfo.fromJson(json, 88);
      expect(info.hasUpdate, isFalse);

      final olderInfo = AppUpdateInfo.fromJson({
        'version_code': 85,
        'version_name': '1.1.9',
      }, 88);
      expect(olderInfo.hasUpdate, isFalse);
    });
  });

  group('AppUpdateService.checkForUpdate', () {
    test('fetches update info and updates latestUpdateNotifier when update available', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), AppUpdateService.updateJsonUrl);
        return http.Response(
          '{"version_code": 90, "version_name": "1.2.0", "release_notes": "Major update", "apk_url": "https://example.com/apk"}',
          200,
        );
      });

      final result = await AppUpdateService.checkForUpdate(
        client: mockClient,
        force: true,
      );

      expect(result, isNotNull);
      expect(result!.hasUpdate, isTrue);
      expect(result.versionCode, 90);
      expect(AppUpdateService.latestUpdateNotifier.value?.versionCode, 90);
    });

    test('sets latestUpdateNotifier to null when no newer version available', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"version_code": 88, "version_name": "1.1.11", "apk_url": "https://example.com/apk"}',
          200,
        );
      });

      final result = await AppUpdateService.checkForUpdate(
        client: mockClient,
        force: true,
      );

      expect(result, isNotNull);
      expect(result!.hasUpdate, isFalse);
      expect(AppUpdateService.latestUpdateNotifier.value, isNull);
    });

    test('handles HTTP errors gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final result = await AppUpdateService.checkForUpdate(
        client: mockClient,
        force: true,
      );

      expect(result, isNull);
    });
  });
}
