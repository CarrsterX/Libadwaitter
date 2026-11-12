import 'package:flutter/widgets.dart';

import '../../theme/adw_theme.dart';

/// Official Libadwaita window title widget (`AdwWindowTitle`).
///
/// Centers a primary window title and an optional subtitle with official Libadwaita
/// typography and subtle secondary text styling.
class AdwWindowTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AdwWindowTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.typography.heading,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text(
              subtitle!,
              style: theme.typography.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

