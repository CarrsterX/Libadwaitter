import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

/// Displays the demo Preferences modal (`AdwDemoPreferencesDialog`) matching
/// `adw-demo-preferences-dialog.ui` / `adw-demo-preferences-dialog.c`.
Future<void> showAdwDemoPreferencesDialog(BuildContext context) {
  return showAdwPreferencesDialog<void>(
    context: context,
    contentWidth: 640,
    contentHeight: 920,
    pages: [
      AdwPreferencesDialogPage(
        title: 'Layout',
        icon: const _PreferencesLayoutIcon(),
        description: const Text('Preferences pages can have a description'),
        banner: const AdwBanner(
          title: Text('Preferences pages can have a banner'),
          revealed: true,
        ),
        children: [
          const AdwPreferencesGroup(
            title: Text('Pages'),
            description: Text(
              'Preferences are organized in pages, this example has the following pages:',
            ),
            children: [
              AdwActionRow(
                title: Text('Layout'),
                isActivatable: false,
              ),
              AdwActionRow(
                title: Text('Search'),
                isActivatable: false,
              ),
            ],
          ),
          const AdwPreferencesGroup(
            title: Text('Groups'),
            description: Text(
              'Preferences are grouped together, a group can have a title and a description. Descriptions will be wrapped if they are too long. This page has the following groups:',
            ),
            children: [
              AdwActionRow(
                title: Text('An Untitled Group'),
                isActivatable: false,
              ),
              AdwActionRow(
                title: Text('Pages'),
                isActivatable: false,
              ),
              AdwActionRow(
                title: Text('Groups'),
                isActivatable: false,
              ),
              AdwActionRow(
                title: Text('Preferences'),
                isActivatable: false,
              ),
            ],
          ),
          Builder(
            builder: (groupContext) {
              final theme = AdwTheme.of(groupContext);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AdwPreferencesGroup(
                    title: Text('Preferences'),
                    children: [
                      AdwActionRow(
                        title: Text(
                            'Preferences rows are appended to the list box'),
                        isActivatable: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Other widgets are appended after the list box',
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.copyWith(
                        color: theme.colors.foreground.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          AdwPreferencesGroup(
            title: const Text('Toasts'),
            children: [
              Builder(
                builder: (rowContext) => AdwActionRow(
                  title: const Text('Show a Toast'),
                  isActivatable: false,
                  trailing: AdwButton(
                    onPressed: () {
                      AdwPreferencesDialogScope.maybeOf(rowContext)?.addToast(
                        const AdwToast(title: Text('Example Toast')),
                      );
                    },
                    child: const Text('Show'),
                  ),
                ),
              ),
            ],
          ),
          Builder(
            builder: (subpageContext) => AdwPreferencesGroup(
              title: const Text('Subpages'),
              description: const Text('Preferences dialogs can have subpages'),
              children: [
                AdwActionRow(
                  title: const Text('Open Subpage'),
                  trailing: const Icon(AdwIcons.go_next_symbolic, size: 16),
                  onPressed: () => _pushSubpage1(subpageContext),
                ),
                AdwActionRow(
                  title: const Text('Open Another Subpage'),
                  trailing: const Icon(AdwIcons.go_next_symbolic, size: 16),
                  onPressed: () => _pushSubpage2(subpageContext),
                ),
              ],
            ),
          ),
        ],
      ),
      const AdwPreferencesDialogPage(
        title: 'Search',
        icon: Icon(AdwIcons.edit_find_symbolic, size: 16),
        children: [
          AdwPreferencesGroup(
            title: Text('Searching'),
            description: Text(
              'Preferences can be searched, do so using one of the following ways:',
            ),
            children: [
              AdwActionRow(
                title: Text('Activate the Search Button'),
                isActivatable: false,
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AdwShortcutLabel(accelerator: '<ctrl>f'),
                ),
              ),
              AdwActionRow(
                title: Text('Directly Type Your Search'),
                isActivatable: false,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void _pushSubpage1(BuildContext context) {
  final scope = AdwPreferencesDialogScope.maybeOf(context);
  if (scope == null) return;
  scope.pushSubpage(
    AdwNavigationPage(
      title: 'Subpage',
      child: AdwToolbarView(
        topBar: const AdwHeaderBar(isFlat: true),
        content: AdwStatusPage(
          title: const Text('This Is a Subpage'),
          child: AdwButton.pill(
            onPressed: () => _pushSubpage2(context),
            child: const Text('Open Another Subpage'),
          ),
        ),
      ),
    ),
  );
}

void _pushSubpage2(BuildContext context) {
  final scope = AdwPreferencesDialogScope.maybeOf(context);
  if (scope == null) return;
  scope.pushSubpage(
    const AdwNavigationPage(
      title: 'Another Subpage',
      child: AdwToolbarView(
        topBar: AdwHeaderBar(isFlat: true),
        content: AdwStatusPage(
          title: Text('This Is Another Subpage'),
        ),
      ),
    ),
  );
}

class _PreferencesLayoutIcon extends StatelessWidget {
  const _PreferencesLayoutIcon();

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? AdwTheme.of(context).colors.foreground;
    return CustomPaint(
      size: const Size(16, 16),
      painter: _PreferencesLayoutPainter(color: color),
    );
  }
}

class _PreferencesLayoutPainter extends CustomPainter {
  const _PreferencesLayoutPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 16.0;
    final sy = size.height / 16.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * sx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Matches libadwaita/demo/icons/preferences-window-layout.svg (16x16)
    canvas.drawRRect(
      RRect.fromLTRBR(1 * sx, 1 * sy, 8 * sx, 6 * sy, Radius.circular(2 * sx)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        11 * sx,
        1 * sy,
        15 * sx,
        6 * sy,
        Radius.circular(1.5 * sx),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        1 * sx,
        9 * sy,
        5 * sx,
        15 * sy,
        Radius.circular(1.5 * sx),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        8 * sx,
        9 * sy,
        15 * sx,
        15 * sy,
        Radius.circular(2.0885 * sx),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PreferencesLayoutPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
