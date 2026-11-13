import 'package:flutter/widgets.dart';

import 'adw_navigation_transition.dart';

/// A page inside an [AdwNavigationView], mirroring GNOME Libadwaita's
/// `AdwNavigationPage`.
///
/// Each page has a [title] (used by [AdwNavigationView] and [AdwHeaderBar]),
/// an optional [tag] for programmatic pop-to-tag navigation, and a [canPop] flag
/// controlling whether back navigation and predictive swipe-back are enabled.
class AdwNavigationPage extends StatelessWidget {
  /// Optional identifier used by [AdwNavigationViewController.popToTag].
  final String? tag;

  /// Human-readable page title.
  final String title;

  /// Whether this page can be popped via back button or predictive swipe-back.
  final bool canPop;

  /// Called when this page becomes the top visible page.
  final VoidCallback? onShown;

  /// Called when this page is covered or popped.
  final VoidCallback? onHidden;

  /// Called when this page is popped from the navigation stack.
  final VoidCallback? onPopped;

  /// Page body widget.
  final Widget child;

  const AdwNavigationPage({
    super.key,
    this.tag,
    required this.title,
    this.canPop = true,
    this.onShown,
    this.onHidden,
    this.onPopped,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: child,
    );
  }
}

/// Inherited scope exposed by [AdwNavigationView] to descendant widgets such as
/// [AdwHeaderBar] and [AdwNavigationPage] children.
class AdwNavigationViewScope extends InheritedWidget {
  final AdwNavigationViewController controller;
  final bool canPop;
  final String? visiblePageTitle;

  const AdwNavigationViewScope({
    super.key,
    required this.controller,
    required this.canPop,
    this.visiblePageTitle,
    required super.child,
  });

  static AdwNavigationViewScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdwNavigationViewScope>();
  }

  static AdwNavigationViewScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
      scope != null,
      'No AdwNavigationViewScope found in context. Wrap with AdwNavigationView.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AdwNavigationViewScope oldWidget) {
    return controller != oldWidget.controller ||
        canPop != oldWidget.canPop ||
        visiblePageTitle != oldWidget.visiblePageTitle;
  }
}

/// Controller for managing the navigation stack of an [AdwNavigationView].
class AdwNavigationViewController extends ChangeNotifier {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final List<AdwNavigationPage> _stack = <AdwNavigationPage>[];
  bool _defaultPopOnSwipe = true;
  bool _defaultAllowMouseDrag = true;

  /// Whether the stack has more than one page and the top page allows popping.
  bool get canPop => _stack.length > 1 && (_stack.last.canPop);

  /// Currently visible top page, if any.
  AdwNavigationPage? get visiblePage => _stack.isEmpty ? null : _stack.last;

  /// Unmodifiable snapshot of the current navigation stack.
  List<AdwNavigationPage> get navigationStack =>
      List<AdwNavigationPage>.unmodifiable(_stack);

  void _attachViewConfig({
    required List<AdwNavigationPage> initialPages,
    required bool popOnSwipe,
    required bool allowMouseDrag,
  }) {
    _defaultPopOnSwipe = popOnSwipe;
    _defaultAllowMouseDrag = allowMouseDrag;
    if (_stack.isEmpty) {
      _stack.addAll(initialPages);
    }
  }

  /// Pushes [page] onto the navigation stack with Libadwaita slide & spring transition.
  Future<T?> push<T>(
    AdwNavigationPage page, {
    bool? allowMouseDrag,
  }) async {
    final nav = _navigatorKey.currentState;
    if (nav == null) return null;

    if (_stack.isNotEmpty) {
      _stack.last.onHidden?.call();
    }
    _stack.add(page);
    page.onShown?.call();
    notifyListeners();

    final result = await nav.push<T>(
      AdwNavigationPageRoute<T>(
        settings: RouteSettings(name: page.tag ?? page.title),
        allowSwipeBack: _defaultPopOnSwipe && page.canPop,
        allowMouseDrag: allowMouseDrag ?? _defaultAllowMouseDrag,
        builder: (context) => AdwNavigationViewScope(
          controller: this,
          canPop: canPop,
          visiblePageTitle: page.title,
          child: page,
        ),
      ),
    );

    return result;
  }

  /// Pops the top page if [canPop] is true.
  Future<bool> pop<T>([T? result]) async {
    final nav = _navigatorKey.currentState;
    if (nav == null || !canPop) return false;
    return nav.maybePop<T>(result);
  }

  /// Pops pages until the page matching [tag] is on top.
  bool popToTag(String tag) {
    final nav = _navigatorKey.currentState;
    if (nav == null) return false;
    final index = _stack.lastIndexWhere((p) => p.tag == tag);
    if (index == -1 || index == _stack.length - 1) return false;

    nav.popUntil((route) => route.settings.name == tag);
    return true;
  }

  void _handleRoutePopped(Route<dynamic> route) {
    if (_stack.length <= 1) return;
    final popped = _stack.removeLast();
    popped.onHidden?.call();
    popped.onPopped?.call();
    if (_stack.isNotEmpty) {
      _stack.last.onShown?.call();
    }
    notifyListeners();
  }
}

/// Page-based stack navigation container mirroring GNOME Libadwaita's
/// `AdwNavigationView`.
///
/// Provides native Libadwaita horizontal slide transitions, predictive swipe-back
/// gestures (touch, trackpad, optional mouse drag, and system predictive back),
/// and [AdwNavigationViewScope] for automatic header bar back-button integration.
class AdwNavigationView extends StatefulWidget {
  /// The root page displayed at the bottom of the navigation stack.
  final AdwNavigationPage initialPage;

  /// Optional pre-populated navigation stack (bottom-to-top) used on initial mount.
  final List<AdwNavigationPage>? initialPages;

  /// Optional external controller; an internal controller is created if omitted.
  final AdwNavigationViewController? controller;

  /// Whether horizontal mouse dragging can trigger predictive back gestures.
  final bool allowMouseDrag;

  /// Whether horizontal touch/trackpad swipe-back gestures are enabled.
  final bool popOnSwipe;

  const AdwNavigationView({
    super.key,
    required this.initialPage,
    this.initialPages,
    this.controller,
    this.allowMouseDrag = true,
    this.popOnSwipe = true,
  });

  @override
  State<AdwNavigationView> createState() => _AdwNavigationViewState();
}

class _AdwNavigationViewState extends State<AdwNavigationView> {
  late final AdwNavigationViewController _controller;
  late final _AdwNavObserver _observer;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = AdwNavigationViewController();
      _ownsController = true;
    }
    final effectiveInitialPages = (widget.initialPages != null &&
            widget.initialPages!.isNotEmpty)
        ? widget.initialPages!
        : <AdwNavigationPage>[widget.initialPage];

    _controller._attachViewConfig(
      initialPages: effectiveInitialPages,
      popOnSwipe: widget.popOnSwipe,
      allowMouseDrag: widget.allowMouseDrag,
    );
    _controller.addListener(_onStackChanged);
    _observer = _AdwNavObserver(onPop: _controller._handleRoutePopped);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStackChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onStackChanged() {
    if (mounted) setState(() {});
  }

  Route<dynamic> _buildPageRoute(
    AdwNavigationPage page, {
    required bool isRoot,
  }) {
    return AdwNavigationPageRoute<dynamic>(
      settings: RouteSettings(
        name: page.tag ?? page.title,
      ),
      allowSwipeBack: !isRoot && widget.popOnSwipe && page.canPop,
      allowMouseDrag: widget.allowMouseDrag,
      builder: (context) => AdwNavigationViewScope(
        controller: _controller,
        canPop: !isRoot && page.canPop,
        visiblePageTitle: page.title,
        child: page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveInitialPages = (widget.initialPages != null &&
            widget.initialPages!.isNotEmpty)
        ? widget.initialPages!
        : <AdwNavigationPage>[widget.initialPage];

    return ClipRect(
      child: Navigator(
        key: _controller._navigatorKey,
        observers: [_observer],
        onGenerateInitialRoutes: (navigator, initialRoute) {
          return <Route<dynamic>>[
            for (int i = 0; i < effectiveInitialPages.length; i++)
              _buildPageRoute(
                effectiveInitialPages[i],
                isRoot: i == 0,
              ),
          ];
        },
        onGenerateRoute: (settings) {
          return _buildPageRoute(widget.initialPage, isRoot: true);
        },
      ),
    );
  }
}

class _AdwNavObserver extends NavigatorObserver {
  final void Function(Route<dynamic> route) onPop;

  _AdwNavObserver({required this.onPop});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onPop(route);
  }
}
