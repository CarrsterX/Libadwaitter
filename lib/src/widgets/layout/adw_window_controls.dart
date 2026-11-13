import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_desktop_settings.dart';
import '../../theme/adw_theme.dart';
import 'adw_window.dart';

enum AdwWindowButtonType {
  minimize,
  maximize,
  close,
}

/// Individual GNOME window control button (Close, Maximize, Minimize).
///
/// Follows upstream Libadwaita metrics:
/// - Outer button hitbox: 34x34px (`min-width: 24px; padding: 5px;`)
/// - Inner circular image: 24x24px (`padding: 4px; border-radius: 100%;`)
/// - Upstream vector icons in 16x16 coordinate space
/// - Uniform subtle tint across all window control buttons
/// - Direct pointer [Listener] dispatch to bypass Flutter's gesture arena for 0ms response
class AdwWindowControlButton extends StatefulWidget {
  final AdwWindowButtonType type;
  final VoidCallback? onPressed;
  final bool isMaximized;
  final double buttonSize;
  final double circleSize;

  const AdwWindowControlButton({
    super.key,
    required this.type,
    this.onPressed,
    this.isMaximized = false,
    this.buttonSize = 34.0,
    this.circleSize = 24.0,
  });

  @override
  State<AdwWindowControlButton> createState() => _AdwWindowControlButtonState();
}

class _AdwWindowControlButtonState extends State<AdwWindowControlButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final Color currentColor = theme.colors.windowForeground;

    // Upstream Libadwaita CSS:
    // windowcontrols > button > image: background-color: color-mix(in srgb, currentColor 10%, transparent);
    // windowcontrols > button:hover > image: background-color: color-mix(in srgb, currentColor 15%, transparent);
    // windowcontrols > button:active > image: background-color: color-mix(in srgb, currentColor 30%, transparent);
    Color bg;
    if (_isPressed) {
      bg = currentColor.withValues(alpha: 0.30);
    } else if (_isHovered) {
      bg = currentColor.withValues(alpha: 0.15);
    } else {
      bg = currentColor.withValues(alpha: 0.10);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _isPressed = false;
        });
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          setState(() => _isPressed = true);
        },
        onPointerUp: (_) {
          setState(() => _isPressed = false);
          if (_isHovered) {
            widget.onPressed?.call();
          }
        },
        onPointerCancel: (_) {
          setState(() => _isPressed = false);
        },
        child: SizedBox(
          width: widget.buttonSize,
          height: widget.buttonSize,
          child: Center(
            child: AnimatedContainer(
              duration: AdwCurves.shortDuration,
              curve: AdwCurves.standard,
              width: widget.circleSize,
              height: widget.circleSize,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CustomPaint(
                    painter: _GnomeWindowControlSvgPainter(
                      type: widget.type,
                      color: currentColor,
                      isMaximized: widget.isMaximized,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Exact vector painter for official GNOME window control SVGs:
/// - `window-close-symbolic.svg`
/// - `window-maximize-symbolic.svg`
/// - `window-restore-symbolic.svg`
/// - `window-minimize-symbolic.svg`
class _GnomeWindowControlSvgPainter extends CustomPainter {
  final AdwWindowButtonType type;
  final Color color;
  final bool isMaximized;

  _GnomeWindowControlSvgPainter({
    required this.type,
    required this.color,
    this.isMaximized = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 16.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case AdwWindowButtonType.close:
        // Exact vector path from upstream `window-close-symbolic.svg` (viewBox 0 0 16 16)
        final path = Path()
          ..moveTo(4, 4)
          ..lineTo(5.03125, 4)
          ..cubicTo(5.285156, 4.011719, 5.542969, 4.128906, 5.71875, 4.3125)
          ..lineTo(8, 6.59375)
          ..lineTo(10.3125, 4.3125)
          ..cubicTo(10.578125, 4.082031, 10.757812, 4.007812, 11, 4)
          ..lineTo(12, 4)
          ..lineTo(12, 5)
          ..cubicTo(12, 5.285156, 11.964844, 5.550781, 11.75, 5.75)
          ..lineTo(9.46875, 8.03125)
          ..lineTo(11.71875, 10.28125)
          ..cubicTo(11.90625, 10.46875, 12, 10.734375, 12, 11)
          ..lineTo(12, 12)
          ..lineTo(11, 12)
          ..cubicTo(10.734375, 12, 10.46875, 11.90625, 10.28125, 11.71875)
          ..lineTo(8, 9.4375)
          ..lineTo(5.71875, 11.71875)
          ..cubicTo(5.53125, 11.90625, 5.265625, 12, 5, 12)
          ..lineTo(4, 12)
          ..lineTo(4, 11)
          ..cubicTo(4, 10.734375, 4.09375, 10.46875, 4.28125, 10.28125)
          ..lineTo(6.5625, 8.03125)
          ..lineTo(4.28125, 5.75)
          ..cubicTo(4.070312, 5.554688, 3.976562, 5.28125, 4, 5)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case AdwWindowButtonType.maximize:
        if (isMaximized) {
          // Exact vector path from upstream `window-restore-symbolic.svg`
          final path = Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(const Rect.fromLTWH(4.99, 4.99, 6.01, 6.01))
            ..addRect(const Rect.fromLTWH(6.99, 6.99, 2.01, 2.01));
          canvas.drawPath(path, paint);
        } else {
          // Exact vector path from upstream `window-maximize-symbolic.svg` (8x8 outer, 4x4 cutout)
          final path = Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(const Rect.fromLTWH(3.99, 3.99, 8.01, 8.01))
            ..addRect(const Rect.fromLTWH(5.99, 5.99, 4.01, 4.01));
          canvas.drawPath(path, paint);
        }
        break;

      case AdwWindowButtonType.minimize:
        // Exact vector path from upstream `window-minimize-symbolic.svg` (8x2 bottom bar)
        canvas.drawRect(const Rect.fromLTWH(4, 10, 8, 2), paint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GnomeWindowControlSvgPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.isMaximized != isMaximized;
  }
}

/// Official in-app GNOME window control buttons container (`-`, `□`, `✕`).
///
/// Follows upstream Libadwaita CSS (`windowcontrols { border-spacing: 3px; }`)
/// and synchronizes button visibility and order with the host desktop shell
/// (`org.gnome.desktop.wm.preferences` `button-layout`) when explicit overrides
/// are not provided.
class AdwWindowControls extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback? onMaximize;
  final VoidCallback? onMinimize;
  final bool? showMinimize;
  final bool? showMaximize;
  final bool? showClose;
  final double spacing;

  const AdwWindowControls({
    super.key,
    this.onClose,
    this.onMaximize,
    this.onMinimize,
    this.showMinimize,
    this.showMaximize,
    this.showClose,
    this.spacing = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final windowScope = AdwWindowScope.maybeOf(context);
    final controller = windowScope?.controller;
    final isMaximized = windowScope?.isMaximized ?? false;

    final effectiveOnClose = onClose ?? controller?.close;
    final effectiveOnMaximize = onMaximize ?? controller?.maximize;
    final effectiveOnMinimize = onMinimize ?? controller?.minimize;

    return ValueListenableBuilder<AdwWindowButtonLayout>(
      valueListenable: AdwDesktopSettings.windowButtonLayout,
      builder: (context, layout, _) {
        final List<String> tokens;
        if (showMinimize == null &&
            showMaximize == null &&
            showClose == null) {
          tokens = layout.endButtons.isNotEmpty
              ? layout.endButtons
              : layout.startButtons;
        } else {
          tokens = <String>[
            if (showMinimize ?? layout.hasMinimize) 'minimize',
            if (showMaximize ?? layout.hasMaximize) 'maximize',
            if (showClose ?? layout.hasClose) 'close',
          ];
        }

        final children = <Widget>[];
        for (int i = 0; i < tokens.length; i++) {
          if (i > 0) {
            children.add(SizedBox(width: spacing));
          }
          switch (tokens[i]) {
            case 'minimize':
              children.add(
                AdwWindowControlButton(
                  type: AdwWindowButtonType.minimize,
                  onPressed: effectiveOnMinimize,
                ),
              );
              break;
            case 'maximize':
              children.add(
                AdwWindowControlButton(
                  type: AdwWindowButtonType.maximize,
                  isMaximized: isMaximized,
                  onPressed: effectiveOnMaximize,
                ),
              );
              break;
            case 'close':
              children.add(
                AdwWindowControlButton(
                  type: AdwWindowButtonType.close,
                  onPressed: effectiveOnClose,
                ),
              );
              break;
          }
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        );
      },
    );
  }
}
