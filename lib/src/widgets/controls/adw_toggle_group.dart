import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Single item descriptor within an [AdwToggleGroup].
class AdwToggleItem<T> {
  final T value;
  final Widget child;
  final Widget? icon;
  final Widget? label;
  final String? tooltip;
  final bool enabled;

  const AdwToggleItem({
    required this.value,
    this.child = const SizedBox.shrink(),
    this.icon,
    this.label,
    this.tooltip,
    this.enabled = true,
  });

  /// Convenience constructor creating a standard icon + label toggle item.
  factory AdwToggleItem.withLabel({
    required T value,
    Widget? icon,
    required Widget label,
    String? tooltip,
    bool enabled = true,
  }) {
    return AdwToggleItem(
      value: value,
      icon: icon,
      label: label,
      tooltip: tooltip,
      enabled: enabled,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: AdwMetrics.spacingSmall),
          ],
          label,
        ],
      ),
    );
  }
}

/// Official Libadwaita segmented toggle group (`AdwToggleGroup`).
///
/// Follows upstream Libadwaita linked button bar specifications:
/// - GitLab source: `https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/...`
/// - CSS selector: `.linked.toggle-group`
///
/// Displays multiple mutually-exclusive options in a unified rounded container (6px radius)
/// with an animated active pill indicator and 1px dividers between unselected items.
class AdwToggleGroup<T> extends StatelessWidget {
  /// The list of selectable items.
  final List<AdwToggleItem<T>> items;

  /// The currently active selected value.
  final T selectedValue;

  /// Callback emitted when a new item is selected.
  final ValueChanged<T>? onChanged;

  /// Minimum height of each toggle item (default [AdwMetrics.buttonMinHeight]).
  final double height;

  /// Padding surrounding each individual toggle segment.
  final EdgeInsetsGeometry itemPadding;

  /// Whether all segments expand to share equal width across the container.
  final bool homogeneous;

  const AdwToggleGroup({
    super.key,
    required this.items,
    required this.selectedValue,
    this.onChanged,
    this.height = AdwMetrics.buttonMinHeight,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    this.homogeneous = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final List<Widget> children = [];

    for (int index = 0; index < items.length; index++) {
      final item = items[index];
      final isSelected = item.value == selectedValue;
      final isLast = index == items.length - 1;
      final nextIsSelected = !isLast && items[index + 1].value == selectedValue;

      final segment = _AdwToggleSegment<T>(
        item: item,
        isSelected: isSelected,
        padding: itemPadding,
        onSelected: item.enabled && onChanged != null
            ? () => onChanged!(item.value)
            : null,
      );

      children.add(homogeneous ? Expanded(child: segment) : segment);

      if (!isLast && !isSelected && !nextIsSelected) {
        children.add(
          Container(
            width: 1,
            height: height * 0.5,
            color: theme.colors.dividerColor,
          ),
        );
      }
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colors.cardBackground,
        borderRadius: BorderRadius.circular(AdwMetrics.buttonRadius),
        border: Border.all(
          color: theme.colors.borderColor,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: homogeneous ? MainAxisSize.max : MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _AdwToggleSegment<T> extends StatefulWidget {
  final AdwToggleItem<T> item;
  final bool isSelected;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onSelected;

  const _AdwToggleSegment({
    required this.item,
    required this.isSelected,
    required this.padding,
    this.onSelected,
  });

  @override
  State<_AdwToggleSegment<T>> createState() => _AdwToggleSegmentState<T>();
}

class _AdwToggleSegmentState<T> extends State<_AdwToggleSegment<T>> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isClickable => widget.item.enabled && widget.onSelected != null;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final duration = AdwCurves.resolve(context, AdwCurves.shortDuration);

    Color bg = const Color(0x00000000);
    Color fg = theme.colors.foreground;

    if (widget.isSelected) {
      bg = theme.colors.buttonBackground;
      fg = theme.colors.foreground;
    } else if (_isClickable) {
      if (_isPressed) {
        bg = theme.colors.activeColor;
      } else if (_isHovered) {
        bg = theme.colors.hoverColor;
      }
    }

    if (!widget.item.enabled) {
      fg = fg.withOpacity(0.4);
    }

    Widget content = widget.item.child;
    if (widget.item.icon != null || widget.item.label != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.item.icon != null) ...[
            IconTheme(
              data: IconThemeData(
                color: fg,
                size: AdwMetrics.iconSizeSmall,
              ),
              child: widget.item.icon!,
            ),
            if (widget.item.label != null)
              const SizedBox(width: AdwMetrics.spacingSmall),
          ],
          if (widget.item.label != null)
            DefaultTextStyle(
              style: theme.typography.body.copyWith(
                color: fg,
                height: 1.0,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: widget.item.label!,
            ),
        ],
      );
    }

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
        onTap: widget.onSelected,
        child: AnimatedContainer(
          duration: duration,
          curve: AdwCurves.standard,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AdwMetrics.buttonRadius - 2),
            boxShadow: widget.isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: DefaultTextStyle(
              style: theme.typography.body.copyWith(
                color: fg,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

