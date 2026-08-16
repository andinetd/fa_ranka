import 'package:flutter/material.dart';

/// Resolves a bank's stored name to its bundled logo asset and renders it.
///
/// Renders nothing when the bank has no known logo, and falls back to a
/// colored initial badge if the asset file fails to load.
class BankLogo extends StatelessWidget {
  const BankLogo({
    super.key,
    required this.bankName,
    this.size = 14,
  });

  final String? bankName;
  final double size;

  static const Map<String, String> _logoAssets = {
    'cbe': 'assets/bank_logos/cbe.webp',
    'awash': 'assets/bank_logos/awash.webp',
    'boa': 'assets/bank_logos/boa.webp',
    'telebirr': 'assets/bank_logos/telebirr.webp',
  };

  static const Map<String, Color> _brandColors = {
    'cbe': Color(0xFFB8860B),
    'awash': Color(0xFFB71C1C),
    'boa': Color(0xFF1565C0),
    'telebirr': Color(0xFF4A148C),
  };

  static String? _keyOf(String? bankName) {
    final normalized = (bankName ?? '').trim().toLowerCase().replaceAll(' ', '');
    if (normalized.isEmpty) return null;
    if (normalized == 'boa' || normalized.contains('abyssinia')) return 'boa';
    if (normalized.contains('awash')) return 'awash';
    if (normalized.contains('telebirr') ||
        normalized.contains('ethiotelecom')) {
      return 'telebirr';
    }
    if (normalized.contains('cbe') || normalized.contains('commercialbank')) {
      return 'cbe';
    }
    return null;
  }

  static bool hasLogo(String? bankName) => _keyOf(bankName) != null;

  static String? assetForBank(String? bankName) {
    final key = _keyOf(bankName);
    return key == null ? null : _logoAssets[key];
  }

  @override
  Widget build(BuildContext context) {
    final key = _keyOf(bankName);
    if (key == null) return const SizedBox.shrink();

    return Image.asset(
      _logoAssets[key]!,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _Badge(
        letter: (bankName ?? '?').trim().isEmpty
            ? '?'
            : (bankName ?? '?').trim()[0].toUpperCase(),
        color: _brandColors[key] ?? Colors.grey,
        size: size,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.letter,
    required this.color,
    required this.size,
  });

  final String letter;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.6,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}