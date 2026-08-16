import 'package:flutter/material.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/features/goals/presentation/widgets/edit_goal_sheet.dart';

class CreateGoalPage extends StatelessWidget {
  const CreateGoalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: isDark
          ? DarkAppColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Create Goal'),
        backgroundColor: isDark
            ? DarkAppColors.homeCardBackground
            : Colors.white,
        foregroundColor: isDark
            ? DarkAppColors.appBarForeground
            : AppColors.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: const EditGoalSheet(isModal: false),
    );
  }
}
