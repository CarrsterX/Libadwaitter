import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class ButtonsPage extends StatelessWidget {
  const ButtonsPage({super.key});

  List<AdwSplitButtonMenuItem> _buildSampleMenu(BuildContext context) {
    void notify(String item) {
      AdwToastOverlay.of(context).addToast(
        AdwToast(title: Text('$item selected')),
      );
    }

    return [
      AdwSplitButtonMenuItem(
        label: 'Item 1',
        onPressed: () => notify('Item 1'),
      ),
      AdwSplitButtonMenuItem(
        label: 'Item 2',
        onPressed: () => notify('Item 2'),
      ),
      AdwSplitButtonMenuItem(
        label: 'Item 3',
        onPressed: () => notify('Item 3'),
      ),
    ];
  }

  void _onOpenPressed(BuildContext context) {
    AdwToastOverlay.of(context).addToast(
      const AdwToast(title: Text('Open clicked')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _buildSampleMenu(context);

    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.buttons, size: 128),
      title: const Text('Buttons'),
      description: const Text('Button helper widgets'),
      maxWidth: 400.0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdwSplitButton(
                  icon: const Icon(AdwIcons.document_open_symbolic),
                  onPressed: () => _onOpenPressed(context),
                  menuItems: menuItems,
                ),
                const SizedBox(width: 12),
                AdwSplitButton(
                  label: const Text('Open'),
                  onPressed: () => _onOpenPressed(context),
                  menuItems: menuItems,
                ),
                const SizedBox(width: 12),
                AdwSplitButton(
                  icon: const Icon(AdwIcons.document_open_symbolic),
                  label: const Text('Open'),
                  onPressed: () => _onOpenPressed(context),
                  menuItems: menuItems,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdwSplitButton(
                  isFlat: true,
                  icon: const Icon(AdwIcons.document_open_symbolic),
                  onPressed: () => _onOpenPressed(context),
                  menuItems: menuItems,
                ),
                const SizedBox(width: 12),
                AdwSplitButton(
                  isFlat: true,
                  label: const Text('Open'),
                  onPressed: () => _onOpenPressed(context),
                  menuItems: menuItems,
                ),
                const SizedBox(width: 12),
                AdwSplitButton(
                  isFlat: true,
                  icon: const Icon(AdwIcons.document_open_symbolic),
                  label: const Text('Open'),
                  onPressed: () => _onOpenPressed(context),
                  menuItems: menuItems,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
