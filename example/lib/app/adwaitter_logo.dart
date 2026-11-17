import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

/// Crisp vector symbolic outline logo for Adwaitter Demo, matching
/// `example/assets/icons/libadwaiiter-symbolic-outline.svg`.
class AdwaitterSymbolicLogo extends StatelessWidget {
  const AdwaitterSymbolicLogo({
    super.key,
    this.size = 128,
    this.color,
    this.strokeWidth = 1.1,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ??
        IconTheme.of(context).color ??
        AdwTheme.of(context).colors.windowForeground;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AdwaitterSymbolicOutlinePainter(
          color: resolvedColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _AdwaitterSymbolicOutlinePainter extends CustomPainter {
  const _AdwaitterSymbolicOutlinePainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // SVG viewBox is 16x16 with transform:
    // translate(8, 8) scale(0.25) translate(-60, -64)
    final scale = size.width / 16.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      // Scale stroke proportionally with icon size (1.1px at 16px, 8.8px at 128px).
      ..strokeWidth = strokeWidth / 0.25;

    canvas.save();
    canvas.scale(scale, scale);
    canvas.translate(8, 8);
    canvas.scale(0.25, 0.25);
    canvas.translate(-60, -64);

    // 1. Top ribbon
    final p1 = Path()
      ..moveTo(48, 53.5)
      ..lineTo(66, 35.5)
      ..lineTo(82, 35.5)
      ..lineTo(56, 61.5)
      ..close();
    canvas.drawPath(p1, paint);

    // 2. Large left triangle
    final p2 = Path()
      ..moveTo(35, 66.5)
      ..lineTo(61, 66.5)
      ..lineTo(61, 92.5)
      ..close();
    canvas.drawPath(p2, paint);

    // 3. Center diamond
    final p3 = Path()
      ..moveTo(61, 66.5)
      ..lineTo(69, 58.5)
      ..lineTo(77, 66.5)
      ..lineTo(69, 74.5)
      ..close();
    canvas.drawPath(p3, paint);

    // 4. Top-right triangle
    final p4 = Path()
      ..moveTo(69, 58.5)
      ..lineTo(85, 58.5)
      ..lineTo(77, 66.5)
      ..close();
    canvas.drawPath(p4, paint);

    // 5. Bottom-right triangle
    final p5 = Path()
      ..moveTo(69, 74.5)
      ..lineTo(77, 66.5)
      ..lineTo(85, 74.5)
      ..close();
    canvas.drawPath(p5, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_AdwaitterSymbolicOutlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
