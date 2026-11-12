import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Interactive navigation sidebar item (`AdwSidebarItem`).
///
/// Implements the selection style of GNOME Libadwaita:
/// - Subtle background on hover.
/// - Rounded selection highlight (6px).
/// - Symbolic icon vertically aligned with the title text.
class AdwSidebarItem extends StatefulWidget {
  final Widget? icon;
  final Widget title;
  final Widget? trailing;
  final bool isSelected;
  final VoidCallback? onTap;

  const AdwSidebarItem({
    super.key,
    this.icon,
    required this.title,
    this.trailing,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<AdwSidebarItem> createState() => _AdwSidebarItemState();
}

class _AdwSidebarItemState extends State<AdwSidebarItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final isDark = theme.colors.isDark;

    Color bg = const Color(0x00000000);
    if (widget.isSelected) {
      if (_isPressed) {
        bg = isDark ? const Color(0x30FFFFFF) : const Color(0x1E000000); // 19%
      } else if (_isHovered) {
        bg = isDark ? const Color(0x21FFFFFF) : const Color(0x16000000); // 13%
      } else {
        bg = theme.colors.sidebarSelectedBackground; // 10% -> exact #424246 over #2e2e32
      }
    } else if (_isPressed) {
      bg = isDark ? const Color(0x29FFFFFF) : const Color(0x14000000); // 16%
    } else if (_isHovered) {
      bg = isDark ? const Color(0x12FFFFFF) : const Color(0x0A000000); // 7%
    }

    final effectiveFg = theme.colors.windowForeground;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AdwCurves.shortDuration,
            constraints: const BoxConstraints(minHeight: 42.0),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  SizedBox(
                    width: AdwMetrics.iconSizeSmall,
                    height: AdwMetrics.iconSizeSmall,
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(
                          color: effectiveFg,
                          size: AdwMetrics.iconSizeSmall,
                        ),
                        child: widget.icon!,
                      ),
                    ),
                  ),
                  const SizedBox(width: AdwMetrics.spacingMedium),
                ],
                Expanded(
                  child: DefaultTextStyle(
                    style: theme.typography.body.copyWith(
                      color: effectiveFg,
                      height: 1.0,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: widget.title,
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

