import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_theme.dart';
import '../layout/adw_window.dart';

/// Adaptive navigation split view (`AdwNavigationSplitView`).
///
/// An architectural pillar of modern GNOME applications (seen in `adwaita-1-demo`
/// and Nautilus):
/// - Left pane: a navigation [sidebar] with dedicated background and border divider.
/// - Right pane: the primary [content] canvas.
/// - Automatically collapses the sidebar when the layout width is below [breakpoint] (default 720px).
class AdwNavigationSplitView extends StatelessWidget {
  final Widget sidebar;
  final Widget content;
  final double sidebarWidth;
  final double breakpoint;
  final bool? collapsed;
  final bool showSidebar;
  final bool showBorder;

  const AdwNavigationSplitView({
    super.key,
    required this.sidebar,
    required this.content,
    this.sidebarWidth = 240.0,
    this.breakpoint = 720.0,
    this.collapsed,
    this.showSidebar = true,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final isWindowActive = AdwWindowScope.maybeOf(context)?.isActive ?? true;
    final effectiveSidebarBg = isWindowActive
        ? theme.colors.sidebarBackground
        : theme.colors.sidebarBackdropBackground;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isAutoCollapsed = constraints.maxWidth < breakpoint;
        final isEffectiveCollapsed = collapsed ?? isAutoCollapsed;

        if (isEffectiveCollapsed) {
          // Collapsed narrow window or mobile view: shows either sidebar or content
          return Container(
            color: theme.colors.windowBackground,
            child: showSidebar ? sidebar : content,
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSidebar)
              AnimatedContainer(
                duration: AdwCurves.normalDuration,
                curve: AdwCurves.standard,
                width: sidebarWidth,
                decoration: BoxDecoration(
                  color: effectiveSidebarBg,
                  border: showBorder
                      ? Border(
                          right: BorderSide(
                            color: theme.colors.sidebarBorder,
                            width: 1,
                          ),
                        )
                      : null,
                ),
                child: sidebar,
              ),
            Expanded(
              child: Container(
                color: theme.colors.windowBackground,
                child: content,
              ),
            ),
          ],
        );
      },
    );
  }
}

