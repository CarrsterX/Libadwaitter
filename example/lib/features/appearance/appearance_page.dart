import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class AppearancePage extends StatelessWidget {
  final AdwThemeMode currentThemeMode;
  final AdwAccentColor? currentAccent;
  final ValueChanged<AdwThemeMode> onThemeModeChanged;
  final ValueChanged<AdwAccentColor?> onAccentChanged;

  const AppearancePage({
    super.key,
    required this.currentThemeMode,
    required this.currentAccent,
    required this.onThemeModeChanged,
    required this.onAccentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return AdwPreferencesPage(
      maxWidth: 560,
      children: [
        AdwPreferencesGroup(
          title: const Text('APPEARANCE & ACCENT COLOR'),
          description: const Text(
            'Supports the 9 official GNOME 47 accent colors with seamless dark mode switching.',
          ),
          children: [
            AdwComboRow<AdwThemeMode>(
              prefix: const Icon(AdwIcons.night_light_symbolic, size: 20),
              title: const Text('Color Scheme'),
              items: AdwThemeMode.values,
              selectedItem: currentThemeMode,
              itemTitleBuilder: (mode) => mode == AdwThemeMode.system
                  ? 'Default'
                  : mode == AdwThemeMode.light
                      ? 'Light'
                      : 'Dark',
              onSelected: onThemeModeChanged,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accent Color',
                    style: theme.typography.body
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AdwAccentColor.values.map((accent) {
                      final effectiveAccent =
                          currentAccent ?? AdwStyleManager.instance.accentColor;
                      final isSelected = effectiveAccent == accent;
                      return GestureDetector(
                        onTap: () => onAccentChanged(accent),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent.color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: theme.colors.foreground,
                                    width: 3,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

