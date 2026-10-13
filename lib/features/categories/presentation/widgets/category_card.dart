import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/app/core/theme/app_colors.dart';

class CategoryCard extends ConsumerWidget {
  final String name;
  final int count;
  final double amount;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.name,
    required this.count,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dims = ref.watch(dimensionsProvider);
    final isDark = AppColors.isDark(context);
    return Material(
      color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: dims.symmetric(h: 12, v: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? DarkAppColors.balanceCardChipBorder
                  : AppColors.balanceCardChipBorder,
              width: 1,
            ),
            boxShadow: isDark
                ? DarkAppColors.homeCardShadowStyle
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? DarkAppColors.appBarForeground
                            : AppColors.appBarForeground,
                      ),
                    ),
                    SizedBox(height: dims(2)),
                    Builder(
                      builder: (context) {
                        final useCompact = AppSettingsService.getBoolSync(
                          AppSettingsService.keyCompactNumbers,
                          fallback: true,
                        );
                        final fmt = useCompact
                            ? NumberFormat.compactCurrency(symbol: 'ETB ')
                            : NumberFormat.currency(
                                symbol: 'ETB ',
                                decimalDigits: 2,
                              );
                        final formatted = fmt.format(amount);
                        return Text(
                          '$formatted • $count messages',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? DarkAppColors.balanceCardMuted
                                : AppColors.balanceCardMuted,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? DarkAppColors.balanceCardChipBackground
                      : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? DarkAppColors.balanceCardChipBorder
                        : AppColors.balanceCardChipBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? DarkAppColors.balanceCardMuted
                      : AppColors.balanceCardMuted,
                  size: dims.icon(18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
