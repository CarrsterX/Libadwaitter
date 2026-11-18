import 'dart:async';
import 'dart:math' as math;

import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../app/adwaitter_logo.dart';
import '../../demo_icons.dart';

class StyleClassesPage extends StatelessWidget {
  const StyleClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.styleClasses, size: 128),
      title: const Text('Style Classes'),
      description: const Text('Various widget styles available for use'),
      child: Center(
        child: Builder(
          builder: (innerContext) => AdwButton.pill(
            onPressed: () => _openStyleDemoDialog(innerContext),
            child: const Text('Run the Demo'),
          ),
        ),
      ),
    );
  }

  void _openStyleDemoDialog(BuildContext context) {
    showAdwDialog<void>(
      context: context,
      builder: (_) => const _StyleDemoDialog(),
    );
  }
}

class _StyleDemoDialog extends StatefulWidget {
  const _StyleDemoDialog();

  @override
  State<_StyleDemoDialog> createState() => _StyleDemoDialogState();
}

class _StyleDemoDialogState extends State<_StyleDemoDialog> {
  bool _osdProgress = false;

  final GlobalKey _openMenuBtnKey = GlobalKey();
  final GlobalKey _moreMenuBtnKey = GlobalKey();
  final GlobalKey _volumeBtnKey = GlobalKey();

  // Interactive demo state
  int _flatToggle = 0;
  int _roundToggle = 0;
  int _osdToggle = 0;
  int _linkedViewToggle = 0;
  bool _regCheck1 = true;
  bool _regCheck2 = false;
  bool _selCheck1 = true;
  bool _selCheck2 = false;
  double _mediaProgress = 0.5;
  final ValueNotifier<double> _volumeNotifier = ValueNotifier<double>(0.0);
  bool _isPlaying = false;

  late final TextEditingController _entryRegular =
      TextEditingController(text: 'Regular');
  late final TextEditingController _entrySuccess =
      TextEditingController(text: 'Success');
  late final TextEditingController _entryWarning =
      TextEditingController(text: 'Warning');
  late final TextEditingController _entryError =
      TextEditingController(text: 'Error');
  late final TextEditingController _linkedEntry1 = TextEditingController();
  late final TextEditingController _linkedEntry2 = TextEditingController();
  late final TextEditingController _streetEntry = TextEditingController();
  late final TextEditingController _cityEntry = TextEditingController();
  late final TextEditingController _provinceEntry = TextEditingController();

  @override
  void dispose() {
    _volumeNotifier.dispose();
    _entryRegular.dispose();
    _entrySuccess.dispose();
    _entryWarning.dispose();
    _entryError.dispose();
    _linkedEntry1.dispose();
    _linkedEntry2.dispose();
    _streetEntry.dispose();
    _cityEntry.dispose();
    _provinceEntry.dispose();
    super.dispose();
  }

  Color _standaloneSuccessColor(AdwThemeData theme) =>
      theme.colors.isDark ? const Color(0xFF78EABE) : const Color(0xFF1B8553);

  Color _standaloneWarningColor(AdwThemeData theme) =>
      theme.colors.isDark ? const Color(0xFFF8E45C) : const Color(0xFF9C6E03);

  Color _standaloneErrorColor(AdwThemeData theme) =>
      theme.colors.isDark ? const Color(0xFFFF7B63) : const Color(0xFFC01C28);

  Color _standaloneAccentColor(AdwThemeData theme) {
    final c = theme.colors.accentColor;
    if (!theme.colors.isDark) return c;
    return Color.lerp(c, const Color(0xFFFFFFFF), 0.35)!;
  }

  void _openStatusPagesDialog(BuildContext context) {
    showAdwDialog<void>(
      context: context,
      builder: (_) => const _StatusPageDemoDialog(),
    );
  }

  void _openSidebarDialog(BuildContext context) {
    showAdwDialog<void>(
      context: context,
      builder: (_) => const _SidebarDemoDialog(),
    );
  }

  IconData _volumeIcon(double volume) {
    if (volume <= 0.0) return AdwIcons.audio_volume_muted_symbolic;
    if (volume < 0.33) return AdwIcons.audio_volume_low_symbolic;
    if (volume < 0.66) return AdwIcons.audio_volume_medium_symbolic;
    return AdwIcons.audio_volume_high_symbolic;
  }

  void _showVolumePopover() {
    final RenderBox? buttonBox =
        _volumeBtnKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null || !buttonBox.hasSize) return;

    final Rect anchorRect =
        buttonBox.localToGlobal(Offset.zero) & buttonBox.size;

    showAdwPopover(
      context: context,
      anchorRect: anchorRect,
      owner: _volumeBtnKey,
      parentAnchor: AdwPopoverAnchor.bottom,
      childAnchor: AdwPopoverAnchor.top,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints(
        minWidth: 58,
        maxWidth: 64,
        maxHeight: 220,
      ),
      builder: (popoverContext, handle) {
        return AdwPopoverSurface(
          isOsd: true,
          arrowSide: AdwPopoverArrowSide.none,
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 44.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OsdIconButton(
                  icon: AdwIcons.list_add_symbolic,
                  onPressed: () {
                    _volumeNotifier.value =
                        (_volumeNotifier.value + 0.1).clamp(0.0, 1.0);
                  },
                ),
                const SizedBox(height: 6.0),
                SizedBox(
                  width: 30.0,
                  height: 100.0,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _volumeNotifier,
                    builder: (_, vol, __) => _OsdSlider(
                      orientation: Axis.vertical,
                      value: vol,
                      onChanged: (v) => _volumeNotifier.value = v,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                _OsdIconButton(
                  icon: AdwIcons.list_remove_symbolic,
                  onPressed: () {
                    _volumeNotifier.value =
                        (_volumeNotifier.value - 0.1).clamp(0.0, 1.0);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDemoPopoverMenu(GlobalKey buttonKey) {
    final RenderBox? buttonBox =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null || !buttonBox.hasSize) return;

    final Rect anchorRect =
        buttonBox.localToGlobal(Offset.zero) & buttonBox.size;

    showAdwPopover(
      context: context,
      anchorRect: anchorRect,
      owner: buttonKey,
      parentAnchor: AdwPopoverAnchor.bottom,
      childAnchor: AdwPopoverAnchor.top,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints(
        minWidth: 160,
        maxWidth: 220,
        maxHeight: 240,
      ),
      builder: (popoverContext, handle) {
        return AdwPopoverSurface(
          arrowSide: AdwPopoverArrowSide.none,
          child: SizedBox(
            width: 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdwPopoverMenuItem(
                  label: 'Item 1',
                  onTap: handle.dismiss,
                ),
                AdwPopoverMenuItem(
                  label: 'Item 2',
                  onTap: handle.dismiss,
                ),
                AdwPopoverMenuItem(
                  label: 'Item 3',
                  onTap: handle.dismiss,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1.0) ?? 1.0;
    final narrowBreakpoint = adwLengthUnitToPx(
      AdwLengthUnit.sp,
      550.0,
      textScale: textScale,
    );

    return AdwDialog(
      title: 'Style Classes',
      contentWidth: 800.0,
      contentHeight: 920.0,
      child: AdwToolbarView(
        topBar: const AdwHeaderBar(
          title: Text('Style Classes'),
          isFlat: true,
        ),
        content: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth <= narrowBreakpoint;

                return AdwPreferencesPage(
                  description: const Text(
                    'Hover over widgets to see their exact style class names',
                  ),
                  children: [
                    _buildButtonsGroup(theme, isNarrow),
                    _buildEntriesGroup(theme, isNarrow),
                    _buildToggleGroupsGroup(theme, isNarrow),
                    _buildLinkedControlsGroup(theme),
                    _buildLabelsGroup(theme, isNarrow),
                    _buildCardsAndListsGroup(theme),
                    _buildAppIconsGroup(theme),
                    _buildCheckButtonsGroup(theme),
                    _buildToolbarsGroup(theme),
                    _buildBackgroundsGroup(theme),
                    _buildMiscGroup(context, theme),
                  ],
                );
              },
            ),
            if (_osdProgress)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _StyleTooltip(
                  message: 'osd',
                  child: Container(
                    height: 3.0,
                    color:
                        theme.colors.windowForeground.withValues(alpha: 0.12),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(
                        height: 3.0,
                        color: theme.colors.accentColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsGroup(AdwThemeData theme, bool isNarrow) {
    final row1Left = Row(
      children: [
        Expanded(
          child: AdwButton(
            onPressed: () {},
            child: const Text('Regular', overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: _StyleTooltip(
            message: 'flat',
            child: AdwButton.flat(
              onPressed: () {},
              child: const Text('Flat', overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ],
    );

    final row1Right = Row(
      children: [
        Expanded(
          child: _StyleTooltip(
            message: 'suggested-action',
            child: AdwButton.suggested(
              onPressed: () {},
              child: const Text('Suggested', overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: _StyleTooltip(
            message: 'destructive-action',
            child: AdwButton.destructive(
              onPressed: () {},
              child: const Text('Destructive', overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ],
    );

    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('Buttons'),
      description: const Text(
        'The "flat", "suggested-action" and "destructive" style classes action can be used together with "pill" or "circular".\n\n'
        'The "opaque" style class allows to create buttons with custom colors that look similar to "suggested-action".',
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isNarrow) ...[
              row1Left,
              const SizedBox(height: 6.0),
              row1Right,
            ] else
              Row(
                children: [
                  Expanded(child: row1Left),
                  const SizedBox(width: 6.0),
                  Expanded(child: row1Right),
                ],
              ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: _StyleTooltip(
                      message: 'circular',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdwButton(
                            isCircular: true,
                            width: 34.0,
                            height: 34.0,
                            onPressed: () {},
                            child: const Icon(
                              AdwIcons.list_add_symbolic,
                              size: 16.0,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          AdwButton(
                            isCircular: true,
                            width: 34.0,
                            height: 34.0,
                            onPressed: () {},
                            child: const Text('A'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Center(
                    child: _StyleTooltip(
                      message: 'pill',
                      child: AdwButton.pill(
                        onPressed: () {},
                        child: const Text(
                          'Pill Button',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Center(
                    child: _StyleTooltip(
                      message: 'osd',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _OsdButton(
                            onPressed: () {},
                            child: const Icon(
                              AdwIcons.go_previous_symbolic,
                              size: 16.0,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          _OsdButton(
                            onPressed: () {},
                            child: const Icon(
                              AdwIcons.go_next_symbolic,
                              size: 16.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEntriesGroup(AdwThemeData theme, bool isNarrow) {
    final regularEntry = _StyledEntry(
      controller: _entryRegular,
      placeholder: 'Regular',
    );
    final successEntry = _StyleTooltip(
      message: 'success',
      child: _StyledEntry(
        controller: _entrySuccess,
        placeholder: 'Success',
        semanticColor: _standaloneSuccessColor(theme),
      ),
    );
    final warningEntry = _StyleTooltip(
      message: 'warning',
      child: _StyledEntry(
        controller: _entryWarning,
        placeholder: 'Warning',
        semanticColor: _standaloneWarningColor(theme),
      ),
    );
    final errorEntry = _StyleTooltip(
      message: 'error',
      child: _StyledEntry(
        controller: _entryError,
        placeholder: 'Error',
        semanticColor: _standaloneErrorColor(theme),
      ),
    );

    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('Entries'),
      children: [
        Column(
          children: [
            if (isNarrow) ...[
              regularEntry,
              const SizedBox(height: 6.0),
              successEntry,
              const SizedBox(height: 6.0),
              warningEntry,
              const SizedBox(height: 6.0),
              errorEntry,
            ] else ...[
              Row(
                children: [
                  Expanded(child: regularEntry),
                  const SizedBox(width: 6.0),
                  Expanded(child: successEntry),
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  Expanded(child: warningEntry),
                  const SizedBox(width: 6.0),
                  Expanded(child: errorEntry),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildToggleGroupsGroup(AdwThemeData theme, bool isNarrow) {
    final flatGroup = _StyleTooltip(
      message: 'flat',
      child: AdwToggleGroup<int>(
        style: AdwToggleGroupStyle.flat,
        homogeneous: true,
        selectedValue: _flatToggle,
        onChanged: (v) => setState(() => _flatToggle = v),
        items: [
          AdwToggleItem.withLabel(value: 0, label: const Text('Flat')),
          AdwToggleItem.withLabel(value: 1, label: const Text('Flat')),
        ],
      ),
    );

    final roundGroup = _StyleTooltip(
      message: 'round',
      child: AdwToggleGroup<int>(
        style: AdwToggleGroupStyle.round,
        homogeneous: true,
        selectedValue: _roundToggle,
        onChanged: (v) => setState(() => _roundToggle = v),
        items: [
          AdwToggleItem.withLabel(value: 0, label: const Text('Round')),
          AdwToggleItem.withLabel(value: 1, label: const Text('Round')),
        ],
      ),
    );

    final osdGroup = _StyleTooltip(
      message: 'osd',
      child: Container(
        height: 34.0,
        decoration: BoxDecoration(
          color: const Color(0xCC000000),
          borderRadius: BorderRadius.circular(9.0),
        ),
        padding: const EdgeInsets.all(3.0),
        child: Row(
          children: [
            for (var i = 0; i < 2; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _osdToggle = i),
                  child: AnimatedContainer(
                    duration: AdwCurves.shortDuration,
                    curve: AdwCurves.standard,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _osdToggle == i
                          ? const Color(0xFFFFFFFF)
                          : const Color(0x00000000),
                      borderRadius: BorderRadius.circular(6.0),
                      boxShadow: _osdToggle == i
                          ? const [
                              BoxShadow(
                                color: Color(0x12000006),
                                blurRadius: 3.0,
                                spreadRadius: 1.0,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      'OSD',
                      style: theme.typography.heading.copyWith(
                        color: _osdToggle == i
                            ? const Color(0xCC000000)
                            : const Color(0xE6FFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('Toggle Groups'),
      description: const Text(
        'The "flat", "round" and "osd" style classes action can all be used together',
      ),
      children: [
        if (isNarrow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              flatGroup,
              const SizedBox(height: 6.0),
              roundGroup,
              const SizedBox(height: 6.0),
              osdGroup,
            ],
          )
        else
          Row(
            children: [
              Expanded(child: flatGroup),
              const SizedBox(width: 6.0),
              Expanded(child: roundGroup),
              const SizedBox(width: 6.0),
              Expanded(child: osdGroup),
            ],
          ),
      ],
    );
  }

  Widget _buildLinkedControlsGroup(AdwThemeData theme) {
    const r = Radius.circular(9.0);
    final gapColor = theme.colors.isDark
        ? const Color(0xFF4C4C4E)
        : const Color(0xFFD4D4D5);

    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('Linked Controls'),
      description: const Text(
        'The "linked" style on GtkBox and similar containers allows to visually join related button-like and entry-like widgets',
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _StyleTooltip(
                  message: 'linked',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LinkedIconButton(
                        icon: AdwIcons.view_grid_symbolic,
                        isSelected: _linkedViewToggle == 0,
                        borderRadius: const BorderRadius.horizontal(left: r),
                        onTap: () => setState(() => _linkedViewToggle = 0),
                      ),
                      Container(width: 1.0, height: 34.0, color: gapColor),
                      _LinkedIconButton(
                        icon: AdwIcons.view_list_symbolic,
                        isSelected: _linkedViewToggle == 1,
                        borderRadius: const BorderRadius.horizontal(right: r),
                        onTap: () => setState(() => _linkedViewToggle = 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: _StyleTooltip(
                    message: 'linked',
                    child: SizedBox(
                      height: 34.0,
                      child: Row(
                        children: [
                          Expanded(
                            child: _LinkedEntry(
                              controller: _linkedEntry1,
                              placeholder: 'Entry',
                              borderRadius:
                                  const BorderRadius.horizontal(left: r),
                            ),
                          ),
                          Container(width: 1.0, color: gapColor),
                          Expanded(
                            child: _LinkedEntry(
                              controller: _linkedEntry2,
                              placeholder: 'Entry',
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          Container(width: 1.0, color: gapColor),
                          _LinkedTextButton(
                            label: 'Button',
                            borderRadius:
                                const BorderRadius.horizontal(right: r),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StyleTooltip(
                  message: 'linked',
                  child: SizedBox(
                    width: 34.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LinkedIconButton(
                          icon: AdwIcons.edit_cut_symbolic,
                          isSelected: false,
                          borderRadius: const BorderRadius.vertical(top: r),
                          onTap: () {},
                        ),
                        Container(height: 1.0, color: gapColor),
                        _LinkedIconButton(
                          icon: AdwIcons.edit_copy_symbolic,
                          isSelected: false,
                          borderRadius: BorderRadius.zero,
                          onTap: () {},
                        ),
                        Container(height: 1.0, color: gapColor),
                        _LinkedIconButton(
                          icon: AdwIcons.edit_paste_symbolic,
                          isSelected: false,
                          borderRadius: const BorderRadius.vertical(bottom: r),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: _StyleTooltip(
                    message: 'linked',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 34.0,
                          child: _LinkedEntry(
                            controller: _streetEntry,
                            placeholder: 'Street',
                            borderRadius: const BorderRadius.vertical(top: r),
                          ),
                        ),
                        Container(height: 1.0, color: gapColor),
                        SizedBox(
                          height: 34.0,
                          child: _LinkedEntry(
                            controller: _cityEntry,
                            placeholder: 'City',
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        Container(height: 1.0, color: gapColor),
                        SizedBox(
                          height: 34.0,
                          child: _LinkedEntry(
                            controller: _provinceEntry,
                            placeholder: 'Province',
                            borderRadius:
                                const BorderRadius.vertical(bottom: r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabelsGroup(AdwThemeData theme, bool isNarrow) {
    final typo = theme.typography;
    final colors = theme.colors;

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StyleTooltip(
          message: 'title-1',
          child: Text('Title 1', style: typo.title1),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'title-2',
          child: Text('Title 2', style: typo.title2),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'title-3',
          child: Text('Title 3', style: typo.title3),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'title-4',
          child: Text('Title 4', style: typo.title4),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'monospace',
          child: Text('Monospace', style: typo.code),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'numeric',
          child: Text(
            'Numeric (1234567890)',
            style: typo.body.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'accent',
          child: Text(
            'Accent',
            style: typo.body.copyWith(color: _standaloneAccentColor(theme)),
          ),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'success',
          child: Text(
            'Success',
            style: typo.body.copyWith(color: _standaloneSuccessColor(theme)),
          ),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'warning',
          child: Text(
            'Warning',
            style: typo.body.copyWith(color: _standaloneWarningColor(theme)),
          ),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'error',
          child: Text(
            'Error',
            style: typo.body.copyWith(color: _standaloneErrorColor(theme)),
          ),
        ),
      ],
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StyleTooltip(
          message: 'document',
          child: Text(
            'This is a document paragraph. It should be used for the app\'s main content.',
            style: typo.body.copyWith(height: 1.45),
          ),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'heading',
          child: Text('Heading', style: typo.heading),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'body',
          child: Text(
            'This is a paragraph of a body copy, to be used for medium-long text such as descriptions in the UI.',
            style: typo.body,
          ),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'caption-heading',
          child: Text('Caption Heading', style: typo.captionHeading),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'caption',
          child: Text(
            'Caption body text, to be used for body copy on image captions and the like',
            style: typo.caption,
          ),
        ),
        const SizedBox(height: 12.0),
        _StyleTooltip(
          message: 'dimmed',
          child: Text(
            'This is a dimmed paragraph, mostly used for secondary labels or descriptions.',
            style: typo.body.copyWith(
              color: colors.windowForeground.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );

    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('Labels'),
      children: [
        if (isNarrow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftColumn,
              const SizedBox(height: 12.0),
              rightColumn,
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftColumn),
              const SizedBox(width: 18.0),
              Expanded(child: rightColumn),
            ],
          ),
      ],
    );
  }

  Widget _buildCardsAndListsGroup(AdwThemeData theme) {
    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('Cards and Boxed Lists'),
      description: const Text(
        'The "boxed-list" style class can be used with GtkListBox to create boxed lists.\n\n'
        'The "card" style class can be used to achieve the same style with GtkBox or similar containers, and with GtkButton. '
        'If used together with "activatable" style class, or on a GtkButton, the card will also have hover and press styles.',
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100.0,
              child: Row(
                children: [
                  const Expanded(
                    child: _StyleTooltip(
                      message: 'card',
                      child: _CardSample(
                        label: 'Card',
                        activatable: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _StyleTooltip(
                      message: 'card, activatable',
                      child: _CardSample(
                        label: 'Card (Activatable)',
                        activatable: true,
                        onTap: () {},
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _StyleTooltip(
                      message: 'card',
                      child: _CardSample(
                        label: 'Card (Button)',
                        activatable: true,
                        onTap: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            _StyleTooltip(
              message: 'boxed-list',
              child: AdwPreferencesGroup(
                boxed: true,
                children: [
                  const AdwActionRow(
                    title: Text('Row'),
                    isActivatable: false,
                  ),
                  AdwActionRow(
                    title: const Text('Row (Activatable)'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppIconsGroup(AdwThemeData theme) {
    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('App Icons'),
      description: const Text(
        'The "icon-dropshadow" style class ensures legibility when displaying app icons. '
        'For 32x32 and smaller app icons, "lowres-icon" should be used instead.',
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _StyleTooltip(
                  message: 'icon-dropshadow',
                  child: AdwaitterAppLogo(size: 128.0),
                ),
                const SizedBox(height: 6.0),
                Text('128', style: theme.typography.body),
              ],
            ),
            const SizedBox(width: 12.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _StyleTooltip(
                  message: 'icon-dropshadow',
                  child: AdwaitterAppLogo(size: 64.0),
                ),
                const SizedBox(height: 6.0),
                Text('64', style: theme.typography.body),
              ],
            ),
            const SizedBox(width: 12.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _StyleTooltip(
                  message: 'lowres-icon',
                  child: AdwaitterAppLogo(size: 32.0),
                ),
                const SizedBox(height: 6.0),
                Text('32', style: theme.typography.body),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckButtonsGroup(AdwThemeData theme) {
    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('Check Buttons'),
      description: const Text(
        'The "selection-mode" style class can be used with GtkCheckButton to make them large and round',
      ),
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 28.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AdwCheckbox(
                          value: _regCheck1,
                          size: 20.0,
                          onChanged: (v) => setState(() => _regCheck1 = v),
                        ),
                        const SizedBox(width: 12.0),
                        AdwCheckbox(
                          value: _regCheck2,
                          size: 20.0,
                          onChanged: (v) => setState(() => _regCheck2 = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text('Regular', style: theme.typography.body),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 28.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StyleTooltip(
                          message: 'selection-mode',
                          child: _SelectionModeCheckbox(
                            value: _selCheck1,
                            onChanged: (v) => setState(() => _selCheck1 = v),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        _StyleTooltip(
                          message: 'selection-mode',
                          child: _SelectionModeCheckbox(
                            value: _selCheck2,
                            onChanged: (v) => setState(() => _selCheck2 = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text('Selection Mode', style: theme.typography.body),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbarsGroup(AdwThemeData theme) {
    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('Toolbars'),
      description: const Text(
        'The "toolbar" style class on GtkBox and similar containers gives the same padding, spacing and button appearance as GtkHeaderBar and GtkActionBar have. '
        'A toolbar can additionally have the "osd" style class, useful for floating media controls.\n\n'
        'The "raised" style class can be used to make a button inside a toolbar use default appearance instead.',
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StyleTooltip(
              message: 'toolbar',
              child: Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(color: theme.colors.borderColor),
                ),
                child: Row(
                  children: [
                    AdwButton.flat(
                      key: _openMenuBtnKey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      onPressed: () => _showDemoPopoverMenu(_openMenuBtnKey),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Open'),
                          SizedBox(width: 4.0),
                          Icon(AdwIcons.pan_down_symbolic, size: 16.0),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    AdwButton.flat(
                      width: 34.0,
                      height: 34.0,
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      child: const Icon(AdwIcons.tab_new_symbolic, size: 16.0),
                    ),
                    const Spacer(),
                    AdwButton.flat(
                      width: 34.0,
                      height: 34.0,
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      child:
                          const Icon(AdwIcons.edit_undo_symbolic, size: 16.0),
                    ),
                    const SizedBox(width: 6.0),
                    AdwButton.flat(
                      width: 34.0,
                      height: 34.0,
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      child:
                          const Icon(AdwIcons.edit_redo_symbolic, size: 16.0),
                    ),
                    const SizedBox(width: 18.0),
                    AdwButton.flat(
                      key: _moreMenuBtnKey,
                      width: 34.0,
                      height: 34.0,
                      padding: EdgeInsets.zero,
                      onPressed: () => _showDemoPopoverMenu(_moreMenuBtnKey),
                      child:
                          const Icon(AdwIcons.view_more_symbolic, size: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            _StyleTooltip(
              message: 'toolbar, osd',
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xB3000000),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Row(
                  children: [
                    _OsdIconButton(
                      icon: AdwIcons.media_skip_backward_symbolic,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 6.0),
                    _OsdIconButton(
                      icon: _isPlaying
                          ? AdwIcons.media_playback_pause_symbolic
                          : AdwIcons.media_playback_start_symbolic,
                      onPressed: () => setState(() => _isPlaying = !_isPlaying),
                    ),
                    const SizedBox(width: 6.0),
                    _OsdIconButton(
                      icon: AdwIcons.media_skip_forward_symbolic,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: _OsdSlider(
                        value: _mediaProgress,
                        onChanged: (v) => setState(() => _mediaProgress = v),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    ValueListenableBuilder<double>(
                      valueListenable: _volumeNotifier,
                      builder: (_, vol, __) => _OsdIconButton(
                        key: _volumeBtnKey,
                        icon: _volumeIcon(vol),
                        onPressed: _showVolumePopover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundsGroup(AdwThemeData theme) {
    return AdwPreferencesGroup(
      boxed: false,
      title: const Text('Backgrounds'),
      description: const Text(
        'These style classes can be applied to any widgets that need the specific background and text color',
      ),
      children: [
        SizedBox(
          height: 100.0,
          child: Row(
            children: [
              Expanded(
                child: _StyleTooltip(
                  message: 'background',
                  child: Container(
                    color: theme.colors.windowBackground,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Background',
                      textAlign: TextAlign.center,
                      style: theme.typography.body.copyWith(
                        color: theme.colors.windowForeground,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _StyleTooltip(
                  message: 'view',
                  child: Container(
                    color: theme.colors.viewBackground,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'View',
                      textAlign: TextAlign.center,
                      style: theme.typography.body.copyWith(
                        color: theme.colors.viewForeground,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _StyleTooltip(
                  message: 'osd',
                  child: Container(
                    color: const Color(0xB3000000),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'OSD',
                      textAlign: TextAlign.center,
                      style: theme.typography.body.copyWith(
                        color: const Color(0xE6FFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiscGroup(BuildContext context, AdwThemeData theme) {
    return AdwPreferencesGroup(
      boxed: true,
      title: const Text('Misc'),
      children: [
        AdwActionRow(
          title: const Text('Status Pages'),
          onPressed: () => _openStatusPagesDialog(context),
          trailing: Icon(
            AdwIcons.go_next_symbolic,
            size: 16.0,
            color: theme.colors.windowForeground.withValues(alpha: 0.55),
          ),
        ),
        AdwActionRow(
          title: const Text('Sidebar'),
          onPressed: () => _openSidebarDialog(context),
          trailing: Icon(
            AdwIcons.go_next_symbolic,
            size: 16.0,
            color: theme.colors.windowForeground.withValues(alpha: 0.55),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: AdwWindow.develMode,
          builder: (context, isDevel, _) => AdwSwitchRow(
            title: const Text('Development Window'),
            subtitle: const Text('"devel" style class on GtkWindow'),
            value: isDevel,
            onChanged: (v) => AdwWindow.develMode.value = v,
          ),
        ),
        AdwSwitchRow(
          title: const Text('OSD Progress Bar'),
          subtitle: const Text('"osd" style class on GtkProgressBar'),
          value: _osdProgress,
          onChanged: (v) => setState(() => _osdProgress = v),
        ),
      ],
    );
  }
}

class _StatusPageDemoDialog extends StatefulWidget {
  const _StatusPageDemoDialog();

  @override
  State<_StatusPageDemoDialog> createState() => _StatusPageDemoDialogState();
}

class _StatusPageDemoDialogState extends State<_StatusPageDemoDialog> {
  bool _showSidebar = true;

  @override
  Widget build(BuildContext context) {
    return AdwDialog(
      title: 'Status Pages',
      contentWidth: 640.0,
      contentHeight: 480.0,
      child: AdwToolbarView(
        topBar: AdwHeaderBar(
          title: const Text('Status Pages'),
          start: AdwButton.flat(
            isChecked: _showSidebar,
            padding: const EdgeInsets.all(6.0),
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
            child: const Icon(AdwIcons.sidebar_show_symbolic, size: 16.0),
          ),
        ),
        content: AdwOverlaySplitView(
          showSidebar: _showSidebar,
          collapseBreakpoint: 400.0,
          onShowSidebarChanged: (v) => setState(() => _showSidebar = v),
          sidebar: const _StyleTooltip(
            message: 'compact',
            child: AdwStatusPage(
              icon: AdwaitterSymbolicLogo(size: 96.0),
              title: Text('Compact'),
              description: Text(
                'This status page has the "compact" style class',
              ),
              padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
            ),
          ),
          content: const AdwStatusPage(
            icon: AdwaitterSymbolicLogo(size: 128.0),
            title: Text('Regular'),
            description: Text(
              'This is a regular status page for comparison',
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDemoDialog extends StatefulWidget {
  const _SidebarDemoDialog();

  @override
  State<_SidebarDemoDialog> createState() => _SidebarDemoDialogState();
}

class _SidebarDemoDialogState extends State<_SidebarDemoDialog> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return AdwDialog(
      title: 'Sidebar',
      contentWidth: 720.0,
      contentHeight: 480.0,
      child: AdwNavigationSplitView(
        sidebarWidth: 220.0,
        breakpoint: 400.0,
        sidebarTitle: 'Sidebar',
        contentTitle: 'Sidebar',
        sidebar: AdwToolbarView(
          topBar: Builder(
            builder: (ctx) {
              final isCollapsed =
                  AdwNavigationSplitViewScope.maybeOf(ctx)?.isCollapsed ??
                      false;
              return AdwHeaderBar(
                isFlat: true,
                showTitle: false,
                showWindowControls: isCollapsed,
              );
            },
          ),
          content: _StyleTooltip(
            message: 'navigation-sidebar',
            child: ListView(
              padding: const EdgeInsets.all(6.0),
              children: [
                for (var i = 0; i < 5; i++)
                  Builder(
                    builder: (ctx) {
                      final scope = AdwNavigationSplitViewScope.maybeOf(ctx);
                      final isCollapsed = scope?.isCollapsed ?? false;
                      final isSelected = !isCollapsed && _selectedIndex == i;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _selectedIndex = i);
                          if (isCollapsed) {
                            scope?.showContentPage();
                          }
                        },
                        child: Container(
                          height: 36.0,
                          margin: const EdgeInsets.symmetric(vertical: 1.0),
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colors.sidebarSelectedBackground
                                : const Color(0x00000000),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Item ${i + 1}',
                            style: theme.typography.body,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        content: const AdwToolbarView(
          topBar: AdwHeaderBar(
            isFlat: true,
            title: Text('Sidebar'),
          ),
          content: AdwStatusPage(
            title: Text('Sidebar'),
            description: Text(
              '"navigation-sidebar" style using AdwSidebarItem inside a ListView',
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleTooltip extends StatefulWidget {
  final String message;
  final Widget child;

  const _StyleTooltip({
    required this.message,
    required this.child,
  });

  @override
  State<_StyleTooltip> createState() => _StyleTooltipState();
}

class _StyleTooltipState extends State<_StyleTooltip> {
  OverlayEntry? _entry;
  Timer? _timer;
  Offset? _pointerGlobalPosition;

  @override
  void dispose() {
    _cancelTooltip();
    super.dispose();
  }

  void _scheduleTooltip() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 550), _showTooltip);
  }

  void _cancelTooltip() {
    _timer?.cancel();
    _timer = null;
    _pointerGlobalPosition = null;
    _entry?.remove();
    _entry = null;
  }

  void _showTooltip() {
    if (!mounted || _entry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final RenderBox? targetBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        overlay.context.findRenderObject() as RenderBox?;
    if (targetBox == null ||
        !targetBox.hasSize ||
        overlayBox == null ||
        !overlayBox.hasSize) {
      return;
    }

    final theme = AdwTheme.of(context);
    final textStyle = theme.typography.body.copyWith(
      color: const Color(0xFFFFFFFF),
    );
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    final painter = TextPainter(
      text: TextSpan(text: widget.message, style: textStyle),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    // `_tooltip.scss`: `padding: 6px 10px; border: 1px solid ...; border-radius: 9px;`
    final tooltipWidth = painter.width + 22.0;
    final tooltipHeight = painter.height + 14.0;

    final overlaySize = overlayBox.size;
    final Offset anchorPoint = _pointerGlobalPosition != null
        ? overlayBox.globalToLocal(_pointerGlobalPosition!)
        : targetBox.localToGlobal(
            Offset(targetBox.size.width * 0.5, targetBox.size.height),
            ancestor: overlayBox,
          );

    const edgeMargin = 6.0;
    const pointerBelowOffset = 18.0;
    const pointerAboveOffset = 8.0;

    final double left = (anchorPoint.dx - tooltipWidth * 0.5).clamp(
      edgeMargin,
      math.max(edgeMargin, overlaySize.width - tooltipWidth - edgeMargin),
    );

    double top = anchorPoint.dy + pointerBelowOffset;
    if (top + tooltipHeight + edgeMargin > overlaySize.height &&
        anchorPoint.dy - pointerAboveOffset - tooltipHeight >= edgeMargin) {
      top = anchorPoint.dy - pointerAboveOffset - tooltipHeight;
    }

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xCC000006),
              borderRadius: BorderRadius.circular(9.0),
              border: Border.all(
                color: const Color(0x1AFFFFFF),
                width: 1.0,
              ),
            ),
            child: Text(
              widget.message,
              style: textStyle,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        _pointerGlobalPosition = event.position;
        _scheduleTooltip();
      },
      onHover: (event) {
        _pointerGlobalPosition = event.position;
        if (_entry == null) {
          _scheduleTooltip();
        }
      },
      onExit: (_) => _cancelTooltip(),
      child: widget.child,
    );
  }
}

class _OsdButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _OsdButton({
    required this.child,
    required this.onPressed,
  });

  @override
  State<_OsdButton> createState() => _OsdButtonState();
}

class _OsdButtonState extends State<_OsdButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Matches `_buttons.scss` `button.osd`: 32x32 min + 5px padding = 34x34,
    // border-radius: $button_radius (9px), background-color: RGB(0 0 0 / 65%).
    final bg = _pressed
        ? const Color(0xB33F3F3F)
        : (_hovered ? const Color(0xA6262626) : const Color(0xA6000000));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          width: 42.0,
          height: 42.0,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9.0),
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: const IconThemeData(color: Color(0xE6FFFFFF), size: 16.0),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _StyledEntry extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final Color? semanticColor;

  const _StyledEntry({
    required this.controller,
    required this.placeholder,
    this.semanticColor,
  });

  @override
  State<_StyledEntry> createState() => _StyledEntryState();
}

class _StyledEntryState extends State<_StyledEntry> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    // Matches `_entries.scss` + `_labels.scss`:
    // `currentColor` becomes `--success-color`, `--warning-color`, or `--error-color`,
    // `background-color: color-mix(in srgb, currentColor 10%, transparent)`,
    // NO border unless focused (`focus-ring` = 2px outline at 50% accent/semantic color).
    final currentColor = widget.semanticColor ?? theme.colors.windowForeground;
    final focusColor = widget.semanticColor ?? theme.colors.accentColor;
    final bgColor = currentColor.withValues(alpha: 0.10);

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: AnimatedContainer(
        duration: AdwCurves.shortDuration,
        curve: AdwCurves.standard,
        height: 34.0,
        padding: const EdgeInsets.symmetric(horizontal: 9.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9.0),
          border: _focused
              ? Border.all(
                  color: focusColor.withValues(alpha: 0.50),
                  width: 2.0,
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: EditableText(
                controller: widget.controller,
                focusNode: _focusNode,
                style: theme.typography.body.copyWith(color: currentColor),
                cursorColor: currentColor,
                backgroundCursorColor: theme.colors.windowBackground,
              ),
            ),
            const SizedBox(width: 6.0),
            Icon(
              AdwIcons.edit_copy_symbolic,
              size: 16.0,
              color: currentColor.withValues(alpha: 0.70),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedIconButton extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _LinkedIconButton({
    required this.icon,
    required this.isSelected,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  State<_LinkedIconButton> createState() => _LinkedIconButtonState();
}

class _LinkedIconButtonState extends State<_LinkedIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final fg = theme.colors.windowForeground;
    final double alpha;
    if (_pressed) {
      alpha = widget.isSelected ? 0.40 : 0.30;
    } else if (widget.isSelected) {
      alpha = _hovered ? 0.35 : 0.30;
    } else if (_hovered) {
      alpha = 0.15;
    } else {
      alpha = 0.10;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: AdwCurves.normalDuration,
          curve: AdwCurves.standard,
          width: 34.0,
          height: 34.0,
          decoration: BoxDecoration(
            color: fg.withValues(alpha: alpha),
            borderRadius: widget.borderRadius,
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: 16.0,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _LinkedTextButton extends StatefulWidget {
  final String label;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _LinkedTextButton({
    required this.label,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  State<_LinkedTextButton> createState() => _LinkedTextButtonState();
}

class _LinkedTextButtonState extends State<_LinkedTextButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final fg = theme.colors.windowForeground;
    final alpha = _pressed ? 0.30 : (_hovered ? 0.15 : 0.10);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: AdwCurves.normalDuration,
          curve: AdwCurves.standard,
          height: 34.0,
          padding: const EdgeInsets.symmetric(horizontal: 17.0),
          decoration: BoxDecoration(
            color: fg.withValues(alpha: alpha),
            borderRadius: widget.borderRadius,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: theme.typography.heading,
          ),
        ),
      ),
    );
  }
}

class _LinkedEntry extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final BorderRadius borderRadius;

  const _LinkedEntry({
    required this.controller,
    required this.placeholder,
    required this.borderRadius,
  });

  @override
  State<_LinkedEntry> createState() => _LinkedEntryState();
}

class _LinkedEntryState extends State<_LinkedEntry> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final fg = theme.colors.windowForeground;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.10),
          borderRadius: widget.borderRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9.0),
        alignment: Alignment.centerLeft,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (widget.controller.text.isEmpty)
              Text(
                widget.placeholder,
                style: theme.typography.body.copyWith(
                  color: fg.withValues(alpha: 0.55),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            EditableText(
              controller: widget.controller,
              focusNode: _focusNode,
              style: theme.typography.body,
              cursorColor: fg,
              backgroundCursorColor: theme.colors.windowBackground,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSample extends StatefulWidget {
  final String label;
  final bool activatable;
  final VoidCallback? onTap;

  const _CardSample({
    required this.label,
    required this.activatable,
    this.onTap,
  });

  @override
  State<_CardSample> createState() => _CardSampleState();
}

class _CardSampleState extends State<_CardSample> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    // Matches `_misc.scss` `%card`:
    // `background-color: var(--card-bg-color)` (no bright border),
    // hover adds 3% currentColor, active adds 8% currentColor.
    Color bg = theme.colors.cardBackground;
    if (widget.activatable) {
      if (_pressed) {
        bg = Color.alphaBlend(
          theme.colors.windowForeground.withValues(alpha: 0.08),
          bg,
        );
      } else if (_hovered) {
        bg = Color.alphaBlend(
          theme.colors.windowForeground.withValues(alpha: 0.03),
          bg,
        );
      }
    }

    return MouseRegion(
      cursor: widget.activatable
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown:
            widget.activatable ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.activatable
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel:
            widget.activatable ? () => setState(() => _pressed = false) : null,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AdwMetrics.cardRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000006),
                blurRadius: 0.0,
                spreadRadius: 1.0,
              ),
              BoxShadow(
                color: Color(0x12000006),
                blurRadius: 3.0,
                spreadRadius: 1.0,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x08000006),
                blurRadius: 6.0,
                spreadRadius: 2.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: theme.typography.body,
          ),
        ),
      ),
    );
  }
}

class _SelectionModeCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SelectionModeCheckbox({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SelectionModeCheckbox> createState() => _SelectionModeCheckboxState();
}

class _SelectionModeCheckboxState extends State<_SelectionModeCheckbox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    // Matches `_checks.scss` `checkbutton.selection-mode`:
    // 14px icon + 7px padding = 28x28 circle, 2px inset trough border when unchecked.
    final fg = theme.colors.windowForeground;
    final isChecked = widget.value;
    final borderAlpha = _hovered ? 0.20 : 0.15;
    final fillColor = isChecked
        ? (_hovered
            ? Color.alphaBlend(
                theme.colors.accentForeground.withValues(alpha: 0.10),
                theme.colors.accentColor,
              )
            : theme.colors.accentColor)
        : (_hovered ? fg.withValues(alpha: 0.06) : const Color(0x00000000));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onChanged(!isChecked),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AdwCurves.shortDuration,
          curve: AdwCurves.standard,
          width: 28.0,
          height: 28.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            border: isChecked
                ? null
                : Border.all(
                    color: fg.withValues(alpha: borderAlpha),
                    width: 2.0,
                  ),
          ),
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: isChecked ? 1.0 : 0.6,
            duration: AdwCurves.shortDuration,
            curve: AdwCurves.standard,
            child: AnimatedOpacity(
              opacity: isChecked ? 1.0 : 0.0,
              duration: AdwCurves.shortDuration,
              curve: AdwCurves.standard,
              child: Icon(
                AdwIcons.object_select_symbolic,
                size: 14.0,
                color: theme.colors.accentForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OsdIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _OsdIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_OsdIconButton> createState() => _OsdIconButtonState();
}

class _OsdIconButtonState extends State<_OsdIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = _pressed
        ? const Color(0x29FFFFFF)
        : (_hovered ? const Color(0x12FFFFFF) : const Color(0x00000000));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          width: 42.0,
          height: 42.0,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9.0),
          ),
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 16.0, color: const Color(0xE6FFFFFF)),
        ),
      ),
    );
  }
}

class _OsdSlider extends StatefulWidget {
  final double value;
  final Axis orientation;
  final ValueChanged<double> onChanged;

  const _OsdSlider({
    required this.value,
    this.orientation = Axis.horizontal,
    required this.onChanged,
  });

  @override
  State<_OsdSlider> createState() => _OsdSliderState();
}

class _OsdSliderState extends State<_OsdSlider> {
  bool _hovered = false;
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    // Matches `_scale.scss` + `_common.scss` `.osd`:
    // - trough: 6px, `$trough_color` (15% white) -> `$trough_hover_color` (20% white) on hover/active
    // - highlight: `--accent-bg-color` (75% white) -> illuminated (85% white) on hover/active
    // - slider thumb: 24x18 pill (`$slider_color` #D2D2D3) -> pure white (`#FFFFFF`) on hover/active
    final isLit = _hovered || _active;
    final troughColor =
        isLit ? const Color(0x33FFFFFF) : const Color(0x26FFFFFF);
    final highlightColor =
        isLit ? const Color(0xD9FFFFFF) : const Color(0xBFFFFFFF);
    final thumbColor =
        isLit ? const Color(0xFFFFFFFF) : const Color(0xFFD2D2D3);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (widget.orientation == Axis.vertical) {
            final height = constraints.maxHeight;
            void updateVertical(Offset localPosition) {
              if (height <= 0) return;
              // Inverted vertical scale: top = 1.0, bottom = 0.0
              final next = (1.0 - (localPosition.dy / height)).clamp(0.0, 1.0);
              widget.onChanged(next);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                setState(() => _active = true);
                updateVertical(d.localPosition);
              },
              onTapUp: (_) => setState(() => _active = false),
              onTapCancel: () => setState(() => _active = false),
              onVerticalDragStart: (d) {
                setState(() => _active = true);
                updateVertical(d.localPosition);
              },
              onVerticalDragUpdate: (d) => updateVertical(d.localPosition),
              onVerticalDragEnd: (_) => setState(() => _active = false),
              onVerticalDragCancel: () => setState(() => _active = false),
              child: SizedBox(
                width: 30.0,
                height: height,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 6.0,
                      height: height,
                      decoration: BoxDecoration(
                        color: troughColor,
                        borderRadius: BorderRadius.circular(99.0),
                      ),
                    ),
                    FractionallySizedBox(
                      heightFactor: widget.value,
                      child: Container(
                        width: 6.0,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(99.0),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: (height - 18.0) * widget.value,
                      child: Container(
                        width: 18.0,
                        height: 18.0,
                        decoration: BoxDecoration(
                          color: thumbColor,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000006),
                              blurRadius: 0.0,
                              spreadRadius: 1.0,
                            ),
                            BoxShadow(
                              color: Color(0x33000006),
                              blurRadius: 4.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final width = constraints.maxWidth;
          void updateHorizontal(Offset localPosition) {
            if (width <= 0) return;
            widget.onChanged((localPosition.dx / width).clamp(0.0, 1.0));
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              setState(() => _active = true);
              updateHorizontal(d.localPosition);
            },
            onTapUp: (_) => setState(() => _active = false),
            onTapCancel: () => setState(() => _active = false),
            onHorizontalDragStart: (d) {
              setState(() => _active = true);
              updateHorizontal(d.localPosition);
            },
            onHorizontalDragUpdate: (d) => updateHorizontal(d.localPosition),
            onHorizontalDragEnd: (_) => setState(() => _active = false),
            onHorizontalDragCancel: () => setState(() => _active = false),
            child: SizedBox(
              height: 30.0,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: troughColor,
                      borderRadius: BorderRadius.circular(99.0),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: widget.value,
                    child: Container(
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(99.0),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width - 18.0) * widget.value,
                    child: Container(
                      width: 18.0,
                      height: 18.0,
                      decoration: BoxDecoration(
                        color: thumbColor,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000006),
                            blurRadius: 0.0,
                            spreadRadius: 1.0,
                          ),
                          BoxShadow(
                            color: Color(0x33000006),
                            blurRadius: 4.0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
