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
  avatar,
  spinner,
  alertDialog,
  aboutDialog,
  clamp,
  wrapBox,
  multiLayoutView,
  styleClasses,
  animations,
  clockWorld,
  clockAlarm,
  clockStopwatch,
  clockTimer,
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
    // Sidebar (16px) uses standard 2px SVG weight; 128px statuspage uses ~8px
    final strokeWidth = s <= 24.0
        ? (s * 0.125).clamp(1.8, 2.5)
        : (s * 0.0625).clamp(2.5, 8.2);
    final thinStroke = s <= 24.0
        ? (s * 0.085).clamp(1.2, 1.9)
        : (s * 0.046).clamp(2.0, 6.0);

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
        final u = s / 16.0;
        final rect = Rect.fromLTRB(1.0 * u, 1.0 * u, 15.0 * u, 14.0 * u);
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(1.92 * u),
        );
        canvas.drawRRect(rrect, strokePaint);
        final listLinePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawLine(
          Offset(1.0 * u, 5.5 * u),
          Offset(15.0 * u, 5.5 * u),
          listLinePaint,
        );
        canvas.drawLine(
          Offset(1.0 * u, 9.5 * u),
          Offset(15.0 * u, 9.5 * u),
          listLinePaint,
        );
        break;

      case DemoIconType.toggleGroup:
        final u = s / 16.0;
        final inner = RRect.fromRectAndRadius(
          Rect.fromLTWH(3.0 * u, 4.0 * u, 7.0 * u, 8.0 * u),
          Radius.circular(1.04 * u),
        );
        final toggleFill = Paint()
          ..color = color.withValues(alpha: 0.30)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(inner, toggleFill);
        final outer = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.0 * u, 2.0 * u, 14.0 * u, 12.0 * u),
          Radius.circular(3.31 * u),
        );
        canvas.drawRRect(outer, strokePaint);
        break;

      case DemoIconType.buttons:
        final u = s / 16.0;
        final topPill = RRect.fromRectAndRadius(
          Rect.fromLTRB(1.0 * u, 2.0 * u, 15.0 * u, 6.0 * u),
          Radius.circular(2.0 * u),
        );
        final bottomPill = RRect.fromRectAndRadius(
          Rect.fromLTRB(1.0 * u, 9.0 * u, 15.0 * u, 13.0 * u),
          Radius.circular(2.0 * u),
        );
        canvas.drawRRect(topPill, strokePaint);
        canvas.drawRRect(bottomPill, strokePaint);
        break;

      case DemoIconType.carousel:
        final u = s / 16.0;
        final carouselPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s <= 24 ? strokeWidth : s * 0.0625
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final center = RRect.fromRectAndRadius(
          Rect.fromLTRB(4.0 * u, 2.0 * u, 12.0 * u, 12.0 * u),
          Radius.circular(2.0 * u),
        );
        canvas.drawRRect(center, carouselPaint);
        canvas.drawLine(
          Offset(1.0 * u, 4.0 * u),
          Offset(1.0 * u, 10.0 * u),
          carouselPaint,
        );
        canvas.drawLine(
          Offset(15.0 * u, 4.0 * u),
          Offset(15.0 * u, 10.0 * u),
          carouselPaint,
        );
        final dotPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        final dotRadius = carouselPaint.strokeWidth * 0.55;
        canvas.drawCircle(Offset(5.0 * u, 15.0 * u), dotRadius, dotPaint);
        canvas.drawCircle(Offset(8.0 * u, 15.0 * u), dotRadius, dotPaint);
        canvas.drawCircle(Offset(11.0 * u, 15.0 * u), dotRadius, dotPaint);
        break;

      case DemoIconType.viewSwitcher:
        final u = s / 16.0;
        final outerPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s <= 24 ? strokeWidth : s * 0.0625
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final innerPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s <= 24 ? strokeWidth * 0.55 : s * 0.028
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round;
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTRB(1.0 * u, 1.0 * u, 15.0 * u, 15.0 * u),
          Radius.circular(2.2 * u),
        );
        canvas.drawRRect(frame, outerPaint);
        canvas.drawLine(
          Offset(1.2 * u, 4.5 * u),
          Offset(14.8 * u, 4.5 * u),
          innerPaint,
        );
        canvas.drawLine(
          Offset(5.65 * u, 1.2 * u),
          Offset(5.65 * u, 4.5 * u),
          innerPaint,
        );
        canvas.drawLine(
          Offset(10.35 * u, 1.2 * u),
          Offset(10.35 * u, 4.5 * u),
          innerPaint,
        );
        break;

      case DemoIconType.splitView:
        final u = s / 16.0;
        final sidebarFillPaint = Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        final sidebarPane = RRect.fromRectAndCorners(
          Rect.fromLTRB(1.0 * u, 2.0 * u, 6.5 * u, 14.0 * u),
          topLeft: Radius.circular(2.0 * u),
          bottomLeft: Radius.circular(2.0 * u),
        );
        canvas.drawRRect(sidebarPane, sidebarFillPaint);
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTRB(1.0 * u, 2.0 * u, 15.0 * u, 14.0 * u),
          Radius.circular(2.0 * u),
        );
        canvas.drawRRect(frame, strokePaint);
        canvas.drawLine(
          Offset(6.5 * u, 2.0 * u),
          Offset(6.5 * u, 14.0 * u),
          thinPaint,
        );
        break;

      case DemoIconType.navigationView:
        final u = s / 16.0;
        final bracketPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round;
        final bracket = Path()
          ..moveTo(5.0 * u, 2.0 * u)
          ..lineTo(12.0 * u, 2.0 * u)
          ..quadraticBezierTo(14.0 * u, 2.0 * u, 14.0 * u, 4.0 * u)
          ..lineTo(14.0 * u, 12.0 * u)
          ..quadraticBezierTo(14.0 * u, 14.0 * u, 12.0 * u, 14.0 * u)
          ..lineTo(5.0 * u, 14.0 * u);
        canvas.drawPath(bracket, bracketPaint);
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
        final openFrame = Path()
          ..moveTo(1.5 * u, 1.5 * u)
          ..lineTo(12.5 * u, 1.5 * u)
          ..arcToPoint(
            Offset(14.5 * u, 3.5 * u),
            radius: Radius.circular(2.0 * u),
          )
          ..lineTo(14.5 * u, 12.5 * u)
          ..arcToPoint(
            Offset(12.5 * u, 14.5 * u),
            radius: Radius.circular(2.0 * u),
          )
          ..lineTo(8.5 * u, 14.5 * u);
        canvas.drawPath(openFrame, strokePaint);
        final bannerDetailPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = thinPaint.strokeWidth * 0.65
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawLine(
          Offset(1.5 * u, 10.5 * u),
          Offset(14.5 * u, 10.5 * u),
          bannerDetailPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(5.0 * u, 4.5 * u, 6.5 * u, 3.0 * u),
            Radius.circular(1.5 * u),
          ),
          bannerDetailPaint,
        );
        break;

      case DemoIconType.tabView:
        final u = s / 16.0;
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTRB(1.0 * u, 1.0 * u, 15.0 * u, 15.0 * u),
          Radius.circular(2.05 * u),
        );
        canvas.drawRRect(frame, strokePaint);
        final tabPath = Path()
          ..moveTo(6.0 * u, 1.0 * u)
          ..lineTo(6.67 * u, 4.36 * u)
          ..cubicTo(
            6.86 * u,
            5.31 * u,
            7.70 * u,
            6.0 * u,
            8.68 * u,
            6.0 * u,
          )
          ..lineTo(15.0 * u, 6.0 * u);
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

      case DemoIconType.avatar:
        final u = s / 16.0;
        canvas.drawCircle(Offset(8.0 * u, 5.0 * u), 3.75 * u, strokePaint);
        final shoulders = Path()
          ..moveTo(1.5 * u, 14.5 * u)
          ..arcToPoint(
            Offset(5.25 * u, 10.75 * u),
            radius: Radius.circular(3.75 * u),
          )
          ..lineTo(10.75 * u, 10.75 * u)
          ..arcToPoint(
            Offset(14.5 * u, 14.5 * u),
            radius: Radius.circular(3.75 * u),
          );
        canvas.drawPath(shoulders, strokePaint);
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

      case DemoIconType.clockWorld:
        final u = s / 16.0;
        canvas.drawCircle(Offset(8.0 * u, 8.0 * u), 7.0 * u, strokePaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(8.0 * u, 8.0 * u),
            width: 7.0 * u,
            height: 14.0 * u,
          ),
          thinPaint,
        );
        final latTop = Path()
          ..moveTo(2.25 * u, 4.07 * u)
          ..quadraticBezierTo(8.0 * u, 6.2 * u, 13.79 * u, 4.05 * u);
        final latBot = Path()
          ..moveTo(2.25 * u, 11.95 * u)
          ..quadraticBezierTo(8.0 * u, 9.8 * u, 13.79 * u, 11.98 * u);
        canvas.drawPath(latTop, thinPaint);
        canvas.drawPath(latBot, thinPaint);
        break;

      case DemoIconType.clockAlarm:
        final u = s / 16.0;
        canvas.drawCircle(Offset(8.0 * u, 8.0 * u), 5.0 * u, strokePaint);
        // Bells
        canvas.drawLine(
            Offset(1.8 * u, 3.8 * u), Offset(3.8 * u, 1.8 * u), strokePaint);
        canvas.drawLine(
            Offset(14.2 * u, 3.8 * u), Offset(12.2 * u, 1.8 * u), strokePaint);
        // Feet
        canvas.drawLine(
            Offset(5.0 * u, 12.0 * u), Offset(4.0 * u, 14.0 * u), strokePaint);
        canvas.drawLine(Offset(11.0 * u, 12.0 * u), Offset(12.0 * u, 14.0 * u),
            strokePaint);
        // Hands
        final hands = Path()
          ..moveTo(8.0 * u, 5.0 * u)
          ..lineTo(8.0 * u, 8.0 * u)
          ..lineTo(10.0 * u, 9.0 * u);
        canvas.drawPath(hands, thinPaint);
        break;

      case DemoIconType.clockStopwatch:
        final u = s / 16.0;
        canvas.drawCircle(Offset(8.0 * u, 9.0 * u), 5.0 * u, strokePaint);
        // Top crown + side button
        canvas.drawLine(
            Offset(6.0 * u, 1.0 * u), Offset(10.0 * u, 1.0 * u), strokePaint);
        canvas.drawLine(
            Offset(8.0 * u, 1.0 * u), Offset(8.0 * u, 4.0 * u), strokePaint);
        canvas.drawLine(
            Offset(2.0 * u, 4.5 * u), Offset(3.4 * u, 3.1 * u), strokePaint);
        // Hand
        canvas.drawLine(
            Offset(8.0 * u, 9.0 * u), Offset(10.0 * u, 7.0 * u), thinPaint);
        break;

      case DemoIconType.clockTimer:
        final u = s / 16.0;
        // Top and bottom bars
        canvas.drawLine(
            Offset(2.5 * u, 1.0 * u), Offset(13.5 * u, 1.0 * u), strokePaint);
        canvas.drawLine(
            Offset(2.5 * u, 14.0 * u), Offset(13.5 * u, 14.0 * u), strokePaint);
        // Hourglass sides
        final left = Path()
          ..moveTo(4.0 * u, 1.0 * u)
          ..lineTo(4.0 * u, 4.0 * u)
          ..quadraticBezierTo(4.0 * u, 5.0 * u, 4.8 * u, 5.55 * u)
          ..lineTo(7.0 * u, 7.0 * u)
          ..lineTo(7.0 * u, 8.0 * u)
          ..lineTo(4.8 * u, 9.45 * u)
          ..quadraticBezierTo(4.0 * u, 10.0 * u, 4.0 * u, 11.0 * u)
          ..lineTo(4.0 * u, 14.0 * u);
        final right = Path()
          ..moveTo(11.0 * u, 1.0 * u)
          ..lineTo(11.0 * u, 4.0 * u)
          ..quadraticBezierTo(11.0 * u, 5.0 * u, 10.2 * u, 5.55 * u)
          ..lineTo(8.0 * u, 7.0 * u)
          ..lineTo(8.0 * u, 8.0 * u)
          ..lineTo(10.2 * u, 9.45 * u)
          ..quadraticBezierTo(11.0 * u, 10.0 * u, 11.0 * u, 11.0 * u)
          ..lineTo(11.0 * u, 14.0 * u);
        canvas.drawPath(left, strokePaint);
        canvas.drawPath(right, strokePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DemoWidgetIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}

