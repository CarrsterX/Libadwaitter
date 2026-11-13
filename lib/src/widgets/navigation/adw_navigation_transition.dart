import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/adw_spring.dart';
import '../../theme/adw_curves.dart';
import '../../theme/adw_theme.dart';

/// Visual transition matching GNOME Libadwaita's `AdwNavigationView`.
///
/// Unlike iOS (edge-only Cupertino physics) or Android (predictive scale-down),
/// Libadwaita slides the active page `1:1` horizontally while the underlying
/// page performs a subtle parallax shift (`-33%`) with a progressive dimming
/// scrim and a soft left-edge drop shadow on the incoming/outgoing page.
class AdwNavigationPageTransition extends StatelessWidget {
  final Animation<double> primaryAnimation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final bool linearTransition;

  const AdwNavigationPageTransition({
    super.key,
    required this.primaryAnimation,
    required this.secondaryAnimation,
    required this.child,
    this.linearTransition = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.maybeOf(context);
    final isDark = theme?.colors.isDark ?? false;

    final Animation<double> effectivePrimary = linearTransition
        ? primaryAnimation
        : CurvedAnimation(
            parent: primaryAnimation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInOutCubic,
          );

    final Animation<double> effectiveSecondary = linearTransition
        ? secondaryAnimation
        : CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInOutCubic,
          );

    final Color pageBackground = theme?.colors.windowBackground ??
        (isDark ? const Color(0xFF242424) : const Color(0xFFFAFAFA));

    return AnimatedBuilder(
      animation: Listenable.merge([effectivePrimary, effectiveSecondary]),
      builder: (context, builtChild) {
        final double enterProgress = effectivePrimary.value.clamp(0.0, 1.0);
        final double exitProgress = effectiveSecondary.value.clamp(0.0, 1.0);

        // Primary slide: enters from 1.0 (right) to 0.0 (center) while the
        // underlying page stays stationary behind it.
        final double dx = 1.0 - enterProgress;

        // Left-edge shadow opacity peaks mid-transition and disappears when settled
        final double shadowFactor =
            (enterProgress > 0.0 && enterProgress < 1.0)
                ? math.sin(enterProgress * math.pi).clamp(0.0, 1.0)
                : 0.0;

        // Subtle dimming overlay on the underlying page as a new page slides above it
        final double maxDimAlpha = isDark ? 0.18 : 0.10;
        final double dimAlpha = (exitProgress * maxDimAlpha).clamp(0.0, 1.0);

        return FractionalTranslation(
          translation: Offset(dx, 0.0),
          transformHitTests: true,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // Left-edge cast shadow matching Libadwaita's `--shade-color`
              if (shadowFactor > 0.0)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: -18,
                  width: 18,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Color.fromRGBO(
                              0,
                              0,
                              0,
                              (isDark ? 0.28 : 0.14) * shadowFactor,
                            ),
                            const Color(0x00000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Opaque page surface so underlying pages never bleed through during slide
              ColoredBox(
                color: pageBackground,
                child: builtChild!,
              ),
              // Subtle dimming overlay on the underlying page
              if (dimAlpha > 0.0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color.fromRGBO(0, 0, 0, dimAlpha),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

/// A [PageRoute] implementing GNOME Libadwaita's predictive navigation gestures.
///
/// Supports:
/// - Touch and optional mouse horizontal swipe-back (`AdwSwipeTracker` semantics).
/// - Two-finger trackpad horizontal pan gestures (`PointerPanZoomEvent`).
/// - System-level predictive back events (`WidgetsBindingObserver`) on mobile
///   platforms, rendering Libadwaita's horizontal slide instead of Android's scale-down.
/// - Velocity-preserving [AdwSpringParams.navigation] physics on release.
class AdwNavigationPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final bool allowSwipeBack;
  final bool allowMouseDrag;
  final bool edgeOnly;
  final double edgeWidth;
  final AdwSpringParams springParams;

  @override
  final bool maintainState;

  AdwNavigationPageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
    super.fullscreenDialog = false,
    this.allowSwipeBack = true,
    this.allowMouseDrag = true,
    this.edgeOnly = false,
    this.edgeWidth = 36.0,
    this.springParams = AdwSpringParams.navigation,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => AdwCurves.normalDuration;

  @override
  Duration get reverseTransitionDuration => AdwCurves.normalDuration;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is AdwNavigationPageRoute ||
        nextRoute is PageRoute;
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is AdwNavigationPageRoute ||
        previousRoute is PageRoute;
  }

  bool _skipReverseOnSpringPop = false;
  final ValueNotifier<bool> _interactiveGestureNotifier =
      ValueNotifier<bool>(false);

  @override
  bool get opaque {
    if (_interactiveGestureNotifier.value ||
        (navigator?.userGestureInProgress ?? false)) {
      return false;
    }
    return super.opaque;
  }

  @override
  void dispose() {
    _interactiveGestureNotifier.dispose();
    super.dispose();
  }

  @override
  bool didPop(T? result) {
    if (_skipReverseOnSpringPop) {
      _skipReverseOnSpringPop = false;
      controller?.value = 0.0;
    }
    return super.didPop(result);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final nav = navigator;
    final listenable = nav != null
        ? Listenable.merge([
            _interactiveGestureNotifier,
            nav.userGestureInProgressNotifier,
          ])
        : _interactiveGestureNotifier;

    return _AdwPredictiveBackScope<T>(
      route: this,
      allowSwipeBack: allowSwipeBack,
      allowMouseDrag: allowMouseDrag,
      edgeOnly: edgeOnly,
      edgeWidth: edgeWidth,
      springParams: springParams,
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, builtChild) {
          final bool linear = _interactiveGestureNotifier.value ||
              (nav?.userGestureInProgress ?? false);
          return AdwNavigationPageTransition(
            primaryAnimation: animation,
            secondaryAnimation: secondaryAnimation,
            linearTransition: linear,
            child: builtChild!,
          );
        },
        child: child,
      ),
    );
  }
}

class _AdwPredictiveBackScope<T> extends StatefulWidget {
  final AdwNavigationPageRoute<T> route;
  final bool allowSwipeBack;
  final bool allowMouseDrag;
  final bool edgeOnly;
  final double edgeWidth;
  final AdwSpringParams springParams;
  final Widget child;

  const _AdwPredictiveBackScope({
    required this.route,
    required this.allowSwipeBack,
    required this.allowMouseDrag,
    required this.edgeOnly,
    required this.edgeWidth,
    required this.springParams,
    required this.child,
  });

  @override
  State<_AdwPredictiveBackScope<T>> createState() =>
      _AdwPredictiveBackScopeState<T>();
}

class _AdwPredictiveBackScopeState<T> extends State<_AdwPredictiveBackScope<T>>
    with WidgetsBindingObserver {
  bool _isDragging = false;
  bool _isSystemPredictiveBack = false;
  bool _isAnimatingOut = false;
  double _trackpadAccumulatedDx = 0.0;
  bool _trackpadActive = false;
  VelocityTracker? _trackpadVelocityTracker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _canInteractivePop {
    final nav = widget.route.navigator;
    if (!widget.allowSwipeBack || nav == null || _isAnimatingOut) {
      return false;
    }
    if (widget.route.isFirst || !widget.route.isCurrent) {
      return false;
    }
    return widget.route.popDisposition != RoutePopDisposition.doNotPop;
  }

  AnimationController? get _controller {
    // ignore: invalid_use_of_protected_member
    return widget.route.controller;
  }

  void _startGesture() {
    if (_isDragging) return;
    _isDragging = true;
    widget.route._interactiveGestureNotifier.value = true;
    widget.route.navigator?.didStartUserGesture();
    // ignore: invalid_use_of_protected_member
    widget.route.changedInternalState();
  }

  void _updateGestureDelta(double dx, double viewportWidth) {
    final controller = _controller;
    if (controller == null || viewportWidth <= 0) return;
    final double deltaProgress = dx / viewportWidth;
    controller.value = (controller.value - deltaProgress).clamp(0.0, 1.0);
  }

  void _endGesture(double velocityPxPerSec, double viewportWidth) {
    final controller = _controller;
    final nav = widget.route.navigator;
    if (!_isDragging) return;
    _isDragging = false;

    if (controller == null || nav == null) {
      nav?.didStopUserGesture();
      return;
    }

    final double normalizedVelocity =
        viewportWidth > 0 ? -(velocityPxPerSec / viewportWidth) : 0.0;
    final bool shouldPop =
        velocityPxPerSec > 320.0 ||
        (velocityPxPerSec > -150.0 && controller.value < 0.58);

    if (shouldPop) {
      _isAnimatingOut = true;
      final sim = widget.springParams.createSimulation(
        start: controller.value,
        end: 0.0,
        velocity: normalizedVelocity,
      );
      controller.animateWith(sim).whenComplete(() {
        widget.route._interactiveGestureNotifier.value = false;
        nav.didStopUserGesture();
        // ignore: invalid_use_of_protected_member
        widget.route.changedInternalState();
        if (mounted && widget.route.isCurrent) {
          widget.route._skipReverseOnSpringPop = true;
          nav.pop();
        }
        _isAnimatingOut = false;
      });
    } else {
      final sim = widget.springParams.createSimulation(
        start: controller.value,
        end: 1.0,
        velocity: normalizedVelocity,
      );
      controller.animateWith(sim).whenComplete(() {
        widget.route._interactiveGestureNotifier.value = false;
        nav.didStopUserGesture();
        // ignore: invalid_use_of_protected_member
        widget.route.changedInternalState();
      });
    }
  }

  void _cancelGesture() {
    if (!_isDragging) return;
    _endGesture(0.0, context.size?.width ?? 1.0);
  }

  // --- System Predictive Back (Android 14+ / platform back gestures) ---

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (!_canInteractivePop || _isDragging) {
      return false;
    }
    _isSystemPredictiveBack = true;
    _startGesture();
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_isSystemPredictiveBack) return;
    final controller = _controller;
    if (controller == null) return;
    controller.value = (1.0 - backEvent.progress).clamp(0.0, 1.0);
  }

  @override
  void handleCommitBackGesture() {
    if (!_isSystemPredictiveBack) return;
    _isSystemPredictiveBack = false;
    final width = context.size?.width ?? 400.0;
    _endGesture(600.0, width);
  }

  @override
  void handleCancelBackGesture() {
    if (!_isSystemPredictiveBack) return;
    _isSystemPredictiveBack = false;
    final width = context.size?.width ?? 400.0;
    _endGesture(-300.0, width);
  }

  // --- Trackpad two-finger pan support (Linux/macOS desktop) ---

  void _handlePointerPanZoomStart(PointerPanZoomStartEvent event) {
    if (!_canInteractivePop) return;
    _trackpadAccumulatedDx = 0.0;
    _trackpadActive = false;
    _trackpadVelocityTracker =
        VelocityTracker.withKind(PointerDeviceKind.trackpad)
          ..addPosition(event.timeStamp, Offset.zero);
  }

  void _handlePointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (!_canInteractivePop && !_trackpadActive) return;
    _trackpadAccumulatedDx += event.panDelta.dx;
    _trackpadVelocityTracker?.addPosition(
      event.timeStamp,
      event.localPan * 0.38,
    );
    if (!_trackpadActive) {
      // Activate only on clear rightward horizontal intent
      if (_trackpadAccumulatedDx > 16.0 &&
          event.panDelta.dx.abs() > event.panDelta.dy.abs()) {
        _trackpadActive = true;
        _startGesture();
      }
      return;
    }
    final double effectiveDistance = math.max(context.size?.width ?? 400.0, 420.0);
    // Match Libadwaita's gentle touchpad swipe sensitivity without libinput acceleration spikes
    _updateGestureDelta(event.panDelta.dx * 0.38, effectiveDistance);
  }

  void _handlePointerPanZoomEnd(PointerPanZoomEndEvent event) {
    final tracker = _trackpadVelocityTracker;
    _trackpadVelocityTracker = null;
    if (!_trackpadActive) return;
    _trackpadActive = false;
    final double effectiveDistance = math.max(context.size?.width ?? 400.0, 420.0);
    final double velocityDx =
        tracker?.getVelocity().pixelsPerSecond.dx ?? 0.0;
    _endGesture(velocityDx, effectiveDistance);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerPanZoomStart: _handlePointerPanZoomStart,
      onPointerPanZoomUpdate: _handlePointerPanZoomUpdate,
      onPointerPanZoomEnd: _handlePointerPanZoomEnd,
      child: RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: <Type, GestureRecognizerFactory>{
          HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer>(
            // Trackpad gestures are handled exclusively via PointerPanZoom events above
            // to avoid double-counting deltas with HorizontalDragGestureRecognizer.
            () => HorizontalDragGestureRecognizer(
              supportedDevices: widget.allowMouseDrag
                  ? const {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.stylus,
                    }
                  : const {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.stylus,
                    },
            ),
            (HorizontalDragGestureRecognizer instance) {
              instance
                ..onStart = (details) {
                  if (!_canInteractivePop) return;
                  if (widget.edgeOnly &&
                      details.localPosition.dx > widget.edgeWidth) {
                    return;
                  }
                  _startGesture();
                }
                ..onUpdate = (details) {
                  if (!_isDragging) return;
                  final width = context.size?.width ?? 400.0;
                  _updateGestureDelta(details.delta.dx, width);
                }
                ..onEnd = (details) {
                  if (!_isDragging) return;
                  final width = context.size?.width ?? 400.0;
                  _endGesture(details.velocity.pixelsPerSecond.dx, width);
                }
                ..onCancel = _cancelGesture;
            },
          ),
        },
        child: IgnorePointer(
          ignoring: _isAnimatingOut,
          child: widget.child,
        ),
      ),
    );
  }
}

