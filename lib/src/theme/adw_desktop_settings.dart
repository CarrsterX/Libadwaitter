import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Configuration descriptor for desktop animation characteristics and speed factors.
class AdwAnimationSettings {
  /// Whether animations are enabled globally by the host desktop environment.
  final bool enableAnimations;

  /// Global duration multiplier derived from the desktop environment (e.g. KDE AnimationDurationFactor).
  final double durationFactor;

  /// Name of the active desktop environment detected by the host runner (e.g. GNOME, KDE, XFCE).
  final String desktop;

  const AdwAnimationSettings({
    this.enableAnimations = true,
    this.durationFactor = 1.0,
    this.desktop = 'GNOME',
  });

  /// Resolves a requested baseline animation [duration] against desktop preferences:
  /// - Returns [Duration.zero] immediately if animations are disabled (Reduced Motion).
  /// - Applies [durationFactor] scaling when custom animation speed is configured.
  Duration resolve(Duration duration) {
    if (!enableAnimations) return Duration.zero;
    if (durationFactor == 1.0 || duration == Duration.zero) return duration;
    final int scaledMs = (duration.inMilliseconds * durationFactor).round();
    return Duration(milliseconds: scaledMs);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdwAnimationSettings &&
          runtimeType == other.runtimeType &&
          enableAnimations == other.enableAnimations &&
          durationFactor == other.durationFactor &&
          desktop == other.desktop;

  @override
  int get hashCode => Object.hash(enableAnimations, durationFactor, desktop);
}

/// Inherited scope propagating [AdwAnimationSettings] down the widget tree.
class AdwAnimationScope extends InheritedWidget {
  final AdwAnimationSettings settings;

  const AdwAnimationScope({
    super.key,
    required this.settings,
    required super.child,
  });

  static AdwAnimationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdwAnimationScope>();
  }

  static AdwAnimationScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
      scope != null,
      'No AdwAnimationScope found in context. Ensure your app is wrapped with AdwApplication.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AdwAnimationScope oldWidget) {
    return settings != oldWidget.settings;
  }
}

/// Parsed representation of the desktop shell's window decoration button layout
/// (`org.gnome.desktop.wm.preferences` `button-layout`, e.g. `:minimize,maximize,close` or `:close`).
class AdwWindowButtonLayout {
  final List<String> startButtons;
  final List<String> endButtons;

  const AdwWindowButtonLayout({
    this.startButtons = const <String>[],
    this.endButtons = const <String>['minimize', 'maximize', 'close'],
  });

  static const Set<String> _supportedTokens = {'minimize', 'maximize', 'close'};

  factory AdwWindowButtonLayout.parse(String raw) {
    final parts = raw.split(':');
    final leftRaw = parts.isNotEmpty ? parts[0] : '';
    final rightRaw = parts.length > 1 ? parts[1] : '';

    List<String> parseSide(String side) {
      return side
          .split(',')
          .map((t) => t.trim())
          .where((t) => _supportedTokens.contains(t))
          .toList(growable: false);
    }

    return AdwWindowButtonLayout(
      startButtons: parseSide(leftRaw),
      endButtons: parseSide(rightRaw),
    );
  }

  bool get hasMinimize =>
      startButtons.contains('minimize') || endButtons.contains('minimize');
  bool get hasMaximize =>
      startButtons.contains('maximize') || endButtons.contains('maximize');
  bool get hasClose =>
      startButtons.contains('close') || endButtons.contains('close');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AdwWindowButtonLayout) return false;
    if (startButtons.length != other.startButtons.length ||
        endButtons.length != other.endButtons.length) {
      return false;
    }
    for (int i = 0; i < startButtons.length; i++) {
      if (startButtons[i] != other.startButtons[i]) return false;
    }
    for (int i = 0; i < endButtons.length; i++) {
      if (endButtons[i] != other.endButtons[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(startButtons), Object.hashAll(endButtons));
}

/// Native desktop integration service querying host settings (GNOME, Qt/KDE, XFCE).
class AdwDesktopSettings {
  static const MethodChannel _channel = MethodChannel('libadwaitter/settings');
  static final ValueNotifier<AdwAnimationSettings> animationSettings =
      ValueNotifier(const AdwAnimationSettings());
  static final ValueNotifier<AdwWindowButtonLayout> windowButtonLayout =
      ValueNotifier(const AdwWindowButtonLayout());

  static bool _initialized = false;

  /// Initializes platform channel bindings for desktop animation and shell button preferences.
  static void initialize() {
    if (_initialized || kIsWeb || !Platform.isLinux) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAnimationSettingsChanged') {
        final Map<dynamic, dynamic>? args =
            call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          _updateFromMap(args);
        }
      } else if (call.method == 'onWindowButtonLayoutChanged') {
        final String? layout = call.arguments as String?;
        if (layout != null) {
          windowButtonLayout.value = AdwWindowButtonLayout.parse(layout);
        }
      }
    });

    _fetchInitialSettings();
  }

  static void _fetchInitialSettings() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getAnimationSettings');
      if (result != null) {
        _updateFromMap(result);
      }
    } catch (_) {
      // Gracefully retain GNOME standard defaults if channel is unavailable
    }

    try {
      final String? layout =
          await _channel.invokeMethod<String>('getWindowButtonLayout');
      if (layout != null) {
        windowButtonLayout.value = AdwWindowButtonLayout.parse(layout);
      }
    } catch (_) {
      // Gracefully retain default button layout if channel is unavailable
    }
  }

  static void _updateFromMap(Map<dynamic, dynamic> map) {
    final bool enabled = map['enableAnimations'] as bool? ?? true;
    final num? factorNum = map['durationFactor'] as num?;
    final double factor =
        (factorNum != null ? factorNum.toDouble() : 1.0).clamp(0.0, 5.0);
    final String desktop = map['desktop'] as String? ?? 'GNOME';

    animationSettings.value = AdwAnimationSettings(
      enableAnimations: enabled,
      durationFactor: factor,
      desktop: desktop,
    );
  }
}

