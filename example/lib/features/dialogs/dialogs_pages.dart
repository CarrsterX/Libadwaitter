import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../app/adwaitter_logo.dart';
import '../../demo_icons.dart';

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

class AlertDialogPage extends StatefulWidget {
  const AlertDialogPage({super.key});

  @override
  State<AlertDialogPage> createState() => _AlertDialogPageState();
}

class _AlertDialogPageState extends State<AlertDialogPage> {
  AdwToast? _lastToast;

  void _showResponseToast(String response) {
    final overlay = AdwToastOverlay.of(context);
    if (_lastToast != null) {
      overlay.dismissToast(_lastToast!);
    }
    final toast = AdwToast(title: Text('Dialog response: $response'));
    _lastToast = toast;
    overlay.addToast(toast);
  }

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.alertDialog, size: 134),
      title: const Text('Alert Dialog'),
      description: const Text('Adaptive alert dialog'),
      child: Center(
        child: AdwButton.pill(
          onPressed: () {
            showAdwAlertDialog(
              context: context,
              barrierDismissible: false,
              heading: const Text('Save Changes?'),
              body: const Text(
                'Open document contains unsaved changes. '
                'Changes which are not saved will be permanently lost.',
              ),
              actions: [
                AdwButton(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10.5),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _showResponseToast('cancel');
                  },
                  child: const Text('Cancel'),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AdwTheme.of(context).colors.isDark
                        ? const Color(0xFF5D4446)
                        : const Color(0xFFF2D5D6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AdwButton.flat(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      _showResponseToast('discard');
                    },
                    child: Text(
                      'Discard',
                      style: TextStyle(
                        color: AdwTheme.of(context).colors.isDark
                            ? const Color(0xFFFF938C)
                            : const Color(0xFFDC7272),
                      ),
                    ),
                  ),
                ),
                AdwButton.suggested(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10.5),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _showResponseToast('save');
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
          child: const Text('Alert Dialog'),
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
      icon: const DemoWidgetIcon(DemoIconType.aboutDialog, size: 128),
      title: const Text('About Dialog'),
      description: const Text('An about dialog'),
      child: Center(
        child: AdwButton.pill(
          onPressed: () {
            showAdwAboutDialog(
              context: context,
              applicationIcon: const AdwaitterAppLogo(size: 140),
              applicationName: 'Adwaitter',
              developerName: 'Claudio Carrasco',
              version: '1.2.3',
              releaseNotesVersion: '1.2.0',
              releaseNotes: 'This release adds the following features:\n\n'
                  '• Added a way to export fonts.\n'
                  '• Better support for monospace fonts.\n'
                  '• Added a way to preview italic text.\n'
                  '• Bug fixes and performance improvements.\n'
                  '• Translation updates.',
              comments:
                  'Typeset is an app that doesn’t exist and is used as an '
                  'example content for this about dialog.',
              website: 'https://example.org',
              issueUrl: 'https://example.org',
              supportUrl: 'https://example.org',
              copyright: '© 2026 Claudio Carrasco',
              license: 'GNU Lesser General Public License v2.1',
              developers: const ['Claudio Carrasco <claudio@example.com>'],
              artists: const ['GNOME Design Team'],
              links: const [
                AdwAboutLink(
                  title: 'Documentation',
                  url:
                      'https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/class.AboutDialog.html',
                ),
              ],
              legalSections: const [
                AdwAboutLegalSection(
                  title: 'Fonts',
                  license:
                      "This application uses font data from <a href='https://example.org'>somewhere</a>.",
                ),
              ],
              acknowledgements: const [
                AdwAboutAcknowledgement(
                  title: 'Special thanks to',
                  people: ['My cat'],
                ),
              ],
              otherAppsTitle: 'Inspired by',
              onOpenUrl: (url) => AdwPortal.openUri(url),
              otherApps: const [
                AdwAboutOtherApp(
                  appId: 'dev.flutter.Flutter',
                  name: 'Flutter',
                  summary: 'Build apps for any screen',
                  icon: FlutterLogo(size: 32),
                  url: 'https://flutter.dev',
                ),
                AdwAboutOtherApp(
                  appId: 'org.gnome.Adwaita1.Demo',
                  name: 'Libadwaita',
                  summary: 'Building blocks for modern GNOME apps',
                  icon: LibadwaitaAppLogo(size: 32),
                  url: 'https://gnome.pages.gitlab.gnome.org/libadwaita/',
                ),
              ],
            );
          },
          child: const Text('Run Demo'),
        ),
      ),
    );
  }
}
