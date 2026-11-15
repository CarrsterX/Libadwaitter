import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';
import 'tab_view_demo_window.dart';

class TabViewPage extends StatelessWidget {
  const TabViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.tabView, size: 128),
      title: const Text('Tab View'),
      description: const Text('A modern tab widget'),
      child: Center(
        child: AdwButton.pill(
          onPressed: () => openTabViewDemoWindow(),
          child: const Text('Run the Demo'),
        ),
      ),
    );
  }
}

