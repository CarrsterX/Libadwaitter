import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class BannerPage extends StatefulWidget {
  const BannerPage({super.key});

  @override
  State<BannerPage> createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> {
  bool _showBanner = true;
  bool _showButton = true;
  bool _suggestedStyle = false;
  late final TextEditingController _titleController;
  late final TextEditingController _buttonController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: 'Metered connection — updates paused',
    );
    _buttonController = TextEditingController(
      text: 'Network Settings',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AdwStatusPage(
            icon: const DemoWidgetIcon(DemoIconType.banner, size: 128),
            title: const Text('Banner'),
            description: const Text('A bar with contextual information'),
            child: AdwClamp(
              maximumSize: 400,
              child: AdwPreferencesGroup(
                children: [
                  AdwSwitchRow(
                    title: const Text('Show Banner'),
                    value: _showBanner,
                    onChanged: (value) => setState(() => _showBanner = value),
                  ),
                  AdwEntryRow(
                    title: const Text('Title'),
                    controller: _titleController,
                    editIcon:
                        const Icon(AdwIcons.document_edit_symbolic, size: 16),
                    onChanged: (_) => setState(() {}),
                  ),
                  AdwEntryRow(
                    title: const Text('Button'),
                    controller: _buttonController,
                    editIcon:
                        const Icon(AdwIcons.document_edit_symbolic, size: 16),
                    onChanged: (_) => setState(() {}),
                    suffix: AdwSwitch(
                      value: _showButton,
                      onChanged: (value) => setState(() => _showButton = value),
                    ),
                  ),
                  AdwSwitchRow(
                    title: const Text('Suggested Style'),
                    value: _suggestedStyle,
                    onChanged: (value) =>
                        setState(() => _suggestedStyle = value),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AdwBanner(
            revealed: _showBanner,
            useSuggestedStyle: _suggestedStyle,
            title: Text(_titleController.text),
            buttonLabel: _showButton && _buttonController.text.isNotEmpty
                ? _buttonController.text
                : null,
            onButtonPressed: () {
              AdwToastOverlay.of(context).addToast(
                const AdwToast(title: Text('Banner button activated')),
              );
            },
          ),
        ),
      ],
    );
  }
}
