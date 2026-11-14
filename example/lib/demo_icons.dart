import 'package:flutter/widgets.dart';

enum DemoIconType {
  navigationView,
  splitView,
  viewSwitcher,
  tabView,
  bottomSheet,
  carousel,
  boxedList,
  toggleGroup,
  buttons,
  banner,
  toasts,
  spinner,
  alertDialog,
  aboutDialog,
  clamp,
  wrapBox,
  multiLayoutView,
  styleClasses,
  animations,
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
    final strokeWidth = (s * 0.115).clamp(1.85, 9.5);
    final thinStroke = (s * 0.07).clamp(1.2, 6.0);

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
        final u = s / 16.0;
        final bracket = Path()
          ..moveTo(5.0 * u, 2.0 * u)
          ..lineTo(12.0 * u, 2.0 * u)
          ..quadraticBezierTo(14.0 * u, 2.0 * u, 14.0 * u, 4.0 * u)
          ..lineTo(14.0 * u, 12.0 * u)
          ..quadraticBezierTo(14.0 * u, 14.0 * u, 12.0 * u, 14.0 * u)
          ..lineTo(5.0 * u, 14.0 * u);
        canvas.drawPath(bracket, strokePaint);
        final arrow = Path()
          ..moveTo(6.0 * u, 5.0 * u)
          ..lineTo(3.0 * u, 8.0 * u)
          ..lineTo(6.0 * u, 11.0 * u)
          ..moveTo(9.0 * u, 8.0 * u)
          ..lineTo(3.0 * u, 8.0 * u);
        canvas.drawPath(arrow, strokePaint);
        break;

      case DemoIconType.banner:
        final u = s / 16.0;
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5 * u, 1.5 * u, 13.0 * u, 13.0 * u),
          Radius.circular(2.0 * u),
        );
        canvas.drawRRect(frame, strokePaint);
        canvas.drawLine(
          Offset(1.5 * u, 10.5 * u),
          Offset(14.5 * u, 10.5 * u),
          thinPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4.5 * u, 4.5 * u, 7.0 * u, 3.0 * u),
            Radius.circular(1.5 * u),
          ),
          thinPaint,
        );
        break;

      case DemoIconType.tabView:
        final u = s / 16.0;
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5 * u, 1.5 * u, 13.0 * u, 13.0 * u),
          Radius.circular(2.0 * u),
        );
        canvas.drawRRect(frame, strokePaint);
        final tabPath = Path()
          ..moveTo(6.0 * u, 1.5 * u)
          ..lineTo(6.6 * u, 4.4 * u)
          ..quadraticBezierTo(6.9 * u, 6.0 * u, 8.6 * u, 6.0 * u)
          ..lineTo(14.5 * u, 6.0 * u);
        canvas.drawPath(tabPath, strokePaint);
        break;

      case DemoIconType.bottomSheet:
        final u = s / 16.0;
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5 * u, 1.5 * u, 13.0 * u, 13.0 * u),
          Radius.circular(2.0 * u),
        );
        canvas.drawRRect(frame, strokePaint);
        final sheet = RRect.fromRectAndCorners(
          Rect.fromLTWH(1.5 * u, 8.0 * u, 13.0 * u, 6.5 * u),
          topLeft: Radius.circular(2.0 * u),
          topRight: Radius.circular(2.0 * u),
          bottomLeft: Radius.circular(2.0 * u),
          bottomRight: Radius.circular(2.0 * u),
        );
        canvas.drawRRect(sheet, strokePaint);
        canvas.drawLine(
          Offset(6.5 * u, 10.5 * u),
          Offset(9.5 * u, 10.5 * u),
          thinPaint,
        );
        break;

      case DemoIconType.toasts:
        final u = s / 16.0;
        // Bell outline matching widget-toast.svg
        final bell = Path()
          ..moveTo(8.0 * u, 1.5 * u)
          ..lineTo(8.0 * u, 3.0 * u)
          ..moveTo(2.0 * u, 12.0 * u)
          ..quadraticBezierTo(4.0 * u, 12.0 * u, 4.0 * u, 10.0 * u)
          ..lineTo(4.0 * u, 7.0 * u)
          ..arcToPoint(
            Offset(12.0 * u, 7.0 * u),
            radius: Radius.circular(4.0 * u),
          )
          ..lineTo(12.0 * u, 10.0 * u)
          ..quadraticBezierTo(12.0 * u, 12.0 * u, 14.0 * u, 12.0 * u)
          ..lineTo(2.0 * u, 12.0 * u);
        canvas.drawPath(bell, strokePaint);
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(8.0 * u, 13.0 * u),
            width: 4.0 * u,
            height: 3.6 * u,
          ),
          0,
          3.14159,
          false,
          strokePaint,
        );
        break;

      case DemoIconType.spinner:
        final u = s / 16.0;
        final trackPaint = Paint()
          ..color = color.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawCircle(Offset(8.0 * u, 8.0 * u), 6.0 * u, trackPaint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(8.0 * u, 8.0 * u), radius: 6.0 * u),
          -1.57,
          2.1,
          false,
          strokePaint,
        );
        break;

      case DemoIconType.alertDialog:
        final u = s / 16.0;
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5 * u, 1.5 * u, 13.0 * u, 13.0 * u),
          Radius.circular(2.0 * u),
        );
        canvas.drawRRect(frame, strokePaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4.5 * u, 9.5 * u, 7.0 * u, 3.0 * u),
            Radius.circular(1.5 * u),
          ),
          thinPaint,
        );
        break;

      case DemoIconType.aboutDialog:
        final u = s / 16.0;
        canvas.drawCircle(Offset(8.0 * u, 8.0 * u), 6.5 * u, strokePaint);
        canvas.drawCircle(Offset(8.0 * u, 5.0 * u), strokeWidth * 0.55, fillPaint);
        final iPath = Path()
          ..moveTo(7.0 * u, 8.0 * u)
          ..lineTo(8.0 * u, 8.0 * u)
          ..lineTo(8.0 * u, 11.2 * u);
        canvas.drawPath(iPath, strokePaint);
        break;

      case DemoIconType.clamp:
        final u = s / 16.0;
        final leftChevron = Path()
          ..moveTo(2.0 * u, 5.0 * u)
          ..lineTo(5.0 * u, 8.0 * u)
          ..lineTo(2.0 * u, 11.0 * u);
        final rightChevron = Path()
          ..moveTo(14.0 * u, 5.0 * u)
          ..lineTo(11.0 * u, 8.0 * u)
          ..lineTo(14.0 * u, 11.0 * u);
        canvas.drawPath(leftChevron, strokePaint);
        canvas.drawPath(rightChevron, strokePaint);
        break;

      case DemoIconType.wrapBox:
        final u = s / 16.0;
        canvas.drawLine(Offset(3.0 * u, 4.0 * u), Offset(11.0 * u, 4.0 * u), strokePaint);
        canvas.drawLine(Offset(3.0 * u, 8.0 * u), Offset(13.0 * u, 8.0 * u), strokePaint);
        canvas.drawLine(Offset(3.0 * u, 12.0 * u), Offset(7.0 * u, 12.0 * u), strokePaint);
        break;

      case DemoIconType.multiLayoutView:
        final u = s / 16.0;
        final back = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5 * u, 1.5 * u, 8.5 * u, 10.5 * u),
          Radius.circular(2.0 * u),
        );
        final front = RRect.fromRectAndRadius(
          Rect.fromLTWH(4.5 * u, 6.0 * u, 10.0 * u, 8.5 * u),
          Radius.circular(2.0 * u),
        );
        canvas.drawRRect(back, strokePaint);
        canvas.drawRRect(front, strokePaint);
        break;

      case DemoIconType.styleClasses:
        final u = s / 16.0;
        // Paintbrush matching style-classes.svg
        final handle = Path()
          ..moveTo(6.0 * u, 3.0 * u)
          ..lineTo(6.0 * u, 5.0 * u)
          ..lineTo(3.0 * u, 5.0 * u)
          ..quadraticBezierTo(1.5 * u, 5.0 * u, 1.5 * u, 7.0 * u)
          ..lineTo(1.5 * u, 8.0 * u)
          ..lineTo(14.5 * u, 8.0 * u)
          ..lineTo(14.5 * u, 7.0 * u)
          ..quadraticBezierTo(14.5 * u, 5.0 * u, 13.0 * u, 5.0 * u)
          ..lineTo(10.0 * u, 5.0 * u)
          ..lineTo(10.0 * u, 3.0 * u)
          ..arcToPoint(
            Offset(6.0 * u, 3.0 * u),
            radius: Radius.circular(2.0 * u),
            clockwise: false,
          );
        final bristles = Path()
          ..moveTo(3.0 * u, 8.0 * u)
          ..lineTo(1.8 * u, 13.0 * u)
          ..quadraticBezierTo(1.5 * u, 14.5 * u, 3.0 * u, 14.5 * u)
          ..lineTo(6.0 * u, 14.5 * u)
          ..lineTo(7.0 * u, 12.5 * u)
          ..lineTo(8.0 * u, 14.5 * u)
          ..lineTo(10.0 * u, 14.5 * u)
          ..lineTo(11.0 * u, 12.0 * u)
          ..lineTo(12.0 * u, 14.5 * u)
          ..lineTo(13.0 * u, 14.5 * u)
          ..quadraticBezierTo(14.5 * u, 14.5 * u, 14.2 * u, 13.0 * u)
          ..lineTo(13.0 * u, 8.0 * u);
        canvas.drawPath(handle, strokePaint);
        canvas.drawPath(bristles, strokePaint);
        break;

      case DemoIconType.animations:
        final u = s / 16.0;
        // Bouncing ball curve + ball matching animations.svg
        final bounce = Path()
          ..moveTo(1.5 * u, 1.5 * u)
          ..cubicTo(3.8 * u, 4.6 * u, 4.5 * u, 9.8 * u, 5.0 * u, 14.5 * u)
          ..cubicTo(5.0 * u, 9.7 * u, 6.5 * u, 5.0 * u, 9.5 * u, 5.0 * u)
          ..quadraticBezierTo(11.5 * u, 5.0 * u, 12.0 * u, 8.0 * u);
        canvas.drawPath(bounce, strokePaint);
        canvas.drawCircle(Offset(13.0 * u, 13.0 * u), 1.8 * u, strokePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DemoWidgetIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}

