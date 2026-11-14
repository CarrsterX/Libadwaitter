import 'package:flutter/widgets.dart';

enum DemoIconType {
  navigationView,
  splitView,
  viewSwitcher,
  carousel,
  boxedList,
  toggleGroup,
  buttons,
  banner,
}

/// Crisp vector symbolic icons matching the `adwaita-1-demo` widget icons.
class DemoWidgetIcon extends StatelessWidget {
  final DemoIconType type;
  final double? size;
  final Color? color;

  const DemoWidgetIcon(
    this.type, {
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 16.0;
    final resolvedColor =
        color ?? iconTheme.color ?? const Color(0xFFFFFFFF);

    return SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: CustomPaint(
        painter: _DemoWidgetIconPainter(
          type: type,
          color: resolvedColor,
        ),
      ),
    );
  }
}

class _DemoWidgetIconPainter extends CustomPainter {
  final DemoIconType type;
  final Color color;

  const _DemoWidgetIconPainter({
    required this.type,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final strokeWidth = (s * 0.068).clamp(1.25, 6.5);
    final thinStroke = (s * 0.048).clamp(1.1, 4.5);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thinStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case DemoIconType.boxedList:
        final rect = Rect.fromLTWH(s * 0.09, s * 0.13, s * 0.82, s * 0.74);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.14));
        canvas.drawRRect(rrect, strokePaint);
        final inset = strokeWidth * 0.45;
        canvas.drawLine(
          Offset(s * 0.09 + inset, s * 0.377),
          Offset(s * 0.91 - inset, s * 0.377),
          thinPaint,
        );
        canvas.drawLine(
          Offset(s * 0.09 + inset, s * 0.623),
          Offset(s * 0.91 - inset, s * 0.623),
          thinPaint,
        );
        break;

      case DemoIconType.toggleGroup:
        final outer = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.10, s * 0.20, s * 0.80, s * 0.60),
          Radius.circular(s * 0.16),
        );
        canvas.drawRRect(outer, strokePaint);
        final inner = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.22, s * 0.32, s * 0.26, s * 0.36),
          Radius.circular(s * 0.08),
        );
        canvas.drawRRect(inner, fillPaint);
        break;

      case DemoIconType.buttons:
        final topPill = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.12, s * 0.16, s * 0.76, s * 0.28),
          Radius.circular(s * 0.14),
        );
        final bottomPill = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.12, s * 0.56, s * 0.76, s * 0.28),
          Radius.circular(s * 0.14),
        );
        canvas.drawRRect(topPill, strokePaint);
        canvas.drawRRect(bottomPill, strokePaint);
        break;

      case DemoIconType.carousel:
        final center = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.28, s * 0.16, s * 0.44, s * 0.68),
          Radius.circular(s * 0.10),
        );
        canvas.drawRRect(center, strokePaint);
        canvas.drawLine(
          Offset(s * 0.12, s * 0.32),
          Offset(s * 0.12, s * 0.68),
          strokePaint,
        );
        canvas.drawLine(
          Offset(s * 0.88, s * 0.32),
          Offset(s * 0.88, s * 0.68),
          strokePaint,
        );
        break;

      case DemoIconType.viewSwitcher:
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.12, s * 0.16, s * 0.76, s * 0.68),
          Radius.circular(s * 0.12),
        );
        canvas.drawRRect(frame, strokePaint);
        canvas.drawLine(
          Offset(s * 0.13, s * 0.42),
          Offset(s * 0.87, s * 0.42),
          thinPaint,
        );
        canvas.drawLine(
          Offset(s * 0.50, s * 0.17),
          Offset(s * 0.50, s * 0.42),
          thinPaint,
        );
        break;

      case DemoIconType.splitView:
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.10, s * 0.16, s * 0.80, s * 0.68),
          Radius.circular(s * 0.12),
        );
        canvas.drawRRect(frame, strokePaint);
        canvas.drawLine(
          Offset(s * 0.40, s * 0.17),
          Offset(s * 0.40, s * 0.83),
          thinPaint,
        );
        break;

      case DemoIconType.navigationView:
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.22, s * 0.16, s * 0.66, s * 0.68),
          Radius.circular(s * 0.12),
        );
        canvas.drawRRect(frame, strokePaint);
        canvas.drawLine(
          Offset(s * 0.10, s * 0.50),
          Offset(s * 0.54, s * 0.50),
          strokePaint,
        );
        canvas.drawLine(
          Offset(s * 0.40, s * 0.36),
          Offset(s * 0.54, s * 0.50),
          strokePaint,
        );
        canvas.drawLine(
          Offset(s * 0.40, s * 0.64),
          Offset(s * 0.54, s * 0.50),
          strokePaint,
        );
        break;

      case DemoIconType.banner:
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.12, s * 0.14, s * 0.76, s * 0.72),
          Radius.circular(s * 0.12),
        );
        canvas.drawRRect(frame, strokePaint);
        canvas.drawLine(
          Offset(s * 0.13, s * 0.42),
          Offset(s * 0.87, s * 0.42),
          thinPaint,
        );
        canvas.drawLine(
          Offset(s * 0.28, s * 0.28),
          Offset(s * 0.56, s * 0.28),
          thinPaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DemoWidgetIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}

