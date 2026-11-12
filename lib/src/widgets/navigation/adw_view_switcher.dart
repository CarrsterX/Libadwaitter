import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Item descriptor for [AdwViewSwitcher].
class AdwViewSwitcherItem {
  final Widget? icon;
  final String title;
  final Widget? badge;

  const AdwViewSwitcherItem({
    this.icon,
    required this.title,
    this.badge,
  });
}

/// Segmented view switcher control (`AdwViewSwitcher`).
///
/// Switches between main views using segmented pill tabs placed inside
/// the header bar (as seen in GNOME Software).
class AdwViewSwitcher extends StatelessWidget {
  final List<AdwViewSwitcherItem> items;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const AdwViewSwitcher({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.buttonBackground,
        borderRadius: BorderRadius.circular(AdwMetrics.pillRadius),
        border: Border.all(
          color: theme.colors.borderColor,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++)
            _ViewSwitcherTab(
              item: items[i],
              isSelected: i == currentIndex,
              onTap: () => onIndexChanged(i),
            ),
        ],
      ),
    );
  }
}

class _ViewSwitcherTab extends StatefulWidget {
  final AdwViewSwitcherItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewSwitcherTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ViewSwitcherTab> createState() => _ViewSwitcherTabState();
}

class _ViewSwitcherTabState extends State<_ViewSwitcherTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    Color backgroundColor = const Color(0x00000000);
    if (widget.isSelected) {
      backgroundColor = theme.colors.cardBackground;
    } else if (_isHovered) {
      backgroundColor = theme.colors.hoverBackground;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AdwCurves.shortDuration,
          curve: AdwCurves.standard,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AdwMetrics.pillRadius),
            boxShadow: widget.isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.item.icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: 16,
                    color: widget.isSelected
                        ? theme.colors.foreground
                        : theme.colors.secondaryForeground,
                  ),
                  child: widget.item.icon!,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.item.title,
                style: theme.typography.body.copyWith(
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: widget.isSelected
                      ? theme.colors.foreground
                      : theme.colors.secondaryForeground,
                ),
              ),
              if (widget.item.badge != null) ...[
                const SizedBox(width: 6),
                widget.item.badge!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

