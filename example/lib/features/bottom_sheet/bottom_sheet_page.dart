import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class BottomSheetPage extends StatelessWidget {
  const BottomSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final isCollapsed =
        AdwNavigationSplitViewScope.maybeOf(context)?.isCollapsed ?? false;

    return AdwBottomSheet(
      sheetHeight: 283.0,
      content: AdwToolbarView(
        topBar: AdwHeaderBar(
          isFlat: true,
          showWindowControls: true,
          showStartWindowControls: isCollapsed,
          showEndWindowControls: true,
        ),
        content: const Padding(
          padding: EdgeInsets.only(bottom: 46.0),
          child: AdwStatusPage(
            icon: DemoWidgetIcon(DemoIconType.bottomSheet, size: 128),
            title: Text('Bottom Sheet'),
            description: Text('A bottom sheet with an optional bottom bar'),
          ),
        ),
      ),
      sheet: Stack(
        children: [
          Center(
            child: Icon(
              AdwIcons.go_down_symbolic,
              size: 128,
              color: theme.colors.statusIconColor,
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdwHeaderBar(isFlat: true),
          ),
        ],
      ),
      bottomBar: SizedBox(
        height: 46.0,
        child: Center(
          child: Text(
            'Pull Up Here',
            style: theme.typography.body,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
