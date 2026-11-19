import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

/// Crisp vector symbolic outline logo for Adwaitter Demo, matching
/// `example/assets/icons/libadwaiiter-symbolic-outline.svg`.
class AdwaitterSymbolicLogo extends StatelessWidget {
  const AdwaitterSymbolicLogo({
    super.key,
    this.size = 128,
    this.color,
    this.strokeWidth = 1.45,
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

/// Full-color Libadwaitter application icon matching `example/assets/icons/libadwaitter.svg`.
class AdwaitterAppLogo extends StatelessWidget {
  const AdwaitterAppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: const _AdwaitterAppLogoPainter()),
    );
  }
}

class _AdwaitterAppLogoPainter extends CustomPainter {
  const _AdwaitterAppLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 128.0;
    canvas.save();
    canvas.scale(scale, scale);

    const rect = Rect.fromLTWH(26, 24, 76, 76);
    const radius = Radius.circular(6);

    // 3D bottom bevel
    canvas.save();
    canvas.translate(64, 65.5);
    canvas.rotate(0.7853981633974483); // 45 deg
    canvas.translate(-64, -64);
    final bevelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF3584E4), Color(0xFF62A0EA), Color(0xFF3584E4)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), bevelPaint);
    canvas.restore();

    // Main gradient diamond
    canvas.save();
    canvas.translate(64, 62);
    canvas.rotate(0.7853981633974483);
    canvas.translate(-64, -62);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3584E4), Color(0xFF8FF0A4)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), bgPaint);
    canvas.restore();

    // White foreground geometry
    canvas.translate(2, 3.5);
    void drawPoly(List<Offset> pts, double opacity) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(
        path,
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }

    drawPoly(
      const [Offset(46, 50), Offset(64, 32), Offset(80, 32), Offset(54, 58)],
      0.92,
    );
    drawPoly(
      const [Offset(33, 63), Offset(59, 63), Offset(59, 89)],
      0.96,
    );
    drawPoly(
      const [Offset(59, 63), Offset(67, 55), Offset(75, 63), Offset(67, 71)],
      0.96,
    );
    drawPoly(
      const [Offset(67, 55), Offset(83, 55), Offset(75, 63)],
      0.72,
    );
    drawPoly(
      const [Offset(67, 71), Offset(75, 63), Offset(83, 71)],
      0.45,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_AdwaitterAppLogoPainter oldDelegate) => false;
}

/// Full-color Libadwaita Demo application icon matching `org.gnome.Adwaita1.Demo.svg`.
class LibadwaitaAppLogo extends StatelessWidget {
  const LibadwaitaAppLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: const _LibadwaitaAppLogoPainter()),
    );
  }
}

class _LibadwaitaAppLogoPainter extends CustomPainter {
  const _LibadwaitaAppLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 128.0;
    canvas.save();
    canvas.scale(scale, scale);

    const rect = Rect.fromLTWH(26, 24, 76, 76);
    const radius = Radius.circular(6);

    // 3D bottom bevel
    canvas.save();
    canvas.translate(64, 65.5);
    canvas.rotate(0.7853981633974483);
    canvas.translate(-64, -64);
    final bevelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF3584E4), Color(0xFF62A0EA), Color(0xFF3584E4)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), bevelPaint);
    canvas.restore();

    // Main gradient diamond
    canvas.save();
    canvas.translate(64, 62);
    canvas.rotate(0.7853981633974483);
    canvas.translate(-64, -62);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3584E4), Color(0xFF8FF0A4)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), bgPaint);
    canvas.restore();

    // Official 3 Libadwaita triangles (shifted -8, -6 in 128x128)
    canvas.translate(-8, -6);
    void drawTri(Offset a, Offset b, Offset c, double opacity) {
      final path = Path()..addPolygon([a, b, c], true);
      canvas.drawPath(
        path,
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }

    drawTri(const Offset(36, 68), const Offset(72, 68), const Offset(72, 104), 0.95);
    drawTri(const Offset(96, 44), const Offset(72, 44), const Offset(72, 68), 0.75);
    drawTri(const Offset(72, 68), const Offset(90, 68), const Offset(90, 86), 0.40);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LibadwaitaAppLogoPainter oldDelegate) => false;
}
