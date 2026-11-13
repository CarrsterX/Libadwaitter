import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

enum AdwButtonStyle {
  standard,
  flat,
  suggested,
  destructive,
}

/// Official button widget adhering to Libadwaita metrics and visual states.
class AdwButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final AdwButtonStyle style;
  final bool isPill;
  final bool isCircular;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const AdwButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style = AdwButtonStyle.standard,
    this.isPill = false,
    this.isCircular = false,
    this.padding,
    this.width,
    this.height,
  });

  /// Flat button variant (transparent until hovered or active).
  const AdwButton.flat({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.width,
    this.height,
  })  : style = AdwButtonStyle.flat,
        isPill = false,
        isCircular = false;

  /// Suggested action button variant (styled with the active accent color).
  const AdwButton.suggested({
    super.key,
    required this.child,
    this.onPressed,
    this.isPill = false,
    this.padding,
    this.width,
    this.height,
  })  : style = AdwButtonStyle.suggested,
        isCircular = false;

  /// Destructive action button variant (styled with GNOME red alert color).
  const AdwButton.destructive({
    super.key,
    required this.child,
    this.onPressed,
    this.isPill = false,
    this.padding,
    this.width,
    this.height,
  })  : style = AdwButtonStyle.destructive,
        isCircular = false;

  /// Pill button variant (fully rounded capsule edges).
  const AdwButton.pill({
    super.key,
    required this.child,
    this.onPressed,
    this.style = AdwButtonStyle.standard,
    this.padding,
    this.width,
    this.height,
  })  : isPill = true,
        isCircular = false;

  /// Circular button variant for icon actions.
  const AdwButton.circular({
    super.key,
    required this.child,
    this.onPressed,
    this.style = AdwButtonStyle.standard,
    this.padding,
    double size = 34.0,
  })  : isPill = false,
        isCircular = true,
        width = size,
        height = size;

  @override
  State<AdwButton> createState() => _AdwButtonState();
}

class _AdwButtonState extends State<AdwButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final isDark = theme.colors.isDark;

    // Compute background and foreground colors according to style and state
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor = const Color(0x00000000);

    switch (widget.style) {
      case AdwButtonStyle.suggested:
        backgroundColor = theme.colors.accentColor;
        foregroundColor = theme.colors.accentForeground;
        if (_isPressed) {
          backgroundColor =
              Color.lerp(backgroundColor, const Color(0xFF000000), 0.15)!;
        } else if (_isHovered) {
          backgroundColor =
              Color.lerp(backgroundColor, const Color(0xFFFFFFFF), 0.12)!;
        }
        break;

      case AdwButtonStyle.destructive:
        backgroundColor = theme.colors.destructiveColor;
        foregroundColor = theme.colors.destructiveForeground;
        if (_isPressed) {
          backgroundColor =
              Color.lerp(backgroundColor, const Color(0xFF000000), 0.15)!;
        } else if (_isHovered) {
          backgroundColor =
              Color.lerp(backgroundColor, const Color(0xFFFFFFFF), 0.12)!;
        }
        break;

      case AdwButtonStyle.flat:
        foregroundColor = theme.colors.windowForeground;
        if (_isPressed) {
          backgroundColor = theme.colors.activeColor;
        } else if (_isHovered) {
          backgroundColor = theme.colors.hoverColor;
        } else {
          backgroundColor = const Color(0x00000000);
        }
        break;

      case AdwButtonStyle.standard:
        foregroundColor = theme.colors.windowForeground;
        if (isDark) {
          backgroundColor = const Color(0x14FFFFFF); // 8% white
          borderColor = const Color(0x0DFFFFFF);
          if (_isPressed) {
            backgroundColor = const Color(0x28FFFFFF);
          } else if (_isHovered) {
            backgroundColor = const Color(0x1EFFFFFF);
          }
        } else {
          backgroundColor = const Color(0x0D000000); // 5% black
          borderColor = const Color(0x0A000000);
          if (_isPressed) {
            backgroundColor = const Color(0x1E000000);
          } else if (_isHovered) {
            backgroundColor = const Color(0x14000000);
          }
        }
        break;
    }

    if (!_isEnabled) {
      backgroundColor = backgroundColor.withValues(alpha: 0.5);
      foregroundColor = foregroundColor.withValues(alpha: 0.4);
    }

    final borderRadius = widget.isCircular || widget.isPill
        ? BorderRadius.circular(AdwMetrics.pillRadius)
        : BorderRadius.circular(AdwMetrics.buttonRadius);

    final defaultPadding = widget.isCircular
        ? EdgeInsets.zero
        : (widget.isPill
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 6));

    Widget buttonContent = AnimatedDefaultTextStyle(
      duration: AdwCurves.shortDuration,
      style: theme.typography.body.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w500,
      ),
      child: IconTheme(
        data: IconThemeData(
          color: foregroundColor,
          size: AdwMetrics.iconSizeMedium,
        ),
        child: Center(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: widget.child,
        ),
      ),
    );

    return MouseRegion(
      cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (_isEnabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isEnabled) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (_isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (_isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (_isEnabled) setState(() => _isPressed = false);
        },
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AdwCurves.shortDuration,
          curve: AdwCurves.standard,
          constraints: BoxConstraints(
            minWidth: widget.width ?? 0.0,
            maxWidth: widget.width ?? double.infinity,
            minHeight: widget.height ??
                (widget.isCircular ? 0.0 : AdwMetrics.buttonMinHeight),
            maxHeight: widget.height ?? double.infinity,
          ),
          padding: widget.padding ?? defaultPadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: buttonContent,
        ),
      ),
    );
  }
}
