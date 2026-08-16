import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';

class FilterChipWidget extends ConsumerWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: dims.symmetric(h: 10, v: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? DarkAppColors.balanceCardChipBackground : AppColors.balanceCardChipBackground)
              : (isDark ? DarkAppColors.homeCardBackground : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? (isDark ? DarkAppColors.balanceCardChipBorder : AppColors.balanceCardChipBorder)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? (isDark ? DarkAppColors.balanceCardForeground : AppColors.balanceCardForeground)
                    : (isDark ? DarkAppColors.appBarForeground : Colors.black87),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBarWidget extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final bool showAdvancedFilters;
  final VoidCallback onDismissAdvancedFilters;

  const SearchBarWidget({
    super.key,
    required this.searchController,
    required this.showAdvancedFilters,
    required this.onDismissAdvancedFilters,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: widget.searchController,
        onTap: () {
          if (widget.showAdvancedFilters) {
            widget.onDismissAdvancedFilters();
          }
        },
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? DarkAppColors.appBarForeground : const Color(0xFF1A1A2E),
          letterSpacing: 0.1,
        ),
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey[400],
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: dims.only(l: 16, r: 10),
            child: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.grey.shade500 : Colors.grey[400],
              size: dims.icon(22),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: widget.searchController.text.isNotEmpty
              ? Padding(
                  padding: dims.only(r: 8),
                  child: GestureDetector(
                    onTap: () {
                      widget.searchController.clear();
                    },
                    child: Container(
                      margin: dims.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                        size: dims.icon(16),
                      ),
                    ),
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 163, 173, 142),
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: isDark ? DarkAppColors.balanceCardChipBackground : Colors.white,
          contentPadding: dims.symmetric(
            v: 16,
            h: 20,
          ),
        ),
      ),
    );
  }
}
