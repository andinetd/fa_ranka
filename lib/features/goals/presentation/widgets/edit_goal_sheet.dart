import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/providers/database_provider.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/features/transactions/presentation/providers/transaction_data_providers.dart';

import 'goal_form_fields.dart';

export 'goal_form_fields.dart';

class EditGoalSheet extends ConsumerStatefulWidget {
  final GoalRow? goal;
  final bool isModal;

  const EditGoalSheet({super.key, this.goal, this.isModal = true});

  @override
  ConsumerState<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends ConsumerState<EditGoalSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _startingBalanceController;
  late String _selectedType;
  late String? _selectedPeriod;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  late String _selectedAccount;
  late bool _growthMode;
  bool _isSaving = false;

  static const _typeOptions = ['income_target', 'balance_target'];
  static const _typeLabels = {
    'income_target': 'Income Target',
    'balance_target': 'Balance Target',
  };
  static const _periodOptions = ['One time', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _amountController = TextEditingController(
      text: g != null ? g.targetAmount.toString() : '',
    );
    _startingBalanceController = TextEditingController(
      text: g != null && g.startingBalance > 0
          ? g.startingBalance.toString()
          : '',
    );
    _selectedType = g?.type ?? 'income_target';
    _selectedPeriod = g?.period;
    _selectedStartDate = g != null && g.startDate > 0
        ? DateTime.fromMillisecondsSinceEpoch(g.startDate)
        : null;
    _selectedEndDate = g != null && g.endDate > 0
        ? DateTime.fromMillisecondsSinceEpoch(g.endDate)
        : null;
    _selectedAccount = g?.accountFilter ?? 'All Accounts';
    _growthMode = g?.growthMode ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _startingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    final calMode = ref.watch(calendarModeProvider);
    final bottom = widget.isModal
        ? MediaQuery.of(context).viewInsets.bottom
        : 0.0;
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
            if (widget.isModal) ...[
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
                widget.goal == null ? 'Create Goal' : 'Edit Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DarkAppColors.appBarForeground : null,
                ),
              ),
              SizedBox(height: dims(16)),
            ],
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Save for car',
                labelStyle: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : null,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? DarkAppColors.homeAccentGreen
                        : AppColors.homeNavigationSelected,
                    width: 1.5,
                  ),
                ),
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : null,
              ),
              cursorColor: isDark
                  ? DarkAppColors.homeAccentGreen
                  : AppColors.homeNavigationSelected,
            ),
            SizedBox(height: dims(12)),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type',
                labelStyle: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : null,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              ),
              dropdownColor: isDark
                  ? DarkAppColors.homeCardBackground
                  : Colors.white,
              iconEnabledColor: isDark
                  ? DarkAppColors.appBarForeground
                  : Colors.black87,
              items: _typeOptions
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        _typeLabels[t] ?? t,
                        style: TextStyle(
                          color: isDark
                              ? DarkAppColors.appBarForeground
                              : Colors.black87,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedType = value);
              },
            ),
            SizedBox(height: dims(12)),
            DropdownButtonFormField<String?>(
              initialValue: _selectedPeriod,
              decoration: InputDecoration(
                labelText: 'Period',
                labelStyle: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : null,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              ),
              dropdownColor: isDark
                  ? DarkAppColors.homeCardBackground
                  : Colors.white,
              iconEnabledColor: isDark
                  ? DarkAppColors.appBarForeground
                  : Colors.black87,
              items: _periodOptions
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p,
                        style: TextStyle(
                          color: isDark
                              ? DarkAppColors.appBarForeground
                              : Colors.black87,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedPeriod = value);
              },
            ),
            SizedBox(height: dims(8)),
            GoalDatePickers(
              startDate: _selectedStartDate,
              endDate: _selectedEndDate,
              calMode: calMode,
              isDark: isDark,
              onStartDatePicked: (date) {
                if (!mounted) return;
                setState(() => _selectedStartDate = date);
              },
              onEndDatePicked: (date) {
                if (!mounted) return;
                setState(() => _selectedEndDate = date);
              },
            ),
            SizedBox(height: dims(12)),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Target amount',
                hintText: 'Enter target amount',
                prefixText: 'ETB ',
                labelStyle: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : null,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? DarkAppColors.homeAccentGreen
                        : AppColors.homeNavigationSelected,
                    width: 1.5,
                  ),
                ),
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : null,
              ),
              cursorColor: isDark
                  ? DarkAppColors.homeAccentGreen
                  : AppColors.homeNavigationSelected,
            ),
            SizedBox(height: dims(12)),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccount,
              decoration: InputDecoration(
                labelText: 'Account',
                labelStyle: TextStyle(
                  color: isDark ? DarkAppColors.balanceCardMuted : null,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
              style: TextStyle(
                color: isDark ? DarkAppColors.appBarForeground : Colors.black87,
              ),
              dropdownColor: isDark
                  ? DarkAppColors.homeCardBackground
                  : Colors.white,
              iconEnabledColor: isDark
                  ? DarkAppColors.appBarForeground
                  : Colors.black87,
              items: accountItems
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(
                        a,
                        style: TextStyle(
                          color: isDark
                              ? DarkAppColors.appBarForeground
                              : Colors.black87,
                        ),
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
                  color: isDark
                      ? DarkAppColors.balanceCardMuted
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
            if (_selectedType == 'balance_target' &&
                _selectedPeriod != null) ...[
              const SizedBox(height: 8),
              GoalGrowthModeTile(
                growthMode: _growthMode,
                period: _selectedPeriod,
                amountText: _amountController.text,
                isDark: isDark,
                onChanged: (v) => setState(() => _growthMode = v),
              ),
              if (_growthMode) ...[
                SizedBox(height: dims(8)),
                TextField(
                  controller: _startingBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Starting balance',
                    hintText: 'Current account balance',
                    prefixText: 'ETB ',
                    labelStyle: TextStyle(
                      color: isDark ? DarkAppColors.balanceCardMuted : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? DarkAppColors.homeAccentGreen
                            : AppColors.homeNavigationSelected,
                        width: 1.5,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? DarkAppColors.appBarForeground : null,
                  ),
                  cursorColor: isDark
                      ? DarkAppColors.homeAccentGreen
                      : AppColors.homeNavigationSelected,
                ),
              ],
            ],
            SizedBox(height: dims(16)),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  padding: dims.symmetric(v: 14),
                  backgroundColor: isDark
                      ? DarkAppColors.homeAccentGreen
                      : null,
                  foregroundColor: isDark ? Colors.white : null,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.goal == null ? 'Create Goal' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDark ? DarkAppColors.homeCardBackground : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSave() async {
    final db = ref.read(databaseProvider);
    final isDark = AppColors.isDark(context);
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (name.isEmpty ||
        amount == null ||
        amount <= 0 ||
        amount.isNaN ||
        amount.isInfinite) {
      if (!mounted) return;
      _showSnackBar('Please enter a valid name and amount.', isDark);
      return;
    }

    if (_selectedPeriod == null &&
        (_selectedStartDate == null || _selectedEndDate == null)) {
      if (!mounted) return;
      _showSnackBar('Please select start and end dates.', isDark);
      return;
    }

    if (_selectedEndDate != null &&
        _selectedStartDate != null &&
        _selectedEndDate!.isBefore(_selectedStartDate!)) {
      if (!mounted) return;
      _showSnackBar('End date must be on or after start date.', isDark);
      return;
    }

    final startingBalance = double.tryParse(
      _startingBalanceController.text.trim(),
    );

    if (_growthMode && (startingBalance == null || startingBalance < 0)) {
      if (!mounted) return;
      _showSnackBar(
        'Please enter a valid starting balance (0 or more).',
        isDark,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final startMs = _selectedStartDate != null
          ? DateTime(
              _selectedStartDate!.year,
              _selectedStartDate!.month,
              _selectedStartDate!.day,
            ).millisecondsSinceEpoch
          : 0;
      final endMs = _selectedEndDate != null
          ? DateTime(
              _selectedEndDate!.year,
              _selectedEndDate!.month,
              _selectedEndDate!.day,
              23,
              59,
              59,
            ).millisecondsSinceEpoch
          : 0;

      if (widget.goal == null) {
        await db.saveGoal(
          name: name,
          type: _selectedType,
          targetAmount: amount,
          period: _selectedPeriod,
          startDate: startMs,
          endDate: endMs,
          accountFilter: _selectedAccount,
          growthMode: _growthMode,
          startingBalance: startingBalance ?? 0.0,
        );
      } else {
        await db.updateGoal(
          id: widget.goal!.id,
          name: name,
          type: _selectedType,
          targetAmount: amount,
          period: _selectedPeriod,
          startDate: startMs,
          endDate: endMs,
          accountFilter: _selectedAccount,
          growthMode: _growthMode,
          startingBalance: startingBalance ?? 0.0,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Could not save goal. Please try again.', isDark);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
