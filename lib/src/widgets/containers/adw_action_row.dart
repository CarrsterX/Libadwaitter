import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Standard Libadwaita action row (`AdwActionRow`).
///
/// Designed to be used inside an [AdwPreferencesGroup] or standalone.
/// Accepts either [prefix] / [leading] on the left and [suffix] / [trailing] on the right.
class AdwActionRow extends StatefulWidget {
  final Widget? leading;
  final Widget? prefix;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? suffix;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final bool isActivatable;

  const AdwActionRow({
    super.key,
    this.leading,
    this.prefix,
    required this.title,
    this.subtitle,
    this.trailing,
    this.suffix,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.isActivatable = true,
  });

  Widget? get effectivePrefix => prefix ?? leading;
  Widget? get effectiveSuffix => suffix ?? trailing;

  @override
  State<AdwActionRow> createState() => _AdwActionRowState();
}

class _AdwActionRowState extends State<AdwActionRow> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isClickable => widget.onPressed != null && widget.isActivatable;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final prefixWidget = widget.effectivePrefix;
    final suffixWidget = widget.effectiveSuffix;

    Color rowColor = const Color(0x00000000);
    if (_isClickable) {
      if (_isPressed) {
        rowColor = theme.colors.activeColor;
      } else if (_isHovered) {
        rowColor = theme.colors.hoverColor;
      }
    }

    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AdwMetrics.rowMinHeight),
      child: Padding(
        padding: widget.padding,
        child: Row(
          children: [
            if (prefixWidget != null) ...[
              IconTheme(
                data: IconThemeData(
                  color: theme.colors.windowForeground,
                  size: AdwMetrics.iconSizeMedium,
                ),
                child: prefixWidget,
              ),
              const SizedBox(width: AdwMetrics.spacingMedium),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: theme.typography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    child: widget.title,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: theme.typography.subtitle,
                      child: widget.subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (suffixWidget != null) ...[
              const SizedBox(width: AdwMetrics.spacingMedium),
              IconTheme(
                data: IconThemeData(
                  color: theme.colors.secondaryForeground,
                  size: AdwMetrics.iconSizeMedium,
                ),
                child: suffixWidget,
              ),
            ],
          ],
        ),
      ),
    );

    return MouseRegion(
      cursor: _isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (_isClickable) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isClickable) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (_isClickable) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (_isClickable) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (_isClickable) setState(() => _isPressed = false);
        },
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AdwCurves.shortDuration,
          color: rowColor,
          child: content,
        ),
      ),
    );
  }
}

