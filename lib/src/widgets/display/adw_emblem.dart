import 'package:flutter/widgets.dart';

import '../../theme/adw_theme.dart';

/// Official geometric Libadwaita emblem (designed by Jakub Steiner).
///
/// Renders the three distinctive triangles of Libadwaita using pure
/// native vector painting with customizable size, stroke, and color.
class AdwEmblem extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AdwEmblem({
    super.key,
    this.size = 120.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final effectiveColor = color ??
        theme.colors.secondaryForeground.withValues(alpha: theme.colors.isDark ? 0.45 : 0.35);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AdwEmblemPainter(
          color: effectiveColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _AdwEmblemPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _AdwEmblemPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 16.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Triangle 1: d="M 9 7 L 9 1 L 15 1 Z"
    path.moveTo(9 * scale, 7 * scale);
    path.lineTo(9 * scale, 1 * scale);
    path.lineTo(15 * scale, 1 * scale);
    path.close();

    // Triangle 2: d="M 14 7 L 9 7 L 14 12 Z"
    path.moveTo(14 * scale, 7 * scale);
    path.lineTo(9 * scale, 7 * scale);
    path.lineTo(14 * scale, 12 * scale);
    path.close();

    // Triangle 3: d="M 9 7 L 1 7 L 9 15 Z"
    path.moveTo(9 * scale, 7 * scale);
    path.lineTo(1 * scale, 7 * scale);
    path.lineTo(9 * scale, 15 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AdwEmblemPainter oldDelegate) {
    return color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
  }
}

