import 'package:flutter/material.dart';

import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/auth/presentation/providers/biometric_provider.dart';
import 'package:faranka/features/auth/data/biometric_service.dart';
import 'package:go_router/go_router.dart';

class UnlockPage extends StatefulWidget {
  const UnlockPage({super.key});

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  bool _authFailed = false;
  bool _noBiometrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAuthenticate());
  }

  Future<void> _tryAuthenticate() async {
    setState(() {
      _authFailed = false;
      _noBiometrics = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final available = await BiometricService.hasBiometrics();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _noBiometrics = true;
      });
      return;
    }

    final ok = await BiometricService.authenticate(
      reason: 'Authenticate to access your transactions',
    );

    if (!mounted) return;
    if (ok) {
      setBiometricPassed(true);
      if (mounted) context.go('/');
    } else {
      setState(() {
        _authFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = isDark ? DarkAppColors.homeNavigationSelected : AppColors.homeSeed;
    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 64, color: accent),
                const SizedBox(height: 24),
                Text(
                  'Faranka',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authenticate to access your transactions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  ),
                ),
                const SizedBox(height: 40),
                if (_authFailed)
                  Column(
                    children: [
                      Icon(Icons.fingerprint, size: 48, color: accent),
                      const SizedBox(height: 16),
                      Text(
                        'Authentication failed. Try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _tryAuthenticate,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Try again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_noBiometrics)
                  Column(
                    children: [
                      Icon(Icons.smartphone, size: 48, color: accent),
                      const SizedBox(height: 16),
                      Text(
                        'No biometrics enrolled on this device.\nAdd a fingerprint or face unlock in Settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
