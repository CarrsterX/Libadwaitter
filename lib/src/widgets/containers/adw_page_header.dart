import 'package:flutter/widgets.dart';

import '../../theme/adw_theme.dart';

/// Builds the centered optional header widgets (`icon`, `title`, `description`)
/// shared between `AdwStatusPage` and `AdwPreferencesPage`.
List<Widget> buildAdwPageHeader({
  required AdwThemeData theme,
  Widget? icon,
  Widget? title,
  Widget? description,
  bool hasContentAfter = false,
}) {
  return [
    if (icon != null) ...[
      Center(
        child: IconTheme(
          data: IconThemeData(
            size: 128,
            color: theme.colors.isDark
                ? theme.colors.secondaryForeground.withValues(alpha: 0.55)
                : const Color(0xFF8C8C90),
          ),
          child: icon,
        ),
      ),
      if (title != null || description != null || hasContentAfter)
        const SizedBox(height: 36),
    ],
    if (title != null) ...[
      DefaultTextStyle(
        style: theme.typography.title1,
        textAlign: TextAlign.center,
        child: title,
      ),
      if (description != null)
        const SizedBox(height: 10)
      else if (hasContentAfter)
        const SizedBox(height: 38),
    ],
    if (description != null) ...[
      DefaultTextStyle(
        style: theme.typography.body.copyWith(
          color: theme.colors.secondaryForeground,
        ),
        textAlign: TextAlign.center,
        child: description,
      ),
      if (hasContentAfter) const SizedBox(height: 38),
    ],
  ];
}

