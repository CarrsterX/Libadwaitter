import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Preference row with numeric increment/decrement spin control (`AdwSpinRow`).
///
/// Enables users to adjust numeric values within bounded ranges using
/// dedicated stepper buttons `[-]` and `[+]`.
class AdwSpinRow extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? prefix;
  final double value;
  final double min;
  final double max;
  final double step;
  final int decimalDigits;
  final ValueChanged<double>? onChanged;

  const AdwSpinRow({
    super.key,
    required this.title,
    this.subtitle,
    this.prefix,
    required this.value,
    this.min = 0.0,
    this.max = 100.0,
    this.step = 1.0,
    this.decimalDigits = 0,
    this.onChanged,
  });

  @override
  State<AdwSpinRow> createState() => _AdwSpinRowState();
}

class _AdwSpinRowState extends State<AdwSpinRow> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    _focusNode.requestFocus();
    final next = (widget.value + widget.step).clamp(widget.min, widget.max);
    if (next != widget.value) {
      widget.onChanged?.call(next);
    }
  }

  void _decrement() {
    _focusNode.requestFocus();
    final next = (widget.value - widget.step).clamp(widget.min, widget.max);
    if (next != widget.value) {
      widget.onChanged?.call(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final canDecrement = widget.value > widget.min;
    final canIncrement = widget.value < widget.max;

    final displayText = widget.decimalDigits == 0
        ? widget.value.toInt().toString()
        : widget.value.toStringAsFixed(widget.decimalDigits);

    return TapRegion(
      onTapOutside: (_) {
        if (_focusNode.hasFocus) _focusNode.unfocus();
      },
      child: Focus(
        focusNode: _focusNode,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _focusNode.requestFocus(),
          child: AnimatedContainer(
            duration: AdwCurves.shortDuration,
            curve: AdwCurves.standard,
            constraints:
                const BoxConstraints(minHeight: AdwMetrics.rowMinHeight),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AdwMetrics.cardRadius),
              border: Border.all(
                color: theme.colors.accentColor.withValues(
                  alpha: _isFocused ? 0.75 : 0.0,
                ),
                width: 2.0,
              ),
            ),
            child: Row(
              children: [
                if (widget.prefix != null) ...[
                  widget.prefix!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: theme.typography.body.copyWith(
                          fontSize: 14.0,
                          fontWeight: FontWeight.normal,
                        ),
                        child: widget.title,
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        DefaultTextStyle(
                          style: theme.typography.caption.copyWith(
                            color: theme.colors.secondaryForeground,
                          ),
                          child: widget.subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayText,
                      textAlign: TextAlign.right,
                      style: theme.typography.body.copyWith(
                        fontSize: 14.0,
                        fontWeight: FontWeight.normal,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SpinButton(
                      isIncrement: false,
                      enabled: canDecrement,
                      onPressed: _decrement,
                    ),
                    const SizedBox(width: 6),
                    _SpinButton(
                      isIncrement: true,
                      enabled: canIncrement,
                      onPressed: _increment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinButton extends StatefulWidget {
  final bool isIncrement;
  final bool enabled;
  final VoidCallback onPressed;

  const _SpinButton({
    required this.isIncrement,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends State<_SpinButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final Color bgColor;
    if (!widget.enabled) {
      bgColor = theme.colors.buttonBackground.withValues(alpha: 0.45);
    } else if (_isPressed) {
      bgColor = theme.colors.activeColor;
    } else if (_isHovered) {
      bgColor = theme.colors.hoverBackground;
    } else {
      bgColor = theme.colors.buttonBackground;
    }

    final Color fgColor = widget.enabled
        ? theme.colors.windowForeground
        : theme.colors.secondaryForeground.withValues(alpha: 0.4);

    return MouseRegion(
      cursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (widget.enabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (widget.enabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (widget.enabled) setState(() => _isPressed = false);
        },
        onTap: widget.enabled ? widget.onPressed : null,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
          ),
          child: CustomPaint(
            painter: _SpinSymbolPainter(
              isIncrement: widget.isIncrement,
              color: fgColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinSymbolPainter extends CustomPainter {
  final bool isIncrement;
  final Color color;

  const _SpinSymbolPainter({
    required this.isIncrement,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const halfLen = 4.5;

    canvas.drawLine(
      Offset(cx - halfLen, cy),
      Offset(cx + halfLen, cy),
      paint,
    );
    if (isIncrement) {
      canvas.drawLine(
        Offset(cx, cy - halfLen),
        Offset(cx, cy + halfLen),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpinSymbolPainter oldDelegate) =>
      oldDelegate.isIncrement != isIncrement || oldDelegate.color != color;
}
