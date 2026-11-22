import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Outcome status of an XDG Desktop Portal or native desktop integration call.
enum AdwPortalStatus {
  /// The user granted permission or the portal action completed successfully.
  granted,

  /// The user explicitly denied permission in the system prompt.
  denied,

  /// The user dismissed or cancelled the system dialog.
  cancelled,

  /// The current platform or environment does not support this portal.
  unsupported,

  /// An unexpected native or D-Bus error occurred.
  error,
}

/// Result returned by [AdwPortal] calls.
///
/// Designed to degrade gracefully on non-Linux platforms (Android, iOS, macOS,
/// Windows, Web) where [status] will be [AdwPortalStatus.unsupported].
class AdwPortalResult<T> {
  const AdwPortalResult({
    required this.status,
    this.value,
    this.errorMessage,
  });

  const AdwPortalResult.granted([T? value])
      : this(status: AdwPortalStatus.granted, value: value);

  const AdwPortalResult.denied([String? message])
      : this(status: AdwPortalStatus.denied, errorMessage: message);

  const AdwPortalResult.cancelled()
      : this(status: AdwPortalStatus.cancelled);

  const AdwPortalResult.unsupported([String? message])
      : this(status: AdwPortalStatus.unsupported, errorMessage: message);

  const AdwPortalResult.error(String message)
      : this(status: AdwPortalStatus.error, errorMessage: message);

  final AdwPortalStatus status;
  final T? value;
  final String? errorMessage;

  bool get isGranted => status == AdwPortalStatus.granted;
  bool get isDenied => status == AdwPortalStatus.denied;
  bool get isCancelled => status == AdwPortalStatus.cancelled;
  bool get isUnsupported => status == AdwPortalStatus.unsupported;
  bool get isError => status == AdwPortalStatus.error;
}

/// Information about the active Linux runtime and sandbox environment.
class AdwSandboxInfo {
  const AdwSandboxInfo({
    required this.isLinux,
    required this.isFlatpak,
    required this.isSnap,
    required this.isWayland,
    this.flatpakId,
    this.snapName,
  });

  const AdwSandboxInfo.nonLinux()
      : isLinux = false,
        isFlatpak = false,
        isSnap = false,
        isWayland = false,
        flatpakId = null,
        snapName = null;

  final bool isLinux;
  final bool isFlatpak;
  final bool isSnap;
  final bool isWayland;
  final String? flatpakId;
  final String? snapName;

  bool get isSandboxed => isFlatpak || isSnap;
  bool get isNativeSystem => isLinux && !isSandboxed;
}

/// Priority levels for [AdwPortal.sendNotification].
enum AdwNotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Action button attached to a system notification sent via [AdwPortal.sendNotification].
class AdwNotificationAction {
  const AdwNotificationAction({
    required this.id,
    required this.label,
  });

  /// Identifier returned in [AdwNotificationEvent.actionId] when clicked.
  final String id;

  /// Human-readable button label displayed in the system notification.
  final String label;

  Map<String, String> toMap() => {'id': id, 'label': label};
}

/// Event emitted on [AdwPortal.notificationEvents] when the user taps a
/// notification or clicks one of its [AdwNotificationAction] buttons.
class AdwNotificationEvent {
  const AdwNotificationEvent({
    required this.notificationId,
    this.actionId,
    this.payload,
  });

  /// The `id` originally passed to [AdwPortal.sendNotification].
  final String notificationId;

  /// The clicked [AdwNotificationAction.id], or `null` when the user tapped
  /// the notification body itself (default action).
  final String? actionId;

  /// Optional custom string payload passed to [AdwPortal.sendNotification].
  final String? payload;

  /// Whether this event was triggered by tapping the notification body rather
  /// than an explicit action button.
  bool get isDefaultAction => actionId == null || actionId!.isEmpty;
}

/// Optional Linux desktop & Wayland portal bridge (`libadwaitter/portal`).
///
/// This bridge is strictly decoupled from Libadwaitter's UI widgets: apps
/// targeting Android, iOS, or other platforms can use the full UI library
/// without depending on Linux portals, and calls to [AdwPortal] safely return
/// [AdwPortalStatus.unsupported] when not running on Linux.
class AdwPortal {
  AdwPortal._();

  static const MethodChannel _defaultChannel =
      MethodChannel('libadwaitter/portal');

  static MethodChannel _channel = _defaultChannel;
  static bool _handlerRegistered = false;
  static final StreamController<AdwNotificationEvent> _notificationController =
      StreamController<AdwNotificationEvent>.broadcast();

  /// Stream of system notification clicks and action button activations.
  ///
  /// Works on Linux (`GNotification` / `org.freedesktop.portal.Notification`)
  /// and Android (`NotificationManager`).
  static Stream<AdwNotificationEvent> get notificationEvents {
    _ensureHandlerRegistered();
    return _notificationController.stream;
  }

  static void _ensureHandlerRegistered() {
    if (_handlerRegistered) return;
    _handlerRegistered = true;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onNotificationAction') {
      final args = call.arguments;
      if (args is Map) {
        final notifId = args['id'] as String? ?? 'default';
        final rawAction = args['actionId'] as String?;
        final actionId =
            (rawAction == null || rawAction.isEmpty) ? null : rawAction;
        final rawPayload = args['payload'] as String?;
        final payload =
            (rawPayload == null || rawPayload.isEmpty) ? null : rawPayload;
        _notificationController.add(
          AdwNotificationEvent(
            notificationId: notifId,
            actionId: actionId,
            payload: payload,
          ),
        );
      }
    }
  }

  /// Allows overriding the underlying [MethodChannel] in tests.
  @visibleForTesting
  static void setChannelForTesting(MethodChannel channel) {
    _channel = channel;
    _handlerRegistered = false;
  }

  /// Restores the default [MethodChannel] after tests.
  @visibleForTesting
  static void resetChannelForTesting() {
    _channel = _defaultChannel;
    _handlerRegistered = false;
  }

  static bool get _isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Inspects whether the app is running natively on Linux, inside Flatpak,
  /// or inside Snap, and whether Wayland is active.
  static Future<AdwSandboxInfo> getSandboxInfo() async {
    if (!_isLinux) {
      return const AdwSandboxInfo.nonLinux();
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getSandboxInfo',
      );
      if (result == null) {
        return const AdwSandboxInfo(
          isLinux: true,
          isFlatpak: false,
          isSnap: false,
          isWayland: false,
        );
      }
      return AdwSandboxInfo(
        isLinux: true,
        isFlatpak: result['isFlatpak'] == true,
        isSnap: result['isSnap'] == true,
        isWayland: result['isWayland'] == true,
        flatpakId: result['flatpakId'] as String?,
        snapName: result['snapName'] as String?,
      );
    } on MissingPluginException {
      return const AdwSandboxInfo(
        isLinux: true,
        isFlatpak: false,
        isSnap: false,
        isWayland: false,
      );
    } on PlatformException {
      return const AdwSandboxInfo(
        isLinux: true,
        isFlatpak: false,
        isSnap: false,
        isWayland: false,
      );
    }
  }

  /// Opens a URI (web URL, `mailto:`, etc.) via `org.freedesktop.portal.OpenURI`
  /// on Linux or `Intent.ACTION_VIEW` on Android.
  static Future<AdwPortalResult<void>> openUri(String uri) async {
    return _invokePortal<void>('openUri', {'uri': uri}, true);
  }

  /// Requests permission to post system notifications.
  ///
  /// On Android 13+ (API 33+) this prompts for `POST_NOTIFICATIONS` if not yet
  /// granted. On Linux and older Android versions it returns granted immediately.
  static Future<AdwPortalResult<bool>> requestNotificationPermission() async {
    if (_isLinux) {
      return const AdwPortalResult.granted(true);
    }
    if (!_isAndroid) {
      return const AdwPortalResult.unsupported(
        'System notifications are only supported on Linux and Android.',
      );
    }
    final result = await _invokePortal<bool>(
      'requestNotificationPermission',
      null,
      true,
    );
    return AdwPortalResult<bool>(
      status: result.status,
      value: result.value ?? result.isGranted,
      errorMessage: result.errorMessage,
    );
  }

  /// Sends a system notification via `GNotification` /
  /// `org.freedesktop.portal.Notification` on Linux or `NotificationManager` on
  /// Android.
  ///
  /// Taps on the notification body or any [actions] button are delivered on
  /// [notificationEvents].
  static Future<AdwPortalResult<void>> sendNotification({
    required String id,
    required String title,
    String? body,
    String? iconName,
    AdwNotificationPriority priority = AdwNotificationPriority.normal,
    List<AdwNotificationAction> actions = const [],
    String? payload,
    String? category,
  }) async {
    _ensureHandlerRegistered();
    return _invokePortal<void>(
      'sendNotification',
      {
        'id': id,
        'title': title,
        if (body != null) 'body': body,
        if (iconName != null) 'iconName': iconName,
        'priority': priority.name,
        if (actions.isNotEmpty)
          'actions': actions.map((a) => a.toMap()).toList(growable: false),
        if (payload != null) 'payload': payload,
        if (category != null) 'category': category,
      },
      true,
    );
  }

  /// Withdraws a previously sent notification by [id].
  static Future<AdwPortalResult<void>> withdrawNotification(String id) async {
    return _invokePortal<void>('withdrawNotification', {'id': id}, true);
  }

  /// Opens the native system file chooser (portal-backed in Flatpak/Snap)
  /// to select one or more files or a directory without broad filesystem access.
  static Future<AdwPortalResult<List<String>>> openFiles({
    String? title,
    bool multiple = false,
    bool directory = false,
  }) async {
    final result = await _invokePortal<List<dynamic>>('openFiles', {
      if (title != null) 'title': title,
      'multiple': multiple,
      'directory': directory,
    });
    if (!result.isGranted) {
      return AdwPortalResult<List<String>>(
        status: result.status,
        errorMessage: result.errorMessage,
      );
    }
    final paths =
        result.value?.whereType<String>().toList(growable: false) ?? const [];
    return AdwPortalResult.granted(paths);
  }

  /// Opens the native system save file dialog (portal-backed in Flatpak/Snap).
  static Future<AdwPortalResult<String?>> saveFile({
    String? title,
    String? currentName,
  }) async {
    return _invokePortal<String?>('saveFile', {
      if (title != null) 'title': title,
      if (currentName != null) 'currentName': currentName,
    });
  }

  /// Requests permission to run in the background and optionally autostart on
  /// login via `org.freedesktop.portal.Background`.
  static Future<AdwPortalResult<bool>> requestBackground({
    String? reason,
    bool autostart = false,
  }) async {
    final result = await _invokePortal<bool>('requestBackground', {
      if (reason != null) 'reason': reason,
      'autostart': autostart,
    });
    return AdwPortalResult<bool>(
      status: result.status,
      value: result.value ?? result.isGranted,
      errorMessage: result.errorMessage,
    );
  }

  /// Requests camera permission via `org.freedesktop.portal.Camera`.
  static Future<AdwPortalResult<bool>> requestCamera() async {
    final result = await _invokePortal<bool>('requestCamera');
    return AdwPortalResult<bool>(
      status: result.status,
      value: result.value ?? result.isGranted,
      errorMessage: result.errorMessage,
    );
  }

  /// Captures a screenshot through the system confirmation dialog via
  /// `org.freedesktop.portal.Screenshot`, returning the resulting URI if granted.
  static Future<AdwPortalResult<String?>> takeScreenshot({
    bool interactive = true,
  }) async {
    return _invokePortal<String?>('takeScreenshot', {
      'interactive': interactive,
    });
  }

  /// Inhibits idle, suspend, or logout via `org.freedesktop.portal.Inhibit`.
  ///
  /// Returns an opaque handle string that should later be passed to [uninhibit].
  static Future<AdwPortalResult<String?>> inhibit({
    required String reason,
    bool idle = true,
    bool suspend = false,
    bool logout = false,
  }) async {
    return _invokePortal<String?>('inhibit', {
      'reason': reason,
      'idle': idle,
      'suspend': suspend,
      'logout': logout,
    });
  }

  /// Releases a previously acquired [inhibit] handle.
  static Future<AdwPortalResult<void>> uninhibit(String handle) async {
    return _invokePortal<void>('uninhibit', {'handle': handle});
  }

  static Future<AdwPortalResult<T>> _invokePortal<T>(
    String method, [
    Map<String, dynamic>? arguments,
    bool allowAndroid = false,
  ]) async {
    if (!_isLinux && !(allowAndroid && _isAndroid)) {
      return const AdwPortalResult.unsupported(
        'AdwPortal is not supported on this platform.',
      );
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>(method, arguments);
      if (raw is Map) {
        final statusName = raw['status'] as String?;
        final message = raw['errorMessage'] as String?;
        final value = raw['value'] as T?;
        switch (statusName) {
          case 'granted':
            return AdwPortalResult<T>.granted(value);
          case 'denied':
            return AdwPortalResult<T>.denied(message);
          case 'cancelled':
            return AdwPortalResult<T>.cancelled();
          case 'unsupported':
            return AdwPortalResult<T>.unsupported(message);
          default:
            return AdwPortalResult<T>.error(
              message ?? 'Unknown portal response status.',
            );
        }
      }
      return AdwPortalResult<T>.granted(raw as T?);
    } on MissingPluginException {
      return const AdwPortalResult.unsupported(
        'libadwaitter/portal channel is not registered in the Linux runner.',
      );
    } on PlatformException catch (e) {
      return AdwPortalResult<T>.error(e.message ?? e.code);
    }
  }
}

