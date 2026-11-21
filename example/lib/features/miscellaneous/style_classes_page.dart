
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
      theme.colors.standaloneSuccessColor;

  Color _standaloneWarningColor(AdwThemeData theme) =>
      theme.colors.standaloneWarningColor;

  Color _standaloneErrorColor(AdwThemeData theme) =>
      theme.colors.standaloneErrorColor;

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
                AdwButton.osd(
                  isFlat: true,
                  onPressed: () {
                    _volumeNotifier.value =
                        (_volumeNotifier.value + 0.1).clamp(0.0, 1.0);
                  },
                  child: const Icon(AdwIcons.list_add_symbolic, size: 16.0),
                ),
                const SizedBox(height: 6.0),
                SizedBox(
                  width: 30.0,
                  height: 100.0,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _volumeNotifier,
                    builder: (_, vol, __) => AdwSlider(
                      orientation: Axis.vertical,
                      isOsd: true,
                      value: vol,
                      onChanged: (v) => _volumeNotifier.value = v,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                AdwButton.osd(
                  isFlat: true,
                  onPressed: () {
                    _volumeNotifier.value =
                        (_volumeNotifier.value - 0.1).clamp(0.0, 1.0);
                  },
                  child: const Icon(AdwIcons.list_remove_symbolic, size: 16.0),
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
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AdwTooltip(
                  message: 'osd',
                  child: AdwProgressBar(
                    value: 0.5,
                    isOsd: true,
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
          child: AdwTooltip(
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
          child: AdwTooltip(
            message: 'suggested-action',
            child: AdwButton.suggested(
              onPressed: () {},
              child: const Text('Suggested', overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: AdwTooltip(
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
                    child: AdwTooltip(
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
                    child: AdwTooltip(
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
                    child: AdwTooltip(
                      message: 'osd',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdwButton.osd(
                            onPressed: () {},
                            child: const Icon(
                              AdwIcons.go_previous_symbolic,
                              size: 16.0,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          AdwButton.osd(
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
    final regularEntry = AdwEntry(
      controller: _entryRegular,
      placeholder: 'Regular',
      suffix: const Icon(AdwIcons.edit_copy_symbolic),
    );
    final successEntry = AdwTooltip(
      message: 'success',
      child: AdwEntry(
        controller: _entrySuccess,
        placeholder: 'Success',
        style: AdwEntryStyle.success,
        suffix: const Icon(AdwIcons.edit_copy_symbolic),
      ),
    );
    final warningEntry = AdwTooltip(
      message: 'warning',
      child: AdwEntry(
        controller: _entryWarning,
        placeholder: 'Warning',
        style: AdwEntryStyle.warning,
        suffix: const Icon(AdwIcons.edit_copy_symbolic),
      ),
    );
    final errorEntry = AdwTooltip(
      message: 'error',
      child: AdwEntry(
        controller: _entryError,
        placeholder: 'Error',
        style: AdwEntryStyle.error,
        suffix: const Icon(AdwIcons.edit_copy_symbolic),
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
    final flatGroup = AdwTooltip(
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

    final roundGroup = AdwTooltip(
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

    final osdGroup = AdwTooltip(
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
                AdwTooltip(
                  message: 'linked',
                  child: AdwLinkedBox(
                    dividerColor: gapColor,
                    children: [
                      AdwButton(
                        width: 34.0,
                        height: 34.0,
                        padding: EdgeInsets.zero,
                        isChecked: _linkedViewToggle == 0,
                        borderRadius: BorderRadius.zero,
                        onPressed: () => setState(() => _linkedViewToggle = 0),
                        child: const Icon(AdwIcons.view_grid_symbolic, size: 16.0),
                      ),
                      AdwButton(
                        width: 34.0,
                        height: 34.0,
                        padding: EdgeInsets.zero,
                        isChecked: _linkedViewToggle == 1,
                        borderRadius: BorderRadius.zero,
                        onPressed: () => setState(() => _linkedViewToggle = 1),
                        child: const Icon(AdwIcons.view_list_symbolic, size: 16.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: AdwTooltip(
                    message: 'linked',
                    child: AdwLinkedBox(
                      mainAxisSize: MainAxisSize.max,
                      dividerColor: gapColor,
                      children: [
                        Expanded(
                          child: AdwEntry(
                            controller: _linkedEntry1,
                            placeholder: 'Entry',
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        Expanded(
                          child: AdwEntry(
                            controller: _linkedEntry2,
                            placeholder: 'Entry',
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        AdwButton(
                          height: 34.0,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 17.0),
                          borderRadius: BorderRadius.zero,
                          onPressed: () {},
                          child: const Text('Button'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdwTooltip(
                  message: 'linked',
                  child: AdwLinkedBox(
                    direction: Axis.vertical,
                    dividerColor: gapColor,
                    children: [
                      AdwButton(
                        width: 34.0,
                        height: 34.0,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.zero,
                        onPressed: () {},
                        child:
                            const Icon(AdwIcons.edit_cut_symbolic, size: 16.0),
                      ),
                      AdwButton(
                        width: 34.0,
                        height: 34.0,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.zero,
                        onPressed: () {},
                        child: const Icon(AdwIcons.edit_copy_symbolic,
                            size: 16.0),
                      ),
                      AdwButton(
                        width: 34.0,
                        height: 34.0,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.zero,
                        onPressed: () {},
                        child: const Icon(AdwIcons.edit_paste_symbolic,
                            size: 16.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: AdwTooltip(
                    message: 'linked',
                    child: AdwLinkedBox(
                      direction: Axis.vertical,
                      dividerColor: gapColor,
                      children: [
                        AdwEntry(
                          controller: _streetEntry,
                          placeholder: 'Street',
                          borderRadius: BorderRadius.zero,
                        ),
                        AdwEntry(
                          controller: _cityEntry,
                          placeholder: 'City',
                          borderRadius: BorderRadius.zero,
                        ),
                        AdwEntry(
                          controller: _provinceEntry,
                          placeholder: 'Province',
                          borderRadius: BorderRadius.zero,
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
        AdwTooltip(
          message: 'title-1',
          child: Text('Title 1', style: typo.title1),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'title-2',
          child: Text('Title 2', style: typo.title2),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'title-3',
          child: Text('Title 3', style: typo.title3),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'title-4',
          child: Text('Title 4', style: typo.title4),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'monospace',
          child: Text('Monospace', style: typo.code),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'numeric',
          child: Text(
            'Numeric (1234567890)',
            style: typo.body.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'accent',
          child: Text(
            'Accent',
            style: typo.body.copyWith(color: _standaloneAccentColor(theme)),
          ),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'success',
          child: Text(
            'Success',
            style: typo.body.copyWith(color: _standaloneSuccessColor(theme)),
          ),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'warning',
          child: Text(
            'Warning',
            style: typo.body.copyWith(color: _standaloneWarningColor(theme)),
          ),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
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
        AdwTooltip(
          message: 'document',
          child: Text(
            'This is a document paragraph. It should be used for the app\'s main content.',
            style: typo.body.copyWith(height: 1.45),
          ),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'heading',
          child: Text('Heading', style: typo.heading),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'body',
          child: Text(
            'This is a paragraph of a body copy, to be used for medium-long text such as descriptions in the UI.',
            style: typo.body,
          ),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'caption-heading',
          child: Text('Caption Heading', style: typo.captionHeading),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
          message: 'caption',
          child: Text(
            'Caption body text, to be used for body copy on image captions and the like',
            style: typo.caption,
          ),
        ),
        const SizedBox(height: 12.0),
        AdwTooltip(
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
                  Expanded(
                    child: AdwTooltip(
                      message: 'card',
                      child: AdwCard(
                        alignment: Alignment.center,
                        child: Text(
                          'Card',
                          textAlign: TextAlign.center,
                          style: theme.typography.body,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: AdwTooltip(
                      message: 'card, activatable',
                      child: AdwCard(
                        activatable: true,
                        onPressed: () {},
                        alignment: Alignment.center,
                        child: Text(
                          'Card (Activatable)',
                          textAlign: TextAlign.center,
                          style: theme.typography.body,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: AdwTooltip(
                      message: 'card',
                      child: AdwCard(
                        activatable: true,
                        onPressed: () {},
                        alignment: Alignment.center,
                        child: Text(
                          'Card (Button)',
                          textAlign: TextAlign.center,
                          style: theme.typography.body,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            AdwTooltip(
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
                const AdwTooltip(
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
                const AdwTooltip(
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
                const AdwTooltip(
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
                        AdwTooltip(
                          message: 'selection-mode',
                          child: AdwCheckbox(
                            selectionMode: true,
                            value: _selCheck1,
                            onChanged: (v) => setState(() => _selCheck1 = v),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        AdwTooltip(
                          message: 'selection-mode',
                          child: AdwCheckbox(
                            selectionMode: true,
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
            AdwTooltip(
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
            AdwTooltip(
              message: 'toolbar, osd',
              child: AdwOsdSurface(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    AdwButton.osd(
                      isFlat: true,
                      onPressed: () {},
                      child: const Icon(
                        AdwIcons.media_skip_backward_symbolic,
                        size: 16.0,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    AdwButton.osd(
                      isFlat: true,
                      onPressed: () => setState(() => _isPlaying = !_isPlaying),
                      child: Icon(
                        _isPlaying
                            ? AdwIcons.media_playback_pause_symbolic
                            : AdwIcons.media_playback_start_symbolic,
                        size: 16.0,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    AdwButton.osd(
                      isFlat: true,
                      onPressed: () {},
                      child: const Icon(
                        AdwIcons.media_skip_forward_symbolic,
                        size: 16.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: AdwSlider(
                        isOsd: true,
                        value: _mediaProgress,
                        onChanged: (v) => setState(() => _mediaProgress = v),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    ValueListenableBuilder<double>(
                      valueListenable: _volumeNotifier,
                      builder: (_, vol, __) => AdwButton.osd(
                        key: _volumeBtnKey,
                        isFlat: true,
                        onPressed: _showVolumePopover,
                        child: Icon(_volumeIcon(vol), size: 16.0),
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
                child: AdwTooltip(
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
                child: AdwTooltip(
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
                child: AdwTooltip(
                  message: 'osd',
                  child: Container(
                    color: theme.colors.osdBackground,
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
          sidebar: const AdwTooltip(
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
          content: AdwTooltip(
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

