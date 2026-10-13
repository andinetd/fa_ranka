import 'package:flutter/material.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'home_types.dart';

class BalanceCardTheme {
  const BalanceCardTheme._();

  static const double cornerRadius = 6.0;

  static Map<String, Color> bankColors(
    BankBalanceFilter bank,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    switch (bank) {
      case BankBalanceFilter.awash:
        if (isDark) {
          return {
            'bg': const Color(0xFF1E1510),
            'fg': const Color(0xFFCCD6E8),
            'muted': const Color(0xFF9CAAB8),
            'accent': const Color(0xFFF5A623),
            'grid': const Color(0x1ACCD6E8),
            'shadow': const Color(0x14000000),
          };
        }
        return {
          'bg': const Color(0xFFFFF4E6),
          'fg': const Color(0xFF1A2A44),
          'muted': const Color(0xFF6C7A89),
          'accent': const Color(0xFFF58220),
          'grid': const Color(0x1A1A2A44),
          'shadow': const Color(0x14000000),
        };

      case BankBalanceFilter.cbe:
        if (isDark) {
          return {
            'bg': const Color(0xFF0D1B2A),
            'fg': const Color(0xFF8AB4F8),
            'muted': const Color(0xFF9CAAB8),
            'accent': const Color.fromARGB(255, 200, 120, 240),
            'grid': const Color(0x1A8AB4F8),
            'shadow': const Color(0x14000000),
          };
        }
        return {
          'bg': const Color(0xFFF2F6FB),
          'fg': const Color(0xFF003A8F),
          'muted': const Color(0xFF6B7A99),
          'accent': const Color.fromARGB(255, 179, 40, 222),
          'grid': const Color(0x1A003A8F),
          'shadow': const Color(0x14000000),
        };

      case BankBalanceFilter.all:
        return {
          'bg': isDark
              ? DarkAppColors.balanceCardBackground
              : AppColors.balanceCardBackground,
          'fg': isDark
              ? DarkAppColors.balanceCardForeground
              : AppColors.balanceCardForeground,
          'muted': isDark
              ? DarkAppColors.balanceCardMuted
              : AppColors.balanceCardMuted,
          'accent': isDark
              ? DarkAppColors.balanceCardAccent
              : AppColors.balanceCardAccent,
          'grid': isDark
              ? DarkAppColors.balanceCardGrid
              : AppColors.balanceCardGrid,
          'shadow': isDark
              ? DarkAppColors.balanceCardShadow
              : AppColors.balanceCardShadow,
        };

      case BankBalanceFilter.boa:
        if (isDark) {
          return {
            'bg': const Color(0xFF10151D),
            'fg': const Color(0xFF9FC6FF),
            'muted': const Color(0xFF9CAAB8),
            'accent': const Color(0xFF2E7CF6),
            'grid': const Color(0x1A9FC6FF),
            'shadow': const Color(0x14000000),
          };
        }
        return {
          'bg': const Color(0xFFEAF1FB),
          'fg': const Color(0xFF0455A6),
          'muted': const Color(0xFF5F6B85),
          'accent': const Color(0xFF2E7CF6),
          'grid': const Color(0x1A0455A6),
          'shadow': const Color(0x14000000),
        };

      case BankBalanceFilter.telebirr:
        if (isDark) {
          return {
            'bg': const Color(0xFF150F24),
            'fg': const Color(0xFFD5C8F5),
            'muted': const Color(0xFF9CAAB8),
            'accent': const Color(0xFF8C4FF5),
            'grid': const Color(0x1AD5C8F5),
            'shadow': const Color(0x14000000),
          };
        }
        return {
          'bg': const Color(0xFFF3EDFC),
          'fg': const Color(0xFF4A148C),
          'muted': const Color(0xFF7A678F),
          'accent': const Color(0xFF8C4FF5),
          'grid': const Color(0x1A4A148C),
          'shadow': const Color(0x14000000),
        };
    }
  }

  static String balanceTitle(BankBalanceFilter bank) {
    switch (bank) {
      case BankBalanceFilter.all:
        return 'Total balance';
      case BankBalanceFilter.awash:
        return 'Awash balance';
      case BankBalanceFilter.cbe:
        return 'CBE balance';
      case BankBalanceFilter.boa:
        return 'BoA balance';
      case BankBalanceFilter.telebirr:
        return 'Telebirr balance';
    }
  }

  static String periodDropdownLabel(FilterPeriod period) {
    switch (period) {
      case FilterPeriod.weekly:
        return 'This week';
      case FilterPeriod.monthly:
        return 'This month';
      case FilterPeriod.quarterly:
        return 'Last 3 months';
      case FilterPeriod.yearly:
        return 'This year';
    }
  }

  static int daysForPeriod(FilterPeriod period) {
    switch (period) {
      case FilterPeriod.weekly:
        return 7;
      case FilterPeriod.monthly:
        return 30;
      case FilterPeriod.quarterly:
        return 90;
      case FilterPeriod.yearly:
        return 365;
    }
  }
}
