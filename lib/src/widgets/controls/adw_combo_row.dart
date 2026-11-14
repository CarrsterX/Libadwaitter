import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/adw_localizations.dart';
import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Preference row with a native GTK4/Libadwaita popover dropdown (`AdwComboRow`).
///
/// Displays the currently selected value next to a trailing dropdown indicator
/// and opens an anchored popover menu below (or above) the chevron when activated.
class AdwComboRow<T> extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? prefix;
  final List<T> items;
  final T selectedItem;
  final String Function(T item)? itemTitleBuilder;
  final ValueChanged<T>? onSelected;
  final bool enableSearch;
  final String? searchPlaceholder;

  const AdwComboRow({
    super.key,
    required this.title,
    this.subtitle,
    this.prefix,
    required this.items,
    required this.selectedItem,
    this.itemTitleBuilder,
    this.onSelected,
    this.enableSearch = false,
    this.searchPlaceholder,
  });

  @override
  State<AdwComboRow<T>> createState() => _AdwComboRowState<T>();
}

class _AdwComboRowState<T> extends State<AdwComboRow<T>> {
  final GlobalKey _chevronKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  String _formatItem(T item) {
    if (widget.itemTitleBuilder != null) {
      return widget.itemTitleBuilder!(item);
    }
    return item.toString();
  }

  void _showPopoverMenu(BuildContext context) {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final Offset rowOrigin = renderBox.localToGlobal(Offset.zero);
    final Size rowSize = renderBox.size;
    final Rect anchorRect = rowOrigin & rowSize;

    final RenderBox? chevronBox =
        _chevronKey.currentContext?.findRenderObject() as RenderBox?;
    final Rect chevronRect = (chevronBox != null && chevronBox.hasSize)
        ? (chevronBox.localToGlobal(Offset.zero) & chevronBox.size)
        : Rect.fromCenter(
            center: Offset(anchorRect.right - 19.0, anchorRect.center.dy),
            width: 10,
            height: 10,
          );

    final themeData = AdwTheme.maybeOf(context);
    final l10n = AdwLocalizations.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (popoverContext) {
        Widget popover = _AdwComboPopover<T>(
          anchorRect: anchorRect,
          chevronRect: chevronRect,
          items: widget.items,
          selectedItem: widget.selectedItem,
          formatItem: _formatItem,
          enableSearch: widget.enableSearch,
          searchPlaceholder: widget.searchPlaceholder ?? l10n.searchPlaceholder,
          onDismiss: _removeOverlay,
          onSelected: (item) {
            _removeOverlay();
            widget.onSelected?.call(item);
          },
        );

        if (AdwTheme.maybeOf(popoverContext) == null && themeData != null) {
          popover = AdwTheme(data: themeData, child: popover);
        }

        return popover;
      },
    );

    _overlayEntry = entry;
    overlay.insert(entry);
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        fontSize: 14.0,
                        fontWeight: FontWeight.normal,
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      _formatItem(widget.selectedItem),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.copyWith(
                        color: theme.colors.windowForeground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CustomPaint(
                    key: _chevronKey,
                    size: const Size(10, 10),
                    painter: _ChevronDownPainter(
                      color: theme.colors.windowForeground,
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

class _AdwComboPopover<T> extends StatefulWidget {
  final Rect anchorRect;
  final Rect chevronRect;
  final List<T> items;
  final T selectedItem;
  final String Function(T item) formatItem;
  final bool enableSearch;
  final String searchPlaceholder;
  final VoidCallback onDismiss;
  final ValueChanged<T> onSelected;

  const _AdwComboPopover({
    required this.anchorRect,
    required this.chevronRect,
    required this.items,
    required this.selectedItem,
    required this.formatItem,
    required this.enableSearch,
    required this.searchPlaceholder,
    required this.onDismiss,
    required this.onSelected,
  });

  @override
  State<_AdwComboPopover<T>> createState() => _AdwComboPopoverState<T>();
}

class _AdwComboPopoverState<T> extends State<_AdwComboPopover<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchFocused = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleFocusChange);
    if (widget.enableSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final textDirection = Directionality.of(context);
    final itemStyle = theme.typography.body.copyWith(height: 1.15);

    double maxItemTextWidth = 0.0;
    for (final item in widget.items) {
      final painter = TextPainter(
        text: TextSpan(text: widget.formatItem(item), style: itemStyle),
        maxLines: 1,
        textDirection: textDirection,
      )..layout();
      if (painter.width > maxItemTextWidth) {
        maxItemTextWidth = painter.width;
      }
      painter.dispose();
    }
    // Container padding (12) + item horizontal padding (20) + gap (8) + checkmark (12) + scrollbar clearance (10).
    final double popoverWidth = (maxItemTextWidth + 62.0).clamp(
      widget.enableSearch ? 180.0 : 140.0,
      280.0,
    );

    final filteredItems = _query.isEmpty
        ? widget.items
        : widget.items
            .where((item) => widget
                .formatItem(item)
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList(growable: false);

    final searchBg = theme.colors.isDark
        ? const Color(0xFF47474B)
        : const Color(0xFFE6E6EA);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss,
      },
      child: FocusScope(
        autofocus: !widget.enableSearch,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onDismiss,
          child: CustomSingleChildLayout(
            delegate: _PopoverLayoutDelegate(
              anchorRect: widget.anchorRect,
              chevronRect: widget.chevronRect,
            ),
            child: GestureDetector(
              // Absorb taps inside the popover so outside barrier doesn't dismiss prematurely.
              onTap: () {},
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: popoverWidth,
                  maxWidth: popoverWidth,
                  maxHeight: widget.enableSearch ? 380 : 320,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.enableSearch) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: searchBg,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: _searchFocused
                                    ? theme.colors.accentColor
                                        .withValues(alpha: 0.75)
                                    : theme.colors.borderColor,
                                width: _searchFocused ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                CustomPaint(
                                  size: const Size(14, 14),
                                  painter: _SearchIconPainter(
                                    color: theme.colors.secondaryForeground,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      if (_query.isEmpty)
                                        Text(
                                          widget.searchPlaceholder,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.typography.body.copyWith(
                                            fontSize: 14,
                                            color: theme
                                                .colors.secondaryForeground,
                                          ),
                                        ),
                                      EditableText(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        cursorWidth: 1.0,
                                        cursorOpacityAnimates: true,
                                        showCursor: true,
                                        enableInteractiveSelection: true,
                                        style: theme.typography.body.copyWith(
                                          fontSize: 14,
                                          color: theme.colors.popoverForeground,
                                        ),
                                        cursorColor:
                                            theme.colors.windowForeground,
                                        backgroundCursorColor: theme
                                            .colors.windowForeground
                                            .withValues(alpha: 0.14),
                                        selectionColor: theme.colors.accentColor
                                            .withValues(alpha: 0.35),
                                        onChanged: (val) =>
                                            setState(() => _query = val),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: filteredItems.map((item) {
                              final isSelected = item == widget.selectedItem;
                              return _AdwPopoverItem(
                                label: widget.formatItem(item),
                                isSelected: isSelected,
                                onTap: () => widget.onSelected(item),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
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
  final Rect chevronRect;

  _PopoverLayoutDelegate({
    required this.anchorRect,
    required this.chevronRect,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const double edgeMargin = 12.0;
    const double verticalGap = 4.0;

    // Position close to the trailing dropdown chevron so the popover feels directly anchored.
    double x = chevronRect.center.dx + 28.0 - childSize.width;
    x = x.clamp(edgeMargin, math.max(edgeMargin, size.width - childSize.width - edgeMargin));

    // Place directly below the chevron if space permits; otherwise flip above.
    double y = chevronRect.bottom + verticalGap;
    if (y + childSize.height > size.height - edgeMargin) {
      final aboveY = chevronRect.top - childSize.height - verticalGap;
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
    return anchorRect != oldDelegate.anchorRect ||
        chevronRect != oldDelegate.chevronRect;
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

class _SearchIconPainter extends CustomPainter {
  final Color color;

  const _SearchIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final radius = size.width * 0.34;
    final center = Offset(radius + 1.0, radius + 1.0);
    canvas.drawCircle(center, radius, paint);

    final handleStart = Offset(
      center.dx + radius * 0.72,
      center.dy + radius * 0.72,
    );
    final handleEnd = Offset(size.width - 1.0, size.height - 1.0);
    canvas.drawLine(handleStart, handleEnd, paint);
  }

  @override
  bool shouldRepaint(covariant _SearchIconPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
