import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';
import '../controls/adw_switch.dart';

/// An expandable preference row with collapsible nested children (`AdwExpanderRow`).
///
/// Follows the GNOME Libadwaita Expander Row pattern:
/// - Interactive header displaying title, subtitle, prefix, and optional action suffix.
/// - Smooth animated chevron rotation indicating expansion state.
/// - Optional enable switch (`showEnableSwitch`) controlling row interactivity and expansion.
/// - Fluid accordion expand/collapse transition with internal 1px hairline dividers.
class AdwExpanderRow extends StatefulWidget {
  /// The primary label displayed on the row header.
  final Widget title;

  /// An optional descriptive subtitle displayed below [title].
  final Widget? subtitle;

  /// An optional widget placed before the title (e.g. symbolic icon).
  final Widget? prefix;

  /// Alias for [prefix] adhering to standard Flutter conventions.
  final Widget? leading;

  /// An optional action widget placed before the switch and expander chevron.
  final Widget? suffix;

  /// Alias for [suffix] adhering to standard Flutter conventions.
  final Widget? trailing;

  /// The list of nested child preference rows revealed when expanded.
  final List<Widget> children;

  /// Explicit controlled expansion state. When non-null, overrides internal state.
  final bool? expanded;

  /// Initial expansion state when [expanded] is omitted.
  final bool initialExpanded;

  /// Whether to display an integrated enable [AdwSwitch] on the header.
  final bool showEnableSwitch;

  /// Whether the row is enabled and interactive.
  final bool enabled;

  /// Whether the user is permitted to toggle the expansion state.
  final bool enableExpansion;

  /// Called when the enabled state changes via the integrated switch.
  final ValueChanged<bool>? onEnabledChanged;

  /// Called when the expansion state changes.
  final ValueChanged<bool>? onExpandedChanged;

  /// Padding applied to the header row.
  final EdgeInsetsGeometry padding;

  const AdwExpanderRow({
    super.key,
    required this.title,
    this.subtitle,
    this.prefix,
    this.leading,
    this.suffix,
    this.trailing,
    this.children = const <Widget>[],
    this.expanded,
    this.initialExpanded = false,
    this.showEnableSwitch = false,
    this.enabled = true,
    this.enableExpansion = true,
    this.onEnabledChanged,
    this.onExpandedChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  Widget? get effectivePrefix => prefix ?? leading;
  Widget? get effectiveSuffix => suffix ?? trailing;

  @override
  State<AdwExpanderRow> createState() => _AdwExpanderRowState();
}

class _AdwExpanderRowState extends State<AdwExpanderRow>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late bool _isEnabled;
  bool _isHovered = false;

  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expanded ?? widget.initialExpanded;
    _isEnabled = widget.enabled;

    _animController = AnimationController(
      vsync: this,
      duration: AdwCurves.normalDuration,
      value: _isExpanded ? 1.0 : 0.0,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: AdwCurves.standard,
    );

    // Chevron rotates 180 degrees (from pointing down to pointing up)
    _arrowAnimation =
        Tween<double>(begin: 0.0, end: math.pi).animate(_expandAnimation);
  }

  @override
  void didUpdateWidget(covariant AdwExpanderRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled != oldWidget.enabled) {
      setState(() {
        _isEnabled = widget.enabled;
        if (!_isEnabled && _isExpanded) {
          _isExpanded = false;
          _animController.reverse();
        }
      });
    }

    if (widget.expanded != null && widget.expanded != oldWidget.expanded) {
      if (widget.expanded! != _isExpanded) {
        setState(() {
          _isExpanded = widget.expanded!;
          if (_isExpanded) {
            _animController.forward();
          } else {
            _animController.reverse();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (!_isEnabled || !widget.enableExpansion) return;
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
      widget.onExpandedChanged?.call(_isExpanded);
    });
  }

  void _toggleEnabled(bool value) {
    setState(() {
      _isEnabled = value;
      widget.onEnabledChanged?.call(value);
      if (!_isEnabled && _isExpanded) {
        _isExpanded = false;
        _animController.reverse();
        widget.onExpandedChanged?.call(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final prefixWidget = widget.effectivePrefix;
    final suffixWidget = widget.effectiveSuffix;
    final canExpand = _isEnabled && widget.enableExpansion;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Interactive Expander Header Row
        MouseRegion(
          cursor:
              canExpand ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleExpanded,
            child: AnimatedContainer(
              duration: AdwCurves.shortDuration,
              curve: AdwCurves.standard,
              constraints: const BoxConstraints(minHeight: AdwMetrics.rowMinHeight),
              color: _isHovered && canExpand
                  ? theme.colors.hoverBackground
                  : const Color(0x00000000),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DefaultTextStyle(
                          style: theme.typography.body.copyWith(
                            fontSize: 14.0,
                            fontWeight: FontWeight.normal,
                            color: theme.colors.windowForeground,
                          ),
                          child: widget.title,
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          DefaultTextStyle(
                            style: theme.typography.subtitle.copyWith(
                              color: theme.colors.secondaryForeground,
                            ),
                            child: widget.subtitle!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (suffixWidget != null) ...[
                    const SizedBox(width: AdwMetrics.spacingMedium),
                    suffixWidget,
                  ],
                  if (widget.showEnableSwitch) ...[
                    const SizedBox(width: AdwMetrics.spacingMedium),
                    GestureDetector(
                      // Prevent switch taps from bubbling up to row expansion
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: AdwSwitch(
                        value: _isEnabled,
                        onChanged: _toggleEnabled,
                      ),
                    ),
                  ],
                  const SizedBox(width: AdwMetrics.spacingMedium),
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_expandAnimation.value * math.pi,
                        child: _ExpanderChevron(
                          color: !canExpand
                              ? (theme.colors.isDark
                                      ? const Color(0xFFA3A3A5)
                                      : const Color(0xFF8F8F92))
                                  .withValues(alpha: 0.3)
                              : (_isExpanded
                                  ? const Color(0xFF81D0FF)
                                  : (theme.colors.isDark
                                      ? const Color(0xFFA3A3A5)
                                      : const Color(0xFF8F8F92))),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Collapsible nested children container
        ClipRect(
          child: SizeTransition(
            sizeFactor: _expandAnimation,
            child: ColoredBox(
              color: theme.colors.windowBackground,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.children.length; i++) ...[
                    const SizedBox(height: 1),
                    ColoredBox(
                      color: theme.colors.isDark
                          ? const Color(0xFF2A2A2E)
                          : const Color(0xFFF6F6F6),
                      child: widget.children[i],
                    ),
                  ],
                ],
              ),
            ),
            alignment: const AlignmentDirectional(-1.0, -1.0),
          ),
        ),
      ],
    );
  }
}

/// Native vector chevron painter for [AdwExpanderRow] matching GNOME's pan-down icon.
class _ExpanderChevron extends StatelessWidget {
  final Color color;

  const _ExpanderChevron({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(
        painter: _ChevronPainter(color: color),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final Color color;

  const _ChevronPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Paints a down-pointing chevron 'v' that rotates 180deg to up-pointing '^'
    path.moveTo(size.width * 0.18, size.height * 0.34);
    path.lineTo(size.width * 0.50, size.height * 0.66);
    path.lineTo(size.width * 0.82, size.height * 0.34);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
