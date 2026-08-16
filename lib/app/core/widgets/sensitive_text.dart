import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/app/core/providers/sensitive_hide_provider.dart';

class SensitiveText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const SensitiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(sensitiveHideProvider);
    return Text(
      hidden ? '****' : text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

class ClosedEyeIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const ClosedEyeIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ClosedEyePainter(
          color: color ?? IconTheme.of(context).color ?? Colors.grey,
        ),
      ),
    );
  }
}

class _ClosedEyePainter extends CustomPainter {
  final Color color;

  _ClosedEyePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.35;

    // Eyelid seam — a gentle downward arc
    final path = Path();
    path.moveTo(cx - rx, cy);
    path.quadraticBezierTo(cx, cy + 2.5, cx + rx, cy);
    canvas.drawPath(path, paint);

    // Three lashes on top
    for (int i = -1; i <= 1; i++) {
      final lx = cx + i * rx * 0.5;
      final ly = cy + 1.5;
      canvas.drawLine(
        Offset(lx, ly),
        Offset(lx + i * 2.5, ly - 5.0),
        paint..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_ClosedEyePainter old) => old.color != color;
}
