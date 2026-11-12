import 'dart:async';
import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Data model for a Libadwaita floating in-app notification (`AdwToast`).
class AdwToast {
  final Widget title;
  final Widget? action;
  final Duration timeout;
  final VoidCallback? onDismissed;

  const AdwToast({
    required this.title,
    this.action,
    this.timeout = const Duration(seconds: 4),
    this.onDismissed,
  });
}

/// Floating toast notification overlay layer (`AdwToastOverlay`).
///
/// Places pill-styled in-app notifications at the bottom center of the window,
/// matching Libadwaita specifications.
class AdwToastOverlay extends StatefulWidget {
  final Widget child;

  const AdwToastOverlay({
    super.key,
    required this.child,
  });

  static _AdwToastOverlayState of(BuildContext context) {
    final state = context.findAncestorStateOfType<_AdwToastOverlayState>();
    assert(
      state != null,
      'No AdwToastOverlay found in context. '
      'Wrap your view or content hierarchy with AdwToastOverlay.',
    );
    return state!;
  }

  static _AdwToastOverlayState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_AdwToastOverlayState>();
  }

  @override
  State<AdwToastOverlay> createState() => _AdwToastOverlayState();
}

class _AdwToastOverlayState extends State<AdwToastOverlay> with SingleTickerProviderStateMixin {
  final List<AdwToast> _queue = [];
  AdwToast? _currentToast;
  Timer? _timer;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AdwCurves.normalDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: AdwCurves.standard,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: AdwCurves.standard,
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  /// Adds and presents a new [AdwToast].
  void addToast(AdwToast toast) {
    _queue.add(toast);
    if (_currentToast == null) {
      _showNextToast();
    }
  }

  void _showNextToast() {
    if (_queue.isEmpty) {
      _currentToast = null;
      return;
    }

    setState(() {
      _currentToast = _queue.removeAt(0);
    });

    _animController.forward(from: 0.0);

    _timer?.cancel();
    _timer = Timer(_currentToast!.timeout, () {
      _dismissCurrentToast();
    });
  }

  void _dismissCurrentToast() {
    _timer?.cancel();
    _animController.reverse().then((_) {
      _currentToast?.onDismissed?.call();
      _showNextToast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return Stack(
      children: [
        widget.child,
        if (_currentToast != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colors.isDark
                          ? const Color(0xFF38383C)
                          : const Color(0xFF2E2E32),
                      borderRadius: BorderRadius.circular(AdwMetrics.pillRadius),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x38000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DefaultTextStyle(
                          style: theme.typography.body.copyWith(
                            color: const Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w500,
                          ),
                          child: _currentToast!.title,
                        ),
                        if (_currentToast!.action != null) ...[
                          const SizedBox(width: 14),
                          _currentToast!.action!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

