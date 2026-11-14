import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

enum AdwButtonRowStyle {
  standard,
  suggested,
  destructive,
}

/// Native Libadwaita button row (`AdwButtonRow`).
///
/// Designed to be placed inside a separated [AdwPreferencesGroup] (or standalone)
/// to present prominent centered action rows such as `Add Input Source`,
/// `Delete Event`, or `Search`.
class AdwButtonRow extends StatefulWidget {
  final Widget title;
  final Widget? startIcon;
  final Widget? endIcon;
  final AdwButtonRowStyle style;
  final VoidCallback? onPressed;
  final double minHeight;

  const AdwButtonRow({
    super.key,
    required this.title,
    this.startIcon,
    this.endIcon,
    this.style = AdwButtonRowStyle.standard,
    this.onPressed,
    this.minHeight = 45.0,
  });

  /// Suggested-action button row (accent-colored background with light text).
  const AdwButtonRow.suggested({
    super.key,
    required this.title,
    this.startIcon,
    this.endIcon,
    this.onPressed,
    this.minHeight = 45.0,
  }) : style = AdwButtonRowStyle.suggested;

  /// Destructive-action button row (alert red label).
  const AdwButtonRow.destructive({
    super.key,
    required this.title,
    this.startIcon,
    this.endIcon,
    this.onPressed,
    this.minHeight = 45.0,
  }) : style = AdwButtonRowStyle.destructive;

  @override
  State<AdwButtonRow> createState() => _AdwButtonRowState();
}

class _AdwButtonRowState extends State<AdwButtonRow> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final isEnabled = widget.onPressed != null;

    final Color bgColor;
    final Color fgColor;

    final Color idleCardBg = theme.colors.isDark
        ? const Color(0xFF333337)
        : const Color(0xFFFFFFFF);

    switch (widget.style) {
      case AdwButtonRowStyle.standard:
        fgColor = theme.colors.windowForeground;
        if (!isEnabled) {
          bgColor = idleCardBg;
        } else if (_isPressed) {
          bgColor = Color.alphaBlend(theme.colors.activeColor, idleCardBg);
        } else if (_isHovered) {
          bgColor = theme.colors.isDark
              ? Color.alphaBlend(theme.colors.hoverColor, idleCardBg)
              : const Color(0xFFF9F9F9);
        } else {
          bgColor = idleCardBg;
        }
        break;
      case AdwButtonRowStyle.destructive:
        fgColor = theme.colors.isDark
            ? const Color(0xFFFF938C)
            : theme.colors.destructiveColor;
        if (!isEnabled) {
          bgColor = idleCardBg;
        } else if (_isPressed) {
          bgColor = Color.alphaBlend(
              fgColor.withValues(alpha: 0.16), idleCardBg);
        } else if (_isHovered) {
          bgColor = theme.colors.isDark
              ? const Color(0xFF3A3539)
              : const Color(0xFFFDF7F7);
        } else {
          bgColor = idleCardBg;
        }
        break;
      case AdwButtonRowStyle.suggested:
        fgColor = theme.colors.accentForeground;
        final base = theme.colors.accentColor;
        if (!isEnabled) {
          bgColor = base.withValues(alpha: 0.5);
        } else if (_isPressed) {
          bgColor = Color.lerp(base, const Color(0xFF000000), 0.15)!;
        } else if (_isHovered) {
          bgColor = Color.lerp(base, const Color(0xFFFFFFFF), 0.08)!;
        } else {
          bgColor = base;
        }
        break;
    }

    final resolvedFg =
        isEnabled ? fgColor : fgColor.withValues(alpha: 0.45);

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (isEnabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isEnabled) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AdwCurves.shortDuration,
          curve: AdwCurves.standard,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: resolvedFg,
                size: AdwMetrics.iconSizeSmall,
              ),
              child: DefaultTextStyle(
                style: theme.typography.heading.copyWith(
                  fontSize: 14.0,
                  color: resolvedFg,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.startIcon != null) ...[
                      widget.startIcon!,
                      const SizedBox(width: 8),
                    ],
                    widget.title,
                    if (widget.endIcon != null) ...[
                      const SizedBox(width: 8),
                      widget.endIcon!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

