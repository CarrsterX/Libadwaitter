# Libadwaitter

[![License: LGPL v2.1](https://img.shields.io/badge/License-LGPL_v2.1--or--later-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20macOS%20%7C%20Web-blue)](https://flutter.dev)

**Libadwaitter** is a modern, **pure Dart & Flutter** implementation of GNOME's **Libadwaita** design system and UI components, built strictly following the [GNOME Human Interface Guidelines (HIG)](https://developer.gnome.org/hig/).

Its goal is to enable Flutter developers to build native-feeling desktop applications with the visual elegance, animations, tactile feel, and layout patterns of the modern GNOME desktop (Fedora, Ubuntu, Arch, Debian), while enjoying the productivity, reactivity, and declarative paradigms of Flutter.

---

## 🏛️ Upstream Credits & Acknowledgments

This project is directly inspired by and builds upon the incredible work of the **GNOME** community and foundation. All upstream GNOME projects are hosted and maintained on **GitLab**:

* **[GNOME Project](https://www.gnome.org/)**: The premier free software desktop environment for GNU/Linux and UNIX.
* **[Libadwaita on GitLab](https://gitlab.gnome.org/GNOME/libadwaita)**: The official building blocks and widget library for GNOME applications built with GTK4.
* **[GTK 4 on GitLab](https://gitlab.gnome.org/GNOME/gtk)**: The foundational UI toolkit for the GNOME ecosystem.
* **[Adwaita Fonts on GitLab](https://gitlab.gnome.org/GNOME/adwaita-fonts)**: The official contemporary typeface family (`Adwaita Sans` and `Adwaita Mono`), licensed under the SIL Open Font License 1.1.
* **[Adwaita Icon Theme on GitLab](https://gitlab.gnome.org/GNOME/adwaita-icon-theme)**: The official symbolic icon set of the GNOME desktop.
* **[GNOME Human Interface Guidelines (HIG)](https://developer.gnome.org/hig/)**: The official design principles and guidelines.

---

## ✨ Features

* **100% Pure Dart**: No C dependencies, no brittle FFI bindings. Develop and preview cross-platform on Linux, macOS, Windows, or Web.
* **Bundled Official Typography**: Includes `Adwaita Sans` and `Adwaita Mono` in assets out-of-the-box with SIL OFL 1.1 license compliance.
* **Official Palette & GNOME 47 Accent Colors**: Full Light and Dark theme stylesheets extracted from Libadwaita 1.10+, featuring the 9 official GNOME 47 accent colors (*Blue, Teal, Green, Yellow, Orange, Red, Pink, Purple, Slate*).
* **1:1 Naming with Flutter Ergonomics**: Intuitive widget naming (`AdwActionRow`, `AdwPreferencesGroup`, `AdwHeaderBar`, `AdwButton`, `AdwSwitchRow`) backed by standard Flutter callbacks (`onPressed`, `onChanged`, `child`).
* **Decoupled Window & CSD Management**: `AdwWindow` provides client-side decorations with 12px rounded corners, Mutter drop-shadows, and automatic 0px square corners on maximize.
* **Native Internationalization (i18n)**: Built-in `AdwLocalizations` with English as default and extensible delegates.
* **Companion Icon Package**: Independent [`libadwaitter_icons`](packages/libadwaitter_icons) package so you are never forced to bundle icon sets you don't use.

---

## 🚀 Getting Started

Add `libadwaitter` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  libadwaitter: ^0.1.0
  libadwaitter_icons: ^0.1.0 # Optional: official Adwaita symbolic icons
```

### Basic Example

```dart
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';
import 'package:libadwaitter_icons/libadwaitter_icons.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdwApplication(
      title: 'My GNOME App',
      theme: AdwThemeData.light(accent: AdwAccentColor.blue),
      darkTheme: AdwThemeData.dark(accent: AdwAccentColor.blue),
      home: const SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _hardwareAcceleration = true;

  @override
  Widget build(BuildContext context) {
    return AdwWindow(
      headerBar: const AdwHeaderBar(
        title: Text('Settings'),
      ),
      child: AdwPreferencesPage(
        children: [
          AdwPreferencesGroup(
            title: const Text('GENERAL'),
            description: const Text('System preferences and performance'),
            children: [
              AdwSwitchRow(
                leading: const Icon(AdwIcons.preferences_system_symbolic),
                title: const Text('Hardware Acceleration'),
                subtitle: const Text('Utilize GPU for rendering'),
                value: _hardwareAcceleration,
                onChanged: (val) => setState(() => _hardwareAcceleration = val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 📜 License

* **Library Code**: Licensed under the **GNU Lesser General Public License v2.1 or later (LGPL-2.1-or-later)**. See [LICENSE](LICENSE) for details.
* **Typefaces (`assets/fonts/`)**: `Adwaita Sans` and `Adwaita Mono` are licensed under the **SIL Open Font License 1.1 (OFL-1.1)**. See [assets/fonts/OFL.txt](assets/fonts/OFL.txt).

---

## 🌿 Branching & Versioning Strategy

* **`main`**: Stable releases and tags.
* **`rc`**: Release candidates undergoing final stabilization.
* **`beta`**: Pre-release testing and integration.
* **`dev`**: Active day-to-day development.

Releases follow semantic versioning starting from `0.x.y`, tracking upstream Libadwaita milestones:
* `0.0.x` — Bug fixes and polish
* `0.x.0` — New widgets and features
* `x.0.0` — Major releases aligned with upstream Libadwaita releases
