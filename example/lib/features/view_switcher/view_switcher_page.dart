import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class ViewSwitcherPage extends StatelessWidget {
  const ViewSwitcherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.viewSwitcher, size: 128),
      title: const Text('View Switcher'),
      description: const Text("Widgets to switch the window's view"),
      child: Center(
        child: Builder(
          builder: (innerContext) => AdwButton.pill(
            onPressed: () => _openViewSwitcherDemoDialog(innerContext),
            child: const Text('Run the Demo'),
          ),
        ),
      ),
    );
  }

  void _openViewSwitcherDemoDialog(BuildContext context) {
    int currentIndex = 0;
    const items = [
      AdwViewSwitcherItem(
        icon: DemoWidgetIcon(DemoIconType.clockWorld, size: 16),
        title: 'World',
      ),
      AdwViewSwitcherItem(
        icon: DemoWidgetIcon(DemoIconType.clockAlarm, size: 16),
        title: 'Alarm',
      ),
      AdwViewSwitcherItem(
        icon: DemoWidgetIcon(DemoIconType.clockStopwatch, size: 16),
        title: 'Stopwatch',
        badgeNumber: 3,
      ),
      AdwViewSwitcherItem(
        icon: DemoWidgetIcon(DemoIconType.clockTimer, size: 16),
        title: 'Timer',
        needsAttention: true,
      ),
    ];

    const pages = [
      AdwStatusPage(
        icon: DemoWidgetIcon(DemoIconType.clockWorld, size: 128),
        title: Text('World'),
        description: Text('World clocks view'),
      ),
      AdwStatusPage(
        icon: DemoWidgetIcon(DemoIconType.clockAlarm, size: 128),
        title: Text('Alarm'),
        description: Text('Alarms view'),
      ),
      AdwStatusPage(
        icon: DemoWidgetIcon(DemoIconType.clockStopwatch, size: 128),
        title: Text('Stopwatch'),
        description: Text('3 active laps'),
      ),
      AdwStatusPage(
        icon: DemoWidgetIcon(DemoIconType.clockTimer, size: 128),
        title: Text('Timer'),
        description: Text('Timer needs attention'),
      ),
    ];

    showAdwDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AdwDialog(
            contentWidth: 640,
            contentHeight: 480,
            title: 'AdwViewSwitcher Demo',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth <= 550;
                return AdwToolbarView(
                  topBar: AdwHeaderBar(
                    isFlat: true,
                    title: isNarrow ? const Text('AdwViewSwitcher Demo') : null,
                    titleWidget: isNarrow
                        ? null
                        : AdwViewSwitcher(
                            items: items,
                            currentIndex: currentIndex,
                            policy: AdwViewSwitcherPolicy.wide,
                            onIndexChanged: (i) =>
                                setDialogState(() => currentIndex = i),
                          ),
                  ),
                  content: pages[currentIndex],
                  bottomBar: AdwViewSwitcherBar(
                    items: items,
                    currentIndex: currentIndex,
                    reveal: isNarrow,
                    onIndexChanged: (i) =>
                        setDialogState(() => currentIndex = i),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

