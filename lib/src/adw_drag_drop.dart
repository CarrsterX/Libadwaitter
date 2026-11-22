import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Lifecycle phase of an external drag-and-drop operation targeting the window.
enum AdwDropEventType {
  enter,
  update,
  leave,
  drop,
}

/// Payload emitted on [AdwDragAndDrop.events] when files or text are dragged
/// from another application into the window (Linux GTK3 and Android).
class AdwDropEvent {
  const AdwDropEvent({
    required this.type,
    this.position = Offset.zero,
    this.files = const [],
    this.text,
  });

  final AdwDropEventType type;

  /// Pointer position in logical window coordinates.
  final Offset position;

  /// Local file paths dropped into the window.
  final List<String> files;

  /// Plain text or URL dropped into the window, if any.
  final String? text;
}

/// Cross-platform external Drag & Drop bridge (`libadwaitter/dnd`).
///
/// - **Linux:** Receives external files (`text/uri-list`) and text (`text/plain`)
///   dragged from file managers or browsers via GTK3 `drag-data-received`.
/// - **Android:** Receives files and text dragged in split-screen / desktop
///   mode via `View.OnDragListener` and `requestDragAndDropPermissions`.
class AdwDragAndDrop {
  AdwDragAndDrop._();

  static const MethodChannel _defaultChannel =
      MethodChannel('libadwaitter/dnd');

  static MethodChannel _channel = _defaultChannel;
  static bool _handlerRegistered = false;
  static final StreamController<AdwDropEvent> _eventController =
      StreamController<AdwDropEvent>.broadcast();

  /// Broadcast stream of external drag-and-drop events targeting the window.
  static Stream<AdwDropEvent> get events {
    _ensureHandlerRegistered();
    return _eventController.stream;
  }

  static void _ensureHandlerRegistered() {
    if (_handlerRegistered) return;
    _handlerRegistered = true;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onDropEvent') return;
    final args = call.arguments;
    if (args is! Map) return;

    final typeName = args['type'] as String?;
    final type = switch (typeName) {
      'enter' => AdwDropEventType.enter,
      'update' => AdwDropEventType.update,
      'leave' => AdwDropEventType.leave,
      'drop' => AdwDropEventType.drop,
      _ => null,
    };
    if (type == null) return;

    final x = (args['x'] as num?)?.toDouble() ?? 0.0;
    final y = (args['y'] as num?)?.toDouble() ?? 0.0;
    final rawFiles = args['files'];
    final files = rawFiles is List
        ? rawFiles.whereType<String>().toList(growable: false)
        : const <String>[];
    final rawText = args['text'] as String?;
    final text = (rawText != null && rawText.isNotEmpty) ? rawText : null;

    _eventController.add(
      AdwDropEvent(
        type: type,
        position: Offset(x, y),
        files: files,
        text: text,
      ),
    );
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

/// Declarative drop zone widget that reacts to external files or text dragged
/// from other applications via [AdwDragAndDrop].
class AdwDropTarget extends StatefulWidget {
  const AdwDropTarget({
    super.key,
    required this.child,
    this.onDrop,
    this.onDragStateChanged,
    this.builder,
  });

  final Widget child;

  /// Invoked when files and/or text are dropped inside this widget's bounds.
  final void Function(List<String> files, String? text)? onDrop;

  /// Invoked when an external drag enters or leaves this widget's bounds.
  final ValueChanged<bool>? onDragStateChanged;

  /// Optional wrapper builder receiving the current `isDraggingOver` state.
  final Widget Function(
    BuildContext context,
    bool isDraggingOver,
    Widget child,
  )? builder;

  @override
  State<AdwDropTarget> createState() => _AdwDropTargetState();
}

class _AdwDropTargetState extends State<AdwDropTarget> {
  final GlobalKey _key = GlobalKey();
  StreamSubscription<AdwDropEvent>? _sub;
  bool _isDraggingOver = false;

  @override
  void initState() {
    super.initState();
    _sub = AdwDragAndDrop.events.listen(_handleEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool _containsGlobalPoint(Offset globalPos) {
    final renderObject = _key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final local = renderObject.globalToLocal(globalPos);
    return (Offset.zero & renderObject.size).contains(local);
  }

  void _setDraggingOver(bool value) {
    if (_isDraggingOver == value) return;
    setState(() => _isDraggingOver = value);
    widget.onDragStateChanged?.call(value);
  }

  void _handleEvent(AdwDropEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case AdwDropEventType.enter:
      case AdwDropEventType.update:
        _setDraggingOver(_containsGlobalPoint(event.position));
      case AdwDropEventType.leave:
        _setDraggingOver(false);
      case AdwDropEventType.drop:
        final inside =
            _isDraggingOver || _containsGlobalPoint(event.position);
        _setDraggingOver(false);
        if (inside && (event.files.isNotEmpty || event.text != null)) {
          widget.onDrop?.call(event.files, event.text);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.builder != null
        ? widget.builder!(context, _isDraggingOver, widget.child)
        : widget.child;
    return KeyedSubtree(
      key: _key,
      child: content,
    );
  }
}
