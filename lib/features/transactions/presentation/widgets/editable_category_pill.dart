import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';

class EditableCategoryPill extends ConsumerWidget {
  final TransactionData txn;
  final VoidCallback? onTap;

  const EditableCategoryPill({
    super.key,
    required this.txn,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: dims.symmetric(h: 12, v: 10),
        decoration: BoxDecoration(
          color: (isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: dims(4)),
                  Text(
                    txn.parsedCategory.isNotEmpty
                        ? txn.parsedCategory
                        : 'Uncategorized',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: dims.spacingSm),
            Icon(Icons.edit, size: dims.icon(18), color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted),
          ],
        ),
      ),
    );
  }
}
