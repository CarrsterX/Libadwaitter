import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_theme.dart';
import 'adw_carousel.dart';

/// Paginated dot indicator widget for [AdwCarousel] (`AdwCarouselIndicatorDots`).
///
/// Implements upstream GNOME Libadwaita specifications:
/// - GitLab source: `https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/adw-carousel-indicator-dots.c`
/// - CSS selector: `carousel-indicator-dots`
///
/// Visual representation:
/// - Inactive dots: $6 \times 6\,\text{px}$ circles with 35% opacity.
/// - Active dot: $18 \times 6\,\text{px}$ smooth animated capsule with full opacity.
/// - Interactive: tapping any dot navigates directly to that page.
class AdwCarouselIndicatorDots extends StatelessWidget {
  /// The carousel controller driving the active index and page count.
  final AdwCarouselController? controller;

  /// Explicit page count if used independently of an [AdwCarouselController].
  final int? itemCount;

  /// Explicit active page index if used independently.
  final int? currentPage;

  /// Callback when a dot is clicked.
  final ValueChanged<int>? onDotClicked;

  /// Height and diameter of inactive dots in logical pixels (default 6.0).
  final double dotSize;

  /// Expanded width of the active capsule dot in logical pixels (default 18.0).
  final double activeDotWidth;

  /// Horizontal spacing between consecutive dots in logical pixels (default 6.0).
  final double spacing;

  const AdwCarouselIndicatorDots({
    super.key,
    this.controller,
    this.itemCount,
    this.currentPage,
    this.onDotClicked,
    this.dotSize = 6.0,
    this.activeDotWidth = 18.0,
    this.spacing = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) {
          return _buildDots(
            context,
            count: controller!.itemCount,
            current: controller!.currentPage,
            onTap: (index) {
              final duration = AdwCurves.resolve(context, AdwCurves.normalDuration);
              controller!.animateToPage(index, duration: duration);
              onDotClicked?.call(index);
            },
          );
        },
      );
    }

    return _buildDots(
      context,
      count: itemCount ?? 0,
      current: currentPage ?? 0,
      onTap: onDotClicked,
    );
  }

  Widget _buildDots(
    BuildContext context, {
    required int count,
    required int current,
    required ValueChanged<int>? onTap,
  }) {
    if (count <= 1) return const SizedBox.shrink();

    final theme = AdwTheme.of(context);
    final duration = AdwCurves.resolve(context, AdwCurves.shortDuration);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        final targetWidth = isActive ? activeDotWidth : dotSize;
        final targetColor = isActive
            ? theme.colors.foreground
            : theme.colors.foreground.withValues(alpha: 0.35);

        return GestureDetector(
          onTap: onTap != null ? () => onTap(index) : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: AnimatedContainer(
              duration: duration,
              curve: AdwCurves.standard,
              width: targetWidth,
              height: dotSize,
              decoration: BoxDecoration(
                color: targetColor,
                borderRadius: BorderRadius.circular(dotSize / 2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Paginated line indicator widget for [AdwCarousel] (`AdwCarouselIndicatorLines`).
///
/// Implements upstream GNOME Libadwaita specifications:
/// - GitLab source: `https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/adw-carousel-indicator-lines.c`
/// - CSS selector: `carousel-indicator-lines`
class AdwCarouselIndicatorLines extends StatelessWidget {
  final AdwCarouselController? controller;
  final int? itemCount;
  final int? currentPage;
  final ValueChanged<int>? onLineClicked;
  final double lineWidth;
  final double lineHeight;
  final double spacing;

  const AdwCarouselIndicatorLines({
    super.key,
    this.controller,
    this.itemCount,
    this.currentPage,
    this.onLineClicked,
    this.lineWidth = 24.0,
    this.lineHeight = 3.0,
    this.spacing = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) {
          return _buildLines(
            context,
            count: controller!.itemCount,
            current: controller!.currentPage,
            onTap: (index) {
              final duration = AdwCurves.resolve(context, AdwCurves.normalDuration);
              controller!.animateToPage(index, duration: duration);
              onLineClicked?.call(index);
            },
          );
        },
      );
    }

    return _buildLines(
      context,
      count: itemCount ?? 0,
      current: currentPage ?? 0,
      onTap: onLineClicked,
    );
  }

  Widget _buildLines(
    BuildContext context, {
    required int count,
    required int current,
    required ValueChanged<int>? onTap,
  }) {
    if (count <= 1) return const SizedBox.shrink();

    final theme = AdwTheme.of(context);
    final duration = AdwCurves.resolve(context, AdwCurves.shortDuration);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        final targetColor = isActive
            ? theme.colors.foreground
            : theme.colors.foreground.withValues(alpha: 0.25);

        return GestureDetector(
          onTap: onTap != null ? () => onTap(index) : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: AnimatedContainer(
              duration: duration,
              curve: AdwCurves.standard,
              width: lineWidth,
              height: lineHeight,
              decoration: BoxDecoration(
                color: targetColor,
                borderRadius: BorderRadius.circular(lineHeight / 2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

