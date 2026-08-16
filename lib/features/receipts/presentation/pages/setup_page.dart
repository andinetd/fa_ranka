import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faranka/app/core/providers/display_size_provider.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/theme/app_dimensions.dart';
import 'package:faranka/app/core/services/sms.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final SmsService _smsService = SmsService();
  late Future<SmsAvailabilitySummary> _availabilityFuture;

  @override
  void initState() {
    super.initState();
    _availabilityFuture = _smsService.getAvailableBankMessageCounts();
  }

  Future<void> _showAllocationModal(
    BuildContext context,
    SmsAvailabilitySummary availability,
  ) async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AllocationDialog(availability: availability),
    );

    if (result != null && context.mounted) {
      context.go('/results', extra: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);

    return FutureBuilder<SmsAvailabilitySummary>(
      future: _availabilityFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: isDark
                ? DarkAppColors.scaffoldBackground
                : AppColors.scaffoldBackground,
            appBar: AppBar(
              backgroundColor: isDark
                  ? DarkAppColors.homeCardBackground
                  : Colors.white,
              foregroundColor: isDark
                  ? DarkAppColors.appBarForeground
                  : AppColors.appBarForeground,
              title: const Text('Faranka Setup'),
            ),
            body: Center(
              child: Padding(
                padding: dims.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: dims.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DarkAppColors.homeCardBackground
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.homeCardShadowStyle,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: dims.icon(48),
                        color: Colors.redAccent,
                      ),
                      SizedBox(height: dims.spacingMd),
                      Text(
                        'Could not check messages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? DarkAppColors.appBarForeground
                              : AppColors.appBarForeground,
                        ),
                      ),
                      SizedBox(height: dims.spacingSm),
                      Text(
                        'Failed to access phone SMS. Check permissions and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                              : AppColors.balanceCardMuted,
                        ),
                      ),
                      SizedBox(height: dims.spacingLg),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(
                            () => _availabilityFuture = _smsService
                                .getAvailableBankMessageCounts(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? DarkAppColors.homeNavigationSelected
                                : AppColors.homeNavigationSelected,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'Try again',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final availability = snapshot.data;
        final availabilityText = switch (snapshot.connectionState) {
          ConnectionState.waiting =>
            'Checking how many messages are available on this phone...',
          _ when availability != null =>
            'Available to import now: ${availability.total} total (${availability.awash} AWASH, ${availability.cbe} CBE, ${availability.telebirr} TELEBIRR, ${availability.boa} BOA).',
          _ => 'Available to import now: 0 messages detected.',
        };

        return Scaffold(
          backgroundColor: isDark
              ? DarkAppColors.scaffoldBackground
              : AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: isDark
                ? DarkAppColors.homeCardBackground
                : Colors.white,
            foregroundColor: isDark
                ? DarkAppColors.appBarForeground
                : AppColors.appBarForeground,
            title: const Text('Faranka Setup'),
          ),
          body: Center(
            child: Padding(
              padding: dims.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: dims.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? DarkAppColors.homeCardBackground
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.homeCardShadowStyle,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? DarkAppColors.homeNavigationIndicator
                              : AppColors.homeNavigationIndicator,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.sms_outlined,
                          color: isDark
                              ? DarkAppColors.homeNavigationSelected
                              : AppColors.homeNavigationSelected,
                          size: dims.icon(28),
                        ),
                      ),
                      SizedBox(height: dims.spacingMd),
                      Text(
                        'Prepare your import',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? DarkAppColors.appBarForeground
                              : AppColors.appBarForeground,
                        ),
                      ),
                      SizedBox(height: dims.spacingSm),
                      Text(
                        'Choose how many messages to import from each bank, then let Faranka analyze them into spending insights.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                              : AppColors.balanceCardMuted,
                        ),
                      ),
                      SizedBox(height: dims.spacingMd),
                      _AvailabilityBanner(text: availabilityText, dims: dims),
                      SizedBox(height: dims.spacingLg),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? DarkAppColors.homeNavigationSelected
                                : AppColors.homeNavigationSelected,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: availability == null
                              ? null
                              : () =>
                                    _showAllocationModal(context, availability),
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text(
                            'Review import settings',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      SizedBox(height: dims(12)),
                      Text(
                        'You can adjust allocations before the import starts.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? DarkAppColors.balanceCardMuted
                              : AppColors.balanceCardMuted,
                        ),
                      ),
                      SizedBox(height: dims.spacingMd),
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('setup_complete', true);
                            if (context.mounted) context.go('/');
                          },
                          child: const Text('Skip for now'),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: dims(8)),
                        child: Text(
                          'The app will still automatically import messages in the background once SMS permission is granted.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? DarkAppColors.balanceCardMuted
                                : AppColors.balanceCardMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AvailabilityBanner extends ConsumerWidget {
  const _AvailabilityBanner({required this.text, required this.dims});

  final String text;
  final AppDimensions dims;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: dims.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? DarkAppColors.homeNavigationIndicator
            : AppColors.homeNavigationIndicator,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              (isDark
                      ? DarkAppColors.homeNavigationSelected
                      : AppColors.homeNavigationSelected)
                  .withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mail_outline_rounded,
            color: isDark
                ? DarkAppColors.homeNavigationSelected
                : AppColors.homeNavigationSelected,
            size: dims.icon(20),
          ),
          SizedBox(width: dims(10)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? DarkAppColors.appBarForeground
                    : AppColors.appBarForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AllocationDialog extends ConsumerStatefulWidget {
  const AllocationDialog({super.key, required this.availability});

  final SmsAvailabilitySummary availability;

  @override
  ConsumerState<AllocationDialog> createState() => _AllocationDialogState();
}

class _AllocationDialogState extends ConsumerState<AllocationDialog> {
  static const Map<String, String> _bankCanonical = {
    'awash': 'Awash Bank',
    'cbe': 'CBE',
    'telebirr': 'Telebirr',
    'boa': 'BoA',
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController numberOfAwashMessages;
  late final TextEditingController numberOfCbeMessages;
  late final TextEditingController numberOfTelebirrMessages;
  late final TextEditingController numberOfBoaMessages;

  Set<String> _selectedBanks = {};

  List<TextEditingController> get _controllers => [
        numberOfAwashMessages,
        numberOfCbeMessages,
        numberOfTelebirrMessages,
        numberOfBoaMessages,
      ];

  @override
  void initState() {
    super.initState();
    final maxAwash = widget.availability.awash;
    final maxCbe = widget.availability.cbe;
    final maxTelebirr = widget.availability.telebirr;
    final maxBoa = widget.availability.boa;
    numberOfAwashMessages = TextEditingController(
      text: maxAwash > 0 ? '$maxAwash' : '20',
    );
    numberOfCbeMessages = TextEditingController(
      text: maxCbe > 0 ? '$maxCbe' : '20',
    );
    numberOfTelebirrMessages = TextEditingController(
      text: maxTelebirr > 0 ? '$maxTelebirr' : '20',
    );
    numberOfBoaMessages = TextEditingController(
      text: maxBoa > 0 ? '$maxBoa' : '10',
    );
    for (final controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }
    _loadAccess();
  }

  void _onFieldChanged() => setState(() {});

  Future<void> _loadAccess() async {
    final available = <String, int>{
      'Awash Bank': widget.availability.awash,
      'CBE': widget.availability.cbe,
      'Telebirr': widget.availability.telebirr,
      'BoA': widget.availability.boa,
    };
    if (mounted) {
      setState(() {
        _selectedBanks = {
          ...available.entries
              .where((e) => e.value > 0)
              .map((e) => e.key),
        };
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onFieldChanged);
    }
    numberOfAwashMessages.dispose();
    numberOfCbeMessages.dispose();
    numberOfTelebirrMessages.dispose();
    numberOfBoaMessages.dispose();
    super.dispose();
  }

  bool _isBankSelected(String bankId) {
    return _selectedBanks.contains(_bankCanonical[bankId]);
  }

  bool _isBankTracked(String bankId) {
    return false;
  }

  void _toggleBank(String bankId) {
    final canonical = _bankCanonical[bankId]!;
    setState(() {
      if (_selectedBanks.contains(canonical)) {
        _selectedBanks.remove(canonical);
        return;
      }
      _selectedBanks.add(canonical);
    });
  }

  Future<void> _handleGenerateReport() async {
    if (_formKey.currentState!.validate()) {
      final navigator = Navigator.of(context);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_complete', true);

      final dataToSend = <String, int>{
        'awash': _isBankSelected('awash')
            ? int.parse(numberOfAwashMessages.text)
            : 0,
        'cbe': _isBankSelected('cbe') ? int.parse(numberOfCbeMessages.text) : 0,
        'telebirr': _isBankSelected('telebirr')
            ? int.parse(numberOfTelebirrMessages.text)
            : 0,
        'boa': _isBankSelected('boa')
            ? int.parse(numberOfBoaMessages.text)
            : 0,
      };

      navigator.pop(dataToSend);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dims = ref.watch(dimensionsProvider);
    return Dialog(
      backgroundColor: isDark ? DarkAppColors.homeCardBackground : Colors.white,
      insetPadding: dims.symmetric(h: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: dims.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allocation',
                  style: TextStyle(
                    color: isDark
                        ? DarkAppColors.appBarForeground
                        : AppColors.appBarForeground,
                    fontSize: 14,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: dims(6)),
                Text(
                  'Choose how many recent messages to import from each bank.',
                  style: TextStyle(
                    color: isDark
                        ? DarkAppColors.balanceCardMuted
                        : AppColors.balanceCardMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: dims(12)),
                Text(
                  'Available on this phone: ${widget.availability.total} total (${widget.availability.awash} AWASH, ${widget.availability.cbe} CBE, ${widget.availability.telebirr} TELEBIRR, ${widget.availability.boa} BOA).',
                  style: TextStyle(
                    color: isDark
                        ? DarkAppColors.appBarForeground
                        : AppColors.appBarForeground,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: dims(20)),
                _buildBankPicker(dims),
                SizedBox(height: dims(20)),
                _buildAllocationField(
                  'AWASH',
                  numberOfAwashMessages,
                  dims,
                  enabled: _isBankSelected('awash'),
                  tracked: _isBankTracked('awash'),
                ),
                _buildAllocationField(
                  'CBE',
                  numberOfCbeMessages,
                  dims,
                  enabled: _isBankSelected('cbe'),
                  tracked: _isBankTracked('cbe'),
                ),
                _buildAllocationField(
                  'TELEBIRR',
                  numberOfTelebirrMessages,
                  dims,
                  enabled: _isBankSelected('telebirr'),
                  tracked: _isBankTracked('telebirr'),
                ),
                _buildAllocationField(
                  'BOA',
                  numberOfBoaMessages,
                  dims,
                  enabled: _isBankSelected('boa'),
                  tracked: _isBankTracked('boa'),
                ),
                SizedBox(height: dims(20)),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedBanks.isEmpty
                        ? null
                        : _handleGenerateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? DarkAppColors.homeNavigationSelected
                          : AppColors.homeNavigationSelected,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Import messages',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankPicker(AppDimensions dims) {
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which banks do you want to track?',
          style: TextStyle(
            color: isDark
                ? DarkAppColors.appBarForeground
                : AppColors.appBarForeground,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: dims(8)),
        Wrap(
          spacing: dims(8),
          runSpacing: dims(8),
          children: [
            for (final entry in _bankCanonical.entries)
              _buildBankChip(entry.key, entry.value, dims),
          ],
        ),
        SizedBox(height: dims(6)),
        Text(
          _selectedBanks.isEmpty
              ? 'Select at least one bank to import messages.'
              : '${_selectedBanks.length} bank${_selectedBanks.length == 1 ? '' : 's'} selected.',
          style: TextStyle(
            color: isDark
                ? DarkAppColors.balanceCardMuted
                : AppColors.balanceCardMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBankChip(
    String bankId,
    String canonical,
    AppDimensions dims,
  ) {
    final isDark = AppColors.isDark(context);
    final primary = isDark
        ? DarkAppColors.homeNavigationSelected
        : AppColors.homeNavigationSelected;
    final selected = _isBankSelected(bankId);
    final tracked = _isBankTracked(bankId);
    final bg = selected
        ? primary.withValues(alpha: 0.14)
        : isDark
            ? DarkAppColors.homeCardBackground
            : Colors.white;
    final border = selected
        ? primary
        : isDark
            ? Colors.grey.shade700
            : const Color(0xFFE5E7EB);
    final fg = selected || tracked
        ? primary
        : isDark
            ? DarkAppColors.balanceCardMuted
            : AppColors.balanceCardMuted;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _toggleBank(bankId),
        child: Padding(
          padding: dims.symmetric(h: 12, v: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: dims.icon(16),
                color: selected ? primary : fg,
              ),
              SizedBox(width: dims(6)),
              Text(
                canonical,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (tracked) ...[
                SizedBox(width: dims(4)),
                Icon(
                  Icons.star,
                  size: dims.icon(12),
                  color: Colors.amber,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationField(
    String label,
    TextEditingController controller,
    AppDimensions dims, {
    required bool enabled,
    required bool tracked,
  }) {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: dims.only(b: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: isDark
              ? DarkAppColors.appBarForeground
              : AppColors.appBarForeground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        validator: (value) {
          if (!enabled) return null;
          if (value == null || value.isEmpty) return 'Required';
          final parsed = int.tryParse(value);
          if (parsed == null) return 'Enter a number';
          final max = switch (label) {
            'AWASH' => widget.availability.awash,
            'CBE' => widget.availability.cbe,
            'TELEBIRR' => widget.availability.telebirr,
            'BOA' => widget.availability.boa,
            _ => 0,
          };
          if (parsed > max) return 'Max $max available';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark
                ? DarkAppColors.balanceCardMuted
                : AppColors.balanceCardMuted,
            fontSize: 12,
          ),
          suffixIcon: !enabled
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tracked) ...[
                        const Icon(Icons.star,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                      ],
                      const Icon(Icons.lock, color: Colors.grey, size: 18),
                    ],
                  ),
                )
              : null,
          filled: true,
          fillColor: !enabled
              ? Colors.grey.withValues(alpha: 0.08)
              : isDark
                  ? DarkAppColors.scaffoldBackground
                  : AppColors.scaffoldBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.grey.shade700
                  : const Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.grey.shade700
                  : const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? DarkAppColors.homeNavigationSelected
                  : AppColors.homeNavigationSelected,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
