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
      builder: (_) => const AdwDialog(
        contentWidth: 640,
        contentHeight: 480,
        title: 'Navigation Split View',
        child: AdwNavigationSplitView(
          sidebarWidth: 220,
          breakpoint: 400,
          sidebar: AdwToolbarView(
            topBar: AdwHeaderBar(
              isFlat: true,
              title: Text('Sidebar'),
            ),
            content: Center(
              child: Text('Sidebar'),
            ),
          ),
          content: AdwToolbarView(
            topBar: AdwHeaderBar(
              isFlat: true,
              title: Text('Content'),
            ),
            content: Center(
              child: Text('Content'),
            ),
          ),
        ),
      ),
    );
  }

  void _openOverlaySplitViewDemoDialog(BuildContext context) {
    bool showSidebar = true;
    AdwSplitViewPosition sidebarPosition = AdwSplitViewPosition.start;

    showAdwDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AdwDialog(
            contentWidth: 640,
            contentHeight: 480,
            title: 'Overlay Split View',
            child: AdwOverlaySplitView(
              sidebarWidth: 220,
              collapseBreakpoint: 450,
              showSidebar: showSidebar,
              sidebarPosition: sidebarPosition,
              onShowSidebarChanged: (visible) =>
                  setDialogState(() => showSidebar = visible),
              sidebar: const AdwToolbarView(
                topBar: AdwHeaderBar(
                  isFlat: true,
                  title: Text('Sidebar'),
                ),
                content: Center(
                  child: Text('Sidebar'),
                ),
              ),
              content: AdwToolbarView(
                topBar: AdwHeaderBar(
                  title: const Text('Content'),
                  start: AdwButton.flat(
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
                  ),
                ),
                content: Center(
                  child: AdwToggleGroup<AdwSplitViewPosition>(
                    selectedValue: sidebarPosition,
                    onChanged: (pos) =>
                        setDialogState(() => sidebarPosition = pos),
                    items: const [
                      AdwToggleItem(
                        value: AdwSplitViewPosition.start,
                        label: Text('Start'),
                      ),
                      AdwToggleItem(
                        value: AdwSplitViewPosition.end,
                        label: Text('End'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
