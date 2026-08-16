import 'package:flutter/material.dart';

class AppColors {
  static bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

  static const Color scaffoldBackground = Color(0xFFF3F4F6);
  static const Color appBarForeground = Color(0xFF1F2937);
  static const Color homeSeed = Color(0xFF79AE6F);
  static const Color homeNavigationSelected = Color(0xFF2E7D32);
  static const Color homeNavigationUnselected = Color(0xFF6B7280);
  static const Color homeNavigationIndicator = Color(0xFFE8F5E9);
  static const Color homeCardBackground = Colors.white;
  static const Color homeAccentGreen = Color.fromARGB(255, 142, 167, 143);
  static const Color transactionSent = Color.fromARGB(255, 238, 232, 229);
  static const Color transactionReceived = Color.fromARGB(255, 221, 227, 197);
  static const Color transactionSentFont = Color.fromARGB(255, 112, 46, 46);
  static const Color transactionReceivedFont = Color.fromARGB(255, 14, 34, 10);
  static const Color homeCardShadow = Color(0x12000000);

  static const Color balanceCardBackground = Colors.white;
  static const Color balanceCardForeground = Colors.black;
  static const Color balanceCardMuted = Color(0xFF6B7280);
  static const Color balanceCardAccent = Colors.black;
  static const Color balanceCardGrid = Color(0x1A000000);
  static const Color balanceCardChipBackground = Color(0xFFF2F2F2);
  static const Color balanceCardChipBorder = Color(0x22000000);
  static const Color balanceCardShadow = Color(0x14000000);
  static const Color balancePeriodPickerBackground = Color(0xFFBED6BF);
  static const Color balancePeriodPickerText = Color(0xFF58745B);
  static const Color balancePeriodPickerIcon = Color(0xFF111111);
  static const Color balancePeriodPickerShadow = Color(0x22000000);

  static const List<Color> homeCategoryPalette = [
    Color(0xFFFF595E),
    Color(0xFFFFCA3A),
    Color(0xFF8AC926),
    Color(0xFF1982C4),
    Color(0xFF6A4C93),
    Color(0xFFE5E7EB),
  ];

  static const List<BoxShadow> homeCardShadowStyle = [
    BoxShadow(color: homeCardShadow, blurRadius: 10, offset: Offset(0, 3)),
  ];
}

class DarkAppColors {
  static const Color scaffoldBackground = Color(0xFF121212);
  static const Color appBarForeground = Color(0xFFE0E0E0);
  static const Color homeNavigationSelected = Color(0xFF4CAF50);
  static const Color homeNavigationUnselected = Color(0xFF9CA3AF);
  static const Color homeNavigationIndicator = Color(0xFF1B3D1B);
  static const Color homeCardBackground = Color(0xFF1E1E1E);
  static const Color homeAccentGreen = Color.fromARGB(255, 94, 133, 94);
  static const Color transactionSent = Color(0xFF1E1E1E);
  static const Color transactionReceived = Color(0xFF1E1E1E);
  static const Color transactionSentFont = Color.fromARGB(255, 190, 130, 130);
  static const Color transactionReceivedFont = Color.fromARGB(255, 115, 160, 118);
  static const Color homeCardShadow = Color(0x30000000);

  static const Color balanceCardBackground = Color(0xFF1E1E1E);
  static const Color balanceCardForeground = Color(0xFFE0E0E0);
  static const Color balanceCardMuted = Color(0xFF9CA3AF);
  static const Color balanceCardAccent = Color(0xFFE0E0E0);
  static const Color balanceCardGrid = Color(0x1AFFFFFF);
  static const Color balanceCardChipBackground = Color(0xFF2D2D2D);
  static const Color balanceCardChipBorder = Color(0x22FFFFFF);
  static const Color balanceCardShadow = Color(0x14000000);
  static const Color balancePeriodPickerBackground = Color.fromARGB(255, 81, 127, 83);
  static const Color balancePeriodPickerText = Color(0xFFA8D5A8);
  static const Color balancePeriodPickerIcon = Color(0xFFD0D0D0);
  static const Color balancePeriodPickerShadow = Color(0x22000000);

  static const List<BoxShadow> homeCardShadowStyle = [
    BoxShadow(color: homeCardShadow, blurRadius: 10, offset: Offset(0, 3)),
  ];

  static const List<Color> homeCategoryPalette = [
    Color(0xFFFF595E),
    Color(0xFFFFCA3A),
    Color(0xFF8AC926),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFF374151),
  ];
}

class AppTypography {
  // Shared app font family used by ThemeData.
  static const String primaryFontFamily = 'Inter';

  // Dedicated family for the home balance card typography.
  static const String balanceSectionFontFamily = 'Inter';
}
