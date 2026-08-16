import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final textScale = ref.watch(textScaleProvider);

    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: EdgeInsets.all(dims.spacingMd),
        children: [
          _section(dims, textScale, isDark, 'Data Collection',
            'Faranka does not collect, sell, or share any personal data. '
                'All SMS data is processed locally on your device and never sent to any server.',
          ),
          _section(dims, textScale, isDark, 'SMS Permission',
            'The app requests read access to SMS messages solely to parse bank transaction messages '
                'from CBE and Awash. This data is processed exclusively on your device and is never '
                'transmitted anywhere.',
          ),
          _section(dims, textScale, isDark, 'Local-Only Storage',
            'All data is stored in a local database on your device. There is no account system, '
                'no cloud storage, and no server that receives your information.',
          ),
          _section(dims, textScale, isDark, 'Third-Party Services',
            'Faranka uses no analytics, advertising, or tracking SDKs. The only network requests '
                'made by the app are to download bank receipt documents that you explicitly open.',
          ),
          _section(dims, textScale, isDark, 'Data Deletion',
            'You can delete all locally stored data at any time from Settings → Wipe All Data.',
          ),
          Padding(
            padding: EdgeInsets.only(bottom: dims.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact',
                  style: TextStyle(
                    fontSize: 16 * textScale,
                    fontWeight: FontWeight.w700,
                    color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                  ),
                ),
                SizedBox(height: dims.spacingSm),
                Text(
                  'If you have questions about this privacy policy, reach us at:',
                  style: TextStyle(
                    fontSize: 14 * textScale,
                    height: 1.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                SizedBox(height: dims.spacingSm),
                _linkLine(
                  context,
                  dims,
                  textScale,
                  isDark,
                  'email',
                  'mailto:andinetderejem@gmail.com',
                ),
                _linkLine(
                  context,
                  dims,
                  textScale,
                  isDark,
                  'telegram',
                  'tg://resolve?domain=andinet_dereje',
                  webFallbackUrl: 'https://t.me/andinet_dereje',
                ),
              ],
            ),
          ),
          SizedBox(height: dims.spacingLg),
          Text(
            'Last updated: July 2026',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(AppDimensions dims, double ts, bool isDark, String title, String body) {
    return Padding(
      padding: EdgeInsets.only(bottom: dims.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * ts,
              fontWeight: FontWeight.w700,
              color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
            ),
          ),
          SizedBox(height: dims.spacingSm),
          Text(
            body,
            style: TextStyle(
              fontSize: 14 * ts,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkLine(
    BuildContext context,
    AppDimensions dims,
    double ts,
    bool isDark,
    String label,
    String url, {
    String? webFallbackUrl,
  }) {
    final accent = isDark
        ? DarkAppColors.homeNavigationSelected
        : AppColors.homeNavigationSelected;
    return InkWell(
      onTap: () async {
        try {
          var uri = Uri.parse(url);
          var canLaunch = await canLaunchUrl(uri);
          if (!canLaunch && webFallbackUrl != null) {
            uri = Uri.parse(webFallbackUrl);
            canLaunch = await canLaunchUrl(uri);
          }
          if (!context.mounted) return;
          if (canLaunch) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            _showLaunchError(context, label);
          }
        } catch (_) {
          if (!context.mounted) return;
          _showLaunchError(context, label);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14 * ts,
            height: 1.5,
            color: accent,
            decoration: TextDecoration.underline,
            decorationColor: accent,
          ),
        ),
      ),
    );
  }

  void _showLaunchError(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open $value'),
      ),
    );
  }
}
