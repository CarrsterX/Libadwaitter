import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'web/adw_portal_web_stub.dart'
    if (dart.library.js_interop) 'web/adw_portal_web.dart' as web_portal;

/// Outcome status of an XDG Desktop Portal or native desktop integration call.
///
/// {@category Desktop Portals}
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
///
/// {@category Desktop Portals}
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
///
/// {@category Desktop Portals}
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

/// Result returned by [AdwPortal.runCommand] and [AdwPortal.runElevated] on Linux.
///
/// {@category Desktop Portals}
class AdwCommandResult {
  /// Creates a command execution result.
  const AdwCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// Process exit code (`0` indicates success).
  final int exitCode;

  /// Captured standard output text.
  final String stdout;

  /// Captured standard error text.
  final String stderr;

  /// Whether the command terminated with exit code `0`.
  bool get isSuccess => exitCode == 0;
}

/// Alias kept for backwards compatibility with [AdwPortal.runElevated].
typedef AdwElevatedCommandResult = AdwCommandResult;

/// Priority levels for [AdwPortal.sendNotification].
///
/// {@category Desktop Portals}
enum AdwNotificationPriority {
  /// Low-priority silent notification.
  low,

  /// Standard default notification priority.
  normal,

  /// High-priority notification.
  high,

  /// Urgent notification requiring immediate attention.
  urgent,
}

/// Action button attached to a system notification sent via [AdwPortal.sendNotification].
///
/// {@category Desktop Portals}
class AdwNotificationAction {
  /// Creates a notification action button descriptor.
  const AdwNotificationAction({
    required this.id,
    required this.label,
  });

  /// Identifier returned in [AdwNotificationEvent.actionId] when clicked.
  final String id;

  /// Human-readable button label displayed in the system notification.
  final String label;

  /// Serializes this action to a platform-channel map.
  Map<String, String> toMap() => {'id': id, 'label': label};
}

/// Event emitted on [AdwPortal.notificationEvents] when the user taps a
/// notification or clicks one of its [AdwNotificationAction] buttons.
///
/// {@category Desktop Portals}
class AdwNotificationEvent {
  /// Creates a notification interaction event.
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
/// ```dart
/// final info = await AdwPortal.getSandboxInfo();
/// if (info.isLinux) {
///   await AdwPortal.sendNotification(
///     id: 'sync-done',
///     title: 'Sync Complete',
///     body: 'All files are up to date.',
///   );
/// }
/// ```
///
/// {@category Desktop Portals}
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

  static AdwPortalResult<T> _parseWebResult<T>(Map<String, dynamic> raw) {
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
          message ?? 'Unexpected web portal response.',
        );
    }
  }

  /// Opens a URI (web URL, `mailto:`, etc.) via `org.freedesktop.portal.OpenURI`
  /// on Linux, `Intent.ACTION_VIEW` on Android, or `window.open` on Web.
  static Future<AdwPortalResult<void>> openUri(String uri) async {
    if (kIsWeb) {
      return _parseWebResult<void>(await web_portal.webOpenUri(uri));
    }
    return _invokePortal<void>('openUri', {'uri': uri}, true);
  }

  /// Shares [text] and/or local [filePaths] with other applications.
  ///
  /// - **Android:** Opens the native Android Share Sheet (`Intent.createChooser`
  ///   with `ACTION_SEND` / `ACTION_SEND_MULTIPLE`).
  /// - **Linux:** Opens the native "Open With..." chooser for files via
  ///   `org.freedesktop.portal.OpenURI` (or copies plain text to the clipboard).
  /// - **Web:** Uses `navigator.share` with clipboard fallback.
  static Future<AdwPortalResult<void>> share({
    String? text,
    String? subject,
    List<String> filePaths = const [],
    String? title,
  }) async {
    if (kIsWeb) {
      return _parseWebResult<void>(
        await web_portal.webShare(
          title: title ?? subject,
          text: text,
        ),
      );
    }
    return _invokePortal<void>(
      'share',
      {
        if (text != null) 'text': text,
        if (subject != null) 'subject': subject,
        if (filePaths.isNotEmpty) 'filePaths': filePaths,
        if (title != null) 'title': title,
      },
      true,
    );
  }

  /// Requests permission to post system notifications.
  ///
  /// On Android 13+ (API 33+) this prompts for `POST_NOTIFICATIONS` if not yet
  /// granted. On Web this calls `Notification.requestPermission()`.
  /// On Linux and older Android versions it returns granted immediately.
  static Future<AdwPortalResult<bool>> requestNotificationPermission() async {
    if (kIsWeb) {
      final result = _parseWebResult<bool>(
        await web_portal.webRequestNotificationPermission(),
      );
      return AdwPortalResult<bool>(
        status: result.status,
        value: result.value ?? result.isGranted,
        errorMessage: result.errorMessage,
      );
    }
    if (_isLinux) {
      return const AdwPortalResult.granted(true);
    }
    if (!_isAndroid) {
      return const AdwPortalResult.unsupported(
        'System notifications are only supported on Linux, Android, and Web.',
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
  /// `org.freedesktop.portal.Notification` on Linux, `NotificationManager` on
  /// Android, or the Web Notifications API on Web.
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
    if (kIsWeb) {
      return _parseWebResult<void>(
        await web_portal.webSendNotification(
          id: id,
          title: title,
          body: body,
          onEvent: (notifId, actionId, isClosed) {
            if (isClosed) return;
            _notificationController.add(
              AdwNotificationEvent(
                notificationId: notifId,
                actionId: actionId.isEmpty ? null : actionId,
                payload: payload,
              ),
            );
          },
        ),
      );
    }
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
    if (kIsWeb) {
      return _parseWebResult<void>(
        await web_portal.webWithdrawNotification(id),
      );
    }
    return _invokePortal<void>('withdrawNotification', {'id': id}, true);
  }

  /// Opens the native Linux GTK Emoji Chooser popover anchored at optional
  /// window coordinates [x], [y] and returns the selected emoji string.
  ///
  /// On Android, emojis are entered natively via the system virtual keyboard,
  /// so this returns [AdwPortalStatus.unsupported].
  static Future<AdwPortalResult<String?>> pickEmoji({
    double? x,
    double? y,
  }) async {
    return _invokePortal<String?>('pickEmoji', {
      if (x != null) 'x': x,
      if (y != null) 'y': y,
    });
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

  /// Requests administrator authorization on Linux via Polkit
  /// (`org.freedesktop.PolicyKit1.Authority.CheckAuthorization`), displaying
  /// the native desktop authentication dialog when [allowUserInteraction] is
  /// `true`.
  ///
  /// Returns [AdwPortalStatus.unsupported] on non-Linux platforms.
  static Future<AdwPortalResult<bool>> requestAdminAuthorization({
    String actionId = 'org.freedesktop.policykit.exec',
    bool allowUserInteraction = true,
  }) async {
    final result = await _invokePortal<bool>('requestAdminAuthorization', {
      'actionId': actionId,
      'allowUserInteraction': allowUserInteraction,
    });
    return AdwPortalResult<bool>(
      status: result.status,
      value: result.value ?? result.isGranted,
      errorMessage: result.errorMessage,
    );
  }

  /// Executes [executable] with [arguments] using Linux Polkit elevation
  /// (`pkexec`), showing the native system administrator prompt and returning
  /// the command's exit code and output.
  ///
  /// Returns [AdwPortalStatus.cancelled] if the user dismisses the prompt, or
  /// [AdwPortalStatus.unsupported] on non-Linux platforms.
  static Future<AdwPortalResult<AdwElevatedCommandResult>> runElevated(
    String executable, {
    List<String> arguments = const [],
  }) async {
    final result = await _invokePortal<Map<dynamic, dynamic>>('runElevated', {
      'executable': executable,
      'arguments': arguments,
    });
    if (!result.isGranted || result.value == null) {
      return AdwPortalResult<AdwElevatedCommandResult>(
        status: result.status,
        errorMessage: result.errorMessage,
      );
    }
    final map = result.value!;
    return AdwPortalResult<AdwElevatedCommandResult>.granted(
      AdwElevatedCommandResult(
        exitCode: (map['exitCode'] as num?)?.toInt() ?? -1,
        stdout: map['stdout'] as String? ?? '',
        stderr: map['stderr'] as String? ?? '',
      ),
    );
  }

  /// Executes [executable] with [arguments] as the current unprivileged user
  /// on Linux via the native runner (`GSubprocess`).
  ///
  /// When [detached] is `true`, the process is launched without waiting for it
  /// to exit (useful for launching desktop/GUI applications).
  ///
  /// Returns [AdwPortalStatus.unsupported] on non-Linux platforms.
  static Future<AdwPortalResult<AdwCommandResult>> runCommand(
    String executable, {
    List<String> arguments = const [],
    String? workingDirectory,
    bool detached = false,
  }) async {
    final result = await _invokePortal<Map<dynamic, dynamic>>('runCommand', {
      'executable': executable,
      'arguments': arguments,
      if (workingDirectory != null && workingDirectory.isNotEmpty)
        'workingDirectory': workingDirectory,
      'detached': detached,
    });
    if (!result.isGranted || result.value == null) {
      return AdwPortalResult<AdwCommandResult>(
        status: result.status,
        errorMessage: result.errorMessage,
      );
    }
    final map = result.value!;
    return AdwPortalResult<AdwCommandResult>.granted(
      AdwCommandResult(
        exitCode: (map['exitCode'] as num?)?.toInt() ?? -1,
        stdout: map['stdout'] as String? ?? '',
        stderr: map['stderr'] as String? ?? '',
      ),
    );
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

