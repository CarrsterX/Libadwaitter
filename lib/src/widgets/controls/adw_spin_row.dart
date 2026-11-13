import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';
import 'adw_button.dart';

/// Preference row with numeric increment/decrement spin control (`AdwSpinRow`).
///
/// Enables users to adjust numeric values within bounded ranges using
/// dedicated stepper buttons `[-]` and `[+]`.
class AdwSpinRow extends StatelessWidget {
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

  void _increment() {
    final next = (value + step).clamp(min, max);
    if (next != value) {
      onChanged?.call(next);
    }
  }

  void _decrement() {
    final next = (value - step).clamp(min, max);
    if (next != value) {
      onChanged?.call(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final canDecrement = value > min;
    final canIncrement = value < max;

    final displayText = decimalDigits == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(decimalDigits);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (prefix != null) ...[
            prefix!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  child: title,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle(
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.secondaryForeground,
                    ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colors.buttonBackground,
              borderRadius: BorderRadius.circular(AdwMetrics.buttonRadius),
              border: Border.all(
                color: theme.colors.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SpinButton(
                  label: '−',
                  enabled: canDecrement,
                  onPressed: _decrement,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(
                    displayText,
                    textAlign: TextAlign.center,
                    style: theme.typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _SpinButton(
                  label: '+',
                  enabled: canIncrement,
                  onPressed: _increment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _SpinButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends State<_SpinButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPressed : null,
        child: Container(
          width: 32,
          height: 30,
          decoration: BoxDecoration(
            color: widget.enabled && _isHovered
                ? theme.colors.hoverBackground
                : const Color(0x00000000),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.enabled
                    ? theme.colors.foreground
                    : theme.colors.secondaryForeground.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

