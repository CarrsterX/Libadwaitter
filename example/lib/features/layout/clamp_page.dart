import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class ClampPage extends StatefulWidget {
  const ClampPage({super.key});

  @override
  State<ClampPage> createState() => _ClampPageState();
}

class _ClampPageState extends State<ClampPage> {
  double _maximumSize = 400.0;
  double _tighteningThreshold = 300.0;
  AdwLengthUnit _unit = AdwLengthUnit.sp;

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      icon: DemoWidgetIcon(DemoIconType.clamp, size: 128),
      title: const Text('Clamp'),
      description: const Text(
        'This page is clamped to smoothly grow up to a maximum width',
      ),
      maxWidth: 400.0,
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 12.0),
      clampChild: false,
      child: AdwClamp(
        maximumSize: _maximumSize,
        tighteningThreshold: _tighteningThreshold,
        unit: _unit,
        minimumMargin: 0.0,
        child: AdwPreferencesGroup(
          children: [
            AdwSpinRow(
              title: const Text('Maximum Width'),
              value: _maximumSize,
              min: 0.0,
              max: 10000.0,
              step: 10.0,
              onChanged: (value) => setState(() => _maximumSize = value),
            ),
            AdwSpinRow(
              title: const Text('Tightening Threshold'),
              value: _tighteningThreshold,
              min: 0.0,
              max: 10000.0,
              step: 10.0,
              onChanged: (value) =>
                  setState(() => _tighteningThreshold = value),
            ),
            AdwComboRow<AdwLengthUnit>(
              title: const Text('Unit'),
              items: const [
                AdwLengthUnit.px,
                AdwLengthUnit.pt,
                AdwLengthUnit.sp,
              ],
              selectedItem: _unit,
              itemTitleBuilder: (unit) => unit.name,
              onSelected: (unit) => setState(() => _unit = unit),
            ),
          ],
        ),
      ),
    );
  }
}
