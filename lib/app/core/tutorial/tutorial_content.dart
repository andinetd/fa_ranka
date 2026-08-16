import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';

TargetContent _step({
  required String title,
  required String body,
  required bool isDark,
  required AppDimensions dims,
  required bool isLast,
}) {
  return TargetContent(
    align: ContentAlign.top,
    builder: (context, controller) {
      final accent = isDark ? DarkAppColors.homeNavigationSelected : AppColors.homeNavigationSelected;
      final screenH = MediaQuery.of(context).size.height;
      final topPad = MediaQuery.of(context).padding.top + 12;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenH * 0.5),
          child: Container(
            margin: dims.symmetric(h: 12) + EdgeInsets.only(top: topPad, bottom: 12),
            padding: dims.all(16),
            decoration: BoxDecoration(
              color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tips_and_updates, size: dims.icon(20), color: accent),
                    SizedBox(width: dims(8)),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: dims.spacingSm),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                  ),
                ),
                SizedBox(height: dims.spacingMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: controller.skip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: isLast ? controller.skip : controller.next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isLast ? 'Got it' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

List<TargetFocus> homeTutorial({
  required GlobalKey balanceKey,
  required GlobalKey categoryKey,
  required GlobalKey recentTxnKey,
  required bool isDark,
  required AppDimensions dims,
}) {
  return [
    TargetFocus(
      keyTarget: balanceKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        _step(
          title: 'Balance Overview',
          body: 'Swipe left or right to switch between All, Awash, or CBE balances. Use the period picker to view different timeframes.',
          isDark: isDark,
          dims: dims,
          isLast: false,
        ),
      ],
    ),
    TargetFocus(
      keyTarget: categoryKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        _step(
          title: 'Spending Breakdown',
          body: 'See where your money goes. Tap any category to view all transactions in that category.',
          isDark: isDark,
          dims: dims,
          isLast: false,
        ),
      ],
    ),
    TargetFocus(
      keyTarget: recentTxnKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        _step(
          title: 'Recent Transactions',
          body: 'Your latest transactions. Tap one to see full details, receipts, and split categories.',
          isDark: isDark,
          dims: dims,
          isLast: true,
        ),
      ],
    ),
  ];
}

List<TargetFocus> transactionsTutorial({
  required GlobalKey searchKey,
  required bool isDark,
  required AppDimensions dims,
}) {
  return [
    TargetFocus(
      keyTarget: searchKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        _step(
          title: 'Search & Filters',
          body: 'Search by counterparty, amount, or date. Expand the filters to narrow by bank, sort order, amount range, or date range.',
          isDark: isDark,
          dims: dims,
          isLast: true,
        ),
      ],
    ),
  ];
}

List<TargetFocus> budgetsTutorial({
  required GlobalKey fabKey,
  required GlobalKey cardKey,
  required bool hasBudgets,
  required bool isDark,
  required AppDimensions dims,
}) {
  final targets = <TargetFocus>[
    TargetFocus(
      keyTarget: fabKey,
      shape: ShapeLightFocus.Circle,
      contents: [
        _step(
          title: 'Create a Budget',
          body: 'Tap + to create a spending budget for any category. Set a limit and choose a period.',
          isDark: isDark,
          dims: dims,
          isLast: !hasBudgets,
        ),
      ],
    ),
  ];

  if (hasBudgets) {
    targets.add(
      TargetFocus(
        keyTarget: cardKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          _step(
            title: 'Budget Tracking',
            body: 'Progress bars show how you\'re tracking — green for on track, ochre for risk, brick for overrun. Tap a budget to edit it.',
            isDark: isDark,
            dims: dims,
            isLast: true,
          ),
        ],
      ),
    );
  }

  return targets;
}

List<TargetFocus> settingsTutorial({
  required GlobalKey displayKey,
  required bool isDark,
  required AppDimensions dims,
}) {
  return [
    TargetFocus(
      keyTarget: displayKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        _step(
          title: 'Display Settings',
          body: 'Adjust text size and spacing independently. Sliders go from 70% to 140%. Reset all to defaults anytime.',
          isDark: isDark,
          dims: dims,
          isLast: true,
        ),
      ],
    ),
  ];
}

List<TargetFocus> receiptTutorial({
  required GlobalKey splitKey,
  required bool isDark,
  required AppDimensions dims,
}) {
  return [
    TargetFocus(
      keyTarget: splitKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        _step(
          title: 'Split Transaction',
          body: 'Divide a single transaction across multiple categories. Tap "Split Transaction" to assign portions of the amount to different budgets — useful for grocery items that span categories, or utility bills you split with roommates.',
          isDark: isDark,
          dims: dims,
          isLast: true,
        ),
      ],
    ),
  ];
}
