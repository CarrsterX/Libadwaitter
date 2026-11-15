import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

/// Opens a secondary native [AdwWindow] showcasing `AdwTabView`, `AdwTabBar`,
/// `AdwTabOverview`, and `AdwTabButton` with 1:1 parity to `adwaita-1-demo`.
AdwTabViewController openTabViewDemoWindow({bool createInitialTab = true}) {
  final tabController = AdwTabViewController();
  late final AdwSubWindowHandle windowHandle;
  tabController.onEmpty = () {
    windowHandle.close();
  };
  tabController.onCreateWindow = (page) {
    return openTabViewDemoWindow(createInitialTab: false);
  };

  windowHandle = AdwSubWindowManager.instance.openWindow(
    size: const Size(800, 600),
    title: 'Tab View Demo',
    builder: (context, handle) => _TabViewDemoWindowContent(
      controller: tabController,
      windowHandle: handle,
      createInitialTab: createInitialTab,
      onOpenNewWindow: ({bool createInitialTab = true}) =>
          openTabViewDemoWindow(createInitialTab: createInitialTab),
    ),
  );
  return tabController;
}

class _TabPageMeta {
  int colorIndex;
  bool hasIcon;
  int iconIndex;
  bool hasIndicator;
  bool isMuted;

  _TabPageMeta({
    required this.colorIndex,
    this.hasIcon = true,
    required this.iconIndex,
    this.hasIndicator = false,
    this.isMuted = false,
  });
}

class _TabViewDemoWindowContent extends StatefulWidget {
  final AdwTabViewController controller;
  final AdwSubWindowHandle windowHandle;
  final bool createInitialTab;
  final AdwTabViewController Function({bool createInitialTab}) onOpenNewWindow;

  const _TabViewDemoWindowContent({
    required this.controller,
    required this.windowHandle,
    required this.createInitialTab,
    required this.onOpenNewWindow,
  });

  @override
  State<_TabViewDemoWindowContent> createState() =>
      _TabViewDemoWindowContentState();
}

class _TabViewDemoWindowContentState extends State<_TabViewDemoWindowContent> {
  static int _globalTabCounter = 1;
  static int _globalColorCounter = 0;

  static const List<DemoIconType> _demoSymbolicIcons = <DemoIconType>[
    DemoIconType.clockWorld,
    DemoIconType.clockAlarm,
    DemoIconType.clockStopwatch,
    DemoIconType.clockTimer,
    DemoIconType.viewSwitcher,
    DemoIconType.tabView,
  ];

  bool _overviewOpen = false;
  AdwTabPage? _contextMenuPage;
  Offset? _contextMenuPosition;

  @override
  void initState() {
    super.initState();
    widget.controller.onIndicatorActivated = _handleIndicatorActivated;
    if (widget.createInitialTab && widget.controller.nPages == 0) {
      _addNewTab();
    }
  }

  static Color _resolveTabPageColor(int colorIndex, bool isDark) {
    final idx = colorIndex % 8;
    if (idx == 7) {
      return isDark ? const Color(0xFF363636) : const Color(0xFFFFFFFF);
    }
    const hues = <double>[
      211.0,
      138.0,
      48.0,
      28.0,
      356.0,
      280.0,
      25.0,
    ];
    const sats = <double>[0.86, 0.65, 0.90, 0.92, 0.78, 0.60, 0.45];
    return HSLColor.fromAHSL(
      1.0,
      hues[idx],
      sats[idx],
      isDark ? 0.20 : 0.92,
    ).toColor();
  }

  void _syncPageAppearance(AdwTabPage page, bool isDark) {
    final meta = page.userData as _TabPageMeta?;
    if (meta == null) return;
    page.thumbnailColor = _resolveTabPageColor(meta.colorIndex, isDark);
    page.icon = meta.hasIcon
        ? DemoWidgetIcon(
            _demoSymbolicIcons[meta.iconIndex % _demoSymbolicIcons.length],
            size: 16,
          )
        : null;
    if (meta.hasIndicator) {
      page.indicatorIcon = CustomPaint(
        size: const Size(16, 16),
        painter: _TabAudioIndicatorPainter(
          isMuted: meta.isMuted,
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E1E1E),
        ),
      );
      page.indicatorTooltip = meta.isMuted ? 'Unmute Tab' : 'Mute Tab';
    } else {
      page.indicatorIcon = null;
      page.indicatorTooltip = null;
    }
  }

  void _handleIndicatorActivated(AdwTabPage page) {
    final meta = page.userData as _TabPageMeta?;
    if (meta == null || !meta.hasIndicator) return;
    meta.isMuted = !meta.isMuted;
    final isDark = AdwTheme.of(context).colors.isDark;
    _syncPageAppearance(page, isDark);
  }

  AdwTabPage _createPage({
    required String title,
    required _TabPageMeta meta,
  }) {
    late final AdwTabPage page;
    page = AdwTabPage(
      title: title,
      userData: meta,
      child: Builder(
        builder: (pageContext) {
          final isDark = AdwTheme.of(pageContext).colors.isDark;
          final bgColor = _resolveTabPageColor(meta.colorIndex, isDark);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            page.thumbnailColor = bgColor;
          });
          return _TabViewDemoPageBody(
            page: page,
            backgroundColor: bgColor,
            isDark: isDark,
          );
        },
      ),
    );
    final isDark = AdwStyleManager.instance.isDark;
    _syncPageAppearance(page, isDark);
    return page;
  }

  void _addNewTab() {
    final num = _globalTabCounter++;
    final colorIdx = _globalColorCounter++;
    final meta = _TabPageMeta(
      colorIndex: colorIdx,
      hasIcon: true,
      iconIndex: colorIdx,
    );
    final page = _createPage(title: 'Tab $num', meta: meta);
    widget.controller.addPage(page, select: true);
  }

  void _duplicateTab(AdwTabPage source) {
    final srcMeta = source.userData as _TabPageMeta?;
    final meta = _TabPageMeta(
      colorIndex: srcMeta?.colorIndex ?? (_globalColorCounter++),
      hasIcon: srcMeta?.hasIcon ?? true,
      iconIndex: srcMeta?.iconIndex ?? 0,
      hasIndicator: srcMeta?.hasIndicator ?? false,
      isMuted: srcMeta?.isMuted ?? false,
    );
    final copy = _createPage(title: source.title, meta: meta)
      ..loading = source.loading
      ..needsAttention = source.needsAttention;
    final idx = widget.controller.pages.indexOf(source);
    widget.controller.insertPage(copy, idx + 1, select: true);
  }

  void _showContextMenu(
    BuildContext context,
    AdwTabPage page,
    Offset globalPosition,
  ) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final localPos =
        box != null ? box.globalToLocal(globalPosition) : globalPosition;
    setState(() {
      _contextMenuPage = page;
      _contextMenuPosition = localPos;
    });
  }

  void _dismissContextMenu() {
    if (_contextMenuPage != null) {
      setState(() {
        _contextMenuPage = null;
        _contextMenuPosition = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final fg = theme.colors.windowForeground;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth <= 600;

        return Stack(
          fit: StackFit.expand,
          children: [
            AdwTabOverview(
              controller: widget.controller,
              open: _overviewOpen,
              onOpenChanged: (open) => setState(() => _overviewOpen = open),
              enableNewTab: true,
              onCreateTab: _addNewTab,
              onContextMenu: (_, page, pos) =>
                  _showContextMenu(context, page, pos),
              child: AdwToolbarView(
                topBar: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdwHeaderBar(
                      title: const Text('Tab View Demo'),
                      start: AdwButton.flat(
                        width: 34,
                        height: 34,
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            widget.onOpenNewWindow(createInitialTab: true),
                        child: CustomPaint(
                          size: const Size(16, 16),
                          painter: _WindowNewSymbolicPainter(color: fg),
                        ),
                      ),
                      end: isNarrow
                          ? AdwTabButton(
                              controller: widget.controller,
                              onPressed: () =>
                                  setState(() => _overviewOpen = true),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AdwButton.flat(
                                  width: 34,
                                  height: 34,
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      setState(() => _overviewOpen = true),
                                  child: CustomPaint(
                                    size: const Size(16, 16),
                                    painter: _ViewGridSymbolicPainter(color: fg),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AdwButton.flat(
                                  width: 34,
                                  height: 34,
                                  padding: EdgeInsets.zero,
                                  onPressed: _addNewTab,
                                  child: CustomPaint(
                                    size: const Size(16, 16),
                                    painter: _TabNewSymbolicPainter(color: fg),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (!isNarrow)
                      Container(
                        color: theme.colors.headerBarBackground,
                        child: AdwTabBar(
                          controller: widget.controller,
                          autohide: true,
                          isInline: true,
                          onContextMenu: (_, page, pos) =>
                              _showContextMenu(context, page, pos),
                        ),
                      ),
                  ],
                ),
                content: AdwTabView(
                  controller: widget.controller,
                  onNewTabShortcut: _addNewTab,
                ),
              ),
            ),
            if (_contextMenuPage != null && _contextMenuPosition != null)
              _buildTabContextMenuOverlay(
                context: context,
                constraints: constraints,
                theme: theme,
                page: _contextMenuPage!,
                position: _contextMenuPosition!,
              ),
          ],
        );
      },
    );
  }

  Widget _buildTabContextMenuOverlay({
    required BuildContext context,
    required BoxConstraints constraints,
    required AdwThemeData theme,
    required AdwTabPage page,
    required Offset position,
  }) {
    final meta = page.userData as _TabPageMeta?;
    final isDark = theme.colors.isDark;
    const menuWidth = 220.0;
    const menuHeight = 360.0;
    final double left = position.dx
        .clamp(8.0, math.max(8.0, constraints.maxWidth - menuWidth - 8.0))
        .toDouble();
    final double top = position.dy
        .clamp(8.0, math.max(8.0, constraints.maxHeight - menuHeight - 8.0))
        .toDouble();

    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _dismissContextMenu(),
          child: const SizedBox.expand(),
        ),
        Positioned(
          left: left,
          top: top,
          width: menuWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: theme.colors.popoverBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colors.dividerColor,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!page.pinned) ...[
                  _TabMenuItem(
                    label: 'Move to New Window',
                    enabled: widget.controller.nPages > 1,
                    onTap: () {
                      _dismissContextMenu();
                      final target =
                          widget.onOpenNewWindow(createInitialTab: false);
                      widget.controller.transferPage(page, target);
                    },
                  ),
                  _TabMenuItem(
                    label: 'Duplicate',
                    onTap: () {
                      _dismissContextMenu();
                      _duplicateTab(page);
                    },
                  ),
                  _buildMenuDivider(theme),
                ],
                _TabMenuItem(
                  label: page.pinned ? 'Unpin Tab' : 'Pin Tab',
                  onTap: () {
                    _dismissContextMenu();
                    widget.controller.setPagePinned(page, !page.pinned);
                  },
                ),
                _buildMenuDivider(theme),
                _TabMenuItem(
                  label: 'Icon',
                  checked: meta?.hasIcon ?? false,
                  onTap: () {
                    if (meta != null) {
                      meta.hasIcon = !meta.hasIcon;
                      _syncPageAppearance(page, isDark);
                    }
                    _dismissContextMenu();
                  },
                ),
                _TabMenuItem(
                  label: 'Refresh Icon',
                  enabled: meta?.hasIcon ?? false,
                  onTap: () {
                    if (meta != null) {
                      meta.iconIndex++;
                      _syncPageAppearance(page, isDark);
                    }
                    _dismissContextMenu();
                  },
                ),
                _buildMenuDivider(theme),
                _TabMenuItem(
                  label: 'Loading',
                  checked: page.loading,
                  onTap: () {
                    page.loading = !page.loading;
                    _dismissContextMenu();
                  },
                ),
                _TabMenuItem(
                  label: 'Needs Attention',
                  checked: page.needsAttention,
                  onTap: () {
                    page.needsAttention = !page.needsAttention;
                    _dismissContextMenu();
                  },
                ),
                _TabMenuItem(
                  label: 'Indicator',
                  checked: meta?.hasIndicator ?? false,
                  onTap: () {
                    if (meta != null) {
                      meta.hasIndicator = !meta.hasIndicator;
                      _syncPageAppearance(page, isDark);
                    }
                    _dismissContextMenu();
                  },
                ),
                if (!page.pinned) ...[
                  _buildMenuDivider(theme),
                  _TabMenuItem(
                    label: 'Close Other Tabs',
                    enabled: widget.controller.unpinnedPages.length > 1,
                    onTap: () {
                      _dismissContextMenu();
                      widget.controller.closeOtherPages(page);
                    },
                  ),
                  _TabMenuItem(
                    label: 'Close Tabs to the Left',
                    enabled:
                        widget.controller.unpinnedPages.indexOf(page) > 0,
                    onTap: () {
                      _dismissContextMenu();
                      widget.controller.closePagesBefore(page);
                    },
                  ),
                  _TabMenuItem(
                    label: 'Close Tabs to the Right',
                    enabled: widget.controller.unpinnedPages.indexOf(page) <
                        widget.controller.unpinnedPages.length - 1,
                    onTap: () {
                      _dismissContextMenu();
                      widget.controller.closePagesAfter(page);
                    },
                  ),
                  _buildMenuDivider(theme),
                  _TabMenuItem(
                    label: 'Close',
                    onTap: () {
                      _dismissContextMenu();
                      widget.controller.closePage(page);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuDivider(AdwThemeData theme) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      color: theme.colors.dividerColor,
    );
  }
}

class _TabMenuItem extends StatefulWidget {
  final String label;
  final bool enabled;
  final bool? checked;
  final VoidCallback onTap;

  const _TabMenuItem({
    required this.label,
    this.enabled = true,
    this.checked,
    required this.onTap,
  });

  @override
  State<_TabMenuItem> createState() => _TabMenuItemState();
}

class _TabMenuItemState extends State<_TabMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final fg = theme.colors.windowForeground;

    return MouseRegion(
      cursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered && widget.enabled
                ? fg.withValues(alpha: 0.08)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.typography.body.copyWith(
                    fontSize: 13.5,
                    color: widget.enabled
                        ? fg
                        : fg.withValues(alpha: 0.38),
                  ),
                ),
              ),
              if (widget.checked == true)
                Text(
                  '✓',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabViewDemoPageBody extends StatefulWidget {
  final AdwTabPage page;
  final Color backgroundColor;
  final bool isDark;

  const _TabViewDemoPageBody({
    required this.page,
    required this.backgroundColor,
    required this.isDark,
  });

  @override
  State<_TabViewDemoPageBody> createState() => _TabViewDemoPageBodyState();
}

class _TabViewDemoPageBodyState extends State<_TabViewDemoPageBody> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.page.title);
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final fg = widget.isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1E1E1E);
    final entryBg = widget.isDark
        ? const Color(0x22FFFFFF)
        : const Color(0xCCFFFFFF);
    final focusRing = widget.isDark
        ? const Color(0xBFFFFFFF)
        : const Color(0xBF000000);

    return ColoredBox(
      color: widget.backgroundColor,
      child: Center(
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: AnimatedContainer(
            duration: AdwCurves.shortDuration,
            width: 210,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: entryBg,
              borderRadius: BorderRadius.circular(AdwMetrics.entryRadius),
              border: Border.all(
                color: _focused ? focusRing : fg.withValues(alpha: 0.16),
                width: _focused ? 2.0 : 1.0,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: EditableText(
              controller: _textController,
              focusNode: _focusNode,
              style: theme.typography.body.copyWith(
                color: fg,
                height: 1.0,
                leadingDistribution: TextLeadingDistribution.even,
              ),
              cursorColor: fg,
              backgroundCursorColor: fg.withValues(alpha: 0.24),
              onChanged: (val) {
                widget.page.title = val;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowNewSymbolicPainter extends CustomPainter {
  final Color color;

  const _WindowNewSymbolicPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(9.0 * u, 14.0 * u)
      ..lineTo(3.0 * u, 14.0 * u)
      ..quadraticBezierTo(1.5 * u, 14.0 * u, 1.5 * u, 12.5 * u)
      ..lineTo(1.5 * u, 3.5 * u)
      ..quadraticBezierTo(1.5 * u, 2.0 * u, 3.0 * u, 2.0 * u)
      ..lineTo(13.0 * u, 2.0 * u)
      ..quadraticBezierTo(14.5 * u, 2.0 * u, 14.5 * u, 3.5 * u)
      ..lineTo(14.5 * u, 8.5 * u);
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(1.5 * u, 5.2 * u), Offset(14.5 * u, 5.2 * u), paint);
    canvas.drawLine(
        Offset(12.5 * u, 10.5 * u), Offset(12.5 * u, 15.0 * u), paint);
    canvas.drawLine(
        Offset(10.25 * u, 12.75 * u), Offset(14.75 * u, 12.75 * u), paint);
  }

  @override
  bool shouldRepaint(covariant _WindowNewSymbolicPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ViewGridSymbolicPainter extends CustomPainter {
  final Color color;

  const _ViewGridSymbolicPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * u
      ..strokeJoin = StrokeJoin.round;
    final r = Radius.circular(1.2 * u);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2 * u, 2 * u, 4.8 * u, 4.8 * u), r),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(9.2 * u, 2 * u, 4.8 * u, 4.8 * u), r),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2 * u, 9.2 * u, 4.8 * u, 4.8 * u), r),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(9.2 * u, 9.2 * u, 4.8 * u, 4.8 * u), r),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ViewGridSymbolicPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TabNewSymbolicPainter extends CustomPainter {
  final Color color;

  const _TabNewSymbolicPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(1.0 * u, 1.0 * u, 15.0 * u, 15.0 * u),
        Radius.circular(2.96 * u),
      ),
      paint,
    );
    canvas.drawLine(Offset(8.0 * u, 5.0 * u), Offset(8.0 * u, 11.0 * u), paint);
    canvas.drawLine(Offset(5.0 * u, 8.0 * u), Offset(11.0 * u, 8.0 * u), paint);
  }

  @override
  bool shouldRepaint(covariant _TabNewSymbolicPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TabAudioIndicatorPainter extends CustomPainter {
  final bool isMuted;
  final Color color;

  const _TabAudioIndicatorPainter({
    required this.isMuted,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final speaker = Path()
      ..moveTo(2.0 * u, 6.2 * u)
      ..lineTo(4.5 * u, 6.2 * u)
      ..lineTo(8.0 * u, 3.0 * u)
      ..lineTo(8.0 * u, 13.0 * u)
      ..lineTo(4.5 * u, 9.8 * u)
      ..lineTo(2.0 * u, 9.8 * u)
      ..close();
    canvas.drawPath(speaker, paint);
    if (isMuted) {
      canvas.drawLine(
          Offset(10.5 * u, 6.0 * u), Offset(14.0 * u, 10.0 * u), paint);
      canvas.drawLine(
          Offset(14.0 * u, 6.0 * u), Offset(10.5 * u, 10.0 * u), paint);
    } else {
      canvas.drawLine(
          Offset(11.0 * u, 8.0 * u), Offset(14.2 * u, 8.0 * u), paint);
      canvas.drawLine(
          Offset(11.0 * u, 4.5 * u), Offset(13.5 * u, 3.2 * u), paint);
      canvas.drawLine(
          Offset(11.0 * u, 11.5 * u), Offset(13.5 * u, 12.8 * u), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TabAudioIndicatorPainter oldDelegate) =>
      oldDelegate.isMuted != isMuted || oldDelegate.color != color;
}

