import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';

class HomeBottomNav extends ConsumerWidget {
  const HomeBottomNav({super.key, this.selectedIndex = 0});

  final int selectedIndex;

  static const _labels = ['Home', 'Transaction', 'Budget', 'Insights', 'Settings'];
  static const _shortLabels = ['Home', 'Txn', 'Bdgt', 'Insig', 'Stngs'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dims = ref.watch(dimensionsProvider);
    final textScale = ref.watch(textScaleProvider);
    final isDark = AppColors.isDark(context);
    final screenSize = MediaQuery.of(context).size;
    final w = screenSize.width;
    final h = screenSize.height;

    final bool narrow = w < 360 || h < 600;
    final bool wide = w >= 600;

    final double navHeight = dims(wide ? 78.0 : narrow ? 56.0 : 64.0);
    final double iconSize = dims(wide ? 28.0 : narrow ? 20.0 : 24.0);
    final double labelFontSize = wide ? 14.0 : narrow ? 10.0 : 12.0;
    final double horizontalPadding = dims(wide ? 16.0 : narrow ? 4.0 : 8.0);
    final double bottomMargin = dims(wide ? 12.0 : narrow ? 6.0 : 10.0);
    final double borderRadius = dims(wide ? 24.0 : narrow ? 14.0 : 20.0);

    final navWidth = screenSize.width - 2 * horizontalPadding;
    final labelWidth = navWidth / 5;
    final effectiveFontSize = labelFontSize * textScale;
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Transactions',
        style: TextStyle(
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    final labels = textPainter.width > labelWidth * 1.02 ? _shortLabels : _labels;

    final NavigationDestinationLabelBehavior labelBehavior =
        NavigationDestinationLabelBehavior.alwaysShow;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, bottomMargin),
        child: Material(
          elevation: 10,
          shadowColor: isDark ? Colors.white10 : Colors.black26,
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            height: navHeight,
            backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
            indicatorColor: isDark ? DarkAppColors.homeNavigationIndicator : AppColors.homeNavigationIndicator,
            labelBehavior: labelBehavior,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              return TextStyle(
                fontSize: labelFontSize,
                color: states.contains(WidgetState.selected)
                    ? (isDark ? DarkAppColors.homeNavigationSelected : AppColors.homeNavigationSelected)
                    : (isDark ? DarkAppColors.homeNavigationUnselected : AppColors.homeNavigationUnselected),
              );
            }),
            onDestinationSelected: (index) {
              if (index == 0) {
                context.go('/');
              } else if (index == 1) {
                context.go('/transactions');
              } else if (index == 2) {
                context.go('/budgets');
              } else if (index == 3) {
                context.go('/insights');
              } else if (index == 4) {
                context.go('/settings');
              }
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: iconSize),
                selectedIcon: Icon(Icons.home, size: iconSize),
                label: labels[0],
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_outlined, size: iconSize),
                selectedIcon: Icon(Icons.swap_horiz, size: iconSize),
                label: labels[1],
              ),
               NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined, size: iconSize),
                selectedIcon: Icon(Icons.account_balance_wallet, size: iconSize),
                 label: labels[2],
               ),
               NavigationDestination(
                icon: Icon(Icons.insights_outlined, size: iconSize),
                selectedIcon: Icon(Icons.insights, size: iconSize),
                 label: labels[3],
               ),
               NavigationDestination(
                icon: Icon(Icons.settings_outlined, size: iconSize),
                selectedIcon: Icon(Icons.settings, size: iconSize),
                 label: labels[4],
               ),
            ],
          ),
        ),
      ),
    );
  }
}
