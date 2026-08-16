import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_data_providers.dart';

class EditBudgetSheet extends ConsumerStatefulWidget {
  final BudgetConfigRow budget;
  final bool isDark;

  const EditBudgetSheet({super.key, required this.budget, required this.isDark});

  @override
  ConsumerState<EditBudgetSheet> createState() => EditBudgetSheetState();
}

class EditBudgetSheetState extends ConsumerState<EditBudgetSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late String _selectedPeriod;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  late String _selectedAccount;
  late Set<String> _selectedCategories;
  late List<String> _categoryNames;

  static const _periodOptions = [
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
    'One time',
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _nameController = TextEditingController(text: b.name);
    _amountController = TextEditingController(text: b.amount.toString());
    _categoryController = TextEditingController();
    _selectedPeriod = b.period;
    _selectedStartDate = b.startAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(b.startAt)
        : null;
    _selectedEndDate = b.endAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(b.endAt)
        : null;
    _selectedAccount = b.account;
    _selectedCategories = {...b.categories};
    _categoryNames = b.categories.toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date, CalendarMode mode) => date.fmt('MMM d, yyyy', mode);

  InputDecoration _inputDecoration(String label, {String? hint, String? prefix, Widget? icon}) {
    final isDark = widget.isDark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      suffixIcon: icon,
      labelStyle: TextStyle(
        color: isDark ? DarkAppColors.balanceCardMuted : null,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final accountOptions =
        ref.watch(accountOptionsProvider).asData?.value ??
        const ['All Accounts'];
    final accountItems = accountOptions.contains(_selectedAccount)
        ? accountOptions
        : [...accountOptions, _selectedAccount];
    final hasAccountOptions = accountOptions.length > 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: dims(12)),
            Text(
              'Edit budget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? DarkAppColors.appBarForeground : null,
              ),
            ),
            SizedBox(height: dims(16)),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Name', hint: 'Budget name'),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : null,
              ),
              cursorColor: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
            ),
            SizedBox(height: dims(12)),
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod,
              decoration: _inputDecoration('Period'),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              ),
              dropdownColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
              iconEnabledColor: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              items: _periodOptions
                  .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p,
                          style: TextStyle(
                              color: isDark ? DarkAppColors.appBarForeground : Colors.black87))))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedPeriod = value;
                  if (_selectedPeriod != 'One time') {
                    _selectedStartDate = null;
                    _selectedEndDate = null;
                  }
                });
              },
            ),
            if (_selectedPeriod == 'One time') ...[
              SizedBox(height: dims(8)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Start date',
                    style: TextStyle(color: isDark ? DarkAppColors.appBarForeground : null)),
                subtitle: Text(
                  _selectedStartDate == null
                      ? 'Choose a start date'
                      : _formatDate(_selectedStartDate!, calMode),
                  style: TextStyle(color: isDark ? DarkAppColors.balanceCardMuted : null),
                ),
                trailing: Icon(Icons.calendar_today_outlined,
                    color: isDark ? DarkAppColors.balanceCardMuted : null),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedStartDate ?? now,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 10),
                  );
                  if (picked == null || !mounted) return;
                  setState(() {
                    _selectedStartDate = DateTime(picked.year, picked.month, picked.day);
                    if (_selectedEndDate != null &&
                        _selectedEndDate!.isBefore(_selectedStartDate!)) {
                      _selectedEndDate = _selectedStartDate;
                    }
                  });
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('End date',
                    style: TextStyle(color: isDark ? DarkAppColors.appBarForeground : null)),
                subtitle: Text(
                  _selectedEndDate == null
                      ? 'Choose an end date'
                      : _formatDate(_selectedEndDate!, calMode),
                  style: TextStyle(color: isDark ? DarkAppColors.balanceCardMuted : null),
                ),
                trailing: Icon(Icons.event_outlined,
                    color: isDark ? DarkAppColors.balanceCardMuted : null),
                onTap: () async {
                  final now = DateTime.now();
                  final first = _selectedStartDate ?? DateTime(now.year - 5);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedEndDate ?? _selectedStartDate ?? now,
                    firstDate: first,
                    lastDate: DateTime(now.year + 10),
                  );
                  if (picked == null || !mounted) return;
                  setState(() {
                    _selectedEndDate = DateTime(picked.year, picked.month, picked.day);
                  });
                },
              ),
            ],
            SizedBox(height: dims(12)),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('Amount', hint: 'Enter budget amount', prefix: 'ETB '),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : null,
              ),
              cursorColor: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
            ),
            SizedBox(height: dims(12)),
            TextField(
              controller: _categoryController,
              decoration: _inputDecoration(
                'Categories',
                icon: IconButton(
                  icon: Icon(Icons.add,
                      color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected),
                  onPressed: () {
                    final c = _categoryController.text.trim();
                    if (c.isEmpty) return;
                    setState(() {
                      _selectedCategories.add(c);
                      _categoryController.clear();
                    });
                  },
                ),
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : null,
              ),
              cursorColor: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
            ),
            SizedBox(height: dims(8)),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedCategories
                    .map((c) => InputChip(
                          label: Text(c),
                          onDeleted: () => setState(() => _selectedCategories.remove(c)),
                        ))
                    .toList(),
              ),
            ),
            if (_categoryController.text.isNotEmpty) ...[
              SizedBox(height: dims(8)),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _categoryNames
                      .where((c) =>
                          !_selectedCategories.contains(c) &&
                          c.toLowerCase().contains(_categoryController.text.toLowerCase()))
                      .take(8)
                      .map((c) => ActionChip(
                            label: Text(c),
                            onPressed: () => setState(() {
                              _selectedCategories.add(c);
                              _categoryController.clear();
                            }),
                          ))
                      .toList(),
                ),
              ),
            ],
            SizedBox(height: dims(12)),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccount,
              decoration: _inputDecoration('Account'),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              ),
              dropdownColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
              iconEnabledColor: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              items: accountItems
                  .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(a,
                          style: TextStyle(
                              color: isDark ? DarkAppColors.appBarForeground : Colors.black87))))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedAccount = value);
              },
            ),
            if (!hasAccountOptions) ...[
              SizedBox(height: dims(6)),
              Text(
                'No banks found yet — sync SMS to add accounts.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? DarkAppColors.balanceCardMuted : Colors.grey.shade600,
                ),
              ),
            ],
            SizedBox(height: dims(16)),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _handleSave,
                style: FilledButton.styleFrom(
                  padding: dims.symmetric(v: 14),
                  backgroundColor: isDark ? DarkAppColors.homeAccentGreen : null,
                  foregroundColor: isDark ? Colors.white : null,
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final db = ref.read(databaseProvider);
    final typedCategory = _categoryController.text.trim();
    if (typedCategory.isNotEmpty) {
      _selectedCategories.add(typedCategory);
    }
    final newName = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (newName.isEmpty || _selectedCategories.isEmpty || amount == null || amount <= 0 || amount.isNaN || amount.isInfinite) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name, categories, and amount.')),
      );
      return;
    }

    if (widget.budget.period == 'One time' && (_selectedStartDate == null || _selectedEndDate == null)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates.')),
      );
      return;
    }

    if (_selectedEndDate != null && _selectedStartDate != null && _selectedEndDate!.isBefore(_selectedStartDate!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be on or after start date.')),
      );
      return;
    }

    final conflict = await db.customSelect(
      'SELECT id FROM budget_configs WHERE name = ? AND id != ?',
      variables: [Variable<String>(newName), Variable<int>(widget.budget.id)],
    ).get();
    if (conflict.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A budget with this name already exists.')),
      );
      return;
    }

    try {
      await db.updateBudgetConfig(
        id: widget.budget.id,
        name: newName,
        period: _selectedPeriod,
        amount: amount,
        categories: _selectedCategories.toList(),
        account: _selectedAccount,
        startAt: _selectedPeriod == 'One time'
            ? DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day)
                .millisecondsSinceEpoch
            : 0,
        endAt: _selectedPeriod == 'One time'
            ? DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day, 23, 59, 59)
                .millisecondsSinceEpoch
            : 0,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().contains('UNIQUE')
                ? 'A budget with this name already exists.'
                : 'Could not save budget.',
          ),
        ),
      );
    }
  }
}
