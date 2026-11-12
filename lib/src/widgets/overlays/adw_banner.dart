import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_theme.dart';
import '../controls/adw_button.dart';

/// Collapsible informational contextual banner (`AdwBanner`).
///
/// Typically placed directly below an [AdwHeaderBar] to notify
/// critical app states (e.g. "No internet connection", "Update available").
class AdwBanner extends StatefulWidget {
  final Widget title;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final bool revealed;

  const AdwBanner({
    super.key,
    required this.title,
    this.buttonLabel,
    this.onButtonPressed,
    this.revealed = true,
  });

  @override
  State<AdwBanner> createState() => _AdwBannerState();
}

class _AdwBannerState extends State<AdwBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AdwCurves.shortDuration,
      value: widget.revealed ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: AdwCurves.standard,
    );
  }

  @override
  void didUpdateWidget(covariant AdwBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed != oldWidget.revealed) {
      if (widget.revealed) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colors.cardBackground,
          border: Border(
            bottom: BorderSide(
              color: theme.colors.dividerColor,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: theme.typography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                child: widget.title,
              ),
            ),
            if (widget.buttonLabel != null) ...[
              const SizedBox(width: 12),
              AdwButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                onPressed: widget.onButtonPressed,
                child: Text(widget.buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

