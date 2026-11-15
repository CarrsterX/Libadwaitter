import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class ToggleGroupsPage extends StatefulWidget {
  const ToggleGroupsPage({super.key});

  @override
  State<ToggleGroupsPage> createState() => _ToggleGroupsPageState();
}

class _ToggleGroupsPageState extends State<ToggleGroupsPage> {
  String _selectedToggleInterval = 'Day';
  int _selectedAlignment = 1;

  @override
  Widget build(BuildContext context) {
    return AdwPreferencesPage(
      maxWidth: 560,
      groupSpacing: 42.0,
      children: [
        AdwPreferencesGroup(
          title: const Text('TIME INTERVAL SELECTOR'),
          description: const Text(
            'Segmented single-choice toggle bar with animated active indicator.',
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Center(
                child: AdwToggleGroup<String>(
                  selectedValue: _selectedToggleInterval,
                  onChanged: (val) =>
                      setState(() => _selectedToggleInterval = val),
                  items: const [
                    AdwToggleItem(value: 'Day', label: Text('Day')),
                    AdwToggleItem(value: 'Week', label: Text('Week')),
                    AdwToggleItem(value: 'Month', label: Text('Month')),
                    AdwToggleItem(value: 'Year', label: Text('Year')),
                  ],
                ),
              ),
            ),
          ],
        ),
        AdwPreferencesGroup(
          title: const Text('TEXT STYLING TOGGLE'),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Center(
                child: AdwToggleGroup<int>(
                  selectedValue: _selectedAlignment,
                  onChanged: (val) => setState(() => _selectedAlignment = val),
                  items: const [
                    AdwToggleItem(
                      value: 0,
                      icon: Icon(AdwIcons.format_text_direction_ltr_symbolic),
                      tooltip: 'Direction',
                    ),
                    AdwToggleItem(
                      value: 1,
                      icon: Icon(AdwIcons.format_text_bold_symbolic),
                      tooltip: 'Bold',
                    ),
                    AdwToggleItem(
                      value: 2,
                      icon: Icon(AdwIcons.format_text_italic_symbolic),
                      tooltip: 'Italic',
                    ),
                    AdwToggleItem(
                      value: 3,
                      icon: Icon(AdwIcons.format_text_underline_symbolic),
                      tooltip: 'Underline',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

