import 'package:flutter/widgets.dart';

import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';
import '../layout/adw_clamp.dart';
import 'adw_page_header.dart';

/// Scrollable preferences and boxed-list page (`AdwPreferencesPage`).
///
/// Lays out [children] (typically [AdwPreferencesGroup] widgets) inside a
/// clamped scrollable column with uniform inter-group spacing ([groupSpacing])
/// and optional header metadata ([icon], [title], [description]).
class AdwPreferencesPage extends StatelessWidget {
  final Widget? icon;
  final Widget? title;
  final Widget? description;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final double minimumMargin;
  final double groupSpacing;

  const AdwPreferencesPage({
    super.key,
    this.icon,
    this.title,
    this.description,
    required this.children,
    this.padding,
    this.maxWidth = AdwMetrics.preferencesPageMaxWidth,
    this.minimumMargin = 16.0,
    this.groupSpacing = AdwMetrics.preferencesGroupSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final hasHeader = icon != null || title != null || description != null;
    final resolvedPadding = padding ??
        (hasHeader
            ? const EdgeInsets.only(top: 38.0, bottom: 35.0)
            : const EdgeInsets.symmetric(vertical: 24.0));

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: resolvedPadding,
      child: AdwClamp(
        maximumSize: maxWidth,
        minimumMargin: minimumMargin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...buildAdwPageHeader(
              theme: theme,
              icon: icon,
              title: title,
              description: description,
              hasContentAfter: children.isNotEmpty,
            ),
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1 && groupSpacing > 0)
                SizedBox(height: groupSpacing),
            ],
          ],
        ),
      ),
    );
  }
}

