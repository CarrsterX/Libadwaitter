import 'package:flutter/widgets.dart';

import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Container group for preferences (`AdwPreferencesGroup`).
///
/// Groups preference rows ([AdwActionRow], [AdwSwitchRow], [AdwExpanderRow], etc.)
/// inside a rounded card (12px) with subtle 1px dividers between items.
class AdwPreferencesGroup extends StatelessWidget {
  final Widget? title;
  final Widget? description;
  final Widget? headerSuffix;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final bool separated;

  const AdwPreferencesGroup({
    super.key,
    this.title,
    this.description,
    this.headerSuffix,
    this.children = const <Widget>[],
    this.margin =
        const EdgeInsets.only(bottom: AdwMetrics.preferencesGroupSpacing),
    this.separated = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    final List<Widget> itemsWithDividers = [];
    for (int i = 0; i < children.length; i++) {
      itemsWithDividers.add(children[i]);
      if (i < children.length - 1) {
        itemsWithDividers.add(
          Container(
            height: 1,
            color: theme.colors.isDark
                ? theme.colors.windowBackground
                : theme.colors.dividerColor,
          ),
        );
      }
    }

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || headerSuffix != null)
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 2, bottom: 10),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: DefaultTextStyle(
                        style: theme.typography.heading,
                        child: title!,
                      ),
                    ),
                  if (headerSuffix != null) headerSuffix!,
                ],
              ),
            ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: DefaultTextStyle(
                style: theme.typography.subtitle,
                child: description!,
              ),
            ),
          if (children.isNotEmpty && !separated)
            Container(
              decoration: BoxDecoration(
                color: theme.colors.cardBackground,
                borderRadius: BorderRadius.circular(AdwMetrics.cardRadius),
                boxShadow: theme.colors.isDark
                    ? const [
                        BoxShadow(
                          color: Color(0x28000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 3,
                          spreadRadius: 1,
                          offset: Offset(0, 1),
                        ),
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 6,
                          spreadRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: itemsWithDividers,
              ),
            ),
          if (children.isNotEmpty && separated)
            for (int i = 0; i < children.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i < children.length - 1 ? 12.0 : 0.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colors.cardBackground,
                    borderRadius: BorderRadius.circular(AdwMetrics.cardRadius),
                    boxShadow: theme.colors.isDark
                        ? const [
                            BoxShadow(
                              color: Color(0x28000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 3,
                              spreadRadius: 1,
                              offset: Offset(0, 1),
                            ),
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 6,
                              spreadRadius: 2,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: children[i],
                ),
              ),
        ],
      ),
    );
  }
}
