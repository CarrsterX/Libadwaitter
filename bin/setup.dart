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
      stdout.writeln(
          '[dry-run] Would generate Libadwaitter counter app in: ${cwd.path}/lib/main.dart');
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
  svgFile.writeAsStringSync(
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
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

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void apply_window_shadow_margin(GtkWindow* window, gint margin) {
  if (window == nullptr) return;
  GdkWindow* gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_win == nullptr) return;
  gint w = gtk_widget_get_allocated_width(GTK_WIDGET(window));
  gint h = gtk_widget_get_allocated_height(GTK_WIDGET(window));
  if (w > margin * 2 && h > margin * 2) {
    gdk_window_set_shadow_width(gdk_win, margin, margin, margin, margin);
  }
}

static void on_window_size_allocate(GtkWidget* widget,
                                    GtkAllocation* allocation,
                                    gpointer user_data) {
  gint margin = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(widget), "libadwaitter-shadow-margin"));
  if (margin >= 0) {
    apply_window_shadow_margin(GTK_WINDOW(widget), margin);
  }
}

static gboolean window_draw_cb(GtkWidget* widget, cairo_t* cr,
                               gpointer user_data) {
  cairo_save(cr);
  cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0);
  cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
  cairo_paint(cr);
  cairo_restore(cr);
  return FALSE;
}

static void first_frame_cb(MyApplication* self, FlView* view) {
  GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
  gtk_widget_show(toplevel);
  if (GTK_IS_WINDOW(toplevel)) {
    gint margin = GPOINTER_TO_INT(
        g_object_get_data(G_OBJECT(toplevel), "libadwaitter-shadow-margin"));
    apply_window_shadow_margin(GTK_WINDOW(toplevel), margin);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  g_setenv("GTK_USE_PORTAL", "1", FALSE);
  MyApplication* self = MY_APPLICATION(application);

  g_set_prgname(APPLICATION_ID);
  g_set_application_name("__APP_TITLE__");

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  constexpr gint kInitialShadowMargin = 24;
  g_object_set_data(G_OBJECT(window), "libadwaitter-shadow-margin",
                    GINT_TO_POINTER(kInitialShadowMargin));
  gtk_window_set_default_size(window, __WINDOW_WIDTH__ + kInitialShadowMargin * 2,
                              __WINDOW_HEIGHT__ + kInitialShadowMargin * 2);

  GdkGeometry min_geometry = {};
  min_geometry.min_width = 360 + kInitialShadowMargin * 2;
  min_geometry.min_height = 294 + kInitialShadowMargin * 2;
  gtk_window_set_geometry_hints(window, nullptr, &min_geometry,
                                GDK_HINT_MIN_SIZE);

  // Configure RGBA visual for alpha transparency and rounded corners.
  GdkScreen* screen = gtk_window_get_screen(window);
  GdkVisual* visual = gdk_screen_get_rgba_visual(screen);
  if (visual != nullptr && gdk_screen_is_composited(screen)) {
    gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);
    gtk_widget_set_visual(GTK_WIDGET(window), visual);
  }

  g_signal_connect(window, "draw", G_CALLBACK(window_draw_cb), nullptr);
  g_signal_connect(window, "size-allocate", G_CALLBACK(on_window_size_allocate),
                   nullptr);

  GtkCssProvider* css_provider = gtk_css_provider_new();
  gtk_css_provider_load_from_data(
      css_provider,
      "window, .background, decoration { background-color: transparent "
      "!important; background: transparent !important; border: none "
      "!important; outline: none !important; box-shadow: none !important; }",
      -1, nullptr);
  gtk_style_context_add_provider_for_screen(screen,
                                            GTK_STYLE_PROVIDER(css_provider),
                                            GTK_STYLE_PROVIDER_PRIORITY_USER);

  // Disable server-side decorations (SSD) for client-side decorations (CSD).
  GtkWidget* empty_titlebar = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_size_request(empty_titlebar, 0, 0);
  gtk_window_set_titlebar(window, empty_titlebar);
  gtk_window_set_decorated(window, FALSE);
  gtk_window_set_title(window, "__APP_TITLE__");

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color = {0.0, 0.0, 0.0, 0.0};
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  GtkWidget* root_overlay = gtk_overlay_new();
  gtk_container_add(GTK_CONTAINER(root_overlay), GTK_WIDGET(view));
  gtk_widget_show(root_overlay);
  gtk_container_add(GTK_CONTAINER(window), root_overlay);
  g_object_set_data(G_OBJECT(window), "libadwaitter-root-overlay",
                    root_overlay);

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  // Registers LibadwaitterPlugin and all native Linux bridges automatically.
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

static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_init(MyApplication* self) {}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
''';
