import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    return _buildTheme(brightness: Brightness.light);
  }

  static ThemeData dark() {
    return _buildTheme(brightness: Brightness.dark);
  }

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.homeSeed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? DarkAppColors.scaffoldBackground
          : AppColors.scaffoldBackground,
      cardColor: isDark
          ? DarkAppColors.homeCardBackground
          : AppColors.homeCardBackground,
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? DarkAppColors.balanceCardBackground
            : AppColors.balanceCardBackground,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      shadowColor: isDark
          ? const Color(0x30000000)
          : const Color(0x14000000),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.appBarForeground,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.appBarForeground,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark
            ? DarkAppColors.homeCardBackground
            : AppColors.homeCardBackground,
        shadowColor: isDark
            ? const Color(0x30000000)
            : const Color(0x14000000),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : Colors.black12,
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        indicatorColor: isDark
            ? DarkAppColors.homeNavigationIndicator
            : AppColors.homeNavigationIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? (isDark
                    ? DarkAppColors.homeNavigationSelected
                    : AppColors.homeNavigationSelected)
                : (isDark
                    ? DarkAppColors.homeNavigationUnselected
                    : AppColors.homeNavigationUnselected),
          );
        }),
      ),
    );
  }
}
