import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Menu item displayed in the Linux StatusNotifierItem / AppIndicator tray menu.
class AdwTrayMenuItem {
  const AdwTrayMenuItem({
    required this.id,
    required this.label,
    this.enabled = true,
  }) : isSeparator = false;

  const AdwTrayMenuItem.separator()
      : id = '',
        label = '',
        enabled = false,
        isSeparator = true;

  final String id;
  final String label;
  final bool enabled;
  final bool isSeparator;

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'enabled': enabled,
        'isSeparator': isSeparator,
      };
}

/// Event types emitted by [AdwSystemTray.events].
enum AdwTrayEventType {
  /// Primary click on the system tray icon.
  activate,

  /// A context menu item was clicked ([AdwTrayEvent.itemId] identifies it).
  menuItemClicked,

  /// The main window was hidden to background instead of closing.
  windowHiddenToTray,

  /// The main window was restored from background.
  windowRestored,
}

/// Event received from the Linux system tray bridge.
class AdwTrayEvent {
  const AdwTrayEvent({
    required this.type,
    this.itemId,
  });

  final AdwTrayEventType type;
  final String? itemId;
}

/// Linux StatusNotifierItem / AppIndicator system tray & background-mode bridge
/// (`libadwaitter/tray`).
///
/// Uses pure GLib `GDBus` (`org.kde.StatusNotifierItem` + `com.canonical.dbusmenu`)
/// with zero external library dependencies. On non-Linux platforms (such as
/// Android), [isAvailable] safely returns `false` and other calls are no-ops.
class AdwSystemTray {
  AdwSystemTray._();

  static const MethodChannel _defaultChannel =
      MethodChannel('libadwaitter/tray');

  static MethodChannel _channel = _defaultChannel;
  static bool _handlerRegistered = false;
  static final StreamController<AdwTrayEvent> _eventController =
      StreamController<AdwTrayEvent>.broadcast();

  static bool get _isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// Broadcast stream of system tray interactions and background-mode transitions.
  static Stream<AdwTrayEvent> get events {
    _ensureHandlerRegistered();
    return _eventController.stream;
  }

  static void _ensureHandlerRegistered() {
    if (_handlerRegistered) return;
    _handlerRegistered = true;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onTrayEvent') return;
    final args = call.arguments;
    if (args is! Map) return;
    final eventName = args['event'] as String?;
    final type = switch (eventName) {
      'activate' => AdwTrayEventType.activate,
      'menuItemClicked' => AdwTrayEventType.menuItemClicked,
      'windowHiddenToTray' => AdwTrayEventType.windowHiddenToTray,
      'windowRestored' => AdwTrayEventType.windowRestored,
      _ => null,
    };
    if (type == null) return;
    final itemId = args['itemId'] as String?;
    _eventController.add(
      AdwTrayEvent(
        type: type,
        itemId: (itemId != null && itemId.isNotEmpty) ? itemId : null,
      ),
    );
  }

  /// Returns `true` when running on Linux and a StatusNotifier host (e.g.
  /// GNOME AppIndicator extension, KDE Plasma, Waybar, XFCE) is active on D-Bus.
  static Future<bool> isAvailable() async {
    if (!_isLinux) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Registers and displays the interactive system tray icon with optional
  /// context [menuItems].
  static Future<bool> show({
    required String title,
    String? tooltip,
    String? iconName,
    List<AdwTrayMenuItem> menuItems = const [],
  }) async {
    if (!_isLinux) return false;
    _ensureHandlerRegistered();
    try {
      final result = await _channel.invokeMethod<bool>('show', {
        'title': title,
        if (tooltip != null) 'tooltip': tooltip,
        if (iconName != null) 'iconName': iconName,
        'menuItems': menuItems.map((m) => m.toMap()).toList(growable: false),
      });
      return result == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Updates the tray icon's context menu items live.
  static Future<void> updateMenu(List<AdwTrayMenuItem> menuItems) async {
    if (!_isLinux) return;
    try {
      await _channel.invokeMethod<void>('updateMenu', {
        'menuItems': menuItems.map((m) => m.toMap()).toList(growable: false),
      });
    } on MissingPluginException {
      // Runner does not register libadwaitter/tray.
    }
  }

  /// When enabled, closing the main window hides it to the background instead
  /// of terminating the process.
  static Future<void> setHideOnClose(bool enabled) async {
    if (!_isLinux) return;
    _ensureHandlerRegistered();
    try {
      await _channel.invokeMethod<void>('setHideOnClose', {
        'enabled': enabled,
      });
    } on MissingPluginException {
      // Runner does not register libadwaitter/tray.
    }
  }

  /// Hides the main window to background (e.g. minimize to tray).
  static Future<void> hideWindow() async {
    if (!_isLinux) return;
    try {
      await _channel.invokeMethod<void>('hideWindow');
    } on MissingPluginException {
      // Runner does not register libadwaitter/tray.
    }
  }

  /// Restores and presents the main window from background.
  static Future<void> showWindow() async {
    if (!_isLinux) return;
    try {
      await _channel.invokeMethod<void>('showWindow');
    } on MissingPluginException {
      // Runner does not register libadwaitter/tray.
    }
  }

  /// Unregisters the system tray icon and disables hide-on-close.
  static Future<void> hide() async {
    if (!_isLinux) return;
    try {
      await _channel.invokeMethod<void>('hide');
    } on MissingPluginException {
      // Runner does not register libadwaitter/tray.
    }
  }

  @visibleForTesting
  static void setChannelForTesting(MethodChannel channel) {
    _channel = channel;
    _handlerRegistered = false;
  }

  @visibleForTesting
  static void resetChannelForTesting() {
    _channel = _defaultChannel;
    _handlerRegistered = false;
  }
}
