import 'dart:math' as math;
import 'package:flutter/physics.dart';

/// Spring physics parameters mirroring Libadwaita's `AdwSpringParams`.
///
/// Used to drive fluid, velocity-preserving transitions for predictive
/// navigation gestures, carousels, and sheets without synthetic cubic curves.
class AdwSpringParams {
  /// Damping ratio (`>= 0.0`). `1.0` is critically damped (no oscillation).
  final double dampingRatio;

  /// Mass of the simulated object (`> 0.0`).
  final double mass;

  /// Spring stiffness (`> 0.0`). Higher values produce snappier transitions.
  final double stiffness;

  const AdwSpringParams({
    required this.dampingRatio,
    required this.mass,
    required this.stiffness,
  })  : assert(dampingRatio >= 0.0),
        assert(mass > 0.0),
        assert(stiffness > 0.0);

  /// Standard critically-damped spring used by Libadwaita `AdwNavigationView`
  /// for page push/pop and predictive swipe-back completion/cancellation.
  static const AdwSpringParams navigation = AdwSpringParams(
    dampingRatio: 1.0,
    mass: 1.0,
    stiffness: 280.0,
  );

  /// Slightly softer spring suitable for sheets and carousels.
  static const AdwSpringParams gentle = AdwSpringParams(
    dampingRatio: 0.92,
    mass: 1.0,
    stiffness: 300.0,
  );

  /// Converts these parameters into a Flutter [SpringDescription].
  SpringDescription toSpringDescription() {
    final damping =
        2.0 * dampingRatio * math.sqrt(mass * stiffness);
    return SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
  }

  /// Creates a [SpringSimulation] from [start] to [end] with initial [velocity].
  SpringSimulation createSimulation({
    required double start,
    required double end,
    double velocity = 0.0,
  }) {
    return SpringSimulation(
      toSpringDescription(),
      start,
      end,
      velocity,
    );
  }
}

