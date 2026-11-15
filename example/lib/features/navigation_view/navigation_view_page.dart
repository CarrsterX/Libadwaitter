import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class NavigationViewPage extends StatelessWidget {
  const NavigationViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.navigationView, size: 128),
      title: const Text('Navigation View'),
      description: const Text('A page-based navigation container'),
      child: Center(
        child: Builder(
          builder: (innerContext) => AdwButton.pill(
            onPressed: () =>
                _openNavigationViewDemoDialog(innerContext, theme),
            child: const Text('Run the Demo'),
          ),
        ),
      ),
    );
  }

  void _openNavigationViewDemoDialog(
    BuildContext context,
    AdwThemeData theme,
  ) {
    final controller = AdwNavigationViewController();
    late final AdwNavigationPage Function() buildPage2;
    late final AdwNavigationPage Function() buildPage3;
    late final AdwNavigationPage Function() buildPage4;

    buildPage3 = () => AdwNavigationPage(
          tag: 'page-3',
          title: 'Page 3',
          child: AdwToolbarView(
            topBar: const AdwHeaderBar(
              isFlat: true,
              title: Text('Page 3'),
            ),
            content: Center(
              child: Text(
                'This is Page 3',
                style: theme.typography.heading,
              ),
            ),
          ),
        );

    buildPage4 = () => AdwNavigationPage(
          tag: 'page-4',
          title: 'Page 4',
          child: AdwToolbarView(
            topBar: const AdwHeaderBar(
              isFlat: true,
              title: Text('Page 4'),
            ),
            content: Center(
              child: AdwButton.pill(
                onPressed: () => controller.push(buildPage3()),
                child: const Text('Open Page 3'),
              ),
            ),
          ),
        );

    buildPage2 = () => AdwNavigationPage(
          tag: 'page-2',
          title: 'Page 2',
          child: AdwToolbarView(
            topBar: const AdwHeaderBar(
              isFlat: true,
              title: Text('Page 2'),
            ),
            content: Center(
              child: AdwButton.pill(
                onPressed: () => controller.push(buildPage4()),
                child: const Text('Open Page 4'),
              ),
            ),
          ),
        );

    final page1 = AdwNavigationPage(
      tag: 'page-1',
      title: 'Page 1',
      child: AdwToolbarView(
        topBar: const AdwHeaderBar(
          isFlat: true,
          title: Text('Page 1'),
        ),
        content: Center(
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdwButton.pill(
                  onPressed: () => controller.push(buildPage2()),
                  child: const Text('Open Page 2'),
                ),
                const SizedBox(height: 18),
                AdwButton.pill(
                  onPressed: () => controller.push(buildPage3()),
                  child: const Text('Open Page 3'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    showAdwDialog<void>(
      context: context,
      builder: (_) => AdwDialog(
        contentWidth: 360,
        contentHeight: 360,
        title: 'Navigation View',
        child: AdwNavigationView(
          controller: controller,
          initialPage: page1,
        ),
      ),
    );
  }
}

