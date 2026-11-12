import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'adw_desktop_settings.dart';

/// Official animation curves and durations specified by GNOME Libadwaita.
abstract final class AdwCurves {
  /// Standard easing curve for UI transitions in Libadwaita.
  static const Curve standard = Curves.easeOutCubic;

  /// Smooth easing curve for symmetric state transitions (fades, crossfades).
  static const Curve smooth = Curves.easeInOutCubic;

  /// GTK4 `$ease-out-quad` curve used for overlay scrollbar transitions (`cubic-bezier(0.25, 0.46, 0.45, 0.94)`).
  static const Curve easeOutQuad = Cubic(0.25, 0.46, 0.45, 0.94);

  /// Exact switch toggle transition duration specified in GTK4 `gtkswitch.c`: 100ms.
  static const Duration switchDuration = Duration(milliseconds: 100);

  /// Short duration for micro-interactions (hover, pointer press): 150ms.
  static const Duration shortDuration = Duration(milliseconds: 150);

  /// Standard duration for control state changes (switches, buttons) from Libadwaita CSS: 200ms.
  static const Duration normalDuration = Duration(milliseconds: 200);

  /// Medium duration for expander rows and dialog appearances: 250ms.
  static const Duration mediumDuration = Duration(milliseconds: 250);

  /// Duration for top-level view transitions, modal dialog appearances, and banners: 300ms.
  static const Duration windowDuration = Duration(milliseconds: 300);

  /// Universal overlay scrollbar fade and expansion duration specified in GTK4 `_scrolling.scss`: 300ms.
  static const Duration scrollbarDuration = Duration(milliseconds: 300);

  /// Slow duration for complex enter/exit and page transformations: 400ms.
  static const Duration slowDuration = Duration(milliseconds: 400);

  /// Resolves [baseDuration] against desktop animation settings (GNOME, Qt/KDE, XFCE):
  /// - Returns [Duration.zero] if animations are disabled globally by the user.
  /// - Scales duration according to desktop speed factor (e.g. KDE AnimationDurationFactor).
  static Duration resolve(BuildContext context, Duration baseDuration) {
    final scope = AdwAnimationScope.maybeOf(context);
    if (scope != null) {
      return scope.settings.resolve(baseDuration);
    }
    return AdwDesktopSettings.animationSettings.value.resolve(baseDuration);
  }
}
