import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

/// Displays the Colors modal dialog for switching between Light, Dark, and
/// System themes, as well as choosing an Accent Color or Adaptive System Color.
Future<void> showDemoColorsDialog({
  required BuildContext context,
  required AdwThemeMode currentThemeMode,
  required AdwAccentColor? currentAccent,
  required ValueChanged<AdwThemeMode> onThemeModeChanged,
  required ValueChanged<AdwAccentColor?> onAccentChanged,
}) {
  return showAdwDialog<void>(
    context: context,
    builder: (dialogContext) => _DemoColorsDialog(
      initialThemeMode: currentThemeMode,
      initialAccent: currentAccent,
      onThemeModeChanged: onThemeModeChanged,
      onAccentChanged: onAccentChanged,
    ),
  );
}

class _DemoColorsDialog extends StatefulWidget {
  const _DemoColorsDialog({
    required this.initialThemeMode,
    required this.initialAccent,
    required this.onThemeModeChanged,
    required this.onAccentChanged,
  });

  final AdwThemeMode initialThemeMode;
  final AdwAccentColor? initialAccent;
  final ValueChanged<AdwThemeMode> onThemeModeChanged;
  final ValueChanged<AdwAccentColor?> onAccentChanged;

  @override
  State<_DemoColorsDialog> createState() => _DemoColorsDialogState();
}

class _DemoColorsDialogState extends State<_DemoColorsDialog> {
  late AdwThemeMode _themeMode = widget.initialThemeMode;
  late AdwAccentColor? _accent = widget.initialAccent;

  void _selectThemeMode(AdwThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.onThemeModeChanged(mode);
  }

  void _selectAccent(AdwAccentColor? accent) {
    setState(() => _accent = accent);
    widget.onAccentChanged(accent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final accentColor = theme.colors.accentColor;

    return AdwDialog(
      title: 'Colors',
      contentWidth: 480,
      contentHeight: 520,
      child: AdwToolbarView(
        topBar: const AdwHeaderBar(
          isFlat: true,
          showBackButton: false,
          title: Text('Colors'),
        ),
        content: AdwPreferencesPage(
          children: [
            AdwPreferencesGroup(
              title: const Text('Color Scheme'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ThemeSwatch(
                        mode: AdwThemeMode.system,
                        label: 'System',
                        selected: _themeMode == AdwThemeMode.system,
                        accentColor: accentColor,
                        onTap: () => _selectThemeMode(AdwThemeMode.system),
                      ),
                      _ThemeSwatch(
                        mode: AdwThemeMode.light,
                        label: 'Light',
                        selected: _themeMode == AdwThemeMode.light,
                        accentColor: accentColor,
                        onTap: () => _selectThemeMode(AdwThemeMode.light),
                      ),
                      _ThemeSwatch(
                        mode: AdwThemeMode.dark,
                        label: 'Dark',
                        selected: _themeMode == AdwThemeMode.dark,
                        accentColor: accentColor,
                        onTap: () => _selectThemeMode(AdwThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AdwPreferencesGroup(
              title: const Text('Accent Color'),
              description: const Text(
                'Choose a highlight color or use the adaptive system color from GNOME or Android.',
              ),
              children: [
                AdwActionRow(
                  title: const Text('Adaptive System Color'),
                  subtitle: const Text(
                    'Automatically follows GNOME or Android system accent',
                  ),
                  onPressed: () => _selectAccent(null),
                  trailing: _accent == null
                      ? Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const CustomPaint(
                            painter: _CheckPainter(
                              color: Color(0xFFFFFFFF),
                              strokeWidth: 2.0,
                            ),
                          ),
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colors.borderColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final accent in AdwAccentColor.values)
                        _AccentSwatch(
                          accent: accent,
                          selected: _accent == accent,
                          onTap: () => _selectAccent(accent),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatefulWidget {
  const _ThemeSwatch({
    required this.mode,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final AdwThemeMode mode;
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_ThemeSwatch> createState() => _ThemeSwatchState();
}

class _ThemeSwatchState extends State<_ThemeSwatch> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (focused) {
          if (_isFocused != focused) setState(() => _isFocused = focused);
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (_isFocused)
                      Positioned(
                        left: -1,
                        right: -1,
                        top: -1,
                        bottom: -1,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colors.focusBorderColor,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.selected
                                ? widget.accentColor
                                : theme.colors.foreground
                                    .withValues(alpha: 0.16),
                            width: widget.selected ? 2.5 : 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: CustomPaint(
                              painter: _ThemeCirclePainter(mode: widget.mode),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.selected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const CustomPaint(
                            painter: _CheckPainter(
                              color: Color(0xFFFFFFFF),
                              strokeWidth: 2.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: theme.typography.caption.copyWith(
                  color: widget.selected
                      ? theme.colors.foreground
                      : theme.colors.secondaryForeground,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCirclePainter extends CustomPainter {
  const _ThemeCirclePainter({required this.mode});

  final AdwThemeMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const lightColor = Color(0xFFFFFFFF);
    const darkColor = Color(0xFF222226);

    switch (mode) {
      case AdwThemeMode.light:
        canvas.drawRect(rect, Paint()..color = lightColor);
      case AdwThemeMode.dark:
        canvas.drawRect(rect, Paint()..color = darkColor);
      case AdwThemeMode.system:
        canvas.drawRect(rect, Paint()..color = darkColor);
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, Paint()..color = lightColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeCirclePainter oldDelegate) {
    return mode != oldDelegate.mode;
  }
}

class _AccentSwatch extends StatefulWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AdwAccentColor accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AccentSwatch> createState() => _AccentSwatchState();
}

class _AccentSwatchState extends State<_AccentSwatch> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.accent.name,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (focused) {
          if (_isFocused != focused) setState(() => _isFocused = focused);
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (_isFocused)
                Positioned(
                  left: -3.5,
                  right: -3.5,
                  top: -3.5,
                  bottom: -3.5,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colors.focusBorderColor,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: widget.selected
                      ? Border.all(
                          color: theme.colors.foreground,
                          width: 2.5,
                        )
                      : null,
                ),
                padding: EdgeInsets.all(widget.selected ? 2.5 : 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.accent.color,
                    shape: BoxShape.circle,
                  ),
                  child: widget.selected
                      ? const CustomPaint(
                          painter: _CheckPainter(
                            color: Color(0xFFFFFFFF),
                            strokeWidth: 2.0,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({
    required this.color,
    this.strokeWidth = 2.0,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.27, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.69)
      ..lineTo(size.width * 0.75, size.height * 0.34);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    return color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
  }
}
