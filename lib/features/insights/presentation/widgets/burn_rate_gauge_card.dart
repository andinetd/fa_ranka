import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:faranka/app/core/theme/app_colors.dart';
import 'package:faranka/app/core/services/app_settings_service.dart';
import 'package:faranka/features/insights/presentation/widgets/insight_data.dart';

class BurnRateGaugeCard extends StatelessWidget {
  final BurnRateSnapshot snapshot;

  const BurnRateGaugeCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final ratio = snapshot.ratio.isFinite ? snapshot.ratio : 0.0;
    final displayRatio = ratio.clamp(0.0, 2.0);
    final label = ratio < 0.85
        ? 'Below average'
        : ratio <= 1.15
        ? 'Near average'
        : 'Burning fast';
    final labelColor = ratio < 0.85
        ? Colors.green.shade700
        : ratio <= 1.15
        ? Colors.amber.shade800
        : Colors.red.shade700;

    return Column(
      children: [
        SizedBox(
          height: 290,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: BurnRateGaugePainter(displayRatio: displayRatio),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${snapshot.ratio.toStringAsFixed(2)}x',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetric('This month', snapshot.currentTotal, isDark),
            _buildMetric('Avg month', snapshot.historicalAverage, isDark),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildZoneDot(Colors.green.shade500, 'Green zone'),
            const SizedBox(width: 10),
            _buildZoneDot(Colors.amber.shade600, 'Amber zone'),
            const SizedBox(width: 10),
            _buildZoneDot(Colors.red.shade500, 'Red zone'),
          ],
        ),
      ],
    );
  }

  Widget _buildMetric(String label, double value, bool isDark) {
    final useCompact = AppSettingsService.getBoolSync(AppSettingsService.keyCompactNumbers, fallback: true);
    final metricCurrency = useCompact
        ? NumberFormat.compactCurrency(symbol: 'ETB ')
        : NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? DarkAppColors.balanceCardMuted : AppColors.balanceCardMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metricCurrency.format(value),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? DarkAppColors.appBarForeground : AppColors.appBarForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildZoneDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.balanceCardMuted,
          ),
        ),
      ],
    );
  }
}

class BurnRateGaugePainter extends CustomPainter {
  final double displayRatio;

  BurnRateGaugePainter({required this.displayRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.86);
    final radius = min(size.width / 2 - 12, size.height * 0.76);
    final strokeWidth = 22.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double ratioToAngle(double ratio) {
      return pi + (ratio / 2.0) * pi;
    }

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.black.withValues(alpha: 0.05);
    canvas.drawArc(rect, pi, -pi, false, trackPaint);

    void drawZone(double startRatio, double endRatio, Color color) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = color;

      final startAngle = pi - (startRatio / 2.0) * pi;
      final sweepAngle = -((endRatio - startRatio) / 2.0) * pi;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    drawZone(0.0, 0.85, Colors.green.shade400);
    drawZone(0.85, 1.15, Colors.amber.shade400);
    drawZone(1.15, 2.0, Colors.red.shade400);

    for (final tickRatio in [0.0, 0.5, 1.0, 1.5, 2.0]) {
      final angle = ratioToAngle(tickRatio);
      final outer = Offset(
        center.dx + cos(angle) * (radius + 2),
        center.dy + sin(angle) * (radius + 2),
      );
      final inner = Offset(
        center.dx + cos(angle) * (radius - 12),
        center.dy + sin(angle) * (radius - 12),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..strokeWidth = 1.2,
      );
    }

    final needleAngle = ratioToAngle(displayRatio);
    final needleEnd = Offset(
      center.dx + cos(needleAngle) * (radius - 18),
      center.dy + sin(needleAngle) * (radius - 18),
    );

    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = displayRatio < 0.85
            ? Colors.green.shade700
            : displayRatio <= 1.15
            ? Colors.amber.shade700
            : Colors.red.shade700
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 11, Paint()..color = Colors.black87);
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant BurnRateGaugePainter oldDelegate) {
    return oldDelegate.displayRatio != displayRatio;
  }
}
