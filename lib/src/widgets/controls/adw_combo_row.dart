import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Preference row with a native GTK4/Libadwaita popover dropdown (`AdwComboRow`).
///
/// Displays the currently selected value next to a trailing dropdown indicator
/// and opens an anchored popover menu below (or above) the row when activated.
class AdwComboRow<T> extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? prefix;
  final List<T> items;
  final T selectedItem;
  final String Function(T item)? itemTitleBuilder;
  final ValueChanged<T>? onSelected;

  const AdwComboRow({
    super.key,
    required this.title,
    this.subtitle,
    this.prefix,
    required this.items,
    required this.selectedItem,
    this.itemTitleBuilder,
    this.onSelected,
  });

  @override
  State<AdwComboRow<T>> createState() => _AdwComboRowState<T>();
}

class _AdwComboRowState<T> extends State<AdwComboRow<T>> {
  bool _isHovered = false;
  bool _isPressed = false;

  String _formatItem(T item) {
    if (widget.itemTitleBuilder != null) {
      return widget.itemTitleBuilder!(item);
    }
    return item.toString();
  }

  void _showPopoverMenu(BuildContext context) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final Offset rowOrigin = renderBox.localToGlobal(Offset.zero);
    final Size rowSize = renderBox.size;
    final Rect anchorRect = rowOrigin & rowSize;
    final themeData = AdwTheme.maybeOf(context);
    final animDuration = AdwCurves.resolve(context, AdwCurves.shortDuration);

    Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: const Color(0x00000000),
        transitionDuration: animDuration,
        reverseTransitionDuration: animDuration,
        pageBuilder: (popoverContext, animation, secondaryAnimation) {
          Widget popover = _AdwComboPopover<T>(
            anchorRect: anchorRect,
            items: widget.items,
            selectedItem: widget.selectedItem,
            formatItem: _formatItem,
            animation: animation,
            onSelected: (item) {
              Navigator.of(popoverContext).pop();
              widget.onSelected?.call(item);
            },
          );

          if (AdwTheme.maybeOf(popoverContext) == null && themeData != null) {
            popover = AdwTheme(data: themeData, child: popover);
          }

          return popover;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    Color rowBg = const Color(0x00000000);
    if (_isPressed) {
      rowBg = theme.colors.activeColor;
    } else if (_isHovered) {
      rowBg = theme.colors.hoverBackground;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => _showPopoverMenu(context),
        child: AnimatedContainer(
          duration: AdwCurves.shortDuration,
          curve: AdwCurves.standard,
          constraints: const BoxConstraints(minHeight: AdwMetrics.rowMinHeight),
          color: rowBg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (widget.prefix != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: theme.colors.windowForeground,
                    size: AdwMetrics.iconSizeMedium,
                  ),
                  child: widget.prefix!,
                ),
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
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatItem(widget.selectedItem),
                    style: theme.typography.body.copyWith(
                      color: theme.colors.secondaryForeground,
                    ),
                  ),
                  const SizedBox(width: 6),
                  CustomPaint(
                    size: const Size(10, 10),
                    painter: _ChevronDownPainter(
                      color: theme.colors.secondaryForeground.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdwComboPopover<T> extends StatelessWidget {
  final Rect anchorRect;
  final List<T> items;
  final T selectedItem;
  final String Function(T item) formatItem;
  final Animation<double> animation;
  final ValueChanged<T> onSelected;

  const _AdwComboPopover({
    required this.anchorRect,
    required this.items,
    required this.selectedItem,
    required this.formatItem,
    required this.animation,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final curved = CurvedAnimation(parent: animation, curve: AdwCurves.standard);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => Navigator.of(context).pop(),
      child: CustomSingleChildLayout(
        delegate: _PopoverLayoutDelegate(anchorRect: anchorRect),
        child: GestureDetector(
          // Absorb taps inside the popover so outside barrier doesn't dismiss prematurely.
          onTap: () {},
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              alignment: Alignment.topRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 168,
                  maxWidth: 260,
                  maxHeight: 320,
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colors.popoverBackground,
                    borderRadius: BorderRadius.circular(AdwMetrics.cardRadius),
                    border: Border.all(
                      color: theme.colors.borderColor,
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x45000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: items.map((item) {
                        final isSelected = item == selectedItem;
                        return _AdwPopoverItem(
                          label: formatItem(item),
                          isSelected: isSelected,
                          onTap: () => onSelected(item),
                        );
                      }).toList(),
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

class _AdwPopoverItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdwPopoverItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AdwPopoverItem> createState() => _AdwPopoverItemState();
}

class _AdwPopoverItemState extends State<_AdwPopoverItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    Color bg = const Color(0x00000000);
    if (_isPressed) {
      bg = theme.colors.activeColor;
    } else if (_isHovered) {
      bg = theme.colors.hoverColor;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AdwMetrics.buttonRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.typography.body.copyWith(
                    color: theme.colors.popoverForeground,
                    height: 1.15,
                  ),
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 8),
                CustomPaint(
                  size: const Size(12, 12),
                  painter: _CheckmarkPainter(
                    color: theme.colors.popoverForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PopoverLayoutDelegate extends SingleChildLayoutDelegate {
  final Rect anchorRect;

  _PopoverLayoutDelegate({required this.anchorRect});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const double edgeMargin = 12.0;
    const double verticalGap = 4.0;

    // Align right edge of popover with the right side of the row.
    double x = anchorRect.right - childSize.width - 8.0;
    x = x.clamp(edgeMargin, math.max(edgeMargin, size.width - childSize.width - edgeMargin));

    // Place below the row if space permits; otherwise flip above.
    double y = anchorRect.bottom + verticalGap;
    if (y + childSize.height > size.height - edgeMargin) {
      final aboveY = anchorRect.top - childSize.height - verticalGap;
      if (aboveY >= edgeMargin) {
        y = aboveY;
      } else {
        y = math.max(edgeMargin, size.height - childSize.height - edgeMargin);
      }
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _PopoverLayoutDelegate oldDelegate) {
    return anchorRect != oldDelegate.anchorRect;
  }
}

class _ChevronDownPainter extends CustomPainter {
  final Color color;

  const _ChevronDownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(1.5, size.height * 0.35)
      ..lineTo(size.width / 2, size.height * 0.7)
      ..lineTo(size.width - 1.5, size.height * 0.35);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronDownPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class _CheckmarkPainter extends CustomPainter {
  final Color color;

  const _CheckmarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(2.0, size.height * 0.55)
      ..lineTo(size.width * 0.42, size.height * 0.78)
      ..lineTo(size.width - 1.5, size.height * 0.22);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
