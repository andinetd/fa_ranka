import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/utils/date_formatter.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_data_providers.dart';

class CreateBudgetPage extends ConsumerStatefulWidget {
  final List<String> categoryNames;

  const CreateBudgetPage({super.key, required this.categoryNames});

  @override
  ConsumerState<CreateBudgetPage> createState() => _CreateBudgetPageState();
}

class _CreateBudgetPageState extends ConsumerState<CreateBudgetPage> {
  late final List<String> _normalizedCategories;
  final _amountController = TextEditingController();
  final _categoryInputController = TextEditingController();
  static const _periodOptions = [
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
    'One time',
  ];
  String _budgetName = '';
  String _selectedPeriod = 'Monthly';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  final _selectedCategories = <String>{};
  String _selectedAccount = 'All Accounts';
  bool _trackAllSpending = false;

  @override
  void initState() {
    super.initState();
    _normalizedCategories = widget.categoryNames.isNotEmpty
        ? widget.categoryNames
        : const ['General'];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryInputController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date, CalendarMode mode) {
    return date.fmt('MMM d, yyyy', mode);
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text.trim());
    final typedCategory = _categoryInputController.text.trim();
    if (typedCategory.isNotEmpty) {
      _selectedCategories.add(typedCategory);
      _trackAllSpending = false;
    }
    if (_trackAllSpending) {
      _selectedCategories.clear();
    }
    if (_budgetName.isEmpty ||
        amount == null ||
        amount <= 0 ||
        amount.isNaN ||
        amount.isInfinite) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid name and amount.'),
        ),
      );
      return;
    }

    if (!_trackAllSpending && _selectedCategories.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one category or select "Track all spending".',
          ),
        ),
      );
      return;
    }

    if (_selectedPeriod == 'One time' &&
        (_selectedStartDate == null || _selectedEndDate == null)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates.'),
        ),
      );
      return;
    }

    if (_selectedStartDate != null &&
        _selectedEndDate != null &&
        _selectedEndDate!.isBefore(_selectedStartDate!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be on or after start date.'),
        ),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final existing = await db.customSelect(
      'SELECT id FROM budget_configs WHERE name = ?',
      variables: [Variable<String>(_budgetName)],
    ).get();
    if (existing.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A budget with this name already exists. Choose a different name.',
          ),
        ),
      );
      return;
    }

    try {
      await db.saveBudgetConfig(
        name: _budgetName,
        period: _selectedPeriod,
        amount: amount,
        categories: _selectedCategories.toList(),
        account: _selectedAccount,
        startAt: _selectedStartDate != null
            ? DateTime(
                _selectedStartDate!.year,
                _selectedStartDate!.month,
                _selectedStartDate!.day,
              ).millisecondsSinceEpoch
            : 0,
        endAt: _selectedEndDate != null
            ? DateTime(
                _selectedEndDate!.year,
                _selectedEndDate!.month,
                _selectedEndDate!.day,
                23,
                59,
                59,
              ).millisecondsSinceEpoch
            : 0,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().contains('UNIQUE')
                ? 'A budget with this name already exists.'
                : 'Could not save budget. Please try again.',
          ),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? prefix,
    Widget? suffixIcon,
    required bool isDark,
    required AppDimensions dims,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      suffixIcon: suffixIcon,
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
      contentPadding: dims.symmetric(h: 12, v: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final accountOptions =
        ref.watch(accountOptionsProvider).asData?.value ??
        const ['All Accounts'];
    final accountItems = accountOptions.contains(_selectedAccount)
        ? accountOptions
        : [...accountOptions, _selectedAccount];
    final hasAccountOptions = accountOptions.length > 1;

    return Scaffold(
      backgroundColor: isDark ? DarkAppColors.scaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Create Budget'),
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
        foregroundColor: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: SingleChildScrollView(
        padding: dims.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Name',
                hint: 'e.g. Household Monthly',
                isDark: isDark,
                dims: dims,
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
              ),
              cursorColor: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
              onChanged: (value) => _budgetName = value.trim(),
            ),
            SizedBox(height: dims(10)),
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod,
              decoration: _inputDecoration(
                label: 'Period',
                isDark: isDark,
                dims: dims,
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              ),
              dropdownColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
              iconEnabledColor: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              items: _periodOptions
                .map(
                  (period) => DropdownMenuItem(
                    value: period,
                    child: Text(
                      period,
                      style: TextStyle(color: isDark ? DarkAppColors.appBarForeground : Colors.black87),
                    ),
                  ),
                )
                .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedPeriod = value);
              },
            ),
            SizedBox(height: dims(10)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _selectedPeriod == 'One time'
                    ? 'Start date'
                    : 'Start date (optional)',
                style: TextStyle(
                  color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                ),
              ),
              subtitle: Text(
                _selectedStartDate == null
                    ? 'Choose a start date'
                    : _formatDate(_selectedStartDate!, calMode),
                style: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : null,
                ),
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
                  _selectedStartDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                  );
                  if (_selectedEndDate != null &&
                      _selectedEndDate!.isBefore(_selectedStartDate!)) {
                    _selectedEndDate = _selectedStartDate;
                  }
                });
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _selectedPeriod == 'One time'
                    ? 'End date'
                    : 'End date (optional)',
                style: TextStyle(
                  color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                ),
              ),
              subtitle: Text(
                _selectedEndDate == null
                    ? 'Choose an end date'
                    : _formatDate(_selectedEndDate!, calMode),
                style: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : null,
                ),
              ),
              trailing: Icon(Icons.event_outlined,
                  color: isDark ? DarkAppColors.balanceCardMuted : null),
              onTap: () async {
                final now = DateTime.now();
                final first =
                    _selectedStartDate ?? DateTime(now.year - 5);
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _selectedEndDate ?? _selectedStartDate ?? now,
                  firstDate: first,
                  lastDate: DateTime(now.year + 10),
                );
                if (picked == null || !mounted) return;
                setState(() {
                  _selectedEndDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                  );
                });
              },
            ),
            SizedBox(height: dims(10)),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                label: 'Amount',
                hint: 'Enter budget amount',
                prefix: 'ETB ',
                isDark: isDark,
                dims: dims,
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
              ),
              cursorColor: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
            ),
            if (!_trackAllSpending) ...[
              SizedBox(height: dims(10)),
              TextField(
                controller: _categoryInputController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Categories',
                  hint: 'Type category and tap Add',
                  isDark: isDark,
                  dims: dims,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add,
                        color: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected),
                    onPressed: () {
                      final category =
                          _categoryInputController.text.trim();
                      if (category.isEmpty) return;
                      setState(() {
                        _selectedCategories.add(category);
                        _categoryInputController.clear();
                        _trackAllSpending = false;
                      });
                    },
                  ),
                ),
                style: TextStyle(
                  color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                ),
                cursorColor: isDark ? DarkAppColors.homeAccentGreen : AppColors.homeNavigationSelected,
              ),
              SizedBox(height: dims(8)),
              if (_selectedCategories.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedCategories
                        .map(
                          (category) => InputChip(
                            label: Text(category),
                            onDeleted: () => setState(
                              () => _selectedCategories.remove(category),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              SizedBox(height: dims(8)),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _normalizedCategories
                      .where((category) {
                        final query = _categoryInputController.text
                            .trim()
                            .toLowerCase();
                        return !_selectedCategories.contains(category) &&
                            (query.isEmpty ||
                                category.toLowerCase().contains(query));
                      })
                      .take(8)
                      .map(
                        (category) => ActionChip(
                          label: Text(category),
                          onPressed: () => setState(() {
                            _selectedCategories.add(category);
                            _categoryInputController.clear();
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
              SizedBox(height: dims(8)),
              Row(
                children: [
                  if (_selectedCategories.isNotEmpty) ...[
                    Text(
                      'or ',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? DarkAppColors.balanceCardMuted
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  TextButton.icon(
                    icon: Icon(Icons.public, size: dims.icon(18)),
                    label: const Text('Track all spending'),
                    onPressed: () => setState(() {
                      _trackAllSpending = true;
                      _selectedCategories.clear();
                      _categoryInputController.clear();
                    }),
                  ),
                ],
              ),
            ],
            if (_trackAllSpending)
              Padding(
                padding: dims.symmetric(v: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: dims.icon(18),
                      color: isDark
                          ? DarkAppColors.homeAccentGreen
                          : AppColors.homeAccentGreen,
                    ),
                    SizedBox(width: dims.spacingSm),
                    Text(
                      'Tracking all spending',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? DarkAppColors.appBarForeground
                            : const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          setState(() => _trackAllSpending = false),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ),
            SizedBox(height: dims(10)),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccount,
              decoration: _inputDecoration(
                label: 'Account',
                isDark: isDark,
                dims: dims,
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              ),
              dropdownColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
              iconEnabledColor: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              items: accountItems
                .map(
                  (account) => DropdownMenuItem(
                    value: account,
                    child: Text(
                      account,
                      style: TextStyle(color: isDark ? DarkAppColors.appBarForeground : Colors.black87),
                    ),
                  ),
                )
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
            SizedBox(height: dims(20)),
            FilledButton(
              onPressed: _handleSave,
              style: FilledButton.styleFrom(
                padding: dims.symmetric(v: 14),
                backgroundColor: isDark ? DarkAppColors.homeAccentGreen : null,
                foregroundColor: isDark ? Colors.white : null,
              ),
              child: const Text('Save Budget'),
            ),
          ],
        ),
      ),
    );
  }
}
