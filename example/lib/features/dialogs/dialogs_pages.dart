import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../app/adwaitter_logo.dart';

void showDemoAboutDialog(BuildContext context) {
  showAdwAboutDialog(
    context: context,
    applicationIcon: const AdwaitterSymbolicLogo(size: 64),
    applicationName: 'Adwaitter Demo',
    version: '1.0.0',
    developerName: 'Libadwaitter Contributors',
    comments:
        'A pure Dart & Flutter implementation of GNOME Libadwaita and GNOME HIG.',
    website: 'https://gitlab.gnome.org/GNOME/libadwaita',
    copyright: '© 2026 The GNOME Project & Libadwaitter Authors',
    license:
        'GNU Lesser General Public License Version 2.1 (LGPL-2.1-or-later)',
  );
}

void showDemoPreferencesDialog({
  required BuildContext context,
  required AdwThemeMode currentThemeMode,
  required AdwAccentColor? currentAccent,
  required ValueChanged<AdwThemeMode> onThemeModeChanged,
  required ValueChanged<AdwAccentColor?> onAccentChanged,
}) {
  AdwThemeMode localMode = currentThemeMode;
  AdwAccentColor? localAccent = currentAccent;

  showAdwAlertDialog(
    context: context,
    heading: const Text('Preferences'),
    content: StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final theme = AdwTheme.of(dialogContext);
        final resolvedAccent =
            localAccent ?? AdwStyleManager.instance.accentColor;

        return SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdwPreferencesGroup(
                children: [
                  AdwComboRow<AdwThemeMode>(
                    prefix: const Icon(AdwIcons.night_light_symbolic, size: 20),
                    title: const Text('Color Scheme'),
                    items: AdwThemeMode.values,
                    selectedItem: localMode,
                    itemTitleBuilder: (mode) => mode == AdwThemeMode.system
                        ? 'Default'
                        : mode == AdwThemeMode.light
                            ? 'Light'
                            : 'Dark',
                    onSelected: (mode) {
                      setDialogState(() => localMode = mode);
                      onThemeModeChanged(mode);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AdwPreferencesGroup(
                title: const Text('ACCENT COLOR'),
                headerSuffix: localAccent != null
                    ? AdwButton.flat(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        onPressed: () {
                          setDialogState(() => localAccent = null);
                          onAccentChanged(null);
                        },
                        child: const Text('System'),
                      )
                    : null,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Center(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AdwAccentColor.values.map((accent) {
                          final isSelected = resolvedAccent == accent;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() => localAccent = accent);
                              onAccentChanged(accent);
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: accent.color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: theme.colors.foreground,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AdwButton.flat(
                padding: const EdgeInsets.symmetric(vertical: 8),
                onPressed: () {
                  Navigator.of(context).pop();
                  showDemoAboutDialog(context);
                },
                child: const Text('About Adwaitter Demo'),
              ),
            ],
          ),
        );
      },
    ),
    actions: [
      AdwButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  );
}

class AlertDialogPage extends StatelessWidget {
  const AlertDialogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      title: const Text('Alert Dialog'),
      child: Center(
        child: AdwButton(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          onPressed: () {
            showAdwAlertDialog(
              context: context,
              heading: const Text('Reset Demo Settings?'),
              body: const Text(
                'Are you sure you want to reset all controls to their default state? '
                'This action is reversible by changing the controls again.',
              ),
              actions: [
                AdwButton.flat(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                AdwButton.destructive(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AdwToastOverlay.of(context).addToast(
                      const AdwToast(
                        title: Text('Settings restored to defaults'),
                      ),
                    );
                  },
                  child: const Text('Reset'),
                ),
              ],
            );
          },
          child: const Text('Open Alert Dialog'),
        ),
      ),
    );
  }
}

class AboutDialogPage extends StatelessWidget {
  const AboutDialogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      title: const Text('About Dialog'),
      child: Center(
        child: AdwButton.suggested(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          onPressed: () => showDemoAboutDialog(context),
          child: const Text('Open About Dialog'),
        ),
      ),
    );
  }
}

