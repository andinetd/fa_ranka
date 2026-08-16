import 'package:flutter/material.dart';
import 'package:faranka/app/core/theme/app_colors.dart';

enum FilterPeriod { weekly, monthly, quarterly, yearly }

enum CategoryFilterPeriod { oneWeek, oneMonth, threeMonths, oneYear, all }

enum BankBalanceFilter {
  all('All Banks', null),
  boa('BoA', 'boa'),
  awash('Awash', 'awash'),
  cbe('CBE', 'cbe'),
  telebirr('Telebirr', 'telebirr');

  final String label;
  final String? dbFilter;
  const BankBalanceFilter(this.label, this.dbFilter);
}

/// Matches a stored `bank_name` to its balance filter, or null if the bank
/// is not one of the tracked options.
BankBalanceFilter? filterForBankName(String bankName) {
  final lower = bankName.toLowerCase();
  if (lower.contains('awash')) return BankBalanceFilter.awash;
  if (lower.contains('cbe')) return BankBalanceFilter.cbe;
  if (lower.contains('tele') || lower.contains('ethio')) {
    return BankBalanceFilter.telebirr;
  }
  if (lower.contains('boa') || lower.contains('abyssinia')) {
    return BankBalanceFilter.boa;
  }
  return null;
}

const List<Color> homeCategoryColors = AppColors.homeCategoryPalette;

const Color homeCardBackground = AppColors.homeCardBackground;
const Color homeAccentColor = AppColors.homeAccentGreen;
const BorderRadius homeCardBorderRadius = BorderRadius.all(Radius.circular(16));
const List<BoxShadow> homeCardShadow = AppColors.homeCardShadowStyle;
