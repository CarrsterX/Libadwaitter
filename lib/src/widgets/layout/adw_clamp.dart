import 'package:flutter/widgets.dart';

/// Adaptive width-constraining container (`AdwClamp`).
///
/// Constrains the maximum width of its child according to GNOME HIG guidelines,
/// keeping it centered horizontally while allowing fluid narrowing on
/// compact mobile screens or split views.
class AdwClamp extends StatelessWidget {
  final double maximumSize;
  final double tighteningThreshold;
  final Widget child;

  const AdwClamp({
    super.key,
    this.maximumSize = 600.0,
    this.tighteningThreshold = 400.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maximumSize),
        child: child,
      ),
    );
  }
}

