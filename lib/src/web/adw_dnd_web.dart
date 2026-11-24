import 'dart:js_interop';
import 'dart:js_interop_unsafe';

typedef WebDropCallback = void Function({
  required String type,
  required double x,
  required double y,
  List<String> files,
  String? text,
});

@JS('window')
external JSObject get _window;

bool _registered = false;

void webDndRegister(WebDropCallback onEvent) {
  if (_registered) return;
  _registered = true;

  _window.callMethod<JSAny?>(
    'addEventListener'.toJS,
    'dragover'.toJS,
    ((JSObject event) {
      event.callMethod<JSAny?>('preventDefault'.toJS);
      final x = (event['clientX'] as JSNumber?)?.toDartDouble ?? 0.0;
      final y = (event['clientY'] as JSNumber?)?.toDartDouble ?? 0.0;
      onEvent(type: 'update', x: x, y: y);
    }).toJS,
  );

  _window.callMethod<JSAny?>(
    'addEventListener'.toJS,
    'dragleave'.toJS,
    ((JSObject event) {
      final related = event['relatedTarget'];
      if (related.isUndefinedOrNull) {
        onEvent(type: 'leave', x: 0.0, y: 0.0);
      }
    }).toJS,
  );

  _window.callMethod<JSAny?>(
    'addEventListener'.toJS,
    'drop'.toJS,
    ((JSObject event) {
      event.callMethod<JSAny?>('preventDefault'.toJS);
      final x = (event['clientX'] as JSNumber?)?.toDartDouble ?? 0.0;
      final y = (event['clientY'] as JSNumber?)?.toDartDouble ?? 0.0;

      final files = <String>[];
      String? text;

      final dt = event['dataTransfer'] as JSObject?;
      if (dt != null) {
        final fileList = dt['files'] as JSObject?;
        final len = (fileList?['length'] as JSNumber?)?.toDartInt ?? 0;
        for (var i = 0; i < len; i++) {
          final file = fileList?.callMethod<JSObject?>('item'.toJS, i.toJS);
          final name = (file?['name'] as JSString?)?.toDart;
          if (name != null && name.isNotEmpty) {
            files.add(name);
          }
        }
        try {
          final rawText = dt
              .callMethod<JSString?>('getData'.toJS, 'text/plain'.toJS)
              ?.toDart;
          if (rawText != null && rawText.isNotEmpty) {
            text = rawText;
          }
        } catch (_) {}
      }

      onEvent(
        type: 'drop',
        x: x,
        y: y,
        files: files,
        text: text,
      );
    }).toJS,
  );
}
