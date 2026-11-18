import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class MultiLayoutViewPage extends StatelessWidget {
  const MultiLayoutViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.multiLayoutView, size: 128),
      title: const Text('Multi-Layout View'),
      description: const Text(
        'A widget for switching between different layouts',
      ),
      child: Center(
        child: Builder(
          builder: (innerContext) => AdwButton.pill(
            onPressed: () => _openDemoDialog(innerContext),
            child: const Text('Run the Demo'),
          ),
        ),
      ),
    );
  }

  void _openDemoDialog(BuildContext context) {
    showAdwDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = AdwTheme.of(dialogContext);
        final textScale =
            MediaQuery.maybeTextScalerOf(dialogContext)?.scale(1.0) ?? 1.0;
        final breakpointPx = adwLengthUnitToPx(
          AdwLengthUnit.sp,
          500.0,
          textScale: textScale,
        );

        return AdwDialog(
          contentWidth: 800.0,
          contentHeight: 600.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth <= breakpointPx;

              return AdwMultiLayoutView(
                layoutName: isNarrow ? 'narrow' : 'wide',
                children: {
                  'sidebar': Center(
                    child: Text('Sidebar', style: theme.typography.title1),
                  ),
                  'content': Center(
                    child: Text('Content', style: theme.typography.title1),
                  ),
                },
                layouts: const [
                  AdwLayout(
                    name: 'wide',
                    content: AdwOverlaySplitView(
                      sidebar: AdwToolbarView(
                        topBar: AdwHeaderBar(
                          isFlat: true,
                          showTitle: false,
                          showWindowControls: false,
                        ),
                        content: AdwLayoutSlot(id: 'sidebar'),
                      ),
                      content: AdwToolbarView(
                        topBar: AdwHeaderBar(
                          isFlat: true,
                          showTitle: false,
                        ),
                        content: AdwLayoutSlot(id: 'content'),
                      ),
                    ),
                  ),
                  AdwLayout(
                    name: 'narrow',
                    content: AdwToolbarView(
                      bottomBarStyle: AdwToolbarStyle.raised,
                      topBar: AdwHeaderBar(
                        isFlat: true,
                        showTitle: false,
                      ),
                      content: AdwLayoutSlot(id: 'content'),
                      bottomBar: SizedBox(
                        height: 100.0,
                        child: AdwLayoutSlot(id: 'sidebar'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
