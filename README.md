# Libadwaitter

[![License: LGPL v2.1](https://img.shields.io/badge/License-LGPL_v2.1--or--later-blue.svg)](https://github.com/CarrsterX/Libadwaitter/blob/alpha/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Android%20%7C%20Web-blue)](https://flutter.dev)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support%20the%20project-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/carrster)

**Libadwaitter** is a modern, **pure Dart & Flutter** implementation of GNOME's **Libadwaita** design system and UI components, built strictly following the [GNOME Human Interface Guidelines (HIG)](https://developer.gnome.org/hig/).

Its goal is to enable Flutter developers to build native-feeling desktop applications with the visual elegance, animations, tactile feel, and layout patterns of the modern GNOME desktop (Fedora, Ubuntu, Arch, Debian), while enjoying the productivity, reactivity, and declarative paradigms of Flutter.

> **Requirements:** Flutter `>= 3.50.0` with the multi-window feature flag enabled (`flutter config --enable-windowing`).
>
> **Support for Apple Devices:** Help fund a MacBook Pro on [Ko-fi](https://ko-fi.com/carrster) to build, test, and maintain native macOS & iOS support for Libadwaitter.

---

## 🖥️ Native Platform Integrations Showcase

`Libadwaitter` extends [`adwaitter`](https://github.com/CarrsterX/Adwaitter) with native **Linux (GTK3/Wayland)**, **Android (Kotlin)**, and **Web / WASM (`dart:js_interop`)** system bridges — zero third-party packages required:

### Native Multi-Window & Client-Side Decorations (CSD)

![Libadwaitter Multi-Window](https://raw.githubusercontent.com/CarrsterX/Libadwaitter/alpha/doc/screenshots/libadwaitter_multi_window.gif)

### Native Desktop Notifications (`AdwPortal`)

![Libadwaitter Notifications](https://raw.githubusercontent.com/CarrsterX/Libadwaitter/alpha/doc/screenshots/libadwaitter_notifications.gif)

### MPRIS2 & Media Session (`AdwMediaSession`)

![Libadwaitter Media Player](https://raw.githubusercontent.com/CarrsterX/Libadwaitter/alpha/doc/screenshots/libadwaitter_media_player.gif)

### System Tray / AppIndicator (`AdwSystemTray`)

![Libadwaitter System Tray](https://raw.githubusercontent.com/CarrsterX/Libadwaitter/alpha/doc/screenshots/libadwaitter_system_tray.gif)

### Bidirectional Drag & Drop & Native Linux Emoji Picker (`AdwDragAndDrop`)

![Libadwaitter Drag and Drop and Emoji Picker](https://raw.githubusercontent.com/CarrsterX/Libadwaitter/alpha/doc/screenshots/libadwaitter_dnd_and_emoji.gif)

### Polkit Privileged Execution (`AdwPortal`)

![Libadwaitter Polkit](https://raw.githubusercontent.com/CarrsterX/Libadwaitter/alpha/doc/screenshots/libadwaitter_polkit.gif)

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
* **Companion Icon Package**: Independent [`adwaitter_icons`](https://github.com/CarrsterX/Adwaitter_Icons) package so you are never forced to bundle icon sets you don't use.
* **Android Out-of-the-Box**: Automatic edge-to-edge safe areas, Android 14+ **Predictive Back**, 2-level system contrast, multi-window / Desktop Mode support, and Android 12+ Material You dynamic accent colors via `LibadwaitterPlugin` — no manual `MainActivity.kt` or `AndroidManifest.xml` edits required.

---

## 🚀 Getting Started

Add `libadwaitter` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  libadwaitter: ^1.0.0-alpha
  adwaitter_icons: ^0.1.0 # Optional: official Adwaita symbolic icons
```

### Linux Native Setup (Automatic Generator)

Run the built-in CLI generator from the root of your Flutter project (ensure Linux support is enabled first with `flutter create --platforms=linux .`):

```bash
dart run libadwaitter:setup
```

This automatically configures `linux/runner/my_application.cc` with frameless CSD, RGBA transparency for rounded corners, `GTK_USE_PORTAL=1`, Wayland `app_id`, and the native platform channels (`libadwaitter/window`, `libadwaitter/settings`, `libadwaitter/style`, `libadwaitter/portal`, and `PopupWindow`). A backup (`linux/runner/my_application.cc.bak`) is created before overwriting.

**Available options:**

```bash
dart run libadwaitter:setup [options]
```

* `--title <name>`: Initial GTK window title (defaults to `pubspec.yaml` `name`).
* `--app-id <reverse.dns>`: Freedesktop/Wayland application ID (e.g. `io.github.user.myapp`) and updates `linux/CMakeLists.txt`.
* `--width <px>` / `--height <px>`: Initial window dimensions (default: `1080x720`).
* `--counter`: Also generate a starter Libadwaitter counter app in `lib/main.dart`.
* `--flatpak`: Generate Flatpak manifest, `.desktop`, `.metainfo.xml`, and bundle script under `linux/packaging/flatpak/`.
* `--snap`: Generate `snap/snapcraft.yaml` with strict confinement and GNOME extension.
* `--all-packaging`: Generate both Flatpak and Snap packaging.
* `--channel <stable|beta>`: Release channel (`stable` by default).
* `--dry-run`: Preview changes without writing files.
* `--no-backup`: Skip creating `.bak` files.
* `-h`, `--help`: Show full CLI help.

### Android Setup (Zero-Config)

No manual edits to `MainActivity.kt` or `AndroidManifest.xml` are needed. Adding `libadwaitter` automatically bundles `LibadwaitterPlugin`, enabling:
* Android 14+ **Predictive Back** (`android:enableOnBackInvokedCallback="true"` via manifest merger) across `AdwNavigationView`, `AdwBottomSheet`, and bottom-sheet `AdwDialog`s.
* Edge-to-edge system navigation bar insets (`adwBottomSystemInset` & `AdwBottomInsetConsumer`).
* Android 12+ Material You dynamic accent color sync and `isInMultiWindowMode` / Desktop Mode detection.

### Component Highlights

* **Layout & Windows**: `AdwApplication`, `AdwWindow`, `AdwHeaderBar`, `AdwToolbarView`, `AdwWindowControls` (minimize, maximize, fullscreen, close), `AdwClamp`, `AdwClampScrollable`, `AdwWrapBox`, `AdwBreakpointBin`, `AdwMultiLayoutView`.
* **Navigation**: `AdwNavigationView`, `AdwNavigationSplitView`, `AdwOverlaySplitView`, `AdwSidebar` / `AdwSidebarItem`, `AdwTabView` / `AdwTabBar` / `AdwTabOverview`, `AdwViewSwitcher`, `AdwCarousel`.
* **Controls & Containers**: `AdwButton` (`standard`, `flat`, `suggested`, `destructive`, `pill`, `circular`, `osd`), `AdwButtonContent`, `AdwSplitButton`, `AdwToggleGroup`, `AdwEntry`, `AdwSearchBar`, `AdwDropdown`, `AdwSlider`, `AdwSwitch`, `AdwCheckbox` (`selectionMode`), `AdwRadio`, `AdwCard`, `AdwLinkedBox`, `AdwOsdSurface`, `AdwPreferencesPage`, `AdwPreferencesGroup`, `AdwActionRow`, `AdwExpanderRow`, `AdwEntryRow` / `AdwPasswordEntryRow`, `AdwComboRow`, `AdwSpinRow`, `AdwSwitchRow`, `AdwButtonRow`, `AdwStatusPage`.
* **Display & Overlays**: `AdwAvatar`, `AdwEmblem`, `AdwSpinner`, `AdwProgressBar`, `AdwLevelBar`, `AdwDialog`, `AdwAlertDialog`, `AdwAboutDialog`, `AdwPreferencesDialog`, `AdwShortcutsDialog`, `AdwBottomSheet`, `AdwBanner`, `AdwToastOverlay`, `AdwPopoverSurface`, `AdwContextMenu`, `AdwTooltip`.

### Basic Example

```dart
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';
import 'package:adwaitter_icons/adwaitter_icons.dart';

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

## ⚠️ Known Limitations

* **Mobile Web — Browser Edge Back/Forward Gestures (Won't Fix / Browser Sandbox Limitation):** On mobile web browsers (especially Chromium/Brave/Chrome on Android 14+ and Safari on iOS), swiping from the physical left or right screen edges is reserved by the browser/OS for its own Back/Forward history transitions (including Chromium's static tab-snapshot preview and History Manipulation Intervention). Web APIs do not allow JS/CSS/WASM applications to disable, intercept, or override these browser edge gestures or receive native predictive-back progress events.
  * **Mitigation:** On touch Web, `AdwNavigationView` reserves a `72px` safe zone on both screen edges so Adwaita's swipe-back never collides with the browser's edge gesture; in-app swipe-back works smoothly when dragging from the inner area of the view, alongside the `AdwHeaderBar` back button. Native Android APK builds are unaffected and support full Android 14+ Predictive Back natively.

---

## 📜 License

* **Library Code**: Licensed under the **GNU Lesser General Public License v2.1 or later (LGPL-2.1-or-later)**. See [LICENSE](https://github.com/CarrsterX/Libadwaitter/blob/alpha/LICENSE) for details.
* **Typefaces (`assets/fonts/`)**: `Adwaita Sans` and `Adwaita Mono` are licensed under the **SIL Open Font License 1.1 (OFL-1.1)**. See [assets/fonts/OFL.txt](https://github.com/CarrsterX/Adwaitter/blob/alpha/assets/fonts/OFL.txt).

---

## 🌿 Branching & Versioning Strategy

* **`main`**: Stable releases and tags.
* **`beta`**: Pre-release testing and integration.
* **`alpha`**: Early feature-complete testing builds (e.g. `1.0.0-alpha`).
* **`dev`**: Active day-to-day development.

Releases follow semantic versioning starting from `0.x.y`, tracking upstream Libadwaita milestones:
* `0.0.x` — Bug fixes and polish
* `0.x.0` — New widgets and features
* `x.0.0` — Major releases aligned with upstream Libadwaita releases
