import 'package:flutter/material.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

import 'package:faranka/features/home/presentation/widgets/home_bottom_nav.dart';

class UnderConstructionPage extends StatelessWidget {
  const UnderConstructionPage({
    super.key,
    required this.title,
    required this.selectedIndex,
  });

  final String title;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.appBarForeground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(title),
      ),
      bottomNavigationBar: HomeBottomNav(selectedIndex: selectedIndex),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.homeCardShadowStyle,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 52,
                color: AppColors.appBarForeground,
              ),
              SizedBox(height: 10),
              Text(
                'Under Construction',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.appBarForeground,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'This section is coming soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.balanceCardMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
