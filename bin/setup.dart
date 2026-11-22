import 'dart:io';

/// CLI generator to configure a Flutter Linux project for Libadwaitter:
/// - Patches `linux/runner/my_application.cc` with frameless CSD, RGBA
///   transparency for rounded corners, and the native MethodChannels
///   (`libadwaitter/window`, `libadwaitter/settings`, `libadwaitter/style`).
/// - Optionally generates a starter Libadwaitter counter app in `lib/main.dart`
///   when `--counter` is passed.
///
/// Usage:
///   dart run libadwaitter:setup [options]
void main(List<String> args) {
  final options = _parseArgs(args);
  if (options.showHelp) {
    _printUsage();
    return;
  }

  final cwd = Directory.current;
  final pubspecFile = File('${cwd.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln(
      'Error: pubspec.yaml not found in ${cwd.path}. Run this command from the root of your Flutter project.',
    );
    exitCode = 1;
    return;
  }

  final myAppFile = File('${cwd.path}/linux/runner/my_application.cc');
  if (!myAppFile.existsSync()) {
    stderr.writeln(
      'Error: linux/runner/my_application.cc not found.\n'
      'If Linux is not enabled in your project yet, run: flutter create --platforms=linux .',
    );
    exitCode = 1;
    return;
  }

  final resolvedTitle = options.title ?? _inferTitleFromPubspec(pubspecFile);
  final resolvedSlug = _inferSlugFromPubspec(pubspecFile);
  final resolvedAppId = options.appId ?? _inferAppId(cwd, resolvedSlug);
  final isBeta = options.channel == 'beta';
  final effectiveAppId =
      isBeta && !resolvedAppId.endsWith('.Devel') && options.flatpak
          ? '$resolvedAppId.Devel'
          : resolvedAppId;

  final renderedCpp = _renderMyApplicationCc(
    title: resolvedTitle,
    width: options.width,
    height: options.height,
  );

  if (options.dryRun) {
    stdout.writeln('[dry-run] Would update: ${myAppFile.path}');
    stdout.writeln(
      '[dry-run] Title: "$resolvedTitle", default size: ${options.width}x${options.height}',
    );
    stdout.writeln(
      '[dry-run] App ID: $effectiveAppId (channel: ${options.channel})',
    );
    if (options.counter) {
      stdout.writeln('[dry-run] Would generate Libadwaitter counter app in: ${cwd.path}/lib/main.dart');
    }
    if (options.flatpak) {
      stdout.writeln(
        '[dry-run] Would generate Flatpak packaging in: ${cwd.path}/linux/packaging/flatpak/',
      );
    }
    if (options.snap) {
      stdout.writeln(
        '[dry-run] Would generate Snap packaging in: ${cwd.path}/snap/snapcraft.yaml',
      );
    }
    return;
  }

  final existingCpp = myAppFile.readAsStringSync();
  if (options.backup &&
      !existingCpp.contains('libadwaitter/window') &&
      !File('${myAppFile.path}.bak').existsSync()) {
    myAppFile.copySync('${myAppFile.path}.bak');
    stdout.writeln('Backup created: linux/runner/my_application.cc.bak');
  }

  myAppFile.writeAsStringSync(renderedCpp);
  stdout.writeln(
    'Configured linux/runner/my_application.cc (transparent CSD, Wayland app_id, and window/settings/style/portal channels).',
  );

  if (options.appId != null) {
    _updateCmakeApplicationId(cwd, effectiveAppId);
  }

  if (options.counter) {
    final mainFile = File('${cwd.path}/lib/main.dart');
    if (mainFile.existsSync() &&
        options.backup &&
        !File('${mainFile.path}.bak').existsSync()) {
      mainFile.copySync('${mainFile.path}.bak');
      stdout.writeln('Backup created: lib/main.dart.bak');
    }
    mainFile.parent.createSync(recursive: true);
    mainFile.writeAsStringSync(_renderCounterMainDart(title: resolvedTitle));
    stdout.writeln('Generated lib/main.dart with Libadwaitter counter demo.');
  }

  if (options.flatpak) {
    _writeFlatpakPackaging(
      cwd: cwd,
      appId: effectiveAppId,
      binaryName: resolvedSlug,
      title: resolvedTitle,
      channel: options.channel,
    );
  }

  if (options.snap) {
    _writeSnapPackaging(
      cwd: cwd,
      snapName: resolvedSlug.replaceAll('_', '-'),
      binaryName: resolvedSlug,
      title: resolvedTitle,
      channel: options.channel,
    );
  }

  stdout.writeln('\nReady for native development: flutter run -d linux');
  if (options.flatpak) {
    stdout.writeln(
      'To package Flatpak (${options.channel}): ./linux/packaging/flatpak/build-flatpak.sh',
    );
  }
  if (options.snap) {
    stdout.writeln('To package Snap (${options.channel}): snapcraft');
  }
}

class _SetupOptions {
  final bool showHelp;
  final bool dryRun;
  final bool counter;
  final bool backup;
  final bool flatpak;
  final bool snap;
  final String channel;
  final String? appId;
  final String? title;
  final int width;
  final int height;

  const _SetupOptions({
    required this.showHelp,
    required this.dryRun,
    required this.counter,
    required this.backup,
    required this.flatpak,
    required this.snap,
    required this.channel,
    required this.appId,
    required this.title,
    required this.width,
    required this.height,
  });
}

_SetupOptions _parseArgs(List<String> args) {
  bool showHelp = false;
  bool dryRun = false;
  bool counter = false;
  bool backup = true;
  bool flatpak = false;
  bool snap = false;
  String channel = 'stable';
  String? appId;
  String? title;
  int width = 900;
  int height = 625;

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '-h' || arg == '--help') {
      showHelp = true;
    } else if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--counter') {
      counter = true;
    } else if (arg == '--no-backup') {
      backup = false;
    } else if (arg == '--flatpak') {
      flatpak = true;
    } else if (arg == '--snap') {
      snap = true;
    } else if (arg == '--all-packaging') {
      flatpak = true;
      snap = true;
    } else if (arg == '--channel' && i + 1 < args.length) {
      final val = args[++i].toLowerCase();
      if (val == 'stable' || val == 'beta') channel = val;
    } else if (arg.startsWith('--channel=')) {
      final val = arg.substring('--channel='.length).toLowerCase();
      if (val == 'stable' || val == 'beta') channel = val;
    } else if (arg == '--app-id' && i + 1 < args.length) {
      appId = args[++i];
    } else if (arg.startsWith('--app-id=')) {
      appId = arg.substring('--app-id='.length);
    } else if (arg == '--title' && i + 1 < args.length) {
      title = args[++i];
    } else if (arg.startsWith('--title=')) {
      title = arg.substring('--title='.length);
    } else if (arg == '--width' && i + 1 < args.length) {
      width = int.tryParse(args[++i]) ?? width;
    } else if (arg.startsWith('--width=')) {
      width = int.tryParse(arg.substring('--width='.length)) ?? width;
    } else if (arg == '--height' && i + 1 < args.length) {
      height = int.tryParse(args[++i]) ?? height;
    } else if (arg.startsWith('--height=')) {
      height = int.tryParse(arg.substring('--height='.length)) ?? height;
    }
  }

  return _SetupOptions(
    showHelp: showHelp,
    dryRun: dryRun,
    counter: counter,
    backup: backup,
    flatpak: flatpak,
    snap: snap,
    channel: channel,
    appId: appId,
    title: title,
    width: width,
    height: height,
  );
}

void _printUsage() {
  stdout.writeln('''
Libadwaitter Linux Setup Generator

Usage:
  dart run libadwaitter:setup [options]

Native Linux / Wayland options:
  --title <name>         Initial GTK window title (defaults to pubspec.yaml name)
  --app-id <reverse.dns> Freedesktop/Wayland application ID (e.g. io.github.user.myapp)
  --width <px>           Initial window width (default: 900)
  --height <px>          Initial window height (default: 625)
  --counter              Also generate a starter Libadwaitter counter app in lib/main.dart

Distribution options (optional, does not affect native development):
  --flatpak              Generate Flatpak manifest, .desktop, .metainfo.xml, and bundle script
  --snap                 Generate snap/snapcraft.yaml with strict confinement and GNOME extension
  --all-packaging        Generate both Flatpak and Snap packaging
  --channel <type>       Release channel: stable (default) or beta

Other:
  --no-backup            Do not create .bak files before overwriting
  --dry-run              Preview changes without writing files
  -h, --help             Show this help message
''');
}

String _inferSlugFromPubspec(File pubspecFile) {
  final lines = pubspecFile.readAsLinesSync();
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('name:')) {
      final raw = trimmed.substring('name:'.length).trim();
      if (raw.isNotEmpty) return raw;
    }
  }
  return 'libadwaitter_app';
}

String _inferAppId(Directory cwd, String slug) {
  final cmakeFile = File('${cwd.path}/linux/CMakeLists.txt');
  if (cmakeFile.existsSync()) {
    final match = RegExp(r'set\(APPLICATION_ID\s+"([^"]+)"\)')
        .firstMatch(cmakeFile.readAsStringSync());
    if (match != null && match.group(1) != null && match.group(1)!.isNotEmpty) {
      return match.group(1)!;
    }
  }
  return 'org.example.$slug';
}

void _updateCmakeApplicationId(Directory cwd, String appId) {
  final cmakeFile = File('${cwd.path}/linux/CMakeLists.txt');
  if (!cmakeFile.existsSync()) return;
  final content = cmakeFile.readAsStringSync();
  final updated = content.replaceAllMapped(
    RegExp(r'set\(APPLICATION_ID\s+"[^"]+"\)'),
    (_) => 'set(APPLICATION_ID "$appId")',
  );
  if (updated != content) {
    cmakeFile.writeAsStringSync(updated);
    stdout.writeln('Updated APPLICATION_ID in linux/CMakeLists.txt -> $appId');
  }
}

void _writeFlatpakPackaging({
  required Directory cwd,
  required String appId,
  required String binaryName,
  required String title,
  required String channel,
}) {
  final dir = Directory('${cwd.path}/linux/packaging/flatpak');
  dir.createSync(recursive: true);

  final desktopFile = File('${dir.path}/$appId.desktop');
  desktopFile.writeAsStringSync('''[Desktop Entry]
Type=Application
Name=$title
Exec=$binaryName
Icon=$appId
Terminal=false
Categories=Utility;GTK;
StartupNotify=true
StartupWMClass=$appId
''');

  final metainfoFile = File('${dir.path}/$appId.metainfo.xml');
  metainfoFile.writeAsStringSync('''<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>$appId</id>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>MIT</project_license>
  <name>$title</name>
  <summary>$title built with Libadwaitter</summary>
  <description>
    <p>$title is a desktop application built with Flutter and Libadwaitter.</p>
  </description>
  <launchable type="desktop-id">$appId.desktop</launchable>
  <releases>
    <release version="0.1.0" date="2026-01-01" type="${channel == 'beta' ? 'development' : 'stable'}"/>
  </releases>
</component>
''');

  final svgFile = File('${dir.path}/$appId.svg');
  svgFile.writeAsStringSync('''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <rect x="12" y="12" width="104" height="104" rx="24" fill="#3584e4"/>
  <rect x="34" y="34" width="60" height="60" rx="14" fill="none" stroke="#ffffff" stroke-width="8"/>
  <circle cx="64" cy="64" r="10" fill="#ffffff"/>
</svg>
''');

  final manifestFile = File('${dir.path}/$appId.yml');
  manifestFile.writeAsStringSync('''app-id: $appId
runtime: org.gnome.Platform
runtime-version: '47'
sdk: org.freedesktop.Sdk
command: $binaryName
branch: $channel
finish-args:
  - --socket=wayland
  - --socket=fallback-x11
  - --share=ipc
  - --device=dri
modules:
  - name: $binaryName
    buildsystem: simple
    build-commands:
      - mkdir -p /app/bin /app/lib /app/data
      - cp -r bundle/* /app/
      - ln -sf /app/$binaryName /app/bin/$binaryName
      - install -Dm644 $appId.desktop /app/share/applications/$appId.desktop
      - install -Dm644 $appId.metainfo.xml /app/share/metainfo/$appId.metainfo.xml
      - install -Dm644 $appId.svg /app/share/icons/hicolor/scalable/apps/$appId.svg
    sources:
      - type: dir
        path: ../../../build/linux/x64/release/bundle
        dest: bundle
      - type: file
        path: $appId.desktop
      - type: file
        path: $appId.metainfo.xml
      - type: file
        path: $appId.svg
''');

  final scriptFile = File('${dir.path}/build-flatpak.sh');
  scriptFile.writeAsStringSync('''#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/../../.." && pwd)"
PACKAGING_DIR="\$ROOT_DIR/linux/packaging/flatpak"
BUILD_DIR="\$ROOT_DIR/build/flatpak-build"
REPO_DIR="\$ROOT_DIR/build/flatpak-repo"
BUNDLE_OUT="\$ROOT_DIR/build/$appId-$channel.flatpak"

cd "\$ROOT_DIR"
flutter build linux --release

flatpak-builder --force-clean --repo="\$REPO_DIR" "\$BUILD_DIR" "\$PACKAGING_DIR/$appId.yml"
flatpak build-bundle "\$REPO_DIR" "\$BUNDLE_OUT" $appId $channel

echo "Flatpak bundle built: \$BUNDLE_OUT"
''');
  if (!Platform.isWindows) {
    Process.runSync('chmod', ['+x', scriptFile.path]);
  }
  stdout.writeln(
    'Generated Flatpak packaging ($channel) in linux/packaging/flatpak/',
  );
}

void _writeSnapPackaging({
  required Directory cwd,
  required String snapName,
  required String binaryName,
  required String title,
  required String channel,
}) {
  final snapDir = Directory('${cwd.path}/snap');
  snapDir.createSync(recursive: true);

  final snapFile = File('${snapDir.path}/snapcraft.yaml');
  snapFile.writeAsStringSync('''name: $snapName
version: '0.1.0'
summary: $title
description: |
  $title built with Flutter and Libadwaitter.
base: core24
confinement: strict
grade: ${channel == 'beta' ? 'devel' : 'stable'}

apps:
  $snapName:
    command: $binaryName
    extensions: [gnome]
    plugs:
      - wayland
      - x11
      - opengl
      - desktop
      - desktop-legacy
      - gsettings
      - network

parts:
  $snapName:
    plugin: flutter
    source: .
    flutter-target: lib/main.dart
''');
  stdout.writeln('Generated Snap packaging ($channel) in snap/snapcraft.yaml');
}

String _inferTitleFromPubspec(File pubspecFile) {
  final lines = pubspecFile.readAsLinesSync();
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('name:')) {
      final raw = trimmed.substring('name:'.length).trim();
      if (raw.isEmpty) break;
      return raw
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' ');
    }
  }
  return 'Libadwaitter App';
}

String _escapeCString(String input) {
  return input.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}

String _escapeDartSingleQuote(String input) {
  return input.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
}

String _renderMyApplicationCc({
  required String title,
  required int width,
  required int height,
}) {
  final escapedTitle = _escapeCString(title);
  return _myApplicationCcTemplate
      .replaceAll('__APP_TITLE__', escapedTitle)
      .replaceAll('__WINDOW_WIDTH__', width.toString())
      .replaceAll('__WINDOW_HEIGHT__', height.toString());
}

String _renderCounterMainDart({required String title}) {
  final escapedTitle = _escapeDartSingleQuote(title);
  return '''import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';
import 'package:adwaitter_icons/adwaitter_icons.dart';

void main() {
  runApp(const CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdwApplication(
      title: '$escapedTitle',
      home: AdwWindow(
        child: CounterHomePage(),
      ),
    );
  }
}

class CounterHomePage extends StatefulWidget {
  const CounterHomePage({super.key});

  @override
  State<CounterHomePage> createState() => _CounterHomePageState();
}

class _CounterHomePageState extends State<CounterHomePage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return AdwToolbarView(
      topBar: const AdwHeaderBar(
        showWindowControls: true,
        title: Text('$escapedTitle'),
      ),
      content: AdwPreferencesPage(
        title: const Text('Counter Demo'),
        description: const Text(
          'Flutter Linux application configured with Libadwaitter.',
        ),
        children: [
          AdwPreferencesGroup(
            children: [
              AdwActionRow(
                title: const Text('Button Taps'),
                subtitle: const Text('You have pushed the button this many times'),
                suffix: Text(
                  '\$_counter',
                  style: AdwTheme.of(context).typography.title2,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AdwButton(
                onPressed: _counter > 0
                    ? () => setState(() => _counter = 0)
                    : null,
                child: const Text('Reset'),
              ),
              const SizedBox(width: 12),
              AdwButton.suggested(
                isPill: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                onPressed: () => setState(() => _counter++),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AdwIcons.list_add_symbolic, size: 16),
                    SizedBox(width: 8),
                    Text('Increment'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
''';
}

const String _myApplicationCcTemplate = r'''#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <unistd.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

const char* kWindowChannelName = "libadwaitter/window";
const char* kSettingsChannelName = "libadwaitter/settings";
const char* kStyleChannelName = "libadwaitter/style";
const char* kPortalChannelName = "libadwaitter/portal";
const char* kMediaChannelName = "libadwaitter/media";

static gboolean get_system_enable_animations() {
  GtkSettings* settings = gtk_settings_get_default();
  if (settings != nullptr) {
    gboolean enabled = TRUE;
    g_object_get(settings, "gtk-enable-animations", &enabled, NULL);
    return enabled;
  }
  GSettingsSchemaSource* source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) schema =
        g_settings_schema_source_lookup(source, "org.gnome.desktop.interface", TRUE);
    if (schema != nullptr && g_settings_schema_has_key(schema, "enable-animations")) {
      g_autoptr(GSettings) gsettings = g_settings_new("org.gnome.desktop.interface");
      return g_settings_get_boolean(gsettings, "enable-animations");
    }
  }
  return TRUE;
}

static gdouble get_system_duration_factor() {
  const gchar* current_desktop = g_getenv("XDG_CURRENT_DESKTOP");
  if (current_desktop != nullptr && strstr(current_desktop, "KDE") != nullptr) {
    const gchar* config_dir = g_get_user_config_dir();
    g_autofree gchar* path = g_build_filename(config_dir, "kdeglobals", nullptr);
    g_autoptr(GKeyFile) key_file = g_key_file_new();
    if (g_key_file_load_from_file(key_file, path, G_KEY_FILE_NONE, nullptr)) {
      GError* error = nullptr;
      gdouble factor = g_key_file_get_double(key_file, "KDE", "AnimationDurationFactor", &error);
      if (error == nullptr) {
        return factor;
      }
      g_clear_error(&error);
    }
  }
  return 1.0;
}

static FlValue* build_animation_settings_map() {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "enableAnimations",
                           fl_value_new_bool(get_system_enable_animations()));
  fl_value_set_string_take(map, "durationFactor",
                           fl_value_new_float(get_system_duration_factor()));
  const gchar* current_desktop = g_getenv("XDG_CURRENT_DESKTOP");
  fl_value_set_string_take(map, "desktop",
                           fl_value_new_string(current_desktop != nullptr ? current_desktop : "GNOME"));
  return map;
}

static gchar* get_window_button_layout() {
  GSettingsSchemaSource* source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) wm_schema =
        g_settings_schema_source_lookup(source, "org.gnome.desktop.wm.preferences", TRUE);
    if (wm_schema != nullptr && g_settings_schema_has_key(wm_schema, "button-layout")) {
      g_autoptr(GSettings) wm_settings = g_settings_new("org.gnome.desktop.wm.preferences");
      gchar* layout = g_settings_get_string(wm_settings, "button-layout");
      if (layout != nullptr && layout[0] != '\0') {
        return layout;
      }
      g_free(layout);
    }
  }

  GtkSettings* settings = gtk_settings_get_default();
  if (settings != nullptr) {
    gchar* gtk_layout = nullptr;
    g_object_get(settings, "gtk-decoration-layout", &gtk_layout, NULL);
    if (gtk_layout != nullptr && gtk_layout[0] != '\0') {
      return gtk_layout;
    }
    g_free(gtk_layout);
  }

  return g_strdup(":close");
}

static void on_wm_button_layout_changed(GSettings* settings, const gchar* key, gpointer user_data) {
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  g_autofree gchar* layout = get_window_button_layout();
  g_autoptr(FlValue) val = fl_value_new_string(layout);
  fl_method_channel_invoke_method(channel, "onWindowButtonLayoutChanged", val,
                                  nullptr, nullptr, nullptr);
}

static void on_gtk_decoration_layout_changed(GObject* object, GParamSpec* pspec, gpointer user_data) {
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  g_autofree gchar* layout = get_window_button_layout();
  g_autoptr(FlValue) val = fl_value_new_string(layout);
  fl_method_channel_invoke_method(channel, "onWindowButtonLayoutChanged", val,
                                  nullptr, nullptr, nullptr);
}

static void on_gtk_animations_changed(GObject* object, GParamSpec* pspec, gpointer user_data) {
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  g_autoptr(FlValue) map = build_animation_settings_map();
  fl_method_channel_invoke_method(channel, "onAnimationSettingsChanged", map, nullptr, nullptr, nullptr);
}

static void settings_method_call_handler(FlMethodChannel* channel,
                                         FlMethodCall* method_call,
                                         gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getAnimationSettings") == 0) {
    g_autoptr(FlValue) map = build_animation_settings_map();
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "getWindowButtonLayout") == 0) {
    g_autofree gchar* layout = get_window_button_layout();
    g_autoptr(FlValue) val = fl_value_new_string(layout);
    fl_method_call_respond_success(method_call, val, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

struct StyleBridgeState {
  FlMethodChannel* channel = nullptr;
  GSettings* interface_settings = nullptr;
  GSettings* a11y_settings = nullptr;
  GDBusConnection* bus = nullptr;
  guint portal_sub_id = 0;
  gboolean has_portal_scheme = FALSE;
  gchar* portal_color_scheme = nullptr;
  gboolean has_portal_contrast = FALSE;
  gboolean portal_high_contrast = FALSE;
};

static void style_bridge_state_free(gpointer data) {
  StyleBridgeState* state = static_cast<StyleBridgeState*>(data);
  if (state == nullptr) return;
  if (state->bus != nullptr && state->portal_sub_id != 0) {
    g_dbus_connection_signal_unsubscribe(state->bus, state->portal_sub_id);
  }
  g_clear_object(&state->bus);
  g_clear_object(&state->interface_settings);
  g_clear_object(&state->a11y_settings);
  g_clear_object(&state->channel);
  g_clear_pointer(&state->portal_color_scheme, g_free);
  g_free(state);
}

static const gchar* portal_color_scheme_to_string(guint32 value) {
  switch (value) {
    case 1:
      return "prefer-dark";
    case 2:
      return "prefer-light";
    default:
      return "default";
  }
}

static FlValue* build_system_appearance_map(StyleBridgeState* state) {
  FlValue* map = fl_value_new_map();
  g_autofree gchar* color_scheme = g_strdup("default");
  g_autofree gchar* accent_color = g_strdup("blue");
  gboolean high_contrast = FALSE;

  GSettingsSchemaSource* source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) schema =
        g_settings_schema_source_lookup(source, "org.gnome.desktop.interface", TRUE);
    if (schema != nullptr) {
      g_autoptr(GSettings) gsettings = g_settings_new("org.gnome.desktop.interface");
      if (g_settings_schema_has_key(schema, "color-scheme")) {
        g_free(color_scheme);
        color_scheme = g_settings_get_string(gsettings, "color-scheme");
      } else if (g_settings_schema_has_key(schema, "gtk-theme")) {
        g_autofree gchar* gtk_theme = g_settings_get_string(gsettings, "gtk-theme");
        if (gtk_theme != nullptr && g_str_has_suffix(gtk_theme, "-dark")) {
          g_free(color_scheme);
          color_scheme = g_strdup("prefer-dark");
        }
      }
      if (g_settings_schema_has_key(schema, "accent-color")) {
        g_free(accent_color);
        accent_color = g_settings_get_string(gsettings, "accent-color");
      }
    }

    g_autoptr(GSettingsSchema) a11y_schema =
        g_settings_schema_source_lookup(source, "org.gnome.desktop.a11y.interface", TRUE);
    if (a11y_schema != nullptr && g_settings_schema_has_key(a11y_schema, "high-contrast")) {
      g_autoptr(GSettings) a11y_settings = g_settings_new("org.gnome.desktop.a11y.interface");
      high_contrast = g_settings_get_boolean(a11y_settings, "high-contrast");
    }
  }

  if (state != nullptr) {
    if (state->has_portal_scheme && state->portal_color_scheme != nullptr) {
      g_free(color_scheme);
      color_scheme = g_strdup(state->portal_color_scheme);
    }
    if (state->has_portal_contrast) {
      high_contrast = state->portal_high_contrast;
    }
  }

  fl_value_set_string_take(map, "colorScheme", fl_value_new_string(color_scheme));
  fl_value_set_string_take(map, "accentColor", fl_value_new_string(accent_color));
  fl_value_set_string_take(map, "highContrast", fl_value_new_bool(high_contrast));
  return map;
}

static void emit_system_appearance_changed(StyleBridgeState* state) {
  if (state == nullptr || state->channel == nullptr) return;
  g_autoptr(FlValue) map = build_system_appearance_map(state);
  fl_method_channel_invoke_method(state->channel, "onSystemAppearanceChanged", map,
                                  nullptr, nullptr, nullptr);
}

static void on_gsettings_appearance_changed(GSettings* settings, const gchar* key, gpointer user_data) {
  StyleBridgeState* state = static_cast<StyleBridgeState*>(user_data);
  if (state == nullptr) return;
  // GSettings updated directly (e.g. via gsettings CLI); clear stale portal override for color-scheme
  if (g_strcmp0(key, "color-scheme") == 0) {
    state->has_portal_scheme = FALSE;
    g_clear_pointer(&state->portal_color_scheme, g_free);
  } else if (g_strcmp0(key, "high-contrast") == 0) {
    state->has_portal_contrast = FALSE;
  }
  emit_system_appearance_changed(state);
}

static void on_portal_setting_changed(GDBusConnection* connection,
                                      const gchar* sender_name,
                                      const gchar* object_path,
                                      const gchar* interface_name,
                                      const gchar* signal_name,
                                      GVariant* parameters,
                                      gpointer user_data) {
  StyleBridgeState* state = static_cast<StyleBridgeState*>(user_data);
  if (state == nullptr || parameters == nullptr) return;

  const gchar* ns = nullptr;
  const gchar* key = nullptr;
  g_autoptr(GVariant) value = nullptr;
  g_variant_get(parameters, "(&s&sv)", &ns, &key, &value);
  if (g_strcmp0(ns, "org.freedesktop.appearance") != 0 || value == nullptr) {
    return;
  }

  if (g_strcmp0(key, "color-scheme") == 0 && g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32)) {
    guint32 scheme_val = g_variant_get_uint32(value);
    g_free(state->portal_color_scheme);
    state->portal_color_scheme = g_strdup(portal_color_scheme_to_string(scheme_val));
    state->has_portal_scheme = TRUE;
    emit_system_appearance_changed(state);
  } else if (g_strcmp0(key, "contrast") == 0 && g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32)) {
    state->portal_high_contrast = g_variant_get_uint32(value) == 1;
    state->has_portal_contrast = TRUE;
    emit_system_appearance_changed(state);
  }
}

static void on_portal_read_color_scheme_done(GObject* source_object,
                                             GAsyncResult* res,
                                             gpointer user_data) {
  GWeakRef* weak_window = static_cast<GWeakRef*>(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) result = g_dbus_connection_call_finish(G_DBUS_CONNECTION(source_object), res, &error);
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_weak_ref_get(weak_window));
  g_weak_ref_clear(weak_window);
  g_free(weak_window);

  if (error != nullptr || result == nullptr || window == nullptr) {
    return;
  }

  StyleBridgeState* state =
      static_cast<StyleBridgeState*>(g_object_get_data(G_OBJECT(window), "libadwaitter-style-bridge"));
  if (state == nullptr) return;

  g_autoptr(GVariant) outer_variant = nullptr;
  g_variant_get(result, "(v)", &outer_variant);
  if (outer_variant != nullptr && g_variant_is_of_type(outer_variant, G_VARIANT_TYPE_VARIANT)) {
    g_autoptr(GVariant) inner = g_variant_get_variant(outer_variant);
    if (inner != nullptr && g_variant_is_of_type(inner, G_VARIANT_TYPE_UINT32)) {
      guint32 scheme_val = g_variant_get_uint32(inner);
      g_free(state->portal_color_scheme);
      state->portal_color_scheme = g_strdup(portal_color_scheme_to_string(scheme_val));
      state->has_portal_scheme = TRUE;
      emit_system_appearance_changed(state);
    }
  }
}

static void on_session_bus_ready(GObject* source_object, GAsyncResult* res, gpointer user_data) {
  GWeakRef* weak_window = static_cast<GWeakRef*>(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GDBusConnection) bus = g_bus_get_finish(res, &error);
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_weak_ref_get(weak_window));
  g_weak_ref_clear(weak_window);
  g_free(weak_window);

  if (error != nullptr || bus == nullptr || window == nullptr) {
    return;
  }

  StyleBridgeState* state =
      static_cast<StyleBridgeState*>(g_object_get_data(G_OBJECT(window), "libadwaitter-style-bridge"));
  if (state == nullptr) return;

  state->bus = G_DBUS_CONNECTION(g_object_ref(bus));
  state->portal_sub_id = g_dbus_connection_signal_subscribe(
      state->bus,
      "org.freedesktop.portal.Desktop",
      "org.freedesktop.portal.Settings",
      "SettingChanged",
      "/org/freedesktop/portal/desktop",
      "org.freedesktop.appearance",
      G_DBUS_SIGNAL_FLAGS_NONE,
      on_portal_setting_changed,
      state,
      nullptr);

  GWeakRef* read_weak_window = g_new(GWeakRef, 1);
  g_weak_ref_init(read_weak_window, window);
  g_dbus_connection_call(
      state->bus,
      "org.freedesktop.portal.Desktop",
      "/org/freedesktop/portal/desktop",
      "org.freedesktop.portal.Settings",
      "Read",
      g_variant_new("(ss)", "org.freedesktop.appearance", "color-scheme"),
      G_VARIANT_TYPE("(v)"),
      G_DBUS_CALL_FLAGS_NONE,
      -1,
      nullptr,
      on_portal_read_color_scheme_done,
      read_weak_window);
}

static void style_method_call_handler(FlMethodChannel* channel,
                                      FlMethodCall* method_call,
                                      gpointer user_data) {
  StyleBridgeState* state = static_cast<StyleBridgeState*>(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getSystemAppearance") == 0) {
    g_autoptr(FlValue) map = build_system_appearance_map(state);
    fl_method_call_respond_success(method_call, map, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

static GHashTable* g_windows_by_view_id = nullptr;

static gboolean window_draw_cb(GtkWidget* widget, cairo_t* cr, gpointer user_data);
static void apply_window_shadow_margin(GtkWindow* window, gint margin);
static void on_window_size_allocate(GtkWidget* widget,
                                    GtkAllocation* allocation,
                                    gpointer user_data);

static void on_sub_window_destroyed(GtkWidget* widget, gpointer user_data) {
  if (g_windows_by_view_id != nullptr) {
    g_hash_table_remove(g_windows_by_view_id, user_data);
  }
}

static GtkWindow* resolve_target_window(GtkWindow* default_window,
                                        FlValue* args) {
  if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP &&
      g_windows_by_view_id != nullptr) {
    FlValue* v = fl_value_lookup_string(args, "viewId");
    if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
      gint view_id = static_cast<gint>(fl_value_get_int(v));
      gpointer found =
          g_hash_table_lookup(g_windows_by_view_id, GINT_TO_POINTER(view_id));
      if (found != nullptr) {
        return GTK_WINDOW(found);
      }
    }
  }
  return default_window;
}

static gboolean is_gdk_window_tiled(GtkWindow* window) {
  GdkWindow* gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_win == nullptr) return FALSE;
  GdkWindowState state = gdk_window_get_state(gdk_win);
  return (state & (GDK_WINDOW_STATE_TILED |
                   GDK_WINDOW_STATE_TOP_TILED |
                   GDK_WINDOW_STATE_RIGHT_TILED |
                   GDK_WINDOW_STATE_BOTTOM_TILED |
                   GDK_WINDOW_STATE_LEFT_TILED |
                   GDK_WINDOW_STATE_FULLSCREEN)) != 0;
}

static gboolean on_window_state_changed(GtkWidget* widget,
                                        GdkEventWindowState* event,
                                        gpointer user_data) {
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  if (channel == nullptr || event == nullptr) return FALSE;
  gint view_id = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(widget), "libadwaitter-view-id"));
  GdkWindowState state = event->new_window_state;
  gboolean is_max = (state & GDK_WINDOW_STATE_MAXIMIZED) != 0;
  gboolean is_tiled =
      (state & (GDK_WINDOW_STATE_TILED |
                GDK_WINDOW_STATE_TOP_TILED |
                GDK_WINDOW_STATE_RIGHT_TILED |
                GDK_WINDOW_STATE_BOTTOM_TILED |
                GDK_WINDOW_STATE_LEFT_TILED |
                GDK_WINDOW_STATE_FULLSCREEN)) != 0;
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "viewId", fl_value_new_int(view_id));
  fl_value_set_string_take(args, "isMaximized", fl_value_new_bool(is_max));
  fl_value_set_string_take(args, "isTiled", fl_value_new_bool(is_tiled));
  fl_method_channel_invoke_method(channel, "onWindowStateChanged", args,
                                  nullptr, nullptr, nullptr);
  return FALSE;
}

static void on_window_active_changed(GObject* object, GParamSpec* pspec, gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(object);
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  gint view_id = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(window), "libadwaitter-view-id"));
  gboolean active = gtk_window_is_active(window);
  gboolean is_dragging =
      GPOINTER_TO_INT(g_object_get_data(G_OBJECT(window), "libadwaitter-interactive-drag")) != 0;

  if (active) {
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag", GINT_TO_POINTER(0));
  } else if (is_dragging) {
    // Compositor grabs (Wayland/X11 move or resize drag) transiently unset is-active;
    // keep the window visually focused just like native GTK4/Libadwaita windows.
    return;
  }

  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "viewId", fl_value_new_int(view_id));
  fl_value_set_string_take(args, "isActive", fl_value_new_bool(active));
  fl_method_channel_invoke_method(channel, "onWindowActiveChanged", args, nullptr, nullptr, nullptr);
}

static gboolean on_window_post_drag_event(GtkWidget* widget, GdkEvent* event, gpointer user_data) {
  gboolean is_dragging =
      GPOINTER_TO_INT(g_object_get_data(G_OBJECT(widget), "libadwaitter-interactive-drag")) != 0;
  if (is_dragging) {
    g_object_set_data(G_OBJECT(widget), "libadwaitter-interactive-drag", GINT_TO_POINTER(0));
    GtkWindow* window = GTK_WINDOW(widget);
    FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
    gint view_id = GPOINTER_TO_INT(
        g_object_get_data(G_OBJECT(window), "libadwaitter-view-id"));
    gboolean active = gtk_window_is_active(window);
    if (!active) {
      g_autoptr(FlValue) args = fl_value_new_map();
      fl_value_set_string_take(args, "viewId", fl_value_new_int(view_id));
      fl_value_set_string_take(args, "isActive", fl_value_new_bool(FALSE));
      fl_method_channel_invoke_method(channel, "onWindowActiveChanged", args, nullptr, nullptr, nullptr);
    }
  }
  return FALSE;
}

typedef struct {
  GdkDevice* device;
  gint button;
  gdouble x;
  gdouble y;
  gdouble root_x;
  gdouble root_y;
  guint32 timestamp;
} LastPointerState;

static gboolean on_capture_pointer_event(GtkWidget* widget,
                                         GdkEvent* event,
                                         gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  if (window == nullptr || event == nullptr) return FALSE;
  LastPointerState* state = static_cast<LastPointerState*>(
      g_object_get_data(G_OBJECT(window), "libadwaitter-last-pointer"));
  if (state == nullptr) {
    state = g_new0(LastPointerState, 1);
    g_object_set_data_full(G_OBJECT(window), "libadwaitter-last-pointer", state,
                           g_free);
  }
  GdkDevice* dev = gdk_event_get_device(event);
  if (dev != nullptr) {
    state->device = dev;
  }
  gdouble wx = 0, wy = 0;
  if (gdk_event_get_coords(event, &wx, &wy)) {
    state->x = wx;
    state->y = wy;
  }
  gdouble rx = 0, ry = 0;
  if (gdk_event_get_root_coords(event, &rx, &ry)) {
    state->root_x = rx;
    state->root_y = ry;
  }
  guint32 ts = gdk_event_get_time(event);
  if (ts != GDK_CURRENT_TIME) {
    state->timestamp = ts;
  }
  guint btn = 0;
  if (gdk_event_get_button(event, &btn) && btn > 0) {
    state->button = static_cast<gint>(btn);
  } else if (state->button == 0) {
    state->button = 1;
  }
  return FALSE;
}

static void release_fl_view_pointer_state(GtkWindow* window,
                                          LastPointerState* state) {
  GtkWidget* view_widget = GTK_WIDGET(
      g_object_get_data(G_OBJECT(window), "libadwaitter-fl-view"));
  if (view_widget == nullptr) return;
  GdkWindow* view_gdk_win = gtk_widget_get_window(view_widget);
  if (view_gdk_win == nullptr) return;

  GdkEvent* rel = gdk_event_new(GDK_BUTTON_RELEASE);
  rel->button.window = GDK_WINDOW(g_object_ref(view_gdk_win));
  rel->button.send_event = TRUE;
  rel->button.time = state != nullptr ? state->timestamp : GDK_CURRENT_TIME;
  rel->button.x = state != nullptr ? state->x : 0.0;
  rel->button.y = state != nullptr ? state->y : 0.0;
  rel->button.x_root = state != nullptr ? state->root_x : 0.0;
  rel->button.y_root = state != nullptr ? state->root_y : 0.0;
  rel->button.button =
      (state != nullptr && state->button > 0) ? state->button : 1;
  rel->button.state = GDK_BUTTON1_MASK;
  if (state != nullptr && state->device != nullptr) {
    gdk_event_set_device(rel, state->device);
  }
  gtk_widget_event(view_widget, rel);
  gdk_event_free(rel);
}

static void window_method_call_handler(FlMethodChannel* channel,
                                       FlMethodCall* method_call,
                                       gpointer user_data) {
  GtkWindow* default_window = GTK_WINDOW(user_data);
  FlValue* call_args = fl_method_call_get_args(method_call);
  GtkWindow* window = resolve_target_window(default_window, call_args);
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "attachSubWindow") == 0) {
    if (call_args != nullptr &&
        fl_value_get_type(call_args) == FL_VALUE_TYPE_MAP) {
      FlValue* win_val = fl_value_lookup_string(call_args, "windowHandle");
      FlValue* view_val = fl_value_lookup_string(call_args, "viewHandle");
      FlValue* id_val = fl_value_lookup_string(call_args, "viewId");
      if (win_val != nullptr && view_val != nullptr && id_val != nullptr) {
        GtkWindow* sub_win = GTK_WINDOW(
            reinterpret_cast<gpointer>(fl_value_get_int(win_val)));
        FlView* sub_view = FL_VIEW(
            reinterpret_cast<gpointer>(fl_value_get_int(view_val)));
        gint view_id = static_cast<gint>(fl_value_get_int(id_val));
        if (g_windows_by_view_id == nullptr) {
          g_windows_by_view_id =
              g_hash_table_new(g_direct_hash, g_direct_equal);
        }
        g_hash_table_insert(g_windows_by_view_id, GINT_TO_POINTER(view_id),
                            sub_win);
        FlValue* parent_val = fl_value_lookup_string(call_args, "parentViewId");
        if (parent_val != nullptr &&
            fl_value_get_type(parent_val) == FL_VALUE_TYPE_INT) {
          gint parent_view_id =
              static_cast<gint>(fl_value_get_int(parent_val));
          GtkWindow* parent_win = GTK_WINDOW(g_hash_table_lookup(
              g_windows_by_view_id, GINT_TO_POINTER(parent_view_id)));
          if (parent_win != nullptr && parent_win != sub_win) {
            gtk_window_set_transient_for(sub_win, parent_win);
          }
        }
        g_object_set_data(G_OBJECT(sub_win), "libadwaitter-view-id",
                          GINT_TO_POINTER(view_id));
        g_object_set_data(G_OBJECT(sub_win), "libadwaitter-fl-view", sub_view);
        g_signal_connect(sub_win, "destroy",
                         G_CALLBACK(on_sub_window_destroyed),
                         GINT_TO_POINTER(view_id));
        g_signal_connect(sub_win, "draw", G_CALLBACK(window_draw_cb), nullptr);
        g_signal_connect(sub_win, "size-allocate",
                         G_CALLBACK(on_window_size_allocate), nullptr);
        g_signal_connect(sub_win, "notify::is-active",
                         G_CALLBACK(on_window_active_changed), channel);
        g_signal_connect(sub_win, "window-state-event",
                         G_CALLBACK(on_window_state_changed), channel);
        gtk_widget_add_events(
            GTK_WIDGET(sub_win),
            GDK_ENTER_NOTIFY_MASK | GDK_BUTTON_RELEASE_MASK);
        g_signal_connect(sub_view, "button-press-event",
                         G_CALLBACK(on_capture_pointer_event), sub_win);
        g_signal_connect(sub_view, "motion-notify-event",
                         G_CALLBACK(on_capture_pointer_event), sub_win);
        g_signal_connect(sub_win, "enter-notify-event",
                         G_CALLBACK(on_window_post_drag_event), channel);
        g_signal_connect(sub_win, "button-release-event",
                         G_CALLBACK(on_window_post_drag_event), channel);
      }
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "startDragging") == 0) {
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag", GINT_TO_POINTER(1));
    LastPointerState* state = static_cast<LastPointerState*>(
        g_object_get_data(G_OBJECT(window), "libadwaitter-last-pointer"));
    release_fl_view_pointer_state(window, state);
    if (state != nullptr && state->timestamp != GDK_CURRENT_TIME) {
      gtk_window_begin_move_drag(
          window, state->button > 0 ? state->button : 1,
          static_cast<gint>(state->root_x), static_cast<gint>(state->root_y),
          state->timestamp);
    } else {
      GdkSeat* seat = gdk_display_get_default_seat(gdk_display_get_default());
      GdkDevice* pointer = seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
      gint x = 0, y = 0;
      if (pointer != nullptr) {
        gdk_device_get_position(pointer, nullptr, &x, &y);
      }
      guint32 timestamp = gtk_get_current_event_time();
      // Initiate native window drag (Wayland and X11) with pointer device and coordinates
      gtk_window_begin_move_drag(window, 1, x, y, timestamp);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "beginResizeDrag") == 0) {
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag", GINT_TO_POINTER(1));
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* edge_str = "bottomRight";
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* val = fl_value_lookup_string(args, "edge");
      if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING) {
        edge_str = fl_value_get_string(val);
      }
    } else if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_STRING) {
      edge_str = fl_value_get_string(args);
    }

    GdkWindowEdge edge = GDK_WINDOW_EDGE_SOUTH_EAST;
    if (strcmp(edge_str, "top") == 0) {
      edge = GDK_WINDOW_EDGE_NORTH;
    } else if (strcmp(edge_str, "bottom") == 0) {
      edge = GDK_WINDOW_EDGE_SOUTH;
    } else if (strcmp(edge_str, "left") == 0) {
      edge = GDK_WINDOW_EDGE_WEST;
    } else if (strcmp(edge_str, "right") == 0) {
      edge = GDK_WINDOW_EDGE_EAST;
    } else if (strcmp(edge_str, "topLeft") == 0) {
      edge = GDK_WINDOW_EDGE_NORTH_WEST;
    } else if (strcmp(edge_str, "topRight") == 0) {
      edge = GDK_WINDOW_EDGE_NORTH_EAST;
    } else if (strcmp(edge_str, "bottomLeft") == 0) {
      edge = GDK_WINDOW_EDGE_SOUTH_WEST;
    } else if (strcmp(edge_str, "bottomRight") == 0) {
      edge = GDK_WINDOW_EDGE_SOUTH_EAST;
    }

    LastPointerState* state = static_cast<LastPointerState*>(
        g_object_get_data(G_OBJECT(window), "libadwaitter-last-pointer"));
    release_fl_view_pointer_state(window, state);
    if (state != nullptr && state->timestamp != GDK_CURRENT_TIME) {
      gtk_window_begin_resize_drag(
          window, edge, state->button > 0 ? state->button : 1,
          static_cast<gint>(state->root_x), static_cast<gint>(state->root_y),
          state->timestamp);
    } else {
      GdkSeat* seat = gdk_display_get_default_seat(gdk_display_get_default());
      GdkDevice* pointer = seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
      gint x = 0, y = 0;
      if (pointer != nullptr) {
        gdk_device_get_position(pointer, nullptr, &x, &y);
      }
      guint32 timestamp = gtk_get_current_event_time();
      // Initiate native window resize (Wayland and X11) with pointer device and coordinates
      gtk_window_begin_resize_drag(window, edge, 1, x, y, timestamp);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "close") == 0) {
    gtk_window_close(window);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "minimize") == 0) {
    gtk_window_iconify(window);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "maximize") == 0) {
    if (gtk_window_is_maximized(window)) {
      gtk_window_unmaximize(window);
    } else {
      gtk_window_maximize(window);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "isMaximized") == 0) {
    gboolean is_max = gtk_window_is_maximized(window);
    g_autoptr(FlValue) result = fl_value_new_bool(is_max);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "setFullscreen") == 0) {
    gboolean fullscreen = FALSE;
    FlValue* args = fl_method_call_get_args(method_call);
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* val = fl_value_lookup_string(args, "fullscreen");
      if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL) {
        fullscreen = fl_value_get_bool(val);
      }
    }
    if (fullscreen) {
      gtk_window_fullscreen(window);
    } else {
      gtk_window_unfullscreen(window);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "isFullscreen") == 0) {
    GdkWindow* gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
    gboolean is_full = gdk_win != nullptr &&
        (gdk_window_get_state(gdk_win) & GDK_WINDOW_STATE_FULLSCREEN) != 0;
    g_autoptr(FlValue) result = fl_value_new_bool(is_full);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "setShadowMargin") == 0) {
    gint margin = 0;
    FlValue* args = fl_method_call_get_args(method_call);
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* val = fl_value_lookup_string(args, "margin");
      if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT) {
        margin = static_cast<gint>(fl_value_get_int(val));
      }
    }
    apply_window_shadow_margin(window, margin);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "isTiled") == 0) {
    gboolean is_tiled = is_gdk_window_tiled(window);
    g_autoptr(FlValue) result = fl_value_new_bool(is_tiled);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "isActive") == 0) {
    gboolean is_act = gtk_window_is_active(window);
    g_autoptr(FlValue) result = fl_value_new_bool(is_act);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "getWindowHandles") == 0) {
    FlView* view_widget = FL_VIEW(
        g_object_get_data(G_OBJECT(window), "libadwaitter-fl-view"));
    gint view_id = GPOINTER_TO_INT(
        g_object_get_data(G_OBJECT(window), "libadwaitter-view-id"));
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(
        map, "windowHandle",
        fl_value_new_int(reinterpret_cast<int64_t>(window)));
    fl_value_set_string_take(
        map, "viewHandle",
        fl_value_new_int(reinterpret_cast<int64_t>(view_widget)));
    fl_value_set_string_take(map, "viewId", fl_value_new_int(view_id));
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "attachPopupWindow") == 0) {
    if (call_args != nullptr &&
        fl_value_get_type(call_args) == FL_VALUE_TYPE_MAP) {
      FlValue* win_val = fl_value_lookup_string(call_args, "windowHandle");
      if (win_val != nullptr) {
        GtkWindow* popup_win = GTK_WINDOW(
            reinterpret_cast<gpointer>(fl_value_get_int(win_val)));
        if (popup_win != nullptr) {
          g_signal_connect(popup_win, "draw", G_CALLBACK(window_draw_cb),
                           nullptr);
        }
      }
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

// --- XDG Desktop Portal & Linux Sandbox Bridge (libadwaitter/portal) ---

static FlMethodChannel* g_portal_channel = nullptr;
static GtkWindow* g_portal_main_window = nullptr;
static GHashTable* g_fdo_notif_by_nid = nullptr;
static GHashTable* g_fdo_nid_by_id = nullptr;
static guint g_fdo_action_sub_id = 0;
static guint g_fdo_closed_sub_id = 0;

struct FdoNotifMeta {
  gchar* id;
  gchar* payload;
};

static void fdo_notif_meta_free(gpointer data) {
  FdoNotifMeta* meta = static_cast<FdoNotifMeta*>(data);
  if (meta == nullptr) return;
  g_free(meta->id);
  g_free(meta->payload);
  g_free(meta);
}

static void dispatch_notification_event(const gchar* id,
                                        const gchar* action_id,
                                        const gchar* payload) {
  if (g_portal_main_window != nullptr) {
    gtk_window_present(g_portal_main_window);
  }
  if (g_portal_channel == nullptr) return;
  g_autoptr(FlValue) map = fl_value_new_map();
  fl_value_set_string_take(map, "id", fl_value_new_string(id != nullptr ? id : "default"));
  fl_value_set_string_take(map, "actionId", fl_value_new_string(action_id != nullptr ? action_id : ""));
  fl_value_set_string_take(map, "payload", fl_value_new_string(payload != nullptr ? payload : ""));
  fl_method_channel_invoke_method(g_portal_channel, "onNotificationAction", map,
                                  nullptr, nullptr, nullptr);
}

static void on_notification_action_activated(GSimpleAction* action,
                                             GVariant* parameter,
                                             gpointer user_data) {
  if (parameter == nullptr) return;
  const gchar* id = "";
  const gchar* action_id = "";
  const gchar* payload = "";
  g_variant_get(parameter, "(&s&s&s)", &id, &action_id, &payload);
  dispatch_notification_event(id, action_id, payload);
}

static void on_fdo_notification_action_invoked(GDBusConnection* connection,
                                               const gchar* sender_name,
                                               const gchar* object_path,
                                               const gchar* interface_name,
                                               const gchar* signal_name,
                                               GVariant* parameters,
                                               gpointer user_data) {
  if (parameters == nullptr || g_fdo_notif_by_nid == nullptr) return;
  guint32 nid = 0;
  const gchar* action_key = "";
  g_variant_get(parameters, "(u&s)", &nid, &action_key);
  FdoNotifMeta* meta = static_cast<FdoNotifMeta*>(
      g_hash_table_lookup(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid)));
  if (meta == nullptr) return;
  const gchar* effective_action =
      (action_key != nullptr && strcmp(action_key, "default") == 0) ? "" : action_key;
  dispatch_notification_event(meta->id, effective_action, meta->payload);
}

static void on_fdo_notification_closed(GDBusConnection* connection,
                                       const gchar* sender_name,
                                       const gchar* object_path,
                                       const gchar* interface_name,
                                       const gchar* signal_name,
                                       GVariant* parameters,
                                       gpointer user_data) {
  if (parameters == nullptr || g_fdo_notif_by_nid == nullptr) return;
  guint32 nid = 0;
  guint32 reason = 0;
  g_variant_get(parameters, "(uu)", &nid, &reason);
  FdoNotifMeta* meta = static_cast<FdoNotifMeta*>(
      g_hash_table_lookup(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid)));
  if (meta != nullptr && g_fdo_nid_by_id != nullptr) {
    gpointer current = g_hash_table_lookup(g_fdo_nid_by_id, meta->id);
    if (GPOINTER_TO_UINT(current) == nid) {
      g_hash_table_remove(g_fdo_nid_by_id, meta->id);
    }
  }
  g_hash_table_remove(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid));
}

static void ensure_fdo_notifications_subscribed(GDBusConnection* bus) {
  if (bus == nullptr) return;
  if (g_fdo_notif_by_nid == nullptr) {
    g_fdo_notif_by_nid = g_hash_table_new_full(
        g_direct_hash, g_direct_equal, nullptr, fdo_notif_meta_free);
  }
  if (g_fdo_nid_by_id == nullptr) {
    g_fdo_nid_by_id = g_hash_table_new_full(
        g_str_hash, g_str_equal, g_free, nullptr);
  }
  if (g_fdo_action_sub_id == 0) {
    g_fdo_action_sub_id = g_dbus_connection_signal_subscribe(
        bus, "org.freedesktop.Notifications", "org.freedesktop.Notifications",
        "ActionInvoked", "/org/freedesktop/Notifications", nullptr,
        G_DBUS_SIGNAL_FLAGS_NONE, on_fdo_notification_action_invoked, nullptr,
        nullptr);
  }
  if (g_fdo_closed_sub_id == 0) {
    g_fdo_closed_sub_id = g_dbus_connection_signal_subscribe(
        bus, "org.freedesktop.Notifications", "org.freedesktop.Notifications",
        "NotificationClosed", "/org/freedesktop/Notifications", nullptr,
        G_DBUS_SIGNAL_FLAGS_NONE, on_fdo_notification_closed, nullptr, nullptr);
  }
}

static FlValue* build_portal_result(const char* status,
                                    FlValue* value_take,
                                    const char* error_message) {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "status", fl_value_new_string(status));
  if (value_take != nullptr) {
    fl_value_set_string_take(map, "value", value_take);
  }
  if (error_message != nullptr) {
    fl_value_set_string_take(map, "errorMessage",
                             fl_value_new_string(error_message));
  }
  return map;
}

typedef struct {
  FlMethodCall* method_call;
  GDBusConnection* connection;
  guint signal_id;
  bool return_screenshot_uri;
} PortalAsyncRequest;

static void portal_async_request_free(PortalAsyncRequest* req) {
  if (req == nullptr) return;
  if (req->signal_id != 0 && req->connection != nullptr) {
    g_dbus_connection_signal_unsubscribe(req->connection, req->signal_id);
    req->signal_id = 0;
  }
  if (req->connection != nullptr) {
    g_object_unref(req->connection);
  }
  if (req->method_call != nullptr) {
    g_object_unref(req->method_call);
  }
  g_free(req);
}

static void on_portal_request_response(GDBusConnection* connection,
                                       const gchar* sender_name,
                                       const gchar* object_path,
                                       const gchar* interface_name,
                                       const gchar* signal_name,
                                       GVariant* parameters,
                                       gpointer user_data) {
  PortalAsyncRequest* req = static_cast<PortalAsyncRequest*>(user_data);
  if (req == nullptr || req->method_call == nullptr) return;

  guint32 response_code = 2;
  g_autoptr(GVariant) results = nullptr;
  g_variant_get(parameters, "(u@a{sv})", &response_code, &results);

  g_autoptr(FlValue) reply = nullptr;
  if (response_code == 0) {
    if (req->return_screenshot_uri && results != nullptr) {
      const gchar* uri = nullptr;
      if (g_variant_lookup(results, "uri", "&s", &uri) && uri != nullptr) {
        reply = build_portal_result("granted", fl_value_new_string(uri), nullptr);
      } else {
        reply = build_portal_result("granted", nullptr, nullptr);
      }
    } else {
      reply = build_portal_result("granted", fl_value_new_bool(TRUE), nullptr);
    }
  } else if (response_code == 1) {
    reply = build_portal_result("cancelled", nullptr, nullptr);
  } else {
    reply = build_portal_result("denied", nullptr,
                                "Permission denied by user or portal.");
  }

  fl_method_call_respond_success(req->method_call, reply, nullptr);
  portal_async_request_free(req);
}

static void on_portal_dbus_call_finished(GObject* source_object,
                                         GAsyncResult* res,
                                         gpointer user_data) {
  PortalAsyncRequest* req = static_cast<PortalAsyncRequest*>(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) result = g_dbus_connection_call_finish(
      G_DBUS_CONNECTION(source_object), res, &error);
  if (error != nullptr) {
    g_autoptr(FlValue) reply =
        build_portal_result("unsupported", nullptr, error->message);
    fl_method_call_respond_success(req->method_call, reply, nullptr);
    portal_async_request_free(req);
    return;
  }
  // Response will arrive via org.freedesktop.portal.Request::Response signal.
  (void)result;
}

static void dispatch_portal_request(FlMethodCall* method_call,
                                    const char* interface_name,
                                    const char* method_name,
                                    GVariant* parameters,
                                    const char* expected_request_path,
                                    GDBusConnection* bus,
                                    bool return_screenshot_uri) {
  PortalAsyncRequest* req = g_new0(PortalAsyncRequest, 1);
  req->method_call = FL_METHOD_CALL(g_object_ref(method_call));
  req->connection = G_DBUS_CONNECTION(g_object_ref(bus));
  req->return_screenshot_uri = return_screenshot_uri;

  req->signal_id = g_dbus_connection_signal_subscribe(
      bus, "org.freedesktop.portal.Desktop", "org.freedesktop.portal.Request",
      "Response", expected_request_path, nullptr, G_DBUS_SIGNAL_FLAGS_NO_MATCH_RULE,
      on_portal_request_response, req, nullptr);

  g_dbus_connection_call(
      bus, "org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop",
      interface_name, method_name, parameters, G_VARIANT_TYPE("(o)"),
      G_DBUS_CALL_FLAGS_NONE, -1, nullptr, on_portal_dbus_call_finished, req);
}

static gchar* build_portal_request_path(GDBusConnection* bus,
                                        const char* token) {
  const gchar* unique_name = g_dbus_connection_get_unique_name(bus);
  g_autofree gchar* sanitized = g_strdup(unique_name != nullptr ? unique_name : "");
  if (sanitized[0] == ':') {
    sanitized[0] = '_';
    for (gchar* p = sanitized + 1; *p != '\0'; ++p) {
      if (*p == '.') *p = '_';
    }
  }
  return g_strdup_printf("/org/freedesktop/portal/desktop/request/%s/%s",
                         sanitized[0] == '_' ? sanitized + 1 : sanitized, token);
}

static void portal_method_call_handler(FlMethodChannel* channel,
                                       FlMethodCall* method_call,
                                       gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "getSandboxInfo") == 0) {
    gboolean is_flatpak = g_file_test("/.flatpak-info", G_FILE_TEST_EXISTS);
    const gchar* flatpak_id = g_getenv("FLATPAK_ID");
    const gchar* snap_dir = g_getenv("SNAP");
    const gchar* snap_name = g_getenv("SNAP_NAME");
    const gchar* wayland_display = g_getenv("WAYLAND_DISPLAY");

    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(map, "isFlatpak",
                             fl_value_new_bool(is_flatpak || flatpak_id != nullptr));
    fl_value_set_string_take(map, "isSnap",
                             fl_value_new_bool(snap_dir != nullptr || snap_name != nullptr));
    fl_value_set_string_take(map, "isWayland",
                             fl_value_new_bool(wayland_display != nullptr && wayland_display[0] != '\0'));
    if (flatpak_id != nullptr) {
      fl_value_set_string_take(map, "flatpakId", fl_value_new_string(flatpak_id));
    }
    if (snap_name != nullptr) {
      fl_value_set_string_take(map, "snapName", fl_value_new_string(snap_name));
    }
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "openUri") == 0) {
    const gchar* uri = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* uri_val = fl_value_lookup_string(args, "uri");
      if (uri_val != nullptr && fl_value_get_type(uri_val) == FL_VALUE_TYPE_STRING) {
        uri = fl_value_get_string(uri_val);
      }
    }
    if (uri == nullptr) {
      g_autoptr(FlValue) reply = build_portal_result("error", nullptr, "Missing uri argument.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    g_autoptr(GError) error = nullptr;
    if (gtk_show_uri_on_window(window, uri, GDK_CURRENT_TIME, &error)) {
      g_autoptr(FlValue) reply = build_portal_result("granted", nullptr, nullptr);
      fl_method_call_respond_success(method_call, reply, nullptr);
    } else {
      g_autoptr(FlValue) reply = build_portal_result(
          "error", nullptr, error != nullptr ? error->message : "Failed to open URI.");
      fl_method_call_respond_success(method_call, reply, nullptr);
    }
  } else if (strcmp(method, "sendNotification") == 0) {
    const gchar* id = "default";
    const gchar* title = "";
    const gchar* body = nullptr;
    const gchar* icon_name = nullptr;
    const gchar* priority_str = "normal";
    const gchar* payload = "";
    const gchar* category = nullptr;
    FlValue* actions_val = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      if ((v = fl_value_lookup_string(args, "id")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        id = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "title")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        title = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "body")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        body = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "iconName")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        icon_name = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "priority")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        priority_str = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "payload")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        payload = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "category")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        category = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "actions")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_LIST)
        actions_val = v;
    }
    gboolean is_flatpak = g_file_test("/.flatpak-info", G_FILE_TEST_EXISTS);
    if (!is_flatpak) {
      g_autoptr(GError) bus_err = nullptr;
      g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &bus_err);
      if (bus != nullptr) {
        ensure_fdo_notifications_subscribed(bus);
        guint32 replaces_id = 0;
        if (g_fdo_nid_by_id != nullptr) {
          replaces_id = GPOINTER_TO_UINT(g_hash_table_lookup(g_fdo_nid_by_id, id));
        }
        GVariantBuilder actions_builder;
        g_variant_builder_init(&actions_builder, G_VARIANT_TYPE("as"));
        g_variant_builder_add(&actions_builder, "s", "default");
        g_variant_builder_add(&actions_builder, "s", "Open");
        if (actions_val != nullptr) {
          size_t count = fl_value_get_length(actions_val);
          for (size_t i = 0; i < count; ++i) {
            FlValue* item = fl_value_get_list_value(actions_val, i);
            if (item != nullptr && fl_value_get_type(item) == FL_VALUE_TYPE_MAP) {
              FlValue* aid_v = fl_value_lookup_string(item, "id");
              FlValue* label_v = fl_value_lookup_string(item, "label");
              if (aid_v != nullptr && label_v != nullptr &&
                  fl_value_get_type(aid_v) == FL_VALUE_TYPE_STRING &&
                  fl_value_get_type(label_v) == FL_VALUE_TYPE_STRING) {
                g_variant_builder_add(&actions_builder, "s", fl_value_get_string(aid_v));
                g_variant_builder_add(&actions_builder, "s", fl_value_get_string(label_v));
              }
            }
          }
        }
        GVariantBuilder hints_builder;
        g_variant_builder_init(&hints_builder, G_VARIANT_TYPE("a{sv}"));
        guchar urgency = 1;
        if (strcmp(priority_str, "low") == 0) urgency = 0;
        else if (strcmp(priority_str, "urgent") == 0 || strcmp(priority_str, "high") == 0) urgency = 2;
        g_variant_builder_add(&hints_builder, "{sv}", "urgency", g_variant_new_byte(urgency));
        g_variant_builder_add(&hints_builder, "{sv}", "desktop-entry", g_variant_new_string(APPLICATION_ID));
        if (category != nullptr && category[0] != '\0') {
          g_variant_builder_add(&hints_builder, "{sv}", "category", g_variant_new_string(category));
        }
        const gchar* app_name = g_get_application_name();
        if (app_name == nullptr) app_name = APPLICATION_ID;
        g_autoptr(GError) call_err = nullptr;
        g_autoptr(GVariant) res = g_dbus_connection_call_sync(
            bus,
            "org.freedesktop.Notifications",
            "/org/freedesktop/Notifications",
            "org.freedesktop.Notifications",
            "Notify",
            g_variant_new("(susssasa{sv}i)",
                          app_name,
                          replaces_id,
                          icon_name != nullptr ? icon_name : "",
                          title,
                          body != nullptr ? body : "",
                          &actions_builder,
                          &hints_builder,
                          -1),
            G_VARIANT_TYPE("(u)"),
            G_DBUS_CALL_FLAGS_NONE,
            -1,
            nullptr,
            &call_err);
        if (res != nullptr) {
          guint32 nid = 0;
          g_variant_get(res, "(u)", &nid);
          FdoNotifMeta* meta = g_new0(FdoNotifMeta, 1);
          meta->id = g_strdup(id);
          meta->payload = g_strdup(payload);
          g_hash_table_replace(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid), meta);
          g_hash_table_replace(g_fdo_nid_by_id, g_strdup(id), GUINT_TO_POINTER(nid));
          g_autoptr(FlValue) reply = build_portal_result("granted", nullptr, nullptr);
          fl_method_call_respond_success(method_call, reply, nullptr);
          return;
        }
      }
    }
    g_autoptr(GNotification) notification = g_notification_new(title);
    if (body != nullptr) g_notification_set_body(notification, body);
    if (icon_name != nullptr) {
      g_autoptr(GIcon) icon = g_themed_icon_new(icon_name);
      g_notification_set_icon(notification, icon);
    }
#if GLIB_CHECK_VERSION(2, 70, 0)
    if (category != nullptr && category[0] != '\0') {
      g_notification_set_category(notification, category);
    }
#endif
    if (strcmp(priority_str, "low") == 0) {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_LOW);
    } else if (strcmp(priority_str, "high") == 0) {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_HIGH);
    } else if (strcmp(priority_str, "urgent") == 0) {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_URGENT);
    } else {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_NORMAL);
    }
    g_notification_set_default_action_and_target_value(
        notification, "app.libadwaitter-notify",
        g_variant_new("(sss)", id, "", payload));
    if (actions_val != nullptr) {
      size_t count = fl_value_get_length(actions_val);
      for (size_t i = 0; i < count; ++i) {
        FlValue* item = fl_value_get_list_value(actions_val, i);
        if (item != nullptr && fl_value_get_type(item) == FL_VALUE_TYPE_MAP) {
          FlValue* aid_v = fl_value_lookup_string(item, "id");
          FlValue* label_v = fl_value_lookup_string(item, "label");
          if (aid_v != nullptr && label_v != nullptr &&
              fl_value_get_type(aid_v) == FL_VALUE_TYPE_STRING &&
              fl_value_get_type(label_v) == FL_VALUE_TYPE_STRING) {
            g_notification_add_button_with_target_value(
                notification, fl_value_get_string(label_v),
                "app.libadwaitter-notify",
                g_variant_new("(sss)", id, fl_value_get_string(aid_v), payload));
          }
        }
      }
    }
    g_application_send_notification(g_application_get_default(), id, notification);
    g_autoptr(FlValue) reply = build_portal_result("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "withdrawNotification") == 0) {
    const gchar* id = "default";
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = fl_value_lookup_string(args, "id");
      if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        id = fl_value_get_string(v);
      }
    }
    if (g_fdo_nid_by_id != nullptr) {
      guint32 nid = GPOINTER_TO_UINT(g_hash_table_lookup(g_fdo_nid_by_id, id));
      if (nid != 0) {
        g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
        if (bus != nullptr) {
          g_dbus_connection_call(
              bus, "org.freedesktop.Notifications", "/org/freedesktop/Notifications",
              "org.freedesktop.Notifications", "CloseNotification",
              g_variant_new("(u)", nid), nullptr, G_DBUS_CALL_FLAGS_NONE, -1,
              nullptr, nullptr, nullptr);
        }
        g_hash_table_remove(g_fdo_nid_by_id, id);
        if (g_fdo_notif_by_nid != nullptr) {
          g_hash_table_remove(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid));
        }
      }
    }
    g_application_withdraw_notification(g_application_get_default(), id);
    g_autoptr(FlValue) reply = build_portal_result("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "openFiles") == 0) {
    const gchar* title = "Open File";
    gboolean multiple = FALSE;
    gboolean directory = FALSE;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      if ((v = fl_value_lookup_string(args, "title")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        title = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "multiple")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        multiple = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "directory")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        directory = fl_value_get_bool(v);
    }
    GtkFileChooserAction action = directory
        ? GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER
        : GTK_FILE_CHOOSER_ACTION_OPEN;
    GtkFileChooserNative* chooser = gtk_file_chooser_native_new(
        title, window, action, "_Open", "_Cancel");
    gtk_file_chooser_set_select_multiple(GTK_FILE_CHOOSER(chooser), multiple);
    gint res = gtk_native_dialog_run(GTK_NATIVE_DIALOG(chooser));
    g_autoptr(FlValue) reply = nullptr;
    if (res == GTK_RESPONSE_ACCEPT) {
      FlValue* list = fl_value_new_list();
      GSList* files = gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(chooser));
      for (GSList* iter = files; iter != nullptr; iter = iter->next) {
        gchar* path = static_cast<gchar*>(iter->data);
        fl_value_append_take(list, fl_value_new_string(path));
        g_free(path);
      }
      g_slist_free(files);
      reply = build_portal_result("granted", list, nullptr);
    } else {
      reply = build_portal_result("cancelled", nullptr, nullptr);
    }
    g_object_unref(chooser);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "saveFile") == 0) {
    const gchar* title = "Save File";
    const gchar* current_name = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      if ((v = fl_value_lookup_string(args, "title")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        title = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "currentName")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        current_name = fl_value_get_string(v);
    }
    GtkFileChooserNative* chooser = gtk_file_chooser_native_new(
        title, window, GTK_FILE_CHOOSER_ACTION_SAVE, "_Save", "_Cancel");
    gtk_file_chooser_set_do_overwrite_confirmation(GTK_FILE_CHOOSER(chooser), TRUE);
    if (current_name != nullptr) {
      gtk_file_chooser_set_current_name(GTK_FILE_CHOOSER(chooser), current_name);
    }
    gint res = gtk_native_dialog_run(GTK_NATIVE_DIALOG(chooser));
    g_autoptr(FlValue) reply = nullptr;
    if (res == GTK_RESPONSE_ACCEPT) {
      g_autofree gchar* path = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(chooser));
      reply = build_portal_result(
          "granted", path != nullptr ? fl_value_new_string(path) : nullptr, nullptr);
    } else {
      reply = build_portal_result("cancelled", nullptr, nullptr);
    }
    g_object_unref(chooser);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "inhibit") == 0) {
    const gchar* reason = "Application activity";
    gboolean idle = TRUE;
    gboolean suspend = FALSE;
    gboolean logout = FALSE;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      if ((v = fl_value_lookup_string(args, "reason")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        reason = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "idle")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        idle = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "suspend")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        suspend = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "logout")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        logout = fl_value_get_bool(v);
    }
    int flags = 0;
    if (logout) flags |= GTK_APPLICATION_INHIBIT_LOGOUT;
    if (suspend) flags |= GTK_APPLICATION_INHIBIT_SUSPEND;
    if (idle) flags |= GTK_APPLICATION_INHIBIT_IDLE;
    guint cookie = gtk_application_inhibit(
        GTK_APPLICATION(g_application_get_default()), window,
        static_cast<GtkApplicationInhibitFlags>(flags), reason);
    g_autoptr(FlValue) reply = nullptr;
    if (cookie != 0) {
      g_autofree gchar* handle = g_strdup_printf("%u", cookie);
      reply = build_portal_result("granted", fl_value_new_string(handle), nullptr);
    } else {
      reply = build_portal_result("unsupported", nullptr,
                                  "Session inhibit not supported by desktop.");
    }
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "uninhibit") == 0) {
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = fl_value_lookup_string(args, "handle");
      if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        guint cookie = static_cast<guint>(g_ascii_strtoull(fl_value_get_string(v), nullptr, 10));
        if (cookie != 0) {
          gtk_application_uninhibit(GTK_APPLICATION(g_application_get_default()), cookie);
        }
      }
    }
    g_autoptr(FlValue) reply = build_portal_result("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "requestBackground") == 0 ||
             strcmp(method, "requestCamera") == 0 ||
             strcmp(method, "takeScreenshot") == 0) {
    g_autoptr(GError) bus_error = nullptr;
    g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &bus_error);
    if (bus == nullptr) {
      g_autoptr(FlValue) reply = build_portal_result(
          "error", nullptr, bus_error != nullptr ? bus_error->message : "No session D-Bus.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }

    g_autofree gchar* token = g_strdup_printf("libadwaitter_%u", g_random_int());
    g_autofree gchar* request_path = build_portal_request_path(bus, token);

    GVariantBuilder options;
    g_variant_builder_init(&options, G_VARIANT_TYPE_VARDICT);
    g_variant_builder_add(&options, "{sv}", "handle_token", g_variant_new_string(token));

    if (strcmp(method, "requestBackground") == 0) {
      const gchar* reason = "Allow running in background";
      gboolean autostart = FALSE;
      if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
        FlValue* v = nullptr;
        if ((v = fl_value_lookup_string(args, "reason")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
          reason = fl_value_get_string(v);
        if ((v = fl_value_lookup_string(args, "autostart")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
          autostart = fl_value_get_bool(v);
      }
      g_variant_builder_add(&options, "{sv}", "reason", g_variant_new_string(reason));
      g_variant_builder_add(&options, "{sv}", "autostart", g_variant_new_boolean(autostart));
      dispatch_portal_request(
          method_call, "org.freedesktop.portal.Background", "RequestBackground",
          g_variant_new("(sa{sv})", "", &options), request_path, bus, false);
    } else if (strcmp(method, "requestCamera") == 0) {
      dispatch_portal_request(
          method_call, "org.freedesktop.portal.Camera", "AccessCamera",
          g_variant_new("(a{sv})", &options), request_path, bus, false);
    } else {
      gboolean interactive = TRUE;
      if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
        FlValue* v = fl_value_lookup_string(args, "interactive");
        if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
          interactive = fl_value_get_bool(v);
      }
      g_variant_builder_add(&options, "{sv}", "interactive", g_variant_new_boolean(interactive));
      dispatch_portal_request(
          method_call, "org.freedesktop.portal.Screenshot", "Screenshot",
          g_variant_new("(sa{sv})", "", &options), request_path, bus, true);
    }
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

// --- System Media Player Integration (MPRIS2: org.mpris.MediaPlayer2) ---

static const gchar kMprisIntrospectionXml[] =
    "<node>"
    "  <interface name='org.mpris.MediaPlayer2'>"
    "    <method name='Raise'/>"
    "    <method name='Quit'/>"
    "    <property name='CanQuit' type='b' access='read'/>"
    "    <property name='CanRaise' type='b' access='read'/>"
    "    <property name='HasTrackList' type='b' access='read'/>"
    "    <property name='Identity' type='s' access='read'/>"
    "    <property name='DesktopEntry' type='s' access='read'/>"
    "    <property name='SupportedUriSchemes' type='as' access='read'/>"
    "    <property name='SupportedMimeTypes' type='as' access='read'/>"
    "  </interface>"
    "  <interface name='org.mpris.MediaPlayer2.Player'>"
    "    <method name='Next'/>"
    "    <method name='Previous'/>"
    "    <method name='Pause'/>"
    "    <method name='PlayPause'/>"
    "    <method name='Stop'/>"
    "    <method name='Play'/>"
    "    <method name='Seek'>"
    "      <arg name='Offset' type='x' direction='in'/>"
    "    </method>"
    "    <method name='SetPosition'>"
    "      <arg name='TrackId' type='o' direction='in'/>"
    "      <arg name='Position' type='x' direction='in'/>"
    "    </method>"
    "    <signal name='Seeked'>"
    "      <arg name='Position' type='x'/>"
    "    </signal>"
    "    <property name='PlaybackStatus' type='s' access='read'/>"
    "    <property name='LoopStatus' type='s' access='readwrite'/>"
    "    <property name='Rate' type='d' access='read'/>"
    "    <property name='Shuffle' type='b' access='readwrite'/>"
    "    <property name='Metadata' type='a{sv}' access='read'/>"
    "    <property name='Volume' type='d' access='read'/>"
    "    <property name='Position' type='x' access='read'/>"
    "    <property name='MinimumRate' type='d' access='read'/>"
    "    <property name='MaximumRate' type='d' access='read'/>"
    "    <property name='CanGoNext' type='b' access='read'/>"
    "    <property name='CanGoPrevious' type='b' access='read'/>"
    "    <property name='CanPlay' type='b' access='read'/>"
    "    <property name='CanPause' type='b' access='read'/>"
    "    <property name='CanSeek' type='b' access='read'/>"
    "    <property name='CanControl' type='b' access='read'/>"
    "  </interface>"
    "</node>";

struct MprisState {
  GDBusConnection* bus;
  GDBusNodeInfo* node_info;
  guint bus_owner_id;
  guint root_reg_id;
  guint player_reg_id;
  FlMethodChannel* channel;
  GtkWindow* window;
  gchar* title;
  gchar* artist;
  gchar* album;
  gchar* art_url;
  gchar* track_id;
  gint64 duration_us;
  gint64 position_us;
  gint64 position_ts_us;
  gchar* playback_status;
  gchar* loop_status;
  gboolean shuffle;
  gdouble rate;
  gboolean can_go_next;
  gboolean can_go_previous;
  gboolean can_play;
  gboolean can_pause;
  gboolean can_seek;
};

static MprisState g_mpris = {};

static gint64 mpris_current_position_us() {
  gint64 pos = g_mpris.position_us;
  if (g_mpris.playback_status != nullptr &&
      strcmp(g_mpris.playback_status, "Playing") == 0 &&
      g_mpris.position_ts_us > 0) {
    gint64 elapsed = g_get_monotonic_time() - g_mpris.position_ts_us;
    if (elapsed > 0) {
      pos += static_cast<gint64>(elapsed * (g_mpris.rate > 0 ? g_mpris.rate : 1.0));
    }
  }
  if (g_mpris.duration_us > 0 && pos > g_mpris.duration_us) {
    pos = g_mpris.duration_us;
  }
  return pos < 0 ? 0 : pos;
}

static GVariant* mpris_build_metadata_variant() {
  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE("a{sv}"));
  const gchar* tid = (g_mpris.track_id != nullptr &&
                      g_variant_is_object_path(g_mpris.track_id))
                         ? g_mpris.track_id
                         : "/org/libadwaitter/track/0";
  g_variant_builder_add(&builder, "{sv}", "mpris:trackid",
                        g_variant_new_object_path(tid));
  if (g_mpris.duration_us > 0) {
    g_variant_builder_add(&builder, "{sv}", "mpris:length",
                          g_variant_new_int64(g_mpris.duration_us));
  }
  if (g_mpris.title != nullptr && g_mpris.title[0] != '\0') {
    g_variant_builder_add(&builder, "{sv}", "xesam:title",
                          g_variant_new_string(g_mpris.title));
  }
  if (g_mpris.artist != nullptr && g_mpris.artist[0] != '\0') {
    GVariantBuilder artist_builder;
    g_variant_builder_init(&artist_builder, G_VARIANT_TYPE("as"));
    g_variant_builder_add(&artist_builder, "s", g_mpris.artist);
    g_variant_builder_add(&builder, "{sv}", "xesam:artist",
                          g_variant_builder_end(&artist_builder));
  }
  if (g_mpris.album != nullptr && g_mpris.album[0] != '\0') {
    g_variant_builder_add(&builder, "{sv}", "xesam:album",
                          g_variant_new_string(g_mpris.album));
  }
  if (g_mpris.art_url != nullptr && g_mpris.art_url[0] != '\0') {
    g_variant_builder_add(&builder, "{sv}", "mpris:artUrl",
                          g_variant_new_string(g_mpris.art_url));
  }
  return g_variant_builder_end(&builder);
}

static void mpris_dispatch_command(const char* command,
                                   gboolean has_offset,
                                   gint64 offset_us,
                                   gboolean has_position,
                                   gint64 position_us) {
  if (g_mpris.channel == nullptr) return;
  g_autoptr(FlValue) map = fl_value_new_map();
  fl_value_set_string_take(map, "command", fl_value_new_string(command));
  if (has_offset) {
    fl_value_set_string_take(map, "offsetUs", fl_value_new_int(offset_us));
  }
  if (has_position) {
    fl_value_set_string_take(map, "positionUs", fl_value_new_int(position_us));
  }
  fl_method_channel_invoke_method(g_mpris.channel, "onMediaCommand", map,
                                  nullptr, nullptr, nullptr);
}

static void mpris_root_method_call(GDBusConnection* connection,
                                   const gchar* sender,
                                   const gchar* object_path,
                                   const gchar* interface_name,
                                   const gchar* method_name,
                                   GVariant* parameters,
                                   GDBusMethodInvocation* invocation,
                                   gpointer user_data) {
  if (strcmp(method_name, "Raise") == 0) {
    if (g_mpris.window != nullptr) {
      gtk_window_present(g_mpris.window);
    }
    mpris_dispatch_command("raise", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Quit") == 0) {
    mpris_dispatch_command("quit", FALSE, 0, FALSE, 0);
  }
  g_dbus_method_invocation_return_value(invocation, nullptr);
}

static GVariant* mpris_root_get_property(GDBusConnection* connection,
                                         const gchar* sender,
                                         const gchar* object_path,
                                         const gchar* interface_name,
                                         const gchar* property_name,
                                         GError** error,
                                         gpointer user_data) {
  if (strcmp(property_name, "CanQuit") == 0) return g_variant_new_boolean(TRUE);
  if (strcmp(property_name, "CanRaise") == 0) return g_variant_new_boolean(TRUE);
  if (strcmp(property_name, "HasTrackList") == 0) return g_variant_new_boolean(FALSE);
  if (strcmp(property_name, "Identity") == 0) {
    const gchar* name = g_get_application_name();
    return g_variant_new_string(name != nullptr ? name : APPLICATION_ID);
  }
  if (strcmp(property_name, "DesktopEntry") == 0) {
    return g_variant_new_string(APPLICATION_ID);
  }
  if (strcmp(property_name, "SupportedUriSchemes") == 0 ||
      strcmp(property_name, "SupportedMimeTypes") == 0) {
    return g_variant_new_strv(nullptr, 0);
  }
  return nullptr;
}

static void mpris_player_method_call(GDBusConnection* connection,
                                     const gchar* sender,
                                     const gchar* object_path,
                                     const gchar* interface_name,
                                     const gchar* method_name,
                                     GVariant* parameters,
                                     GDBusMethodInvocation* invocation,
                                     gpointer user_data) {
  if (strcmp(method_name, "Play") == 0) {
    mpris_dispatch_command("play", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Pause") == 0) {
    mpris_dispatch_command("pause", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "PlayPause") == 0) {
    mpris_dispatch_command("playPause", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Stop") == 0) {
    mpris_dispatch_command("stop", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Next") == 0) {
    mpris_dispatch_command("next", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Previous") == 0) {
    mpris_dispatch_command("previous", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Seek") == 0) {
    gint64 offset = 0;
    g_variant_get(parameters, "(x)", &offset);
    mpris_dispatch_command("seek", TRUE, offset, FALSE, 0);
  } else if (strcmp(method_name, "SetPosition") == 0) {
    const gchar* tid = nullptr;
    gint64 pos = 0;
    g_variant_get(parameters, "(&ox)", &tid, &pos);
    mpris_dispatch_command("setPosition", FALSE, 0, TRUE, pos);
  }
  g_dbus_method_invocation_return_value(invocation, nullptr);
}

static GVariant* mpris_player_get_property(GDBusConnection* connection,
                                           const gchar* sender,
                                           const gchar* object_path,
                                           const gchar* interface_name,
                                           const gchar* property_name,
                                           GError** error,
                                           gpointer user_data) {
  if (strcmp(property_name, "PlaybackStatus") == 0) {
    return g_variant_new_string(
        g_mpris.playback_status != nullptr ? g_mpris.playback_status : "Stopped");
  }
  if (strcmp(property_name, "LoopStatus") == 0) {
    return g_variant_new_string(
        g_mpris.loop_status != nullptr ? g_mpris.loop_status : "None");
  }
  if (strcmp(property_name, "Rate") == 0) {
    return g_variant_new_double(g_mpris.rate > 0 ? g_mpris.rate : 1.0);
  }
  if (strcmp(property_name, "Shuffle") == 0) {
    return g_variant_new_boolean(g_mpris.shuffle);
  }
  if (strcmp(property_name, "Metadata") == 0) {
    return mpris_build_metadata_variant();
  }
  if (strcmp(property_name, "Volume") == 0) return g_variant_new_double(1.0);
  if (strcmp(property_name, "Position") == 0) {
    return g_variant_new_int64(mpris_current_position_us());
  }
  if (strcmp(property_name, "MinimumRate") == 0) return g_variant_new_double(1.0);
  if (strcmp(property_name, "MaximumRate") == 0) return g_variant_new_double(1.0);
  if (strcmp(property_name, "CanGoNext") == 0) return g_variant_new_boolean(g_mpris.can_go_next);
  if (strcmp(property_name, "CanGoPrevious") == 0) return g_variant_new_boolean(g_mpris.can_go_previous);
  if (strcmp(property_name, "CanPlay") == 0) return g_variant_new_boolean(g_mpris.can_play);
  if (strcmp(property_name, "CanPause") == 0) return g_variant_new_boolean(g_mpris.can_pause);
  if (strcmp(property_name, "CanSeek") == 0) return g_variant_new_boolean(g_mpris.can_seek);
  if (strcmp(property_name, "CanControl") == 0) return g_variant_new_boolean(TRUE);
  return nullptr;
}

static const GDBusInterfaceVTable kMprisRootVTable = {
    mpris_root_method_call,
    mpris_root_get_property,
    nullptr,
    {0},
};

static void mpris_emit_properties_changed(GVariant* changed_props);

static gboolean mpris_player_set_property(GDBusConnection* connection,
                                          const gchar* sender,
                                          const gchar* object_path,
                                          const gchar* interface_name,
                                          const gchar* property_name,
                                          GVariant* value,
                                          GError** error,
                                          gpointer user_data) {
  if (strcmp(property_name, "LoopStatus") == 0 &&
      g_variant_is_of_type(value, G_VARIANT_TYPE_STRING)) {
    const gchar* s = g_variant_get_string(value, nullptr);
    g_clear_pointer(&g_mpris.loop_status, g_free);
    const char* dart_mode = "none";
    if (strcmp(s, "Track") == 0) {
      g_mpris.loop_status = g_strdup("Track");
      dart_mode = "track";
    } else if (strcmp(s, "Playlist") == 0) {
      g_mpris.loop_status = g_strdup("Playlist");
      dart_mode = "playlist";
    } else {
      g_mpris.loop_status = g_strdup("None");
      dart_mode = "none";
    }
    GVariantBuilder changed;
    g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&changed, "{sv}", "LoopStatus",
                          g_variant_new_string(g_mpris.loop_status));
    mpris_emit_properties_changed(g_variant_builder_end(&changed));
    if (g_mpris.channel != nullptr) {
      g_autoptr(FlValue) map = fl_value_new_map();
      fl_value_set_string_take(map, "command", fl_value_new_string("setLoopMode"));
      fl_value_set_string_take(map, "loopMode", fl_value_new_string(dart_mode));
      fl_method_channel_invoke_method(g_mpris.channel, "onMediaCommand", map,
                                      nullptr, nullptr, nullptr);
    }
    return TRUE;
  }
  if (strcmp(property_name, "Shuffle") == 0 &&
      g_variant_is_of_type(value, G_VARIANT_TYPE_BOOLEAN)) {
    g_mpris.shuffle = g_variant_get_boolean(value);
    GVariantBuilder changed;
    g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&changed, "{sv}", "Shuffle",
                          g_variant_new_boolean(g_mpris.shuffle));
    mpris_emit_properties_changed(g_variant_builder_end(&changed));
    if (g_mpris.channel != nullptr) {
      g_autoptr(FlValue) map = fl_value_new_map();
      fl_value_set_string_take(map, "command", fl_value_new_string("setShuffle"));
      fl_value_set_string_take(map, "shuffle", fl_value_new_bool(g_mpris.shuffle));
      fl_method_channel_invoke_method(g_mpris.channel, "onMediaCommand", map,
                                      nullptr, nullptr, nullptr);
    }
    return TRUE;
  }
  return FALSE;
}

static const GDBusInterfaceVTable kMprisPlayerVTable = {
    mpris_player_method_call,
    mpris_player_get_property,
    mpris_player_set_property,
    {0},
};

static void mpris_ensure_registered() {
  if (g_mpris.bus_owner_id != 0) return;
  g_autoptr(GError) error = nullptr;
  if (g_mpris.bus == nullptr) {
    g_mpris.bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
    if (g_mpris.bus == nullptr) return;
  }
  if (g_mpris.node_info == nullptr) {
    g_mpris.node_info = g_dbus_node_info_new_for_xml(kMprisIntrospectionXml, &error);
    if (g_mpris.node_info == nullptr) return;
  }
  if (g_mpris.root_reg_id == 0) {
    g_mpris.root_reg_id = g_dbus_connection_register_object(
        g_mpris.bus, "/org/mpris/MediaPlayer2",
        g_mpris.node_info->interfaces[0], &kMprisRootVTable, nullptr, nullptr,
        &error);
  }
  if (g_mpris.player_reg_id == 0) {
    g_mpris.player_reg_id = g_dbus_connection_register_object(
        g_mpris.bus, "/org/mpris/MediaPlayer2",
        g_mpris.node_info->interfaces[1], &kMprisPlayerVTable, nullptr, nullptr,
        &error);
  }
  g_autofree gchar* sanitized = g_strdup(APPLICATION_ID);
  for (gchar* p = sanitized; *p != '\0'; ++p) {
    if (!g_ascii_isalnum(*p) && *p != '_') *p = '_';
  }
  g_autofree gchar* bus_name = g_strdup_printf(
      "org.mpris.MediaPlayer2.%s.instance%d", sanitized, static_cast<int>(getpid()));
  g_mpris.bus_owner_id = g_bus_own_name_on_connection(
      g_mpris.bus, bus_name, G_BUS_NAME_OWNER_FLAGS_NONE,
      nullptr, nullptr, nullptr, nullptr);
}

static void mpris_emit_properties_changed(GVariant* changed_props) {
  if (g_mpris.bus == nullptr || g_mpris.bus_owner_id == 0) {
    g_variant_unref(g_variant_ref_sink(changed_props));
    return;
  }
  GVariantBuilder invalidated;
  g_variant_builder_init(&invalidated, G_VARIANT_TYPE("as"));
  g_dbus_connection_emit_signal(
      g_mpris.bus, nullptr, "/org/mpris/MediaPlayer2",
      "org.freedesktop.DBus.Properties", "PropertiesChanged",
      g_variant_new("(s@a{sv}as)", "org.mpris.MediaPlayer2.Player",
                    changed_props, &invalidated),
      nullptr);
}

static void mpris_unregister() {
  if (g_mpris.bus != nullptr) {
    if (g_mpris.root_reg_id != 0) {
      g_dbus_connection_unregister_object(g_mpris.bus, g_mpris.root_reg_id);
      g_mpris.root_reg_id = 0;
    }
    if (g_mpris.player_reg_id != 0) {
      g_dbus_connection_unregister_object(g_mpris.bus, g_mpris.player_reg_id);
      g_mpris.player_reg_id = 0;
    }
  }
  if (g_mpris.bus_owner_id != 0) {
    g_bus_unown_name(g_mpris.bus_owner_id);
    g_mpris.bus_owner_id = 0;
  }
}

static void media_method_call_handler(FlMethodChannel* channel,
                                      FlMethodCall* method_call,
                                      gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "setMetadata") == 0) {
    mpris_ensure_registered();
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      g_clear_pointer(&g_mpris.title, g_free);
      g_clear_pointer(&g_mpris.artist, g_free);
      g_clear_pointer(&g_mpris.album, g_free);
      g_clear_pointer(&g_mpris.art_url, g_free);
      g_clear_pointer(&g_mpris.track_id, g_free);
      g_mpris.duration_us = 0;

      if ((v = fl_value_lookup_string(args, "title")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.title = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "artist")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.artist = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "album")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.album = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "artUrl")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.art_url = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "trackId")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.track_id = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "durationUs")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_INT)
        g_mpris.duration_us = fl_value_get_int(v);
    }
    GVariantBuilder changed;
    g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&changed, "{sv}", "Metadata",
                          mpris_build_metadata_variant());
    mpris_emit_properties_changed(g_variant_builder_end(&changed));
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "setPlaybackState") == 0) {
    mpris_ensure_registered();
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      if ((v = fl_value_lookup_string(args, "status")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        const gchar* s = fl_value_get_string(v);
        g_clear_pointer(&g_mpris.playback_status, g_free);
        if (strcmp(s, "playing") == 0) g_mpris.playback_status = g_strdup("Playing");
        else if (strcmp(s, "paused") == 0) g_mpris.playback_status = g_strdup("Paused");
        else g_mpris.playback_status = g_strdup("Stopped");
      }
      if ((v = fl_value_lookup_string(args, "positionUs")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
        g_mpris.position_us = fl_value_get_int(v);
        g_mpris.position_ts_us = g_get_monotonic_time();
      }
      if ((v = fl_value_lookup_string(args, "rate")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_FLOAT) {
        g_mpris.rate = fl_value_get_float(v);
      }
      if ((v = fl_value_lookup_string(args, "loopMode")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        const gchar* lm = fl_value_get_string(v);
        g_clear_pointer(&g_mpris.loop_status, g_free);
        if (strcmp(lm, "track") == 0) g_mpris.loop_status = g_strdup("Track");
        else if (strcmp(lm, "playlist") == 0) g_mpris.loop_status = g_strdup("Playlist");
        else g_mpris.loop_status = g_strdup("None");
      }
      if ((v = fl_value_lookup_string(args, "shuffle")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL) {
        g_mpris.shuffle = fl_value_get_bool(v);
      }
      if ((v = fl_value_lookup_string(args, "canGoNext")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_go_next = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "canGoPrevious")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_go_previous = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "canPlay")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_play = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "canPause")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_pause = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "canSeek")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_seek = fl_value_get_bool(v);
    }
    GVariantBuilder changed;
    g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&changed, "{sv}", "PlaybackStatus",
                          g_variant_new_string(g_mpris.playback_status != nullptr ? g_mpris.playback_status : "Stopped"));
    g_variant_builder_add(&changed, "{sv}", "LoopStatus",
                          g_variant_new_string(g_mpris.loop_status != nullptr ? g_mpris.loop_status : "None"));
    g_variant_builder_add(&changed, "{sv}", "Shuffle", g_variant_new_boolean(g_mpris.shuffle));
    g_variant_builder_add(&changed, "{sv}", "CanGoNext", g_variant_new_boolean(g_mpris.can_go_next));
    g_variant_builder_add(&changed, "{sv}", "CanGoPrevious", g_variant_new_boolean(g_mpris.can_go_previous));
    g_variant_builder_add(&changed, "{sv}", "CanPlay", g_variant_new_boolean(g_mpris.can_play));
    g_variant_builder_add(&changed, "{sv}", "CanPause", g_variant_new_boolean(g_mpris.can_pause));
    g_variant_builder_add(&changed, "{sv}", "CanSeek", g_variant_new_boolean(g_mpris.can_seek));
    mpris_emit_properties_changed(g_variant_builder_end(&changed));
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "setPosition") == 0) {
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = fl_value_lookup_string(args, "positionUs");
      if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
        g_mpris.position_us = fl_value_get_int(v);
        g_mpris.position_ts_us = g_get_monotonic_time();
        if (g_mpris.bus != nullptr && g_mpris.bus_owner_id != 0) {
          g_dbus_connection_emit_signal(
              g_mpris.bus, nullptr, "/org/mpris/MediaPlayer2",
              "org.mpris.MediaPlayer2.Player", "Seeked",
              g_variant_new("(x)", g_mpris.position_us), nullptr);
        }
      }
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "dispose") == 0) {
    mpris_unregister();
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

static void apply_window_shadow_margin(GtkWindow* window, gint margin) {
  if (window == nullptr) return;
  g_object_set_data(G_OBJECT(window), "libadwaitter-shadow-margin",
                    GINT_TO_POINTER(margin));
  GdkWindow* gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_win != nullptr) {
    gdk_window_set_shadow_width(gdk_win, margin, margin, margin, margin);
  }
}

static void on_window_size_allocate(GtkWidget* widget,
                                    GtkAllocation* allocation,
                                    gpointer user_data) {
  gint margin = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(widget), "libadwaitter-shadow-margin"));
  if (margin > 0) {
    apply_window_shadow_margin(GTK_WINDOW(widget), margin);
  }
}

// Cairo draw callback ensuring true alpha transparency (preventing opaque corner artifacts)
static gboolean window_draw_cb(GtkWidget* widget, cairo_t* cr, gpointer user_data) {
  cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0);
  cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint(cr);
  return FALSE;
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
  gtk_widget_show(toplevel);
  gint margin = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(toplevel), "libadwaitter-shadow-margin"));
  if (margin > 0) {
    apply_window_shadow_margin(GTK_WINDOW(toplevel), margin);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  g_setenv("GTK_USE_PORTAL", "1", FALSE);
  MyApplication* self = MY_APPLICATION(application);

  // Set Wayland xdg_toplevel app_id / prgname so compositors match .desktop & icon
  g_set_prgname(APPLICATION_ID);
  g_set_application_name("__APP_TITLE__");

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  // Account for 24px CSD shadow margin on each side so the visible window
  // starts at the requested size identically in both debug and release builds.
  constexpr gint kInitialShadowMargin = 24;
  g_object_set_data(G_OBJECT(window), "libadwaitter-shadow-margin",
                    GINT_TO_POINTER(kInitialShadowMargin));
  gtk_window_set_default_size(window, __WINDOW_WIDTH__ + kInitialShadowMargin * 2,
                              __WINDOW_HEIGHT__ + kInitialShadowMargin * 2);

  // Enforce Libadwaita's standard minimum window dimensions (360x294)
  GdkGeometry min_geometry = {};
  min_geometry.min_width = 360 + kInitialShadowMargin * 2;
  min_geometry.min_height = 294 + kInitialShadowMargin * 2;
  gtk_window_set_geometry_hints(window, nullptr, &min_geometry,
                                GDK_HINT_MIN_SIZE);

  // Configure RGBA visual for alpha transparency and rounded corners
  GdkScreen* screen = gtk_window_get_screen(window);
  GdkVisual* visual = gdk_screen_get_rgba_visual(screen);
  if (visual != nullptr && gdk_screen_is_composited(screen)) {
    gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);
    gtk_widget_set_visual(GTK_WIDGET(window), visual);
  }

  // Hook draw signal to clear the Cairo surface to transparent black (operator CLEAR)
  g_signal_connect(window, "draw", G_CALLBACK(window_draw_cb), nullptr);
  g_signal_connect(window, "size-allocate",
                   G_CALLBACK(on_window_size_allocate), nullptr);

  // Apply transparent GTK CSS rule preventing opaque background drawing
  GtkCssProvider* css_provider = gtk_css_provider_new();
  gtk_css_provider_load_from_data(
      css_provider,
      "window, .background, decoration { background-color: transparent !important; background: transparent !important; border: none !important; outline: none !important; box-shadow: none !important; }",
      -1, nullptr);
  gtk_style_context_add_provider_for_screen(
      screen, GTK_STYLE_PROVIDER(css_provider),
      GTK_STYLE_PROVIDER_PRIORITY_USER);

  // Disable server-side decorations (SSD) to enable in-app client-side decorations (CSD)
  gtk_window_set_decorated(window, FALSE);

  gtk_window_set_title(window, "__APP_TITLE__");

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  // Configure FlView background as fully transparent (alpha = 0.0)
  GdkRGBA background_color = {0.0, 0.0, 0.0, 0.0};
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Register Libadwaitter window control MethodChannel
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* window_channel =
      fl_method_channel_new(messenger, kWindowChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      window_channel, window_method_call_handler, window, nullptr);
  g_signal_connect(window, "notify::is-active",
                   G_CALLBACK(on_window_active_changed), window_channel);
  g_signal_connect(window, "window-state-event",
                   G_CALLBACK(on_window_state_changed), window_channel);
  if (g_windows_by_view_id == nullptr) {
    g_windows_by_view_id = g_hash_table_new(g_direct_hash, g_direct_equal);
  }
  gint main_view_id = static_cast<gint>(fl_view_get_id(view));
  g_hash_table_insert(g_windows_by_view_id, GINT_TO_POINTER(0), window);
  g_hash_table_insert(g_windows_by_view_id, GINT_TO_POINTER(main_view_id),
                      window);
  g_object_set_data(G_OBJECT(window), "libadwaitter-view-id",
                    GINT_TO_POINTER(0));
  g_object_set_data(G_OBJECT(window), "libadwaitter-fl-view", view);
  gtk_widget_add_events(GTK_WIDGET(window), GDK_ENTER_NOTIFY_MASK | GDK_BUTTON_RELEASE_MASK);
  g_signal_connect(view, "button-press-event",
                   G_CALLBACK(on_capture_pointer_event), window);
  g_signal_connect(view, "motion-notify-event",
                   G_CALLBACK(on_capture_pointer_event), window);
  g_signal_connect(window, "enter-notify-event",
                   G_CALLBACK(on_window_post_drag_event), window_channel);
  g_signal_connect(window, "button-release-event",
                   G_CALLBACK(on_window_post_drag_event), window_channel);

  // Register Libadwaitter desktop animation and system settings MethodChannel
  FlMethodChannel* settings_channel =
      fl_method_channel_new(messenger, kSettingsChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      settings_channel, settings_method_call_handler, settings_channel, nullptr);

  // Register Libadwaitter central style manager MethodChannel (theme & accent color)
  FlMethodChannel* style_channel =
      fl_method_channel_new(messenger, kStyleChannelName, FL_METHOD_CODEC(codec));
  StyleBridgeState* style_state = g_new0(StyleBridgeState, 1);
  style_state->channel = style_channel;
  g_object_set_data_full(G_OBJECT(window), "libadwaitter-style-bridge",
                         style_state, style_bridge_state_free);
  fl_method_channel_set_method_call_handler(
      style_channel, style_method_call_handler, style_state, nullptr);

  // Register Libadwaitter XDG Desktop Portal & sandbox bridge MethodChannel
  FlMethodChannel* portal_channel =
      fl_method_channel_new(messenger, kPortalChannelName, FL_METHOD_CODEC(codec));
  g_portal_channel = portal_channel;
  g_portal_main_window = window;
  fl_method_channel_set_method_call_handler(
      portal_channel, portal_method_call_handler, window, nullptr);

  // Register Libadwaitter MPRIS2 system media player MethodChannel
  FlMethodChannel* media_channel =
      fl_method_channel_new(messenger, kMediaChannelName, FL_METHOD_CODEC(codec));
  g_mpris.channel = media_channel;
  g_mpris.window = window;
  fl_method_channel_set_method_call_handler(
      media_channel, media_method_call_handler, window, nullptr);

  // Register GApplication action for interactive GNotification click/button callbacks
  if (g_action_map_lookup_action(G_ACTION_MAP(application), "libadwaitter-notify") == nullptr) {
    g_autoptr(GSimpleAction) notify_action =
        g_simple_action_new("libadwaitter-notify", G_VARIANT_TYPE("(sss)"));
    g_signal_connect(notify_action, "activate",
                     G_CALLBACK(on_notification_action_activated), nullptr);
    g_action_map_add_action(G_ACTION_MAP(application), G_ACTION(notify_action));
  }

  GSettingsSchemaSource* schema_source = g_settings_schema_source_get_default();
  if (schema_source != nullptr) {
    g_autoptr(GSettingsSchema) interface_schema =
        g_settings_schema_source_lookup(schema_source, "org.gnome.desktop.interface", TRUE);
    if (interface_schema != nullptr) {
      style_state->interface_settings = g_settings_new("org.gnome.desktop.interface");
      if (g_settings_schema_has_key(interface_schema, "color-scheme")) {
        g_signal_connect(style_state->interface_settings, "changed::color-scheme",
                         G_CALLBACK(on_gsettings_appearance_changed), style_state);
        g_free(g_settings_get_string(style_state->interface_settings, "color-scheme"));
      } else if (g_settings_schema_has_key(interface_schema, "gtk-theme")) {
        g_signal_connect(style_state->interface_settings, "changed::gtk-theme",
                         G_CALLBACK(on_gsettings_appearance_changed), style_state);
        g_free(g_settings_get_string(style_state->interface_settings, "gtk-theme"));
      }
      if (g_settings_schema_has_key(interface_schema, "accent-color")) {
        g_signal_connect(style_state->interface_settings, "changed::accent-color",
                         G_CALLBACK(on_gsettings_appearance_changed), style_state);
        g_free(g_settings_get_string(style_state->interface_settings, "accent-color"));
      }
    }

    g_autoptr(GSettingsSchema) a11y_schema =
        g_settings_schema_source_lookup(schema_source, "org.gnome.desktop.a11y.interface", TRUE);
    if (a11y_schema != nullptr && g_settings_schema_has_key(a11y_schema, "high-contrast")) {
      style_state->a11y_settings = g_settings_new("org.gnome.desktop.a11y.interface");
      g_signal_connect(style_state->a11y_settings, "changed::high-contrast",
                       G_CALLBACK(on_gsettings_appearance_changed), style_state);
      (void)g_settings_get_boolean(style_state->a11y_settings, "high-contrast");
    }
    g_autoptr(GSettingsSchema) wm_schema =
        g_settings_schema_source_lookup(schema_source, "org.gnome.desktop.wm.preferences", TRUE);
    if (wm_schema != nullptr && g_settings_schema_has_key(wm_schema, "button-layout")) {
      GSettings* wm_settings = g_settings_new("org.gnome.desktop.wm.preferences");
      g_object_set_data_full(G_OBJECT(window), "libadwaitter-wm-gsettings",
                             wm_settings, g_object_unref);
      g_signal_connect(wm_settings, "changed::button-layout",
                       G_CALLBACK(on_wm_button_layout_changed), settings_channel);
      g_free(g_settings_get_string(wm_settings, "button-layout"));
    }
  }

  GWeakRef* weak_window = g_new(GWeakRef, 1);
  g_weak_ref_init(weak_window, window);
  g_bus_get(G_BUS_TYPE_SESSION, nullptr, on_session_bus_ready, weak_window);

  GtkSettings* default_settings = gtk_settings_get_default();
  if (default_settings != nullptr) {
    g_signal_connect(default_settings, "notify::gtk-enable-animations",
                     G_CALLBACK(on_gtk_animations_changed), settings_channel);
    g_signal_connect(default_settings, "notify::gtk-decoration-layout",
                     G_CALLBACK(on_gtk_decoration_layout_changed), settings_channel);
  }

  // Show the window when Flutter renders.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  mpris_unregister();
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_init(MyApplication* self) {}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
''';
