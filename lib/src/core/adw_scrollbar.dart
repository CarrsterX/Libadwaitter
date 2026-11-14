import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/adw_curves.dart';
import '../theme/adw_theme.dart';

/// Libadwaita / GTK4 overlay scrollbar indicator (`AdwScrollbar`).
///
/// Mirrors GTK4 `scrollbar.overlay-indicator`:
/// - Reserves zero layout space (overlays the trailing edge of the scrollable).
/// - Appears as a thin `3px` capsule-rounded pill whenever the pointer hovers
///   over the scrollable view or while scrolling is active.
/// - Smoothly expands to `7px` with higher contrast when hovering or dragging
///   the scrollbar hit area directly.
/// - Works automatically for all scrollables even when no explicit [ScrollController]
///   is provided.
class AdwScrollbar extends StatefulWidget {
  final AxisDirection axisDirection;
  final ScrollController? controller;
  final Widget child;

  const AdwScrollbar({
    super.key,
    required this.axisDirection,
    this.controller,
    required this.child,
  });

  @override
  State<AdwScrollbar> createState() => _AdwScrollbarState();
}

class _AdwScrollbarState extends State<AdwScrollbar> {
  bool _hasMetrics = false;
  double _pixels = 0.0;
  double _minScrollExtent = 0.0;
  double _maxScrollExtent = 0.0;
  double _viewportDimension = 0.0;

  bool _isViewHovered = false;
  bool _isThumbHovered = false;
  bool _isScrolling = false;
  bool _isDragging = false;

  Timer? _fadeTimer;
  double _dragStartOffset = 0.0;
  double _dragStartPixels = 0.0;

  @override
  void dispose() {
    _fadeTimer?.cancel();
    super.dispose();
  }

  void _updateMetrics(ScrollMetrics metrics) {
    final changed = !_hasMetrics ||
        _pixels != metrics.pixels ||
        _minScrollExtent != metrics.minScrollExtent ||
        _maxScrollExtent != metrics.maxScrollExtent ||
        _viewportDimension != metrics.viewportDimension;

    if (changed) {
      _hasMetrics = true;
      _pixels = metrics.pixels;
      _minScrollExtent = metrics.minScrollExtent;
      _maxScrollExtent = metrics.maxScrollExtent;
      _viewportDimension = metrics.viewportDimension;
    }
  }

  void _scheduleHide() {
    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isScrolling = false);
      }
    });
  }

  bool _handleScrollMetrics(ScrollMetricsNotification notification) {
    if (notification.depth == 0) {
      setState(() => _updateMetrics(notification.metrics));
    }
    return false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;

    setState(() {
      _updateMetrics(notification.metrics);
      if (notification is ScrollStartNotification ||
          notification is ScrollUpdateNotification) {
        _isScrolling = true;
        _scheduleHide();
      } else if (notification is ScrollEndNotification) {
        _scheduleHide();
      }
    });
    return false;
  }

  void _onDragStart(DragStartDetails details) {
    final controller = widget.controller;
    if (controller == null || !controller.hasClients) return;
    final axis = axisDirectionToAxis(widget.axisDirection);
    setState(() {
      _isDragging = true;
      _dragStartOffset = axis == Axis.vertical
          ? details.localPosition.dy
          : details.localPosition.dx;
      _dragStartPixels = controller.offset;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double trackLength, double thumbLength) {
    final controller = widget.controller;
    if (controller == null || !controller.hasClients) return;
    final maxTrackTravel = trackLength - thumbLength;
    final maxScrollTravel = _maxScrollExtent - _minScrollExtent;
    if (maxTrackTravel <= 0 || maxScrollTravel <= 0) return;

    final axis = axisDirectionToAxis(widget.axisDirection);
    final currentOffset = axis == Axis.vertical
        ? details.localPosition.dy
        : details.localPosition.dx;
    final deltaPx = currentOffset - _dragStartOffset;
    final isReversed = widget.axisDirection == AxisDirection.up ||
        widget.axisDirection == AxisDirection.left;
    final scrollDelta = (deltaPx / maxTrackTravel) * maxScrollTravel;
    final double target = (_dragStartPixels + (isReversed ? -scrollDelta : scrollDelta))
        .clamp(_minScrollExtent, _maxScrollExtent)
        .toDouble();

    controller.jumpTo(target);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isDragging) {
      setState(() => _isDragging = false);
      _scheduleHide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final isDark = theme.colors.isDark;
    final animDuration = AdwCurves.resolve(context, AdwCurves.scrollbarDuration);

    final isScrollable =
        _hasMetrics && (_maxScrollExtent > _minScrollExtent) && _viewportDimension > 0;
    final isVisible =
        isScrollable && (_isViewHovered || _isThumbHovered || _isScrolling || _isDragging);
    final isExpanded = _isThumbHovered || _isDragging;

    // GTK4 `scrollbar slider`: slim idle pill, 7px hovered (9px with border).
    final thickness = isExpanded
        ? (isDark ? 9.0 : 7.0)
        : (isDark ? 4.0 : 2.5);
    final troughThickness = isExpanded ? 8.0 : 0.0;
    final troughColor = isExpanded
        ? (isDark ? const Color(0x19FFFFFF) : const Color(0x19000000))
        : const Color(0x00000000);
    final thumbColor = isDark
        ? (_isDragging
            ? const Color(0x99FFFFFF)
            : isExpanded
                ? const Color(0x73FFFFFF)
                : const Color(0x33FFFFFF))
        : (_isDragging
            ? const Color(0x8C000000)
            : isExpanded
                ? const Color(0x66000000)
                : const Color(0x2E000000));
    final darkBorder = isDark
        ? Border.all(
            color: isExpanded ? const Color(0x8C000000) : const Color(0x59000000),
            width: 1.0,
          )
        : null;

    final axis = axisDirectionToAxis(widget.axisDirection);
    final isReversed = widget.axisDirection == AxisDirection.up ||
        widget.axisDirection == AxisDirection.left;

    return MouseRegion(
      onEnter: (_) => setState(() => _isViewHovered = true),
      onExit: (_) => setState(() => _isViewHovered = false),
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _handleScrollMetrics,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: Stack(
            children: [
              widget.child,
              if (isScrollable)
                Positioned(
                  top: axis == Axis.vertical ? 6.0 : null,
                  bottom: axis == Axis.vertical ? 6.0 : 2.0,
                  left: axis == Axis.horizontal ? 6.0 : null,
                  right: axis == Axis.vertical ? 2.0 : 6.0,
                  child: AnimatedOpacity(
                    opacity: isVisible ? 1.0 : 0.0,
                    duration: animDuration,
                    curve: AdwCurves.easeOutQuad,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final trackLength = axis == Axis.vertical
                            ? constraints.maxHeight
                            : constraints.maxWidth;
                        if (!trackLength.isFinite || trackLength <= 0) {
                          return const SizedBox.shrink();
                        }

                        final contentExtent =
                            (_maxScrollExtent - _minScrollExtent) + _viewportDimension;
                        final rawThumbLength =
                            (_viewportDimension / contentExtent) * trackLength;
                        final double thumbLength = rawThumbLength
                            .clamp(math.min(32.0, trackLength), trackLength)
                            .toDouble();
                        final double maxTrackTravel =
                            math.max(0.0, trackLength - thumbLength);
                        final double scrollFraction = (_maxScrollExtent - _minScrollExtent) > 0
                            ? ((_pixels - _minScrollExtent) /
                                    (_maxScrollExtent - _minScrollExtent))
                                .clamp(0.0, 1.0)
                                .toDouble()
                            : 0.0;
                        final thumbOffset = (isReversed
                                ? (1.0 - scrollFraction)
                                : scrollFraction) *
                            maxTrackTravel;

                        return MouseRegion(
                          onEnter: (_) => setState(() => _isThumbHovered = true),
                          onExit: (_) => setState(() => _isThumbHovered = false),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onVerticalDragStart:
                                axis == Axis.vertical ? _onDragStart : null,
                            onVerticalDragUpdate: axis == Axis.vertical
                                ? (d) => _onDragUpdate(d, trackLength, thumbLength)
                                : null,
                            onVerticalDragEnd:
                                axis == Axis.vertical ? _onDragEnd : null,
                            onHorizontalDragStart:
                                axis == Axis.horizontal ? _onDragStart : null,
                            onHorizontalDragUpdate: axis == Axis.horizontal
                                ? (d) => _onDragUpdate(d, trackLength, thumbLength)
                                : null,
                            onHorizontalDragEnd:
                                axis == Axis.horizontal ? _onDragEnd : null,
                            child: SizedBox(
                              width: axis == Axis.vertical ? 18.0 : trackLength,
                              height: axis == Axis.vertical ? trackLength : 18.0,
                              child: Stack(
                                children: [
                                  // Trough (track) revealed on scrollbar hover to show full scroll range
                                  AnimatedPositioned(
                                    duration: animDuration,
                                    curve: AdwCurves.easeOutQuad,
                                    top: axis == Axis.vertical ? 1.0 : null,
                                    bottom: axis == Axis.vertical
                                        ? 1.0
                                        : (isExpanded ? 6.0 : 0.0),
                                    left: axis == Axis.horizontal ? 1.0 : null,
                                    right: axis == Axis.vertical
                                        ? (isExpanded ? (isDark ? 7.0 : 6.0) : 0.0)
                                        : 1.0,
                                    child: AnimatedContainer(
                                      duration: animDuration,
                                      curve: AdwCurves.easeOutQuad,
                                      width: axis == Axis.vertical
                                          ? troughThickness
                                          : trackLength - 2.0,
                                      height: axis == Axis.vertical
                                          ? trackLength - 2.0
                                          : troughThickness,
                                      decoration: BoxDecoration(
                                        color: troughColor,
                                        borderRadius: BorderRadius.circular(999.0),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: axis == Axis.vertical ? thumbOffset : null,
                                    bottom: axis == Axis.horizontal ? 0.0 : null,
                                    left: axis == Axis.horizontal ? thumbOffset : null,
                                    right: axis == Axis.vertical ? 0.0 : null,
                                    child: AnimatedPadding(
                                      duration: animDuration,
                                      curve: AdwCurves.easeOutQuad,
                                      padding: EdgeInsets.only(
                                        right: axis == Axis.vertical
                                            ? (isExpanded ? 6.0 : 0.0)
                                            : 0.0,
                                        bottom: axis == Axis.horizontal
                                            ? (isExpanded ? 6.0 : 0.0)
                                            : 0.0,
                                      ),
                                      child: AnimatedContainer(
                                        duration: animDuration,
                                        curve: AdwCurves.easeOutQuad,
                                        width: axis == Axis.vertical
                                            ? thickness
                                            : thumbLength,
                                        height: axis == Axis.vertical
                                            ? thumbLength
                                            : thickness,
                                        decoration: BoxDecoration(
                                          color: thumbColor,
                                          border: darkBorder,
                                          borderRadius:
                                              BorderRadius.circular(999.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

