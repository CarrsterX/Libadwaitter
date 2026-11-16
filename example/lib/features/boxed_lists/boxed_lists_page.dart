import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class BoxedListsPage extends StatefulWidget {
  const BoxedListsPage({super.key});

  @override
  State<BoxedListsPage> createState() => _BoxedListsPageState();
}

class _BoxedListsPageState extends State<BoxedListsPage> {
  bool _switchRowValue = false;
  double _spinValue = 50.0;
  String _selectedComboOption = 'Foo';
  String _selectedEnumComboOption = 'unknown';
  int _selectedPrefixOption = 0;

  @override
  Widget build(BuildContext context) {
    return AdwPreferencesPage(
      icon: const DemoWidgetIcon(DemoIconType.boxedList, size: 128),
      title: const Text('Boxed Lists'),
      description: const Text('Rows for the boxed list pattern'),
      padding: const EdgeInsets.fromLTRB(0, 36, 0, 36),
      maxWidth: 400.0,
      minimumMargin: 14.0,
      groupSpacing: 46.0,
      children: [
        AdwPreferencesGroup(
          children: [
            const AdwActionRow(
              title: Text('Rows Have a Title'),
              subtitle: Text('They also have a subtitle'),
            ),
            AdwActionRow(
              title: const Text('Rows Can Have Suffix Widgets'),
              suffix: AdwButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                onPressed: () {
                  AdwToastOverlay.of(context).addToast(
                    const AdwToast(title: Text('Action clicked')),
                  );
                },
                child: const Text('Action'),
              ),
            ),
          ],
        ),
        AdwPreferencesGroup(
          children: [
            AdwActionRow(
              prefix: AdwRadio<int>(
                value: 0,
                groupValue: _selectedPrefixOption,
                onChanged: (val) =>
                    setState(() => _selectedPrefixOption = val ?? 0),
              ),
              title: const Text('Rows Can Have Prefix Widgets'),
              onPressed: () => setState(() => _selectedPrefixOption = 0),
            ),
            AdwActionRow(
              prefix: AdwRadio<int>(
                value: 1,
                groupValue: _selectedPrefixOption,
                onChanged: (val) =>
                    setState(() => _selectedPrefixOption = val ?? 1),
              ),
              title: const Text('Rows Can Have Prefix Widgets'),
              onPressed: () => setState(() => _selectedPrefixOption = 1),
            ),
          ],
        ),
        AdwPreferencesGroup(
          title: const Text('Entry Rows'),
          separated: true,
          children: [
            const AdwEntryRow(
              title: Text('Entry Row'),
              editIcon: Icon(AdwIcons.document_edit_symbolic, size: 16),
            ),
            AdwEntryRow(
              title: const Text('Entry With Confirmation'),
              showApplyButton: true,
              editIcon: const Icon(AdwIcons.document_edit_symbolic, size: 16),
              onApply: (val) {
                AdwToastOverlay.of(context).addToast(
                  AdwToast(title: Text('Applied: "$val"')),
                );
              },
            ),
            AdwEntryRow(
              title: const Text('Entry With Suffix'),
              editIcon: const Icon(AdwIcons.document_edit_symbolic, size: 16),
              suffix: AdwButton.flat(
                padding: const EdgeInsets.all(6),
                onPressed: () {
                  AdwToastOverlay.of(context).addToast(
                    const AdwToast(title: Text('Suffix action triggered')),
                  );
                },
                child: const Icon(
                  AdwIcons.edit_copy_symbolic,
                  size: 16,
                ),
              ),
            ),
            const AdwPasswordEntryRow(
              title: Text('Password Entry'),
              editIcon: Icon(AdwIcons.document_edit_symbolic, size: 16),
              revealIcon: Icon(AdwIcons.view_reveal_symbolic, size: 16),
              concealIcon: Icon(AdwIcons.view_conceal_symbolic, size: 16),
            ),
          ],
        ),
        AdwPreferencesGroup(
          title: const Text('Spin Rows'),
          children: [
            AdwSpinRow(
              title: const Text('Spin Row'),
              value: _spinValue,
              min: 0,
              max: 100,
              step: 1,
              onChanged: (val) => setState(() => _spinValue = val),
            ),
          ],
        ),
        AdwPreferencesGroup(
          title: const Text('Switch Rows'),
          children: [
            AdwSwitchRow(
              title: const Text('Switch Row'),
              value: _switchRowValue,
              onChanged: (val) => setState(() => _switchRowValue = val),
            ),
          ],
        ),
        AdwPreferencesGroup(
          title: const Text('Combo Rows'),
          children: [
            AdwComboRow<String>(
              title: const Text('Combo Row'),
              items: const ['Foo', 'Bar', 'Baz'],
              selectedItem: _selectedComboOption,
              onSelected: (val) => setState(() => _selectedComboOption = val),
            ),
            AdwComboRow<String>(
              title: const Text('Enumeration Combo Row'),
              subtitle:
                  const Text('This combo row was created from an enumeration'),
              enableSearch: true,
              items: const [
                'unknown',
                'custom',
                'gpl-2-0',
                'gpl-3-0',
                'lgpl-2-1',
                'lgpl-3-0',
                'bsd',
                'mit-x11',
                'artistic',
                'gpl-2-0-only',
                'gpl-2-0-or-later',
                'gpl-3-0-only',
                'gpl-3-0-or-later',
                'lgpl-2-1-only',
                'lgpl-2-1-or-later',
                'bsd-3-clause',
                'apache-2-0',
                'mpl-2-0',
              ],
              selectedItem: _selectedEnumComboOption,
              onSelected: (val) =>
                  setState(() => _selectedEnumComboOption = val),
            ),
          ],
        ),
        AdwPreferencesGroup(
          title: const Text('Expander Rows'),
          children: [
            const AdwExpanderRow(
              title: Text('Expander Row'),
              children: [
                AdwActionRow(title: Text('A Nested Row')),
                AdwActionRow(title: Text('Another Nested Row')),
              ],
            ),
            AdwExpanderRow(
              title: const Text('Expander Row With an Action'),
              suffix: AdwButton.flat(
                padding: const EdgeInsets.all(6),
                onPressed: () {
                  AdwToastOverlay.of(context).addToast(
                    const AdwToast(title: Text('Expander action triggered')),
                  );
                },
                child: const Icon(
                  AdwIcons.edit_copy_symbolic,
                  size: 16,
                ),
              ),
              children: const [
                AdwActionRow(title: Text('A Nested Row')),
                AdwActionRow(title: Text('Another Nested Row')),
              ],
            ),
            const AdwExpanderRow(
              title: Text('Toggleable Expander Row'),
              showEnableSwitch: true,
              enabled: false,
              children: [
                AdwActionRow(title: Text('A Nested Row')),
                AdwActionRow(title: Text('Another Nested Row')),
              ],
            ),
          ],
        ),
        const AdwPreferencesGroup(
          title: Text('Property Rows'),
          children: [
            AdwActionRow.property(
              title: Text('Property Row'),
              subtitle: Text('Value'),
            ),
          ],
        ),
        AdwPreferencesGroup(
          title: const Text('Groups With Suffix'),
          headerSuffix: AdwButton.flat(
            height: 30.0,
            borderRadius: BorderRadius.circular(8.0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            onPressed: () {
              AdwToastOverlay.of(context).addToast(
                const AdwToast(title: Text('Group suffix clicked')),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(AdwIcons.list_add_symbolic, size: 16),
                SizedBox(width: 6),
                Text('Suffix'),
              ],
            ),
          ),
          children: const [
            AdwActionRow(
              minHeight: 53.0,
              title: Text('Groups Can Have a Header Suffix'),
            ),
          ],
        ),
        AdwPreferencesGroup(
          title: const Text('Button Rows'),
          separated: true,
          separatedSpacing: 14.0,
          children: [
            AdwButtonRow(
              startIcon: const Icon(AdwIcons.list_add_symbolic, size: 16),
              title: const Text('Add Input Source'),
              onPressed: () {
                AdwToastOverlay.of(context).addToast(
                  const AdwToast(title: Text('Add Input Source')),
                );
              },
            ),
            AdwButtonRow(
              title: const Text('Add Calendar'),
              endIcon: const Icon(AdwIcons.go_next_symbolic, size: 16),
              onPressed: () {
                AdwToastOverlay.of(context).addToast(
                  const AdwToast(title: Text('Add Calendar')),
                );
              },
            ),
            AdwButtonRow.destructive(
              title: const Text('Delete Event'),
              onPressed: () {
                AdwToastOverlay.of(context).addToast(
                  const AdwToast(title: Text('Delete Event')),
                );
              },
            ),
            AdwButtonRow.suggested(
              title: const Text('Search'),
              onPressed: () {
                AdwToastOverlay.of(context).addToast(
                  const AdwToast(title: Text('Search')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
