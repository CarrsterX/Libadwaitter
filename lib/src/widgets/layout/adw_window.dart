import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show ValueListenable, kIsWeb;
import 'package:flutter/gestures.dart' show kPrimaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';
import 'adw_application.dart';

/// Window edge identifiers for native border resize operations.
enum AdwWindowEdge {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Decoupled interface for native Client-Side Decorations (CSD) / frameless window control.
abstract class AdwWindowController {
  bool get isMaximized;
  bool get isActive;
  ValueListenable<bool>? get activeListenable;
  void close();
  void minimize();
  void maximize();
  void startDragging();
  void beginResizeDrag(AdwWindowEdge edge);
}

/// Native implementation delegating to the desktop platform channel (`libadwaitter/window`).
class AdwNativeWindowController implements AdwWindowController {
  static const MethodChannel _channel = MethodChannel('libadwaitter/window');
  bool _isMaximized = false;
  final ValueNotifier<bool> _activeNotifier = ValueNotifier<bool>(true);

  AdwNativeWindowController() {
    _init();
  }

  void _init() async {
    if (kIsWeb) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWindowActiveChanged') {
        final bool? active = call.arguments as bool?;
        if (active != null) {
          _activeNotifier.value = active;
        }
      }
    });
    try {
      final bool? isMax = await _channel.invokeMethod<bool>('isMaximized');
      if (isMax != null) {
        _isMaximized = isMax;
      }
      final bool? active = await _channel.invokeMethod<bool>('isActive');
      if (active != null) {
        _activeNotifier.value = active;
      }
    } catch (_) {}
  }

  @override
  bool get isMaximized => _isMaximized;

  @override
  bool get isActive => _activeNotifier.value;

  @override
  ValueListenable<bool> get activeListenable => _activeNotifier;

  @override
  void close() {
    if (kIsWeb) return;
    _channel.invokeMethod('close').catchError((_) {});
  }

  @override
  void minimize() {
    if (kIsWeb) return;
    _channel.invokeMethod('minimize').catchError((_) {});
  }

  @override
  void maximize() {
    if (kIsWeb) return;
    _isMaximized = !_isMaximized;
    _channel.invokeMethod('maximize').catchError((_) {});
  }

  @override
  void startDragging() {
    if (kIsWeb) return;
    _channel.invokeMethod('startDragging').catchError((_) {});
  }

  @override
  void beginResizeDrag(AdwWindowEdge edge) {
    if (kIsWeb) return;
    _channel.invokeMethod('beginResizeDrag', {'edge': edge.name}).catchError((_) {});
  }
}

/// Inherited scope providing window state and [AdwWindowController] down the widget tree.
class AdwWindowScope extends InheritedWidget {
  final AdwWindowController? controller;
  final bool isMaximized;
  final bool isActive;

  const AdwWindowScope({
    super.key,
    this.controller,
    required this.isMaximized,
    this.isActive = true,
    required super.child,
  });

  static AdwWindowScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdwWindowScope>();
  }

  static AdwWindowScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
        scope != null, 'No AdwWindowScope found in the current BuildContext.');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AdwWindowScope oldWidget) {
    return controller != oldWidget.controller ||
        isMaximized != oldWidget.isMaximized ||
        isActive != oldWidget.isActive;
  }
}

/// Top-level application window container (`AdwWindow` / `AdwApplicationWindow`).
///
/// Implements GNOME Client-Side Decorations (CSD):
/// - 15px corner radius ([AdwMetrics.windowRadius]) when floating.
/// - Transitions automatically to square corners (0px) and removes shadows when maximized.
/// - Subtle Mutter-style window drop shadow.
/// - 1px adaptive hairline border.
/// - Transparent edge/corner hit test zones enabling native Mutter/Wayland window resizing.
class AdwWindow extends StatefulWidget {
  final AdwWindowController? controller;
  final bool? isMaximized;
  final Widget? headerBar;
  final Widget child;
  final bool showShadow;
  final bool showBorder;

  const AdwWindow({
    super.key,
    this.controller,
    this.isMaximized,
    this.headerBar,
    required this.child,
    this.showShadow = true,
    this.showBorder = true,
  });

  @override
  State<AdwWindow> createState() => _AdwWindowState();
}

class _AdwWindowState extends State<AdwWindow> with WidgetsBindingObserver {
  late final AdwWindowController _effectiveController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _effectiveController = widget.controller ?? _createDefaultController();
    _isActive = _effectiveController.isActive;
    _effectiveController.activeListenable?.addListener(_onActiveChanged);
  }

  @override
  void dispose() {
    _effectiveController.activeListenable?.removeListener(_onActiveChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onActiveChanged() {
    if (mounted) {
      setState(() => _isActive = _effectiveController.isActive);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Fallback backdrop detection for platforms without native GTK focus bridge
    if (_effectiveController.activeListenable == null && mounted) {
      setState(() => _isActive = state == AppLifecycleState.resumed);
    }
  }

  AdwWindowController _createDefaultController() {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      return AdwNativeWindowController();
    }
    return _NoopWindowController();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final effectiveIsMaximized =
        widget.isMaximized ?? _effectiveController.isMaximized;

    final borderRadius = effectiveIsMaximized
        ? BorderRadius.zero
        : BorderRadius.circular(AdwMetrics.windowRadius);

    final shapeScope = AdwWindowShapeScope.maybeOf(context);
    if (shapeScope != null && shapeScope.borderRadiusNotifier.value != borderRadius) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          shapeScope.borderRadiusNotifier.value = borderRadius;
        }
      });
    }

    final effectiveIsActive = _isActive;

    final List<BoxShadow> shadows = (!effectiveIsMaximized && widget.showShadow)
        ? (effectiveIsActive
            ? [
                const BoxShadow(
                  color: Color(0x38000000),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: Offset(0, 6),
                ),
                const BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: Offset(0, 1),
                ),
              ]
            : [
                const BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: Offset(0, 3),
                ),
              ])
        : const [];

    Widget windowContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerBar != null) widget.headerBar!,
        Expanded(child: widget.child),
      ],
    );

    final Widget windowContentWithResizers = Stack(
      children: [
        Positioned.fill(child: windowContent),
        if (!effectiveIsMaximized) ...[
          // Edges (6px border handles)
          Positioned(
            top: 0,
            left: 14,
            right: 14,
            height: 6,
            child: _ResizeHandle(
              cursor: SystemMouseCursors.resizeUp,
              edge: AdwWindowEdge.top,
              onResize: () =>
                  _effectiveController.beginResizeDrag(AdwWindowEdge.top),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 14,
            right: 14,
            height: 6,
            child: _ResizeHandle(
              cursor: SystemMouseCursors.resizeDown,
              edge: AdwWindowEdge.bottom,
              onResize: () =>
                  _effectiveController.beginResizeDrag(AdwWindowEdge.bottom),
            ),
          ),
          Positioned(
            top: 14,
            bottom: 14,
            left: 0,
            width: 6,
            child: _ResizeHandle(
              cursor: SystemMouseCursors.resizeLeft,
              edge: AdwWindowEdge.left,
              onResize: () =>
                  _effectiveController.beginResizeDrag(AdwWindowEdge.left),
            ),
          ),
          Positioned(
            top: 14,
            bottom: 14,
            right: 0,
            width: 6,
            child: _ResizeHandle(
              cursor: SystemMouseCursors.resizeRight,
              edge: AdwWindowEdge.right,
              onResize: () =>
                  _effectiveController.beginResizeDrag(AdwWindowEdge.right),
            ),
          ),
          // Corners (14x14px hitboxes)
          Positioned(
            top: 0,
            left: 0,
            width: 14,
            height: 14,
            child: _ResizeHandle(
              cursor: SystemMouseCursors.resizeUpLeft,
              edge: AdwWindowEdge.topLeft,
              onResize: () =>
                  _effectiveController.beginResizeDrag(AdwWindowEdge.topLeft),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            width: 14,
            height: 14,
            child: _ResizeHandle(
              cursor: SystemMouseCursors.resizeUpRight,
              edge: AdwWindowEdge.topRight,
              onResize: () =>
                  _effectiveController.beginResizeDrag(AdwWindowEdge.topRight),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            width: 14,
            height: 14,
            child: _ResizeHandle(
              cursor: SystemMouseCursors.resizeDownLeft,
              edge: AdwWindowEdge.bottomLeft,
              onResize: () =>
                  _effectiveController.beginResizeDrag(AdwWindowEdge.bottomLeft),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            width: 14,
            height: 14,
            child: _ResizeHandle(
              cursor: SystemMouseCursors.resizeDownRight,
              edge: AdwWindowEdge.bottomRight,
              onResize: () =>
                  _effectiveController.beginResizeDrag(AdwWindowEdge.bottomRight),
            ),
          ),
        ],
      ],
    );

    return AdwWindowScope(
      controller: _effectiveController,
      isMaximized: effectiveIsMaximized,
      isActive: effectiveIsActive,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.windowBackground,
          borderRadius: borderRadius,
          border: widget.showBorder && !effectiveIsMaximized
              ? Border.all(
                  color: theme.colors.windowOutline,
                  width: 1,
                )
              : null,
          boxShadow: shadows,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              windowContentWithResizers,
              if (widget.showBorder && !effectiveIsMaximized)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        border: Border.all(
                          color: theme.colors.windowInnerBorder,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: AdwCurves.shortDuration,
                    color: effectiveIsActive
                        ? const Color(0x00000000)
                        : (theme.colors.isDark
                            ? const Color(0x14000000)
                            : const Color(0x0AFFFFFF)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  final MouseCursor cursor;
  final AdwWindowEdge edge;
  final VoidCallback onResize;

  const _ResizeHandle({
    required this.cursor,
    required this.edge,
    required this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (event.buttons == kPrimaryMouseButton) {
            onResize();
          }
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NoopWindowController implements AdwWindowController {
  @override
  bool get isMaximized => false;
  @override
  bool get isActive => true;
  @override
  ValueListenable<bool>? get activeListenable => null;
  @override
  void close() {}
  @override
  void minimize() {}
  @override
  void maximize() {}
  @override
  void startDragging() {}
  @override
  void beginResizeDrag(AdwWindowEdge edge) {}
}
