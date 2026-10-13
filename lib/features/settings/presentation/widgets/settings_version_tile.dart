import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:faranka/app/core/services/app_update_service.dart';

class SettingsVersionTile extends StatelessWidget {
  const SettingsVersionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '--';
        final build = snapshot.data?.buildNumber ?? '--';
        return ValueListenableBuilder<AppUpdateInfo?>(
          valueListenable: AppUpdateService.latestUpdateNotifier,
          builder: (context, updateInfo, _) {
            final hasUpdate = updateInfo?.hasUpdate ?? false;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                hasUpdate
                    ? Icons.system_update
                    : Icons.new_releases_outlined,
                color: hasUpdate ? const Color(0xFF10B981) : null,
              ),
              title: Row(
                children: [
                  const Text('App Version'),
                  if (hasUpdate) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'v${updateInfo!.versionName} available',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                hasUpdate
                    ? 'Tap to update • Current: Version $version ($build)'
                    : 'Version $version ($build) • Tap to check for updates',
              ),
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checking for updates...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                final result = await AppUpdateService.checkForUpdate(
                  force: true,
                );
                if (!context.mounted) return;
                if (result != null && result.hasUpdate) {
                  await AppUpdateService.showUpdateDialog(
                    context,
                    result,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App is up to date!'),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
