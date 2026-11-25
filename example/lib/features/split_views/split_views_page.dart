import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class SplitViewsPage extends StatelessWidget {
  const SplitViewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.splitView, size: 128),
      title: const Text('Split Views'),
      description: const Text('Widgets that display sidebar and content'),
      child: Center(
        child: Builder(
          builder: (innerContext) => IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdwButton.pill(
                  onPressed: () =>
                      _openNavigationSplitViewDemoDialog(innerContext),
                  child: const Text('Navigation Split View'),
                ),
                const SizedBox(height: 18),
                AdwButton.pill(
                  onPressed: () =>
                      _openOverlaySplitViewDemoDialog(innerContext),
                  child: const Text('Overlay Split View'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNavigationSplitViewDemoDialog(BuildContext context) {
    showAdwDialog<void>(
      context: context,
      builder: (_) => AdwDialog(
        contentWidth: 640,
        contentHeight: 480,
        title: 'Navigation Split View',
        child: AdwNavigationSplitView(
          sidebarWidth: 220,
          breakpoint: 451,
          sidebarTitle: 'Sidebar',
          contentTitle: 'Content',
          sidebar: AdwToolbarView(
            topBar: Builder(
              builder: (ctx) {
                final isCollapsed =
                    AdwNavigationSplitViewScope.maybeOf(ctx)?.isCollapsed ??
                        false;
                return AdwHeaderBar(
                  isFlat: true,
                  showTitle: false,
                  showWindowControls: isCollapsed,
                );
              },
            ),
            content: Builder(
              builder: (ctx) {
                final scope = AdwNavigationSplitViewScope.maybeOf(ctx);
                final isCollapsed = scope?.isCollapsed ?? false;
                return AdwStatusPage(
                  title: const Text('Sidebar'),
                  child: isCollapsed
                      ? AdwButton.pill(
                          onPressed: scope?.showContentPage,
                          child: const Text('Open Content'),
                        )
                      : null,
                );
              },
            ),
          ),
          content: const AdwToolbarView(
            topBar: AdwHeaderBar(isFlat: true, showTitle: false),
            content: AdwStatusPage(
              title: Text('Content'),
            ),
          ),
        ),
      ),
    );
  }

  void _openOverlaySplitViewDemoDialog(BuildContext context) {
    bool showSidebar = MediaQuery.sizeOf(context).width >= 450;
    AdwSplitViewPosition sidebarPosition = AdwSplitViewPosition.start;

    showAdwDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final toggleButton = AdwButton.flat(
            width: 34,
            height: 34,
            padding: EdgeInsets.zero,
            isChecked: showSidebar,
            onPressed: () =>
                setDialogState(() => showSidebar = !showSidebar),
            child: const Icon(
              AdwIcons.sidebar_show_symbolic,
              size: 16,
            ),
          );

          return AdwDialog(
            contentWidth: 640,
            contentHeight: 480,
            title: 'Overlay Split View',
            child: AdwToolbarView(
              topBarStyle: AdwToolbarStyle.raised,
              topBar: AdwHeaderBar(
                title: const Text('Overlay Split View'),
                start: sidebarPosition == AdwSplitViewPosition.start
                    ? toggleButton
                    : null,
                end: sidebarPosition == AdwSplitViewPosition.end
                    ? toggleButton
                    : null,
              ),
              content: AdwOverlaySplitView(
                sidebarWidth: 220,
                collapseBreakpoint: 451,
                showSidebar: showSidebar,
                sidebarPosition: sidebarPosition,
                onShowSidebarChanged: (visible) =>
                    setDialogState(() => showSidebar = visible),
                sidebar: AdwStatusPage(
                  title: const Text('Sidebar'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdwButton.pill(
                        isChecked:
                            sidebarPosition == AdwSplitViewPosition.start,
                        onPressed: () => setDialogState(
                          () => sidebarPosition = AdwSplitViewPosition.start,
                        ),
                        child: const Text('Start'),
                      ),
                      const SizedBox(height: 18),
                      AdwButton.pill(
                        isChecked:
                            sidebarPosition == AdwSplitViewPosition.end,
                        onPressed: () => setDialogState(
                          () => sidebarPosition = AdwSplitViewPosition.end,
                        ),
                        child: const Text('End'),
                      ),
                    ],
                  ),
                ),
                content: const AdwStatusPage(
                  title: Text('Content'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
