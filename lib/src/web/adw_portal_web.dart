import 'dart:js_interop';
import 'dart:js_interop_unsafe';

typedef WebNotificationCallback = void Function(
  String id,
  String actionId,
  bool isClosed,
);

final Map<String, JSObject> _activeNotifications = <String, JSObject>{};

@JS('window')
external JSObject get _window;

@JS('navigator')
external JSObject get _navigator;

JSFunction? get _notificationCtor {
  if (!_window.has('Notification')) return null;
  final raw = _window['Notification'];
  if (raw.isUndefinedOrNull) return null;
  return raw as JSFunction;
}

Future<Map<String, dynamic>> webOpenUri(String uri) async {
  try {
    _window.callMethod<JSAny?>(
      'open'.toJS,
      uri.toJS,
      '_blank'.toJS,
      'noopener,noreferrer'.toJS,
    );
    return const {'status': 'granted'};
  } catch (e) {
    return {'status': 'error', 'errorMessage': e.toString()};
  }
}

Future<Map<String, dynamic>> webShare({
  String? title,
  String? text,
  String? url,
}) async {
  try {
    if (_navigator.has('share')) {
      final data = JSObject();
      if (title != null && title.isNotEmpty) data['title'] = title.toJS;
      if (text != null && text.isNotEmpty) data['text'] = text.toJS;
      if (url != null && url.isNotEmpty) data['url'] = url.toJS;
      final promise = _navigator.callMethod<JSPromise<JSAny?>>(
        'share'.toJS,
        data,
      );
      await promise.toDart;
      return const {'status': 'granted'};
    }
    final fallback = text ?? url ?? title ?? '';
    if (fallback.isNotEmpty && _navigator.has('clipboard')) {
      final clipboard = _navigator['clipboard'] as JSObject?;
      if (clipboard != null && clipboard.has('writeText')) {
        final promise = clipboard.callMethod<JSPromise<JSAny?>>(
          'writeText'.toJS,
          fallback.toJS,
        );
        await promise.toDart;
        return const {'status': 'granted'};
      }
    }
    return const {
      'status': 'unsupported',
      'errorMessage': 'Web Share and Clipboard APIs are unavailable.',
    };
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('AbortError')) {
      return const {'status': 'cancelled'};
    }
    return {'status': 'error', 'errorMessage': msg};
  }
}

Future<Map<String, dynamic>> webRequestNotificationPermission() async {
  final ctor = _notificationCtor;
  if (ctor == null) {
    return const {
      'status': 'unsupported',
      'errorMessage': 'Web Notifications API is not available in this browser.',
    };
  }
  try {
    final current = (ctor['permission'] as JSString?)?.toDart;
    if (current == 'granted') {
      return const {'status': 'granted', 'value': true};
    }
    final promise = ctor.callMethod<JSPromise<JSString>>(
      'requestPermission'.toJS,
    );
    final result = (await promise.toDart).toDart;
    if (result == 'granted') {
      return const {'status': 'granted', 'value': true};
    } else if (result == 'denied') {
      return const {
        'status': 'denied',
        'value': false,
        'errorMessage': 'Notification permission denied by user.',
      };
    }
    return const {'status': 'cancelled', 'value': false};
  } catch (e) {
    return {'status': 'error', 'errorMessage': e.toString()};
  }
}

Future<Map<String, dynamic>> webSendNotification({
  required String id,
  required String title,
  String? body,
  required WebNotificationCallback onEvent,
}) async {
  final ctor = _notificationCtor;
  if (ctor == null) {
    return const {
      'status': 'unsupported',
      'errorMessage': 'Web Notifications API is not available in this browser.',
    };
  }
  try {
    var permission = (ctor['permission'] as JSString?)?.toDart;
    if (permission == 'default') {
      final promise = ctor.callMethod<JSPromise<JSString>>(
        'requestPermission'.toJS,
      );
      permission = (await promise.toDart).toDart;
    }
    if (permission != 'granted') {
      return const {
        'status': 'denied',
        'errorMessage': 'Notification permission not granted.',
      };
    }

    final options = JSObject();
    if (body != null && body.isNotEmpty) {
      options['body'] = body.toJS;
    }
    options['tag'] = id.toJS;

    final notif = ctor.callAsConstructor<JSObject>(title.toJS, options);
    _activeNotifications[id] = notif;

    notif['onclick'] = (() {
      try {
        _window.callMethod<JSAny?>('focus'.toJS);
      } catch (_) {}
      onEvent(id, 'default', false);
    }).toJS;

    notif['onclose'] = (() {
      _activeNotifications.remove(id);
      onEvent(id, '', true);
    }).toJS;

    return const {'status': 'granted'};
  } catch (e) {
    return {'status': 'error', 'errorMessage': e.toString()};
  }
}

Future<Map<String, dynamic>> webWithdrawNotification(String id) async {
  final notif = _activeNotifications.remove(id);
  if (notif != null) {
    try {
      notif.callMethod<JSAny?>('close'.toJS);
    } catch (_) {}
  }
  return const {'status': 'granted'};
}
