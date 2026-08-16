import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';

class DisplaySettingsSheet extends ConsumerStatefulWidget {
  const DisplaySettingsSheet({
    super.key,
    required this.initialTextScale,
    required this.initialSpacingScale,
    required this.onChanged,
  });

  final double initialTextScale;
  final double initialSpacingScale;
  final VoidCallback onChanged;

  @override
  ConsumerState<DisplaySettingsSheet> createState() =>
      DisplaySettingsSheetState();
}

class DisplaySettingsSheetState extends ConsumerState<DisplaySettingsSheet> {
  late double _textScale;
  late double _spacingScale;

  @override
  void initState() {
    super.initState();
    _textScale = widget.initialTextScale;
    _spacingScale = widget.initialSpacingScale;
  }

  void _onTextChanged(double v) {
    setState(() => _textScale = v);
    AppSettingsService.setTextScale(v);
    widget.onChanged();
  }

  void _onSpacingChanged(double v) {
    setState(() => _spacingScale = v);
    AppSettingsService.setSpacingScale(v);
    widget.onChanged();
  }

  void _resetText() => _onTextChanged(1.0);
  void _resetSpacing() => _onSpacingChanged(1.0);
  void _resetAll() {
    _onTextChanged(1.0);
    _onSpacingChanged(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Display Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            label: 'Text Size',
            value: _textScale,
            onChanged: _onTextChanged,
            onReset: _resetText,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildSliderRow(
            label: 'Spacing & Icons',
            value: _spacingScale,
            onChanged: _onSpacingChanged,
            onReset: _resetSpacing,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset All to 100%'),
              onPressed:
                  _textScale == 1.0 && _spacingScale == 1.0 ? null : _resetAll,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required VoidCallback onReset,
    required bool isDark,
  }) {
    final pct = '${(value * 100).round()}%';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    pct,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: value,
                min: 0.70,
                max: 1.40,
                divisions: 14,
                label: pct,
                onChanged: onChanged,
              ),
              Padding(
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Text('70%', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const Spacer(),
                    Text('140%', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.restart_alt,
            color: value == 1.0 ? Colors.grey.shade400 : null,
          ),
          tooltip: 'Reset to default',
          onPressed: value == 1.0 ? null : onReset,
        ),
      ],
    );
  }
}
