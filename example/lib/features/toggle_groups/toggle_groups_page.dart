import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class ToggleGroupsPage extends StatefulWidget {
  const ToggleGroupsPage({super.key});

  @override
  State<ToggleGroupsPage> createState() => _ToggleGroupsPageState();
}

class _ToggleGroupsPageState extends State<ToggleGroupsPage> {
  String _timeFormat = '24';
  String _viewMode = 'grid';
  String _alignment = 'left';
  String _cameraMode = 'picture';

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.toggleGroup, size: 128),
      title: const Text('Toggle Groups'),
      description: const Text('A group of toggle buttons'),
      maxWidth: 400.0,
      padding: const EdgeInsets.fromLTRB(0, 36, 0, 36),
      child: AdwPreferencesGroup(
        margin: const EdgeInsets.only(top: 10),
        children: [
            AdwActionRow(
              title: const Text('Group with Labels'),
              suffix: AdwToggleGroup<String>(
                selectedValue: _timeFormat,
                onChanged: (val) => setState(() => _timeFormat = val),
                items: const [
                  AdwToggleItem(
                    value: '24',
                    label: Text('24-hour'),
                  ),
                  AdwToggleItem(
                    value: '12',
                    label: Text('AM / PM'),
                  ),
                ],
              ),
            ),
            AdwActionRow(
              title: const Text('Group with Icons'),
              suffix: AdwToggleGroup<String>(
                selectedValue: _viewMode,
                onChanged: (val) => setState(() => _viewMode = val),
                items: const [
                  AdwToggleItem(
                    value: 'grid',
                    icon: Icon(AdwIcons.view_grid_symbolic),
                    tooltip: 'Grid View',
                  ),
                  AdwToggleItem(
                    value: 'list',
                    icon: Icon(AdwIcons.view_list_symbolic),
                    tooltip: 'List View',
                  ),
                  AdwToggleItem(
                    value: 'columns',
                    icon: _DualViewIcon(),
                    tooltip: 'Dual View',
                  ),
                ],
              ),
            ),
            AdwActionRow(
              title: const Text('Flat Group'),
              suffix: AdwToggleGroup<String>(
                style: AdwToggleGroupStyle.flat,
                selectedValue: _alignment,
                onChanged: (val) => setState(() => _alignment = val),
                items: const [
                  AdwToggleItem(
                    value: 'left',
                    icon: Icon(AdwIcons.format_justify_left_symbolic),
                    tooltip: 'Left Align',
                  ),
                  AdwToggleItem(
                    value: 'center',
                    icon: Icon(AdwIcons.format_justify_center_symbolic),
                    tooltip: 'Center Align',
                  ),
                  AdwToggleItem(
                    value: 'right',
                    icon: Icon(AdwIcons.format_justify_right_symbolic),
                    tooltip: 'Right Align',
                  ),
                  AdwToggleItem(
                    value: 'fill',
                    icon: Icon(AdwIcons.format_justify_fill_symbolic),
                    tooltip: 'Justify',
                  ),
                ],
              ),
            ),
            AdwActionRow(
              title: const Text('Round Group'),
              suffix: AdwToggleGroup<String>(
                style: AdwToggleGroupStyle.round,
                selectedValue: _cameraMode,
                onChanged: (val) => setState(() => _cameraMode = val),
                items: const [
                  AdwToggleItem(
                    value: 'picture',
                    icon: Icon(AdwIcons.camera_photo_symbolic),
                    tooltip: 'Picture Mode',
                  ),
                  AdwToggleItem(
                    value: 'recording',
                    icon: Icon(AdwIcons.camera_video_symbolic),
                    tooltip: 'Recording Mode',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DualViewIcon extends StatelessWidget {
  const _DualViewIcon();

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final fg = theme.colors.isDark
        ? (IconTheme.of(context).color ?? theme.colors.foreground)
        : const Color(0xFF2F2F34);
    final lineColor = theme.colors.isDark
        ? const Color(0xFF838386)
        : const Color(0xFFAEAEB0);

    return CustomPaint(
      size: const Size(16, 16),
      painter: _DualViewIconPainter(
        foreground: fg,
        innerLineColor: lineColor,
      ),
    );
  }
}

class _DualViewIconPainter extends CustomPainter {
  final Color foreground;
  final Color innerLineColor;

  const _DualViewIconPainter({
    required this.foreground,
    required this.innerLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(0, 1, 16, 15),
          const Radius.circular(3.0),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(2, 3, 7, 13),
          const Radius.circular(1.0),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(9, 3, 14, 13),
          const Radius.circular(1.0),
        ),
      );
    canvas.drawPath(outerPath, Paint()..color = foreground);

    final innerPaint = Paint()..color = innerLineColor;
    for (final rect in const [
      Rect.fromLTWH(3, 5, 3, 2),
      Rect.fromLTWH(10, 5, 3, 2),
      Rect.fromLTWH(3, 8, 3, 2),
      Rect.fromLTWH(10, 8, 3, 2),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(0.5)),
        innerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DualViewIconPainter oldDelegate) {
    return foreground != oldDelegate.foreground ||
        innerLineColor != oldDelegate.innerLineColor;
  }
}
