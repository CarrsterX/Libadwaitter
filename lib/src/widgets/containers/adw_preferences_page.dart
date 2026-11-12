import 'package:flutter/widgets.dart';

import '../../theme/adw_metrics.dart';

/// Preferences and settings page (`AdwPreferencesPage`).
///
/// Lays out [AdwPreferencesGroup] widgets in a scrollable view,
/// clamping the maximum width to 640px to ensure comfortable readability
/// on widescreen displays according to GNOME Human Interface Guidelines.
class AdwPreferencesPage extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  const AdwPreferencesPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    this.maxWidth = AdwMetrics.preferencesPageMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

