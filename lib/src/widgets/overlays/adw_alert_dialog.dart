import 'package:flutter/widgets.dart';

import '../../theme/adw_curves.dart';
import '../../theme/adw_metrics.dart';
import '../../theme/adw_theme.dart';

/// Modern Libadwaita alert dialog (`AdwAlertDialog`).
///
/// Replaces legacy GTK dialogs with a clean, centered layout,
/// 14px rounded corners ([AdwMetrics.dialogRadius]), and styled response action buttons.
class AdwAlertDialog extends StatelessWidget {
  final Widget? heading;
  final Widget? body;
  final Widget? content;
  final List<Widget> actions;

  const AdwAlertDialog({
    super.key,
    this.heading,
    this.body,
    this.content,
    this.actions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 420,
        ),
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
                color: Color(0x4D000000),
                blurRadius: 24,
                spreadRadius: 2,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (heading != null)
                      DefaultTextStyle(
                        style: theme.typography.title3,
                        textAlign: TextAlign.center,
                        child: heading!,
                      ),
                    if (body != null) ...[
                      const SizedBox(height: 8),
                      DefaultTextStyle(
                        style: theme.typography.body.copyWith(
                          color: theme.colors.secondaryForeground,
                        ),
                        textAlign: TextAlign.center,
                        child: body!,
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: 16),
                      content!,
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                Container(
                  height: 1,
                  color: theme.colors.dividerColor,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: actions[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays an [AdwAlertDialog] with smooth GNOME transition animation.
Future<T?> showAdwAlertDialog<T>({
  required BuildContext context,
  Widget? heading,
  Widget? body,
  Widget? content,
  List<Widget> actions = const <Widget>[],
  bool barrierDismissible = true,
}) {
  final themeData = AdwTheme.maybeOf(context);

  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: barrierDismissible,
      barrierColor: const Color(0x66000000),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        Widget dialog = AdwAlertDialog(
          heading: heading,
          body: body,
          content: content,
          actions: actions,
        );
        if (AdwTheme.maybeOf(dialogContext) == null && themeData != null) {
          dialog = AdwTheme(data: themeData, child: dialog);
        }
        return dialog;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AdwCurves.standard,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale:
                Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    ),
  );
}
