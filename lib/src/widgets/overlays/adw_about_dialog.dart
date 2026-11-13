import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';
import '../controls/adw_button.dart';
import '../display/adw_emblem.dart';

/// Official GNOME Libadwaita about dialog (`AdwAboutDialog`).
///
/// Presents application details, developer credits, GitLab repository links, version,
/// and licensing information in alignment with the official Libadwaita 1.5+ specification.
class AdwAboutDialog extends StatelessWidget {
  final Widget? applicationIcon;
  final String applicationName;
  final String? developerName;
  final String? version;
  final String? comments;
  final String? website;
  final String? copyright;
  final String? license;

  const AdwAboutDialog({
    super.key,
    this.applicationIcon,
    required this.applicationName,
    this.developerName,
    this.version,
    this.comments,
    this.website,
    this.copyright,
    this.license,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colors.dialogBackground,
            borderRadius: BorderRadius.circular(AdwMetrics.dialogRadius),
            border: Border.all(
              color: theme.colors.borderColor,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 32,
                spreadRadius: 0,
                offset: Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (applicationIcon != null)
                applicationIcon!
              else
                const AdwEmblem(size: 80),
              const SizedBox(height: 16),
              Text(
                applicationName,
                style: theme.typography.title1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (version != null) ...[
                const SizedBox(height: 4),
                Text(
                  version!,
                  style: theme.typography.caption.copyWith(
                    color: theme.colors.secondaryForeground,
                  ),
                ),
              ],
              if (developerName != null) ...[
                const SizedBox(height: 8),
                Text(
                  developerName!,
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (comments != null) ...[
                const SizedBox(height: 14),
                Text(
                  comments!,
                  textAlign: TextAlign.center,
                  style: theme.typography.body.copyWith(
                    color: theme.colors.secondaryForeground,
                    height: 1.35,
                  ),
                ),
              ],
              if (website != null) ...[
                const SizedBox(height: 12),
                Text(
                  website!,
                  style: theme.typography.body.copyWith(
                    color: theme.colors.accentColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
              if (copyright != null) ...[
                const SizedBox(height: 16),
                Text(
                  copyright!,
                  textAlign: TextAlign.center,
                  style: theme.typography.caption.copyWith(
                    color: theme.colors.secondaryForeground.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
              if (license != null) ...[
                const SizedBox(height: 4),
                Text(
                  license!,
                  style: theme.typography.caption.copyWith(
                    color: theme.colors.secondaryForeground.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AdwButton(
                isPill: true,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays a modal [AdwAboutDialog].
Future<void> showAdwAboutDialog({
  required BuildContext context,
  Widget? applicationIcon,
  required String applicationName,
  String? developerName,
  String? version,
  String? comments,
  String? website,
  String? copyright,
  String? license,
}) {
  final themeData = AdwTheme.maybeOf(context);

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'About Dialog',
    barrierColor: const Color(0x66000000),
    transitionDuration: AdwCurves.shortDuration,
    pageBuilder: (ctx, anim1, anim2) {
      Widget dialog = AdwAboutDialog(
        applicationIcon: applicationIcon,
        applicationName: applicationName,
        developerName: developerName,
        version: version,
        comments: comments,
        website: website,
        copyright: copyright,
        license: license,
      );

      if (themeData != null) {
        dialog = AdwTheme(data: themeData, child: dialog);
      }
      return dialog;
    },
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curve = CurvedAnimation(
        parent: anim,
        curve: AdwCurves.standard,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
          child: child,
        ),
      );
    },
  );
}

