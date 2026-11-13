import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Adaptive width-constraining container (`AdwClamp`).
///
/// Constrains the maximum width of its child according to GNOME HIG guidelines,
/// keeping it centered horizontally with a guaranteed minimum side margin on
/// narrow screens so content never touches the window edges.
class AdwClamp extends StatelessWidget {
  final double maximumSize;
  final double tighteningThreshold;
  final double minimumMargin;
  final double? maximumMargin;
  final Widget child;

  const AdwClamp({
    super.key,
    this.maximumSize = 600.0,
    this.tighteningThreshold = 400.0,
    this.minimumMargin = 12.0,
    this.maximumMargin,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: minimumMargin),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maximumSize),
                child: child,
              ),
            ),
          );
        }

        final availableWidth = constraints.maxWidth;
        final upperMargin = maximumMargin ?? (minimumMargin + 6.0);
        double sideMargin = minimumMargin;

        if (availableWidth > tighteningThreshold &&
            maximumSize > tighteningThreshold) {
          final t = ((availableWidth - tighteningThreshold) /
                  (maximumSize - tighteningThreshold))
              .clamp(0.0, 1.0);
          sideMargin = minimumMargin + (upperMargin - minimumMargin) * t;
        }

        final contentMaxWidth = math.min(
          maximumSize,
          math.max(0.0, availableWidth - sideMargin * 2),
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: sideMargin),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

