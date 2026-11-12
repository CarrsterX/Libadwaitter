import 'package:flutter/widgets.dart';

import '../../theme/adw_theme.dart';

/// Structured toolbar and content layout container (`AdwToolbarView`).
///
/// Coordinates top bars (such as [AdwHeaderBar]), central scrollable content,
/// and optional bottom action bars in alignment with the Libadwaita 1.4+ architecture.
class AdwToolbarView extends StatelessWidget {
  final Widget? topBar;
  final Widget content;
  final Widget? bottomBar;

  const AdwToolbarView({
    super.key,
    this.topBar,
    required this.content,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return Container(
      color: theme.colors.windowBackground,
      child: Column(
        children: [
          if (topBar != null) topBar!,
          Expanded(child: content),
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );
  }
}

