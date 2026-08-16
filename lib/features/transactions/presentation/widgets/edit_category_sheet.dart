import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';

class EditCategorySheet extends ConsumerStatefulWidget {
  final TransactionData txn;
  final BuildContext parentContext;
  final List<Category> categories;

  const EditCategorySheet({
    super.key,
    required this.txn,
    required this.parentContext,
    required this.categories,
  });

  @override
  ConsumerState<EditCategorySheet> createState() => EditCategorySheetState();
}

class EditCategorySheetState extends ConsumerState<EditCategorySheet> {
  late final TextEditingController _controller;
  List<Category> _filtered = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.txn.parsedCategory);
    _filtered = _buildFiltered(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Category> _buildFiltered(String query) {
    final q = query.trim();
    if (q.isEmpty) return [];
    return widget.categories
        .where((c) => c.name.toLowerCase().contains(q.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    final titleMedium = Theme.of(context).textTheme.titleMedium;
    final noMatchStyle = TextStyle(
      color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
    );
    final query = _controller.text.trim();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: dims.only(b: bottomInset),
            child: SingleChildScrollView(
              padding: dims.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: dims.spacingMd),
                  Text('Edit Category', style: titleMedium?.copyWith(
                    color: isDark ? DarkAppColors.appBarForeground : null,
                  )),
                  SizedBox(height: dims.spacingMd),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Category name',
                      hintText: 'Type to search or create',
                      labelStyle: TextStyle(
                        color: isDark ? DarkAppColors.balanceCardMuted : null,
                      ),
                      hintStyle: TextStyle(
                        color: isDark
                            ? DarkAppColors.balanceCardMuted.withValues(alpha: 0.6)
                            : null,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                    ),
                    cursorColor: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
                    onChanged: (q) {
                      setState(() => _filtered = _buildFiltered(q));
                    },
                  ),
                  SizedBox(height: dims(12)),
                  if (query.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: _filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: dims.symmetric(v: 12),
                                child: Text(
                                  'No matches — create "$query"',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: noMatchStyle,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) {
                                final c = _filtered[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: isDark ? DarkAppColors.appBarForeground : null,
                                    ),
                                  ),
                                  tileColor: isDark ? DarkAppColors.homeCardBackground : null,
                                  hoverColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                                  onTap: () {
                                    _controller.text = c.name;
                                    _controller.selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _controller.text.length,
                                      ),
                                    );
                                    setState(() => _filtered = [c]);
                                  },
                                );
                              },
                            ),
                    ),
                  SizedBox(height: dims.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? DarkAppColors.appBarForeground : null,
                        ),
                        child: const Text('Cancel'),
                      ),
                      SizedBox(width: dims.spacingSm),
                      ElevatedButton(
                        onPressed: () => _save(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? DarkAppColors.homeAccentGreen : null,
                          foregroundColor: isDark ? Colors.white : null,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category cannot be empty')),
      );
      return;
    }

    if (newName == widget.txn.parsedCategory) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final normalized = newName.toLowerCase();
    final db = ref.read(databaseProvider);
    final found = await (db.select(db.categories)
          ..where((t) => t.normalizedName.equals(normalized)))
        .get();

    if (found.isEmpty) {
      await db.into(db.categories).insert(
        CategoriesCompanion(
          name: Value(newName),
          normalizedName: Value(normalized),
        ),
      );
    }

    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (!widget.parentContext.mounted) return;
    final messenger = ScaffoldMessenger.of(widget.parentContext);

    try {
      await db.update(db.transactions).replace(
        widget.txn.copyWith(parsedCategory: newName),
      );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Category updated')),
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update category: $e')),
      );
    }
  }
}
