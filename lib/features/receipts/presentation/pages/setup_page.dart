import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/services/sms.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/allocation_dialog.dart';
export '../widgets/allocation_dialog.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final SmsService _smsService = SmsService();
  late Future<SmsAvailabilitySummary> _availabilityFuture;

  @override
  void initState() {
    super.initState();
    _availabilityFuture = _smsService.getAvailableBankMessageCounts();
  }

  Future<void> _showAllocationModal(
    BuildContext context,
    SmsAvailabilitySummary availability,
  ) async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AllocationDialog(availability: availability),
    );

    if (result != null && context.mounted) {
      context.go('/results', extra: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);

    return FutureBuilder<SmsAvailabilitySummary>(
      future: _availabilityFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: isDark
                ? DarkAppColors.scaffoldBackground
                : AppColors.scaffoldBackground,
            appBar: AppBar(
              backgroundColor: isDark
                  ? DarkAppColors.homeCardBackground
                  : Colors.white,
              foregroundColor: isDark
                  ? DarkAppColors.appBarForeground
                  : AppColors.appBarForeground,
              title: const Text('Faranka Setup'),
            ),
            body: Center(
              child: Padding(
                padding: dims.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: dims.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DarkAppColors.homeCardBackground
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.homeCardShadowStyle,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: dims.icon(48),
                        color: Colors.redAccent,
                      ),
                      SizedBox(height: dims.spacingMd),
                      Text(
                        'Could not check messages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? DarkAppColors.appBarForeground
                              : AppColors.appBarForeground,
                        ),
                      ),
                      SizedBox(height: dims.spacingSm),
                      Text(
                        'Failed to access phone SMS. Check permissions and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                              : AppColors.balanceCardMuted,
                        ),
                      ),
                      SizedBox(height: dims.spacingLg),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(
                            () => _availabilityFuture = _smsService
                                .getAvailableBankMessageCounts(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? DarkAppColors.homeNavigationSelected
                                : AppColors.homeNavigationSelected,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'Try again',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final availability = snapshot.data;
        final availabilityText = switch (snapshot.connectionState) {
          ConnectionState.waiting =>
            'Checking how many messages are available on this phone...',
          _ when availability != null =>
            'Available to import now: ${availability.total} total (${availability.awash} AWASH, ${availability.cbe} CBE, ${availability.telebirr} TELEBIRR, ${availability.boa} BOA).',
          _ => 'Available to import now: 0 messages detected.',
        };

        return Scaffold(
          backgroundColor: isDark
              ? DarkAppColors.scaffoldBackground
              : AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: isDark
                ? DarkAppColors.homeCardBackground
                : Colors.white,
            foregroundColor: isDark
                ? DarkAppColors.appBarForeground
                : AppColors.appBarForeground,
            title: const Text('Faranka Setup'),
          ),
          body: Center(
            child: Padding(
              padding: dims.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: dims.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? DarkAppColors.homeCardBackground
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.homeCardShadowStyle,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? DarkAppColors.homeNavigationIndicator
                              : AppColors.homeNavigationIndicator,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.sms_outlined,
                          color: isDark
                              ? DarkAppColors.homeNavigationSelected
                              : AppColors.homeNavigationSelected,
                          size: dims.icon(28),
                        ),
                      ),
                      SizedBox(height: dims.spacingMd),
                      Text(
                        'Prepare your import',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? DarkAppColors.appBarForeground
                              : AppColors.appBarForeground,
                        ),
                      ),
                      SizedBox(height: dims.spacingSm),
                      Text(
                        'Choose how many messages to import from each bank, then let Faranka analyze them into spending insights.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                              : AppColors.balanceCardMuted,
                        ),
                      ),
                      SizedBox(height: dims.spacingMd),
                      _AvailabilityBanner(text: availabilityText, dims: dims),
                      SizedBox(height: dims.spacingLg),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? DarkAppColors.homeNavigationSelected
                                : AppColors.homeNavigationSelected,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: availability == null
                              ? null
                              : () =>
                                    _showAllocationModal(context, availability),
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text(
                            'Review import settings',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      SizedBox(height: dims(12)),
                      Text(
                        'You can adjust allocations before the import starts.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                              : AppColors.balanceCardMuted,
                        ),
                      ),
                      SizedBox(height: dims.spacingMd),
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('setup_complete', true);
                            if (context.mounted) context.go('/');
                          },
                          child: const Text('Skip for now'),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: dims(8)),
                        child: Text(
                          'The app will still automatically import messages in the background once SMS permission is granted.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? DarkAppColors.balanceCardMuted
                                : AppColors.balanceCardMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AvailabilityBanner extends ConsumerWidget {
  const _AvailabilityBanner({required this.text, required this.dims});

  final String text;
  final AppDimensions dims;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: dims.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? DarkAppColors.homeNavigationIndicator
            : AppColors.homeNavigationIndicator,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              (isDark
                      ? DarkAppColors.homeNavigationSelected
                      : AppColors.homeNavigationSelected)
                  .withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mail_outline_rounded,
            color: isDark
                ? DarkAppColors.homeNavigationSelected
                : AppColors.homeNavigationSelected,
            size: dims.icon(20),
          ),
          SizedBox(width: dims(10)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? DarkAppColors.appBarForeground
                    : AppColors.appBarForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
