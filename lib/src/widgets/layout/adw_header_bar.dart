import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';
import 'adw_window.dart';
import 'adw_window_controls.dart';
import 'adw_window_title.dart';

/// Official Libadwaita header bar widget (`AdwHeaderBar`).
///
/// Features an optically centered title, start/end action slots, in-app window
/// controls, and a background drag area for native window movement.
/// Follows upstream Libadwaita CSS:
/// - `headerbar { min-height: 47px; }`
/// - `headerbar > windowhandle > box { padding: 6px 7px 6px 7px; }`
/// - `headerbar > windowhandle > box > box.start, headerbar > windowhandle > box > box.end { border-spacing: 6px; }`
/// - `headerbar .title, windowtitle .title { padding-left: 12px; padding-right: 12px; font-weight: bold; }`
class AdwHeaderBar extends StatelessWidget {
  static const EdgeInsets defaultPadding = EdgeInsets.fromLTRB(7.0, 6.0, 7.0, 6.0);

  final Widget? title;
  final Widget? subtitle;
  final Widget? titleWidget;
  final Widget? start;
  final Widget? end;
  final bool showWindowControls;
  final Widget? windowControls;
  final EdgeInsetsGeometry padding;
  final bool isFlat;

  const AdwHeaderBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.start,
    this.end,
    this.showWindowControls = true,
    this.windowControls,
    this.padding = defaultPadding,
    this.isFlat = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final windowScope = AdwWindowScope.maybeOf(context);
    final controller = windowScope?.controller;
    final isWindowActive = windowScope?.isActive ?? true;

    // Resolve effective title content
    Widget? effectiveTitle = titleWidget;
    if (effectiveTitle == null) {
      if (title is String || subtitle is String) {
        effectiveTitle = AdwWindowTitle(
          title: title is String ? title as String : '',
          subtitle: subtitle is String ? subtitle as String : null,
        );
      } else if (title != null || subtitle != null) {
        effectiveTitle = Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (title != null)
              DefaultTextStyle(
                style: theme.typography.heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                child: title!,
              ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: DefaultTextStyle(
                  style: theme.typography.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  child: subtitle!,
                ),
              ),
          ],
        );
      }
    }

    final effectiveControls = showWindowControls
        ? (windowControls ?? const AdwWindowControls())
        : null;

    final resolvedPadding = padding.resolve(Directionality.of(context));

    Widget? endGroup;
    if (end != null || effectiveControls != null) {
      endGroup = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (end != null) end!,
          if (end != null && effectiveControls != null)
            const SizedBox(width: AdwMetrics.spacingSmall),
          if (effectiveControls != null) effectiveControls,
        ],
      );
    }

    return Container(
      height: AdwMetrics.headerBarHeight,
      decoration: BoxDecoration(
        color: isFlat ? const Color(0x00000000) : theme.colors.headerBarBackground,
        border: isFlat
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.colors.dividerColor,
                  width: 1,
                ),
              ),
      ),
      child: Stack(
        children: [
          // 1. Background layer for native window dragging and double-click maximization
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => controller?.startDragging(),
              onDoubleTap: () => controller?.maximize(),
              child: const SizedBox.expand(),
            ),
          ),
          // 2. Foreground structured layout conforming to GTK4 AdwHeaderBar
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: isWindowActive ? 1.0 : 0.55,
              duration: AdwCurves.shortDuration,
              child: CustomMultiChildLayout(
                delegate: _AdwHeaderBarLayoutDelegate(
                  padding: resolvedPadding,
                ),
                children: [
                  if (start != null)
                    LayoutId(
                      id: _AdwHeaderBarLayoutDelegate.startId,
                      child: start!,
                    ),
                  if (effectiveTitle != null)
                    LayoutId(
                      id: _AdwHeaderBarLayoutDelegate.titleId,
                      child: titleWidget == null
                          ? IgnorePointer(child: effectiveTitle)
                          : effectiveTitle,
                    ),
                  if (endGroup != null)
                    LayoutId(
                      id: _AdwHeaderBarLayoutDelegate.endId,
                      child: endGroup,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Optical center layout delegate implementing official GTK4 / Libadwaita allocation:
/// 1. Allocates start and end widgets.
/// 2. Attempts exact optical centering relative to the total header bar width.
/// 3. If side widgets encroach within the 12px margin, shifts title into the remaining space.
class _AdwHeaderBarLayoutDelegate extends MultiChildLayoutDelegate {
  static const String startId = 'start';
  static const String endId = 'end';
  static const String titleId = 'title';

  final EdgeInsets padding;

  _AdwHeaderBarLayoutDelegate({required this.padding});

  @override
  void performLayout(Size size) {
    double startWidth = 0.0;
    if (hasChild(startId)) {
      final startSize = layoutChild(
        startId,
        BoxConstraints(
          maxWidth: math.max(0.0, size.width - padding.horizontal),
          maxHeight: size.height,
        ),
      );
      startWidth = startSize.width;
      positionChild(
        startId,
        Offset(padding.left, (size.height - startSize.height) / 2),
      );
    }

    double endWidth = 0.0;
    if (hasChild(endId)) {
      final endSize = layoutChild(
        endId,
        BoxConstraints(
          maxWidth: math.max(0.0, size.width - padding.horizontal - startWidth),
          maxHeight: size.height,
        ),
      );
      endWidth = endSize.width;
      positionChild(
        endId,
        Offset(size.width - padding.right - endWidth, (size.height - endSize.height) / 2),
      );
    }

    if (hasChild(titleId)) {
      // Upstream Libadwaita token: minimum 12px side margin around title widget
      const double titleSideMargin = 12.0;

      final double leftBound = padding.left + startWidth + (startWidth > 0 ? titleSideMargin : 0.0);
      final double rightBound = size.width - padding.right - endWidth - (endWidth > 0 ? titleSideMargin : 0.0);
      final double availableWidth = math.max(0.0, rightBound - leftBound);

      final titleSize = layoutChild(
        titleId,
        BoxConstraints(
          maxWidth: availableWidth,
          maxHeight: size.height,
        ),
      );

      // Desired optical center coordinate
      final double idealLeft = (size.width - titleSize.width) / 2;
      double actualLeft;

      if (idealLeft >= leftBound && (idealLeft + titleSize.width) <= rightBound) {
        // Fits at true optical center without encroaching on start or end widgets
        actualLeft = idealLeft;
      } else {
        // Asymmetric shift: center within the available space between bounds
        final double freeSpace = math.max(0.0, availableWidth - titleSize.width);
        actualLeft = leftBound + (freeSpace / 2);
      }

      positionChild(
        titleId,
        Offset(actualLeft, (size.height - titleSize.height) / 2),
      );
    }
  }

  @override
  bool shouldRelayout(covariant _AdwHeaderBarLayoutDelegate oldDelegate) {
    return oldDelegate.padding != padding;
  }
}
