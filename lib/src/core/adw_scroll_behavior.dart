import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../theme/adw_curves.dart';
import '../theme/adw_desktop_settings.dart';
import '../theme/adw_theme.dart';
import 'adw_scrollbar.dart';

/// Transversal scroll behavior for Libadwaitter applications (`AdwScrollBehavior`).
///
/// Mirrors GTK4 `GtkScrolledWindow` across the entire widget tree when injected
/// via [ScrollConfiguration] at the root of [AdwApplication]:
/// - Applies [ClampingScrollPhysics] (non-bouncing Linux/desktop bounds).
/// - Renders [AdwOverscrollIndicator] (GTK4 `overshoot` radial edge glow)
///   when a user drags, flings, or scrolls past content boundaries.
/// - Enables drag scrolling for touch, trackpad, stylus, and mouse devices.
class AdwScrollBehavior extends ScrollBehavior {
  /// Whether to render the GTK4-style radial overshoot glow at scroll bounds.
  final bool showOverscrollGlow;

  const AdwScrollBehavior({
    this.showOverscrollGlow = true,
  });

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return AdwScrollbar(
      axisDirection: details.direction,
      controller: details.controller,
      child: child,
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (!showOverscrollGlow) {
      return child;
    }

    return AdwOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }

  @override
  bool shouldNotify(covariant AdwScrollBehavior oldDelegate) {
    return showOverscrollGlow != oldDelegate.showOverscrollGlow;
  }
}

/// GTK4 `overshoot` radial edge-glow indicator (`AdwOverscrollIndicator`).
///
/// Replicates the `scrolledwindow overshoot.{top,bottom,left,right}` CSS node
/// from GNOME Libadwaita (`_scrolling.scss`), painting a soft elliptical radial
/// light gradient anchored to the leading or trailing edge when scrolling hits
/// a boundary via touch, drag, fling, mouse wheel, or trackpad.
class AdwOverscrollIndicator extends StatefulWidget {
  final AxisDirection axisDirection;
  final Widget child;
  final Color? color;

  const AdwOverscrollIndicator({
    super.key,
    required this.axisDirection,
    required this.child,
    this.color,
  });

  @override
  State<AdwOverscrollIndicator> createState() => _AdwOverscrollIndicatorState();
}

class _AdwOverscrollIndicatorState extends State<AdwOverscrollIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _leadingController;
  late final AnimationController _trailingController;

  double _leadingIntensity = 0.0;
  double _trailingIntensity = 0.0;

  bool _hasMetrics = false;
  double _pixels = 0.0;
  double _minScrollExtent = 0.0;
  double _maxScrollExtent = 0.0;

  @override
  void initState() {
    super.initState();
    _leadingController = AnimationController(
      vsync: this,
      duration: AdwCurves.normalDuration,
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          _leadingIntensity = 0.0;
        }
      });

    _trailingController = AnimationController(
      vsync: this,
      duration: AdwCurves.normalDuration,
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          _trailingIntensity = 0.0;
        }
      });
  }

  @override
  void dispose() {
    _leadingController.dispose();
    _trailingController.dispose();
    super.dispose();
  }

  void _updateMetrics(ScrollMetrics metrics) {
    _hasMetrics = true;
    _pixels = metrics.pixels;
    _minScrollExtent = metrics.minScrollExtent;
    _maxScrollExtent = metrics.maxScrollExtent;
  }

  void _triggerGlow({required bool isLeading, required double delta}) {
    if (delta == 0.0) return;

    const baseDuration = Duration(milliseconds: 420);
    final animDuration =
        AdwAnimationScope.maybeOf(context)?.settings.resolve(baseDuration) ??
            baseDuration;
    _leadingController.duration = animDuration;
    _trailingController.duration = animDuration;

    // Keep wheel/trackpad impulses subtle, matching native GTK4 overshoot.
    final impulse = (delta.abs() / 64.0).clamp(0.35, 1.0);

    if (isLeading) {
      _leadingIntensity = math.max(_leadingIntensity, impulse);
      if (animDuration == Duration.zero) {
        _leadingController.value = 0.0;
        _leadingIntensity = 0.0;
      } else {
        _leadingController.value = 1.0;
        _leadingController.reverse();
      }
    } else {
      _trailingIntensity = math.max(_trailingIntensity, impulse);
      if (animDuration == Duration.zero) {
        _trailingController.value = 0.0;
        _trailingIntensity = 0.0;
      } else {
        _trailingController.value = 1.0;
        _trailingController.reverse();
      }
    }
  }

  bool _handleScrollMetrics(ScrollMetricsNotification notification) {
    if (notification.depth == 0) {
      _updateMetrics(notification.metrics);
    }
    return false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) {
      return false;
    }

    _updateMetrics(notification.metrics);

    if (notification is OverscrollNotification) {
      final delta = notification.overscroll;
      if (delta == 0.0) return false;

      final isReversed = widget.axisDirection == AxisDirection.up ||
          widget.axisDirection == AxisDirection.left;
      final isLeading = isReversed ? delta > 0 : delta < 0;
      _triggerGlow(isLeading: isLeading, delta: delta);
    }

    return false;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_hasMetrics) return;
    // Do not show overshoot on non-scrollable views whose content fits completely.
    if (_maxScrollExtent <= _minScrollExtent) return;

    final axis = axisDirectionToAxis(widget.axisDirection);
    final delta = axis == Axis.vertical ? event.scrollDelta.dy : event.scrollDelta.dx;
    if (delta == 0.0) return;

    final isReversed = widget.axisDirection == AxisDirection.up ||
        widget.axisDirection == AxisDirection.left;
    final effectiveDelta = isReversed ? -delta : delta;

    // Check if scrolling past the leading or trailing boundary.
    if (effectiveDelta < 0 && _pixels + effectiveDelta < _minScrollExtent) {
      final overscroll = (_pixels + effectiveDelta) - _minScrollExtent;
      _triggerGlow(isLeading: true, delta: overscroll);
    } else if (effectiveDelta > 0 && _pixels + effectiveDelta > _maxScrollExtent) {
      final overscroll = (_pixels + effectiveDelta) - _maxScrollExtent;
      _triggerGlow(isLeading: false, delta: overscroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final effectiveColor = widget.color ??
        (theme.colors.isDark
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF000000));
    // Subtle GTK4 Libadwaita overshoot edge highlight.
    final maxOpacity = theme.colors.isDark ? 0.11 : 0.08;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _handleScrollMetrics,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: CustomPaint(
            foregroundPainter: _AdwOverscrollPainter(
              axis: axisDirectionToAxis(widget.axisDirection),
              color: effectiveColor,
              maxOpacity: maxOpacity,
              leadingProgress:
                  Curves.easeOutCubic.transform(_leadingController.value) *
                      _leadingIntensity,
              trailingProgress:
                  Curves.easeOutCubic.transform(_trailingController.value) *
                      _trailingIntensity,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _AdwOverscrollPainter extends CustomPainter {
  final Axis axis;
  final Color color;
  final double maxOpacity;
  final double leadingProgress;
  final double trailingProgress;

  const _AdwOverscrollPainter({
    required this.axis,
    required this.color,
    required this.maxOpacity,
    required this.leadingProgress,
    required this.trailingProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    if (leadingProgress > 0.001) {
      _paintEdgeGlow(canvas, size, isLeading: true, progress: leadingProgress);
    }
    if (trailingProgress > 0.001) {
      _paintEdgeGlow(canvas, size, isLeading: false, progress: trailingProgress);
    }
  }

  void _paintEdgeGlow(
    Canvas canvas,
    Size size, {
    required bool isLeading,
    required double progress,
  }) {
    final peakOpacity = (maxOpacity * progress).clamp(0.0, 1.0);
    // Matches GTK4 Libadwaita overshoot falloff:
    // crisp ~3px edge highlight (100% of peak) tapering into a very subtle 45px diffused tail.
    final glowColors = [
      color.withOpacity(peakOpacity),
      color.withOpacity(peakOpacity * 0.25),
      color.withOpacity(peakOpacity * 0.12),
      color.withOpacity(peakOpacity * 0.04),
      color.withOpacity(0.0),
    ];
    const stops = [0.0, 0.08, 0.35, 0.70, 1.0];

    // Unit circle shader scaled into an ellipse matching GTK4 `radial-gradient(farthest-side at ...)`.
    const unitRect = Rect.fromLTWH(-1.0, -1.0, 2.0, 2.0);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: glowColors,
        stops: stops,
      ).createShader(unitRect);

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    if (axis == Axis.vertical) {
      final glowHeight = 30.0 * (0.65 + 0.35 * progress);
      final radiusX = math.max(size.width * 0.85, 1.0);
      final edgeY = isLeading ? 0.0 : size.height;

      canvas.translate(size.width / 2, edgeY);
      canvas.scale(radiusX, glowHeight);
      canvas.drawCircle(Offset.zero, 1.0, paint);
    } else {
      final glowWidth = 30.0 * (0.65 + 0.35 * progress);
      final radiusY = math.max(size.height * 0.85, 1.0);
      final edgeX = isLeading ? 0.0 : size.width;

      canvas.translate(edgeX, size.height / 2);
      canvas.scale(glowWidth, radiusY);
      canvas.drawCircle(Offset.zero, 1.0, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AdwOverscrollPainter oldDelegate) {
    return axis != oldDelegate.axis ||
        color != oldDelegate.color ||
        maxOpacity != oldDelegate.maxOpacity ||
        leadingProgress != oldDelegate.leadingProgress ||
        trailingProgress != oldDelegate.trailingProgress;
  }
}
