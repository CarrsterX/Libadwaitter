import 'package:flutter/widgets.dart';

import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Libadwaita status or welcome page widget (`AdwStatusPage`).
///
/// Displays a prominent central icon/emblem, bold title, explanatory description,
/// and optional action widgets (as seen on the welcome screen of `adwaita-1-demo`).
class AdwStatusPage extends StatelessWidget {
  final Widget? icon;
  final Widget? title;
  final Widget? description;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const AdwStatusPage({
    super.key,
    this.icon,
    this.title,
    this.description,
    this.child,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: 96,
                    color: theme.colors.secondaryForeground.withValues(alpha: 0.7),
                  ),
                  child: icon!,
                ),
                const SizedBox(height: 24),
              ],
              if (title != null) ...[
                DefaultTextStyle(
                  style: theme.typography.title1,
                  textAlign: TextAlign.center,
                  child: title!,
                ),
                const SizedBox(height: 12),
              ],
              if (description != null) ...[
                DefaultTextStyle(
                  style: theme.typography.body.copyWith(
                    color: theme.colors.secondaryForeground,
                  ),
                  textAlign: TextAlign.center,
                  child: description!,
                ),
                const SizedBox(height: 24),
              ],
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}

