import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_theme.dart';

/// Controller coordinating page transitions and position tracking for [AdwCarousel].
///
/// Follows upstream Libadwaita `AdwCarousel` API:
/// https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/adw-carousel.c
class AdwCarouselController extends ChangeNotifier {
  late final PageController _pageController;
  final bool _ownsController;
  int _itemCount = 0;

  AdwCarouselController({int initialPage = 0})
      : _pageController = PageController(initialPage: initialPage),
        _ownsController = true {
    _pageController.addListener(_onPageControllerNotify);
  }

  /// Internal constructor wrapping an external [PageController].
  AdwCarouselController.fromPageController(PageController pageController)
      : _pageController = pageController,
        _ownsController = false {
    _pageController.addListener(_onPageControllerNotify);
  }

  void _onPageControllerNotify() {
    notifyListeners();
  }

  /// Access underlying [PageController].
  PageController get pageController => _pageController;

  /// Total count of pages currently registered in the carousel.
  int get itemCount => _itemCount;

  /// Internal setter invoked by [AdwCarousel].
  void updateItemCount(int count) {
    if (_itemCount != count) {
      _itemCount = count;
      notifyListeners();
    }
  }

  /// Current continuous scroll position as a double.
  double get page {
    if (!_pageController.hasClients) {
      return _pageController.initialPage.toDouble();
    }
    return _pageController.page ?? _pageController.initialPage.toDouble();
  }

  /// Current discrete rounded page index.
  int get currentPage =>
      page.round().clamp(0, _itemCount > 0 ? _itemCount - 1 : 0);

  /// Animate smoothly to a specific target [page] index.
  Future<void> animateToPage(
    int page, {
    Duration duration = AdwCurves.normalDuration,
    Curve curve = AdwCurves.standard,
  }) {
    if (!_pageController.hasClients) return Future.value();
    final target = page.clamp(0, _itemCount > 0 ? _itemCount - 1 : 0);
    return _pageController.animateToPage(target,
        duration: duration, curve: curve);
  }

  /// Advance to the next page if available.
  Future<void> nextPage({
    Duration duration = AdwCurves.normalDuration,
    Curve curve = AdwCurves.standard,
  }) {
    return animateToPage(currentPage + 1, duration: duration, curve: curve);
  }

  /// Retreat to the previous page if available.
  Future<void> previousPage({
    Duration duration = AdwCurves.normalDuration,
    Curve curve = AdwCurves.standard,
  }) {
    return animateToPage(currentPage - 1, duration: duration, curve: curve);
  }

  /// Jump immediately to the given [page] without animation.
  void jumpToPage(int page) {
    if (!_pageController.hasClients) return;
    final target = page.clamp(0, _itemCount > 0 ? _itemCount - 1 : 0);
    _pageController.jumpToPage(target);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageControllerNotify);
    if (_ownsController) {
      _pageController.dispose();
    }
    super.dispose();
  }
}

/// Libadwaita paginated carousel widget (`AdwCarousel`).
///
/// Implements upstream GNOME Libadwaita specifications:
/// - GitLab source: `https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/src/adw-carousel.c`
/// - CSS selector: `carousel`
///
/// Supports interactive swiping, mouse drag, keyboard traversal, and optional overlay
/// previous/next navigation arrow buttons.
class AdwCarousel extends StatefulWidget {
  /// The list of widgets to display in sequential pages.
  final List<Widget> children;

  /// External controller for orchestrating animations and monitoring positions.
  final AdwCarouselController? controller;

  /// Invoked whenever the active page changes.
  final ValueChanged<int>? onPageChanged;

  /// Horizontal spacing between consecutive carousel items in logical pixels.
  final double spacing;

  /// Fraction of viewport allocated per page (default 1.0 for full-bleed pages).
  final double viewportFraction;

  /// Whether to display overlay floating navigation arrow buttons on hover.
  final bool showNavigationButtons;

  /// Whether touch and mouse dragging are enabled.
  final bool interactive;

  const AdwCarousel({
    super.key,
    required this.children,
    this.controller,
    this.onPageChanged,
    this.spacing = 0.0,
    this.viewportFraction = 1.0,
    this.showNavigationButtons = true,
    this.interactive = true,
  });

  @override
  State<AdwCarousel> createState() => _AdwCarouselState();
}

class _AdwCarouselState extends State<AdwCarousel> {
  late AdwCarouselController _controller;
  bool _isLocalController = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isLocalController = false;
    } else {
      _controller = AdwCarouselController();
      _isLocalController = true;
    }
    _controller.updateItemCount(widget.children.length);
  }

  @override
  void didUpdateWidget(covariant AdwCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_isLocalController) {
        _controller.dispose();
      }
      _initController();
    } else {
      _controller.updateItemCount(widget.children.length);
    }
  }

  @override
  void dispose() {
    if (_isLocalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final count = widget.children.length;

    Widget pageView = PageView.builder(
      controller: _controller.pageController,
      physics: widget.interactive
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      onPageChanged: widget.onPageChanged,
      itemCount: count,
      itemBuilder: (context, index) {
        if (widget.spacing == 0.0) {
          return widget.children[index];
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          child: widget.children[index],
        );
      },
    );

    if (!widget.showNavigationButtons || count <= 1) {
      return pageView;
    }

    final duration = AdwCurves.resolve(context, AdwCurves.shortDuration);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          pageView,
          // Previous button overlay
          Positioned(
            left: 12,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final canGoBack = _controller.currentPage > 0;
                final isVisible = _isHovered && canGoBack;

                return AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: duration,
                  curve: AdwCurves.standard,
                  child: IgnorePointer(
                    ignoring: !isVisible,
                    child: _CarouselNavButton(
                      direction: _NavDirection.previous,
                      onPressed: () => _controller.previousPage(
                        duration: AdwCurves.resolve(
                            context, AdwCurves.normalDuration),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Next button overlay
          Positioned(
            right: 12,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final canGoForward = _controller.currentPage < count - 1;
                final isVisible = _isHovered && canGoForward;

                return AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: duration,
                  curve: AdwCurves.standard,
                  child: IgnorePointer(
                    ignoring: !isVisible,
                    child: _CarouselNavButton(
                      direction: _NavDirection.next,
                      onPressed: () => _controller.nextPage(
                        duration: AdwCurves.resolve(
                            context, AdwCurves.normalDuration),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _NavDirection { previous, next }

class _CarouselNavButton extends StatefulWidget {
  final _NavDirection direction;
  final VoidCallback onPressed;

  const _CarouselNavButton({
    required this.direction,
    required this.onPressed,
  });

  @override
  State<_CarouselNavButton> createState() => _CarouselNavButtonState();
}

class _CarouselNavButtonState extends State<_CarouselNavButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final duration = AdwCurves.resolve(context, AdwCurves.shortDuration);

    Color bg = const Color(0x80000000);
    if (_isPressed) {
      bg = const Color(0xCC000000);
    } else if (_isHovered) {
      bg = const Color(0xA6000000);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: duration,
          curve: AdwCurves.standard,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(12, 12),
              painter: _ChevronPainter(
                direction: widget.direction,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final _NavDirection direction;
  final Color color;

  const _ChevronPainter({
    required this.direction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (direction == _NavDirection.previous) {
      path.moveTo(size.width * 0.7, size.height * 0.1);
      path.lineTo(size.width * 0.3, size.height * 0.5);
      path.lineTo(size.width * 0.7, size.height * 0.9);
    } else {
      path.moveTo(size.width * 0.3, size.height * 0.1);
      path.lineTo(size.width * 0.7, size.height * 0.5);
      path.lineTo(size.width * 0.3, size.height * 0.9);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) {
    return direction != oldDelegate.direction || color != oldDelegate.color;
  }
}
