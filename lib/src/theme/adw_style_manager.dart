import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'adw_colors.dart';

/// System color scheme preference mirroring Libadwaita's `AdwColorScheme`.
enum AdwSystemColorScheme {
  /// Follow the system default (typically light, unless `prefer-dark` is set).
  defaultScheme,

  /// Prefer dark appearance (`prefer-dark`).
  preferDark,

  /// Prefer light appearance (`prefer-light`).
  preferLight,
}

/// Immutable snapshot of host desktop appearance settings.
class AdwSystemAppearance {
  final AdwSystemColorScheme colorScheme;
  final AdwAccentColor accentColor;
  final bool highContrast;

  const AdwSystemAppearance({
    this.colorScheme = AdwSystemColorScheme.defaultScheme,
    this.accentColor = AdwAccentColor.blue,
    this.highContrast = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdwSystemAppearance &&
          runtimeType == other.runtimeType &&
          colorScheme == other.colorScheme &&
          accentColor == other.accentColor &&
          highContrast == other.highContrast;

  @override
  int get hashCode => Object.hash(colorScheme, accentColor, highContrast);
}

/// Central appearance coordinator mirroring GNOME Libadwaita's `AdwStyleManager`.
///
/// Acts as the single source of truth for light/dark theme transitions and
/// system accent color changes, synchronizing live with the host desktop
/// environment (GNOME `org.gnome.desktop.interface` via `libadwaitter/settings`)
/// while allowing applications to override preferences centrally.
class AdwStyleManager extends ChangeNotifier {
  AdwStyleManager._();

  /// The global default [AdwStyleManager] instance (analogous to `adw_style_manager_get_default()`).
  static final AdwStyleManager instance = AdwStyleManager._();

  static const MethodChannel _channel = MethodChannel('libadwaitter/style');
  static bool _initialized = false;

  AdwSystemAppearance _systemAppearance = const AdwSystemAppearance();
  AdwSystemColorScheme? _colorSchemeOverride;
  AdwAccentColor? _accentColorOverride;
  bool _hasPlatformBridge = false;

  /// Current appearance reported by the host desktop environment.
  AdwSystemAppearance get systemAppearance => _systemAppearance;

  /// Active color scheme (override if set, otherwise host system preference).
  AdwSystemColorScheme get colorScheme =>
      _colorSchemeOverride ?? _systemAppearance.colorScheme;

  /// Active accent color (override if set, otherwise host system accent color).
  AdwAccentColor get accentColor =>
      _accentColorOverride ?? _systemAppearance.accentColor;

  /// Whether high-contrast mode is enabled on the host desktop.
  bool get highContrast => _systemAppearance.highContrast;

  /// Whether the resolved appearance is dark.
  bool get isDark {
    switch (colorScheme) {
      case AdwSystemColorScheme.preferDark:
        return true;
      case AdwSystemColorScheme.preferLight:
        return false;
      case AdwSystemColorScheme.defaultScheme:
        // In Libadwaita/GNOME, 'default' resolves to light unless dark is explicitly preferred.
        if (_hasPlatformBridge) {
          return false;
        }
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  /// Centrally overrides the application's color scheme (pass `null` to follow system).
  set colorScheme(AdwSystemColorScheme? value) {
    if (_colorSchemeOverride == value) return;
    _colorSchemeOverride = value;
    notifyListeners();
  }

  /// Centrally overrides the application's accent color (pass `null` to follow system).
  set accentColor(AdwAccentColor? value) {
    if (_accentColorOverride == value) return;
    _accentColorOverride = value;
    notifyListeners();
  }

  /// Initializes the platform bridge for live system theme & accent synchronization.
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb && Platform.isLinux) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onSystemAppearanceChanged') {
          final Map<dynamic, dynamic>? args =
              call.arguments as Map<dynamic, dynamic>?;
          if (args != null) {
            instance._updateFromMap(args);
          }
        }
      });
      instance._fetchInitialAppearance();
    }
  }

  void _fetchInitialAppearance() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getSystemAppearance');
      if (result != null) {
        _updateFromMap(result);
      }
    } catch (_) {
      // Gracefully retain platformBrightness / default accent if channel is unavailable
    }
  }

  /// Called by [AdwApplication] when platform brightness changes at the engine level.
  void handlePlatformBrightnessChanged() {
    if (_colorSchemeOverride == null) {
      notifyListeners();
    }
  }

  void _updateFromMap(Map<dynamic, dynamic> map) {
    final String? schemeStr = map['colorScheme'] as String?;
    final String? accentStr = map['accentColor'] as String?;
    final bool highContrast = map['highContrast'] as bool? ?? false;

    final next = AdwSystemAppearance(
      colorScheme: _parseColorScheme(schemeStr),
      accentColor: _parseAccentColor(accentStr),
      highContrast: highContrast,
    );

    final bool firstBridgeSync = !_hasPlatformBridge;
    _hasPlatformBridge = true;

    if (next != _systemAppearance || firstBridgeSync) {
      _systemAppearance = next;
      notifyListeners();
    }
  }

  static AdwSystemColorScheme _parseColorScheme(String? value) {
    switch (value) {
      case 'prefer-dark':
        return AdwSystemColorScheme.preferDark;
      case 'prefer-light':
        return AdwSystemColorScheme.preferLight;
      default:
        return AdwSystemColorScheme.defaultScheme;
    }
  }

  static AdwAccentColor _parseAccentColor(String? value) {
    switch (value) {
      case 'teal':
        return AdwAccentColor.teal;
      case 'green':
        return AdwAccentColor.green;
      case 'yellow':
        return AdwAccentColor.yellow;
      case 'orange':
        return AdwAccentColor.orange;
      case 'red':
        return AdwAccentColor.red;
      case 'pink':
        return AdwAccentColor.pink;
      case 'purple':
        return AdwAccentColor.purple;
      case 'slate':
        return AdwAccentColor.slate;
      case 'blue':
      default:
        return AdwAccentColor.blue;
    }
  }
}
