import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';
import 'package:adwaitter_icons/adwaitter_icons.dart';

import 'demo_icons.dart';

void main() {
  runApp(const AdwaitaDemoApplication());
}

class AdwaitaDemoApplication extends StatefulWidget {
  const AdwaitaDemoApplication({super.key});

  @override
  State<AdwaitaDemoApplication> createState() => _AdwaitaDemoApplicationState();
}

class _AdwaitaDemoApplicationState extends State<AdwaitaDemoApplication> {
  AdwThemeMode _themeMode = AdwThemeMode.system;
  AdwAccentColor? _accentColor;

  void _setThemeMode(AdwThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _changeAccent(AdwAccentColor? color) {
    setState(() {
      _accentColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdwApplication(
      title: 'Adwaitter Demo',
      themeMode: _themeMode,
      accentColor: _accentColor,
      home: AdwToastOverlay(
        child: AdwaitaDemoWindow(
          currentThemeMode: _themeMode,
          currentAccent: _accentColor,
          onThemeModeChanged: _setThemeMode,
          onAccentChanged: _changeAccent,
        ),
      ),
    );
  }
}

enum DemoPage {
  welcome,
  navigationView,
  splitViews,
  viewSwitcher,
  tabView,
  bottomSheet,
  carousel,
  boxedLists,
  toggleGroups,
  buttons,
  banner,
  toasts,
  spinner,
  avatar,
  alertDialog,
  aboutDialog,
  clamp,
  wrapBox,
  multiLayoutView,
  styleClasses,
  animations,
  appearance,
}

class AdwaitaDemoWindow extends StatefulWidget {
  final AdwThemeMode currentThemeMode;
  final AdwAccentColor? currentAccent;
  final ValueChanged<AdwThemeMode> onThemeModeChanged;
  final ValueChanged<AdwAccentColor?> onAccentChanged;

  const AdwaitaDemoWindow({
    super.key,
    required this.currentThemeMode,
    required this.currentAccent,
    required this.onThemeModeChanged,
    required this.onAccentChanged,
  });

  @override
  State<AdwaitaDemoWindow> createState() => _AdwaitaDemoWindowState();
}

class _AdwaitaDemoWindowState extends State<AdwaitaDemoWindow> {
  DemoPage _selectedPage = DemoPage.welcome;
  String _searchFilter = '';
  bool _searchBarVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchFocused = false;

  // Interactive component demo state variables
  bool _switchRowValue = false;
  double _spinValue = 50.0;
  String _selectedComboOption = 'Foo';
  String _selectedEnumComboOption = 'unknown';
  bool _bannerRevealed = true;
  int _viewSwitcherIndex = 0;
  final AdwCarouselController _carouselController = AdwCarouselController();
  String _selectedToggleInterval = 'Day';
  int _selectedAlignment = 1;
  int _selectedPrefixOption = 0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
  }

  void _handleSearchFocusChange() {
    if (mounted) {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    }
  }

  void _toggleSidebarSearch() {
    setState(() {
      _searchBarVisible = !_searchBarVisible;
      if (_searchBarVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _searchBarVisible) {
            _searchFocusNode.requestFocus();
          }
        });
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        _searchFilter = '';
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  void _showPreferencesMenu(BuildContext context) {
    AdwThemeMode localMode = widget.currentThemeMode;
    AdwAccentColor? localAccent = widget.currentAccent;

    showAdwAlertDialog(
      context: context,
      heading: const Text('Preferences'),
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final theme = AdwTheme.of(dialogContext);
          final resolvedAccent =
              localAccent ?? AdwStyleManager.instance.accentColor;

          return SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdwPreferencesGroup(
                  children: [
                    AdwComboRow<AdwThemeMode>(
                      prefix:
                          const Icon(AdwIcons.night_light_symbolic, size: 20),
                      title: const Text('Color Scheme'),
                      items: AdwThemeMode.values,
                      selectedItem: localMode,
                      itemTitleBuilder: (mode) => mode == AdwThemeMode.system
                          ? 'Default'
                          : mode == AdwThemeMode.light
                              ? 'Light'
                              : 'Dark',
                      onSelected: (mode) {
                        setDialogState(() => localMode = mode);
                        widget.onThemeModeChanged(mode);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AdwPreferencesGroup(
                  title: const Text('ACCENT COLOR'),
                  headerSuffix: localAccent != null
                      ? AdwButton.flat(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          onPressed: () {
                            setDialogState(() => localAccent = null);
                            widget.onAccentChanged(null);
                          },
                          child: const Text('System'),
                        )
                      : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Center(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AdwAccentColor.values.map((accent) {
                            final isSelected = resolvedAccent == accent;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() => localAccent = accent);
                                widget.onAccentChanged(accent);
                              },
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: accent.color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: theme.colors.foreground,
                                          width: 2.5)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AdwButton.flat(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAbout(context);
                  },
                  child: const Text('About Adwaitter Demo'),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        AdwButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    showAdwAboutDialog(
      context: context,
      applicationName: 'Adwaitter Demo',
      version: '1.0.0',
      developerName: 'Libadwaitter Contributors',
      comments:
          'A pure Dart & Flutter implementation of GNOME Libadwaita and GNOME HIG.',
      website: 'https://gitlab.gnome.org/GNOME/libadwaita',
      copyright: '© 2026 The GNOME Project & Libadwaitter Authors',
      license:
          'GNU Lesser General Public License Version 2.1 (LGPL-2.1-or-later)',
    );
  }

  void _showResetDialog(BuildContext context) {
    showAdwAlertDialog(
      context: context,
      heading: const Text('Reset Demo Settings?'),
      body: const Text(
        'Are you sure you want to reset all controls to their default state? '
        'This action is reversible by changing the controls again.',
      ),
      actions: [
        AdwButton.flat(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AdwButton.destructive(
          onPressed: () {
            Navigator.of(context).pop();
            setState(() {
              _switchRowValue = false;
              _spinValue = 50.0;
              _selectedComboOption = 'Option Alpha';
              _bannerRevealed = true;
            });
            AdwToastOverlay.of(context).addToast(
              const AdwToast(
                title: Text('Settings restored to defaults'),
              ),
            );
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }

  void _showDemoToast(BuildContext context) {
    AdwToastOverlay.of(context).addToast(
      AdwToast(
        title: const Text('File downloaded to ~/Downloads'),
        action: AdwButton.suggested(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          onPressed: () {},
          child: const Text('Undo'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final isDark = theme.colors.isDark;

    return AdwWindow(
      showShadow: true,
      showBorder: true,
      child: AdwNavigationSplitView(
        sidebarWidth: 240.0,
        sidebar: _buildSidebar(theme),
        content: _buildContent(theme, isDark),
      ),
    );
  }

  Widget _buildSidebar(AdwThemeData theme) {
    return Column(
      children: [
        // Flat sidebar header bar (matching adwaita-1-demo; shows window controls when collapsed)
        Builder(
          builder: (sidebarContext) {
            final isCollapsed =
                AdwNavigationSplitViewScope.maybeOf(sidebarContext)
                        ?.isCollapsed ??
                    false;
            return AdwHeaderBar(
              isFlat: true,
              showWindowControls: isCollapsed,
              start: AdwButton(
                style: _searchBarVisible
                    ? AdwButtonStyle.standard
                    : AdwButtonStyle.flat,
                width: 34,
                height: 34,
                padding: EdgeInsets.zero,
                onPressed: _toggleSidebarSearch,
                child: const Icon(AdwIcons.edit_find_symbolic, size: 16),
              ),
              title: const Text('Adwaitter Demo'),
              end: AdwButton.flat(
                width: 34,
                height: 34,
                padding: EdgeInsets.zero,
                onPressed: () => _showPreferencesMenu(context),
                child: const Icon(AdwIcons.open_menu_symbolic, size: 16),
              ),
            );
          },
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: AdwCurves.normalDuration,
            curve: AdwCurves.standard,
            alignment: Alignment.topCenter,
            heightFactor: _searchBarVisible ? 1.0 : 0.0,
            child: AnimatedOpacity(
              duration: AdwCurves.normalDuration,
              curve: AdwCurves.standard,
              opacity: _searchBarVisible ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_searchBarVisible,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: TapRegion(
                    onTapOutside: (_) {
                      if (_searchFocusNode.hasFocus) {
                        _searchFocusNode.unfocus();
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _searchFocusNode.requestFocus(),
                      child: AnimatedContainer(
                        duration: AdwCurves.shortDuration,
                        curve: AdwCurves.standard,
                        height: 34,
                        padding: EdgeInsets.symmetric(
                          horizontal: _searchFocused ? 9.0 : 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colors.isDark
                              ? const Color(0xFF3E3E42)
                              : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(7.0),
                          border: Border.all(
                            color: _searchFocused
                                ? theme.colors.accentColor
                                    .withValues(alpha: 0.75)
                                : theme.colors.borderColor,
                            width: _searchFocused ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AdwIcons.edit_find_symbolic,
                              size: 15,
                              color: theme.colors.secondaryForeground,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  if (_searchController.text.isEmpty)
                                    IgnorePointer(
                                      child: Text(
                                        'Find pages',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.typography.body.copyWith(
                                          color: theme
                                              .colors.secondaryForeground
                                              .withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ),
                                  EditableText(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    style: theme.typography.body.copyWith(
                                      color: theme.colors.windowForeground,
                                    ),
                                    cursorColor: theme.colors.windowForeground,
                                    backgroundCursorColor:
                                        theme.colors.borderColor,
                                    selectionColor: theme.colors.accentColor
                                        .withValues(alpha: 0.35),
                                    onChanged: (val) => setState(
                                      () => _searchFilter = val.toLowerCase(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_searchController.text.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchFilter = '');
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Icon(
                                    AdwIcons.edit_clear_symbolic,
                                    size: 15,
                                    color: theme.colors.secondaryForeground,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (sidebarContext) {
              final isCollapsed =
                  AdwNavigationSplitViewScope.maybeOf(sidebarContext)
                          ?.isCollapsed ??
                      false;
              return SingleChildScrollView(
                padding: isCollapsed
                    ? const EdgeInsets.fromLTRB(12, 20, 12, 24)
                    : const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isCollapsed)
                      AdwPreferencesGroup(
                        margin: const EdgeInsets.only(bottom: 18),
                        children: [
                          _buildSidebarItem(
                            page: DemoPage.welcome,
                            iconWidget: const AdwEmblem(size: 16, strokeWidth: 1.25),
                            title: 'Welcome',
                            isCollapsed: true,
                          ),
                        ],
                      )
                    else
                      _buildSidebarItem(
                        page: DemoPage.welcome,
                        iconWidget: const AdwEmblem(size: 16, strokeWidth: 1.25),
                        title: 'Welcome',
                        isCollapsed: false,
                      ),
                    _buildSidebarSection(
                        theme,
                        'Navigation',
                        [
                          _buildSidebarItem(
                            page: DemoPage.navigationView,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.navigationView,
                                size: 16),
                            title: 'Navigation View',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.splitViews,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.splitView,
                                size: 16),
                            title: 'Split Views',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.viewSwitcher,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.viewSwitcher,
                                size: 16),
                            title: 'View Switcher',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.tabView,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.tabView,
                                size: 16),
                            title: 'Tab View',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.bottomSheet,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.bottomSheet,
                                size: 16),
                            title: 'Bottom Sheet',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.carousel,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.carousel,
                                size: 16),
                            title: 'Carousel',
                            isCollapsed: isCollapsed,
                          ),
                        ],
                        isCollapsed: isCollapsed),
                    _buildSidebarSection(
                        theme,
                        'Controls',
                        [
                          _buildSidebarItem(
                            page: DemoPage.boxedLists,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.boxedList,
                                size: 16),
                            title: 'Boxed Lists',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.toggleGroups,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.toggleGroup,
                                size: 16),
                            title: 'Toggle Groups',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.buttons,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.buttons,
                                size: 16),
                            title: 'Buttons',
                            isCollapsed: isCollapsed,
                          ),
                        ],
                        isCollapsed: isCollapsed),
                    _buildSidebarSection(
                        theme,
                        'Display',
                        [
                          _buildSidebarItem(
                            page: DemoPage.banner,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.banner,
                                size: 16),
                            title: 'Banner',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.toasts,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.toasts,
                                size: 16),
                            title: 'Toasts',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.spinner,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.spinner,
                                size: 16),
                            title: 'Spinner',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.avatar,
                            icon: AdwIcons.avatar_default_symbolic,
                            title: 'Avatar',
                            isCollapsed: isCollapsed,
                          ),
                        ],
                        isCollapsed: isCollapsed),
                    _buildSidebarSection(
                        theme,
                        'Dialogs',
                        [
                          _buildSidebarItem(
                            page: DemoPage.alertDialog,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.alertDialog,
                                size: 16),
                            title: 'Alert Dialog',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.aboutDialog,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.aboutDialog,
                                size: 16),
                            title: 'About Dialog',
                            isCollapsed: isCollapsed,
                          ),
                        ],
                        isCollapsed: isCollapsed),
                    _buildSidebarSection(
                        theme,
                        'Layout',
                        [
                          _buildSidebarItem(
                            page: DemoPage.clamp,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.clamp,
                                size: 16),
                            title: 'Clamp',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.wrapBox,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.wrapBox,
                                size: 16),
                            title: 'Wrap Box',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.multiLayoutView,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.multiLayoutView,
                                size: 16),
                            title: 'Multi-Layout View',
                            isCollapsed: isCollapsed,
                          ),
                        ],
                        isCollapsed: isCollapsed),
                    _buildSidebarSection(
                        theme,
                        'Miscellaneous',
                        [
                          _buildSidebarItem(
                            page: DemoPage.styleClasses,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.styleClasses,
                                size: 16),
                            title: 'Style Classes',
                            isCollapsed: isCollapsed,
                          ),
                          _buildSidebarItem(
                            page: DemoPage.animations,
                            iconWidget: const DemoWidgetIcon(
                                DemoIconType.animations,
                                size: 16),
                            title: 'Animations',
                            isCollapsed: isCollapsed,
                          ),
                        ],
                        isCollapsed: isCollapsed),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required DemoPage page,
    Widget? iconWidget,
    IconData? icon,
    required String title,
    required bool isCollapsed,
  }) {
    if (_searchFilter.isNotEmpty &&
        !title.toLowerCase().contains(_searchFilter)) {
      return const SizedBox.shrink();
    }
    return Builder(
      builder: (itemContext) {
        void handleSelect() {
          setState(() => _selectedPage = page);
          AdwNavigationSplitViewScope.maybeOf(itemContext)?.showContentPage();
        }

        if (isCollapsed) {
          final isSingleItem = page == DemoPage.welcome;
          return AdwActionRow(
            minHeight: isSingleItem ? 46.0 : AdwMetrics.rowMinHeight,
            padding: isSingleItem
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            prefix: iconWidget ?? (icon != null ? Icon(icon, size: 16) : null),
            title: Text(title),
            trailing: const Icon(AdwIcons.go_next_symbolic, size: 16),
            onPressed: handleSelect,
          );
        }

        return AdwSidebarItem(
          icon: iconWidget ?? (icon != null ? Icon(icon) : null),
          title: Text(title),
          isSelected: _selectedPage == page,
          onTap: handleSelect,
        );
      },
    );
  }

  Widget _buildSidebarSection(
    AdwThemeData theme,
    String title,
    List<Widget> items, {
    required bool isCollapsed,
  }) {
    final visibleItems =
        items.where((item) => item is! SizedBox).toList(growable: false);
    if (visibleItems.isEmpty) return const SizedBox.shrink();

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: AdwPreferencesGroup(
          margin: const EdgeInsets.only(bottom: 18),
          title: Text(title),
          children: visibleItems,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
          child: Text(
            title,
            style: theme.typography.sectionTitle,
          ),
        ),
        ...visibleItems,
      ],
    );
  }

  Widget _buildContent(AdwThemeData theme, bool isDark) {
    return Column(
      children: [
        // Flat content view header bar with in-app window controls on the right
        const AdwHeaderBar(
          isFlat: true,
          showWindowControls: true,
        ),
        Expanded(
          child: _buildPageBody(theme, isDark),
        ),
      ],
    );
  }

  String _getPageTitle(DemoPage page) {
    switch (page) {
      case DemoPage.welcome:
        return 'Welcome to Adwaitter Demo';
      case DemoPage.navigationView:
        return 'Navigation View';
      case DemoPage.splitViews:
        return 'Split Views';
      case DemoPage.viewSwitcher:
        return 'View Switcher';
      case DemoPage.tabView:
        return 'Tab View';
      case DemoPage.bottomSheet:
        return 'Bottom Sheet';
      case DemoPage.carousel:
        return 'Carousel';
      case DemoPage.boxedLists:
        return 'Boxed Lists';
      case DemoPage.toggleGroups:
        return 'Toggle Groups';
      case DemoPage.buttons:
        return 'Buttons';
      case DemoPage.banner:
        return 'Banner';
      case DemoPage.toasts:
        return 'Toast';
      case DemoPage.spinner:
        return 'Spinner';
      case DemoPage.avatar:
        return 'Avatar';
      case DemoPage.alertDialog:
        return 'Alert Dialog';
      case DemoPage.aboutDialog:
        return 'About Dialog';
      case DemoPage.clamp:
        return 'Clamp';
      case DemoPage.wrapBox:
        return 'Wrap Box';
      case DemoPage.multiLayoutView:
        return 'Multi-Layout View';
      case DemoPage.styleClasses:
        return 'Style Classes';
      case DemoPage.animations:
        return 'Animations';
      case DemoPage.appearance:
        return 'Appearance & Accent';
    }
  }

  Widget _buildPageBody(AdwThemeData theme, bool isDark) {
    switch (_selectedPage) {
      case DemoPage.welcome:
        return const AdwStatusPage(
          icon: AdwEmblem(size: 128, strokeWidth: 0.85),
          title: Text('Welcome to Adwaitter Demo'),
          description:
              Text('This is a tour of the features the library has to offer'),
        );

      case DemoPage.boxedLists:
        return AdwPreferencesPage(
          icon: const DemoWidgetIcon(DemoIconType.boxedList, size: 136),
          title: const Text('Boxed Lists'),
          description: const Text('Rows for the boxed list pattern'),
          children: [
                AdwPreferencesGroup(
                  children: [
                    const AdwActionRow(
                      title: Text('Rows Have a Title'),
                      subtitle: Text('They also have a subtitle'),
                    ),
                    AdwActionRow(
                      title: const Text('Rows Can Have Suffix Widgets'),
                      suffix: AdwButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        onPressed: () {
                          AdwToastOverlay.of(context).addToast(
                            const AdwToast(title: Text('Action clicked')),
                          );
                        },
                        child: const Text('Action'),
                      ),
                    ),
                  ],
                ),
                AdwPreferencesGroup(
                  children: [
                    AdwActionRow(
                      prefix: AdwRadio<int>(
                        value: 0,
                        groupValue: _selectedPrefixOption,
                        onChanged: (val) =>
                            setState(() => _selectedPrefixOption = val ?? 0),
                      ),
                      title: const Text('Rows Can Have Prefix Widgets'),
                      onPressed: () =>
                          setState(() => _selectedPrefixOption = 0),
                    ),
                    AdwActionRow(
                      prefix: AdwRadio<int>(
                        value: 1,
                        groupValue: _selectedPrefixOption,
                        onChanged: (val) =>
                            setState(() => _selectedPrefixOption = val ?? 1),
                      ),
                      title: const Text('Rows Can Have Prefix Widgets'),
                      onPressed: () =>
                          setState(() => _selectedPrefixOption = 1),
                    ),
                  ],
                ),
                AdwPreferencesGroup(
                  title: const Text('Entry Rows'),
                  separated: true,
                  children: [
                    const AdwEntryRow(
                      title: Text('Entry Row'),
                      editIcon: Icon(AdwIcons.document_edit_symbolic, size: 16),
                    ),
                    AdwEntryRow(
                      title: const Text('Entry With Confirmation'),
                      showApplyButton: true,
                      editIcon:
                          const Icon(AdwIcons.document_edit_symbolic, size: 16),
                      onApply: (val) {
                        AdwToastOverlay.of(context).addToast(
                          AdwToast(title: Text('Applied: "$val"')),
                        );
                      },
                    ),
                    AdwEntryRow(
                      title: const Text('Entry With Suffix'),
                      editIcon:
                          const Icon(AdwIcons.document_edit_symbolic, size: 16),
                      suffix: AdwButton.flat(
                        padding: const EdgeInsets.all(6),
                        onPressed: () {
                          AdwToastOverlay.of(context).addToast(
                            const AdwToast(
                                title: Text('Suffix action triggered')),
                          );
                        },
                        child: const Icon(
                          AdwIcons.edit_copy_symbolic,
                          size: 16,
                        ),
                      ),
                    ),
                    const AdwPasswordEntryRow(
                      title: Text('Password Entry'),
                      editIcon: Icon(AdwIcons.document_edit_symbolic, size: 16),
                      revealIcon: Icon(AdwIcons.view_reveal_symbolic, size: 16),
                      concealIcon:
                          Icon(AdwIcons.view_conceal_symbolic, size: 16),
                    ),
                  ],
                ),
                AdwPreferencesGroup(
                  title: const Text('Spin Rows'),
                  children: [
                    AdwSpinRow(
                      title: const Text('Spin Row'),
                      value: _spinValue,
                      min: 0,
                      max: 100,
                      step: 1,
                      onChanged: (val) => setState(() => _spinValue = val),
                    ),
                  ],
                ),
                AdwPreferencesGroup(
                  title: const Text('Switch Rows'),
                  children: [
                    AdwSwitchRow(
                      title: const Text('Switch Row'),
                      value: _switchRowValue,
                      onChanged: (val) =>
                          setState(() => _switchRowValue = val),
                    ),
                  ],
                ),
                AdwPreferencesGroup(
                  title: const Text('Combo Rows'),
                  children: [
                    AdwComboRow<String>(
                      title: const Text('Combo Row'),
                      items: const ['Foo', 'Bar', 'Baz'],
                      selectedItem: _selectedComboOption,
                      onSelected: (val) =>
                          setState(() => _selectedComboOption = val),
                    ),
                    AdwComboRow<String>(
                      title: const Text('Enumeration Combo Row'),
                      subtitle: const Text(
                          'This combo row was created from an enumeration'),
                      enableSearch: true,
                      items: const [
                        'unknown',
                        'custom',
                        'gpl-2-0',
                        'gpl-3-0',
                        'lgpl-2-1',
                        'lgpl-3-0',
                        'bsd',
                        'mit-x11',
                        'artistic',
                        'gpl-2-0-only',
                        'gpl-2-0-or-later',
                        'gpl-3-0-only',
                        'gpl-3-0-or-later',
                        'lgpl-2-1-only',
                        'lgpl-2-1-or-later',
                        'bsd-3-clause',
                        'apache-2-0',
                        'mpl-2-0',
                      ],
                      selectedItem: _selectedEnumComboOption,
                      onSelected: (val) =>
                          setState(() => _selectedEnumComboOption = val),
                    ),
                  ],
                ),
                AdwPreferencesGroup(
                  title: const Text('Expander Rows'),
                  children: [
                    const AdwExpanderRow(
                      title: Text('Expander Row'),
                      children: [
                        AdwActionRow(
                          title: Text('A Nested Row'),
                        ),
                        AdwActionRow(
                          title: Text('Another Nested Row'),
                        ),
                      ],
                    ),
                    AdwExpanderRow(
                      title: const Text('Expander Row With an Action'),
                      suffix: AdwButton.flat(
                        padding: const EdgeInsets.all(6),
                        onPressed: () {
                          AdwToastOverlay.of(context).addToast(
                            const AdwToast(
                                title: Text('Expander action triggered')),
                          );
                        },
                        child: const Icon(
                          AdwIcons.edit_copy_symbolic,
                          size: 16,
                        ),
                      ),
                      children: const [
                        AdwActionRow(
                          title: Text('A Nested Row'),
                        ),
                        AdwActionRow(
                          title: Text('Another Nested Row'),
                        ),
                      ],
                    ),
                    const AdwExpanderRow(
                      title: Text('Toggleable Expander Row'),
                      showEnableSwitch: true,
                      enabled: false,
                      children: [
                        AdwActionRow(
                          title: Text('A Nested Row'),
                        ),
                        AdwActionRow(
                          title: Text('Another Nested Row'),
                        ),
                      ],
                    ),
                  ],
                ),
                const AdwPreferencesGroup(
                  title: Text('Property Rows'),
                  children: [
                    AdwActionRow.property(
                      title: Text('Property Row'),
                      subtitle: Text('Value'),
                    ),
                  ],
                ),
                AdwPreferencesGroup(
                  title: const Text('Groups With Suffix'),
                  headerSuffix: AdwButton.flat(
                    height: 30.0,
                    borderRadius: BorderRadius.circular(8.0),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    onPressed: () {
                      AdwToastOverlay.of(context).addToast(
                        const AdwToast(title: Text('Group suffix clicked')),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(AdwIcons.list_add_symbolic, size: 16),
                        SizedBox(width: 6),
                        Text('Suffix'),
                      ],
                    ),
                  ),
                  children: const [
                    AdwActionRow(
                      minHeight: 53.0,
                      title: Text('Groups Can Have a Header Suffix'),
                    ),
                  ],
                ),
                AdwPreferencesGroup(
                  title: const Text('Button Rows'),
                  separated: true,
                  separatedSpacing: 14.0,
                  children: [
                    AdwButtonRow(
                      startIcon:
                          const Icon(AdwIcons.list_add_symbolic, size: 16),
                      title: const Text('Add Input Source'),
                      onPressed: () {
                        AdwToastOverlay.of(context).addToast(
                          const AdwToast(title: Text('Add Input Source')),
                        );
                      },
                    ),
                    AdwButtonRow(
                      title: const Text('Add Calendar'),
                      endIcon: const Icon(AdwIcons.go_next_symbolic, size: 16),
                      onPressed: () {
                        AdwToastOverlay.of(context).addToast(
                          const AdwToast(title: Text('Add Calendar')),
                        );
                      },
                    ),
                    AdwButtonRow.destructive(
                      title: const Text('Delete Event'),
                      onPressed: () {
                        AdwToastOverlay.of(context).addToast(
                          const AdwToast(title: Text('Delete Event')),
                        );
                      },
                    ),
                    AdwButtonRow.suggested(
                      title: const Text('Search'),
                      onPressed: () {
                        AdwToastOverlay.of(context).addToast(
                          const AdwToast(title: Text('Search')),
                        );
                      },
                    ),
                  ],
                ),
              ],
        );

      case DemoPage.buttons:
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: AdwClamp(
            maximumSize: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdwButton(
                  onPressed: () {},
                  child: const Text('Standard Button'),
                ),
                const SizedBox(height: 12),
                AdwButton.suggested(
                  onPressed: () {},
                  child: const Text('Suggested Action (Accent)'),
                ),
                const SizedBox(height: 12),
                AdwButton.destructive(
                  onPressed: () {},
                  child: const Text('Destructive Action (Red)'),
                ),
                const SizedBox(height: 12),
                AdwButton.flat(
                  onPressed: () {},
                  child: const Text('Flat Button'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: AdwButton.pill(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    onPressed: () {},
                    child: const Text('Pill Button'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: AdwButton.circular(
                    padding: const EdgeInsets.all(12),
                    onPressed: () {},
                    child: const Icon(AdwIcons.user_home_symbolic, size: 18),
                  ),
                ),
              ],
            ),
          ),
        );

      case DemoPage.viewSwitcher:
        return Column(
          children: [
            const SizedBox(height: 16),
            AdwViewSwitcher(
              items: const [
                AdwViewSwitcherItem(
                  icon: Icon(AdwIcons.view_reveal_symbolic),
                  title: 'Explore',
                ),
                AdwViewSwitcherItem(
                  icon: Icon(AdwIcons.system_software_install_symbolic),
                  title: 'Installed',
                ),
                AdwViewSwitcherItem(
                  icon: Icon(AdwIcons.software_update_available_symbolic),
                  title: 'Updates',
                ),
              ],
              currentIndex: _viewSwitcherIndex,
              onIndexChanged: (i) => setState(() => _viewSwitcherIndex = i),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _viewSwitcherIndex == 0
                      ? 'Explore View Content'
                      : (_viewSwitcherIndex == 1
                          ? 'Installed Packages'
                          : 'System Updates Available'),
                  style: theme.typography.title2,
                ),
              ),
            ),
          ],
        );

      case DemoPage.banner:
        return Column(
          children: [
            AdwBanner(
              revealed: _bannerRevealed,
              title: const Text(
                  'No Internet Connection. Some features may be unavailable.'),
              buttonLabel: 'Retry',
              onButtonPressed: () {
                AdwToastOverlay.of(context).addToast(
                  const AdwToast(title: Text('Retrying network connection...')),
                );
              },
            ),
            Expanded(
              child: Center(
                child: AdwButton(
                  onPressed: () =>
                      setState(() => _bannerRevealed = !_bannerRevealed),
                  child: Text(_bannerRevealed ? 'Hide Banner' : 'Show Banner'),
                ),
              ),
            ),
          ],
        );

      case DemoPage.toasts:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdwButton.suggested(
                isPill: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                onPressed: () => _showDemoToast(context),
                child: const Text('Show Toast Notification'),
              ),
              const SizedBox(height: 12),
              AdwButton(
                isPill: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                onPressed: () {
                  AdwToastOverlay.of(context).addToast(
                    const AdwToast(
                      title: Text('Preferences saved successfully'),
                    ),
                  );
                },
                child: const Text('Show Simple Toast'),
              ),
            ],
          ),
        );

      case DemoPage.appearance:
        return AdwPreferencesPage(
          maxWidth: 560,
          children: [
                AdwPreferencesGroup(
                  title: const Text('APPEARANCE & ACCENT COLOR'),
                  description: const Text(
                    'Supports the 9 official GNOME 47 accent colors with seamless dark mode switching.',
                  ),
                  children: [
                    AdwComboRow<AdwThemeMode>(
                      prefix:
                          const Icon(AdwIcons.night_light_symbolic, size: 20),
                      title: const Text('Color Scheme'),
                      items: AdwThemeMode.values,
                      selectedItem: widget.currentThemeMode,
                      itemTitleBuilder: (mode) => mode == AdwThemeMode.system
                          ? 'Default'
                          : mode == AdwThemeMode.light
                              ? 'Light'
                              : 'Dark',
                      onSelected: widget.onThemeModeChanged,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accent Color',
                            style: theme.typography.body
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: AdwAccentColor.values.map((accent) {
                              final effectiveAccent = widget.currentAccent ??
                                  AdwStyleManager.instance.accentColor;
                              final isSelected = effectiveAccent == accent;
                              return GestureDetector(
                                onTap: () => widget.onAccentChanged(accent),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: accent.color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: theme.colors.foreground,
                                            width: 3)
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ],
        );

      case DemoPage.alertDialog:
        return AdwStatusPage(
          title: const Text('Alert Dialog'),
          child: Center(
            child: AdwButton(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              onPressed: () => _showResetDialog(context),
              child: const Text('Open Alert Dialog'),
            ),
          ),
        );

      case DemoPage.aboutDialog:
        return AdwStatusPage(
          title: const Text('About Dialog'),
          child: Center(
            child: AdwButton.suggested(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              onPressed: () => _showAbout(context),
              child: const Text('Open About Dialog'),
            ),
          ),
        );

      case DemoPage.carousel:
        return _buildCarouselPage(theme);

      case DemoPage.toggleGroups:
        return _buildToggleGroupsPage(theme);

      case DemoPage.navigationView:
        return AdwStatusPage(
          icon: const DemoWidgetIcon(DemoIconType.navigationView, size: 128),
          title: const Text('Navigation View'),
          description: const Text('A page-based navigation container'),
          child: Center(
            child: Builder(
              builder: (innerContext) => AdwButton.pill(
                onPressed: () =>
                    _openNavigationViewDemoDialog(innerContext, theme),
                child: const Text('Run the Demo'),
              ),
            ),
          ),
        );

      case DemoPage.splitViews:
        return AdwStatusPage(
          icon: const DemoWidgetIcon(DemoIconType.splitView, size: 128),
          title: const Text('Split Views'),
          description: const Text('Widgets that display sidebar and content'),
          child: Center(
            child: Builder(
              builder: (innerContext) => IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdwButton.pill(
                      onPressed: () =>
                          _openNavigationSplitViewDemoDialog(innerContext),
                      child: const Text('Navigation Split View'),
                    ),
                    const SizedBox(height: 18),
                    AdwButton.pill(
                      onPressed: () =>
                          _openOverlaySplitViewDemoDialog(innerContext),
                      child: const Text('Overlay Split View'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case DemoPage.tabView:
      case DemoPage.bottomSheet:
      case DemoPage.spinner:
      case DemoPage.avatar:
      case DemoPage.clamp:
      case DemoPage.wrapBox:
      case DemoPage.multiLayoutView:
      case DemoPage.styleClasses:
      case DemoPage.animations:
        return AdwStatusPage(
          title: Text(_getPageTitle(_selectedPage)),
          description: const Text('Pending review against native demo'),
        );
    }
  }

  void _openNavigationSplitViewDemoDialog(BuildContext context) {
    showAdwDialog<void>(
      context: context,
      builder: (_) => const AdwDialog(
        contentWidth: 640,
        contentHeight: 480,
        title: 'Navigation Split View',
        child: AdwNavigationSplitView(
          sidebarWidth: 220,
          sidebar: AdwToolbarView(
            topBar: AdwHeaderBar(
              isFlat: true,
              showWindowControls: false,
              title: SizedBox.shrink(),
            ),
            content: AdwStatusPage(
              title: Text('Sidebar'),
            ),
          ),
          content: AdwToolbarView(
            topBar: AdwHeaderBar(
              isFlat: true,
              title: SizedBox.shrink(),
            ),
            content: AdwStatusPage(
              title: Text('Content'),
            ),
          ),
        ),
      ),
    );
  }

  void _openOverlaySplitViewDemoDialog(BuildContext context) {
    bool showSidebar = true;
    AdwSplitViewPosition position = AdwSplitViewPosition.start;

    showAdwDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AdwDialog(
            contentWidth: 640,
            contentHeight: 480,
            title: 'Overlay Split View',
            child: AdwToolbarView(
              topBar: AdwHeaderBar(
                title: const Text('Overlay Split View'),
                start: position == AdwSplitViewPosition.start
                    ? AdwButton.flat(
                        width: 34,
                        height: 34,
                        isChecked: showSidebar,
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            setDialogState(() => showSidebar = !showSidebar),
                        child: const Icon(AdwIcons.sidebar_show_symbolic,
                            size: 16),
                      )
                    : null,
                end: position == AdwSplitViewPosition.end
                    ? AdwButton.flat(
                        width: 34,
                        height: 34,
                        isChecked: showSidebar,
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            setDialogState(() => showSidebar = !showSidebar),
                        child: const Icon(AdwIcons.sidebar_show_right_symbolic,
                            size: 16),
                      )
                    : null,
              ),
              content: AdwOverlaySplitView(
                showSidebar: showSidebar,
                sidebarPosition: position,
                onShowSidebarChanged: (v) =>
                    setDialogState(() => showSidebar = v),
                sidebar: AdwStatusPage(
                  title: const Text('Sidebar'),
                  child: Center(
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AdwButton.pill(
                            isChecked: position == AdwSplitViewPosition.start,
                            onPressed: () => setDialogState(
                                () => position = AdwSplitViewPosition.start),
                            child: const Text('Start'),
                          ),
                          const SizedBox(height: 18),
                          AdwButton.pill(
                            isChecked: position == AdwSplitViewPosition.end,
                            onPressed: () => setDialogState(
                                () => position = AdwSplitViewPosition.end),
                            child: const Text('End'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                content: const AdwStatusPage(
                  title: Text('Content'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openNavigationViewDemoDialog(
      BuildContext context, AdwThemeData theme) {
    final navController = AdwNavigationViewController();

    AdwNavigationPage buildPage3() {
      return AdwNavigationPage(
        tag: 'page-3',
        title: 'Page 3',
        child: AdwToolbarView(
          topBar: const AdwHeaderBar(isFlat: true),
          content: Center(
            child: Text(
              'Page 3',
              style: theme.typography.title1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    AdwNavigationPage buildPage4() {
      return AdwNavigationPage(
        tag: 'page-4',
        title: 'Page 4',
        child: AdwToolbarView(
          topBar: const AdwHeaderBar(isFlat: true),
          content: Center(
            child: AdwButton.pill(
              onPressed: () => navController.push(buildPage3()),
              child: const Text('Open Page 3'),
            ),
          ),
        ),
      );
    }

    AdwNavigationPage buildPage2() {
      return AdwNavigationPage(
        tag: 'page-2',
        title: 'Page 2',
        child: AdwToolbarView(
          topBar: const AdwHeaderBar(isFlat: true),
          content: Center(
            child: AdwButton.pill(
              onPressed: () => navController.push(buildPage4()),
              child: const Text('Open Page 4'),
            ),
          ),
        ),
      );
    }

    showAdwDialog<void>(
      context: context,
      builder: (_) => AdwDialog(
        contentWidth: 360,
        contentHeight: 360,
        title: 'AdwNavigationView Demo',
        child: AdwNavigationView(
          controller: navController,
          initialPage: AdwNavigationPage(
            tag: 'page-1',
            title: 'Page 1',
            child: AdwToolbarView(
              topBar: const AdwHeaderBar(isFlat: true),
              content: Center(
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdwButton.pill(
                        onPressed: () => navController.push(buildPage2()),
                        child: const Text('Open Page 2'),
                      ),
                      const SizedBox(height: 18),
                      AdwButton.pill(
                        onPressed: () => navController.push(buildPage3()),
                        child: const Text('Open Page 3'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselPage(AdwThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: AdwClamp(
        maximumSize: 740,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Featured banner carousel (resembling GNOME Software upstream)
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AdwMetrics.cardRadius),
                child: AdwCarousel(
                  controller: _carouselController,
                  showNavigationButtons: true,
                  children: [
                    _buildBannerCard(
                      theme: theme,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF632CA6), Color(0xFF813D9C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: const AdwEmblem(size: 64),
                      title: 'Emblema',
                      subtitle: 'Generar avatares de proyectos',
                    ),
                    _buildBannerCard(
                      theme: theme,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A5FB4), Color(0xFF3584E4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: const Icon(AdwIcons.applications_games_symbolic,
                          size: 64, color: Color(0xFFFFFFFF)),
                      title: 'Retro Games',
                      subtitle: 'Colección de clásicos arcade y aventuras',
                    ),
                    _buildBannerCard(
                      theme: theme,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF26A269), Color(0xFF33D17A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: const Icon(AdwIcons.utilities_terminal_symbolic,
                          size: 64, color: Color(0xFFFFFFFF)),
                      title: 'Code Builder',
                      subtitle: 'Herramientas modernas para desarrolladores',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Dots indicator
            Center(
              child: AdwCarouselIndicatorDots(
                controller: _carouselController,
                dotSize: 7,
                activeDotWidth: 20,
              ),
            ),
            const SizedBox(height: 28),
            // Category tiles (matching GNOME Software lower section)
            Text(
              'CATEGORIES',
              style: theme.typography.sectionTitle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCategoryCard(
                    'Crear', const Color(0xFF7852FF), const Color(0xFF3B82F6)),
                _buildCategoryCard('Trabajo', const Color(0xFFF59E0B),
                    const Color(0xFFFBBF24)),
                _buildCategoryCard(
                    'Juegos', const Color(0xFFEC4899), const Color(0xFF8B5CF6)),
                _buildCategoryCard('Socializar', const Color(0xFFEF4444),
                    const Color(0xFFF97316)),
                _buildCategoryCard('Aprendizaje', const Color(0xFF10B981),
                    const Color(0xFF059669)),
                _buildCategoryCard('Desarrollo', const Color(0xFF374151),
                    const Color(0xFF1F2937)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard({
    required AdwThemeData theme,
    required Gradient gradient,
    required Widget icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              inherit: false,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 13,
              inherit: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String label, Color startColor, Color endColor) {
    return Container(
      width: 170,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AdwMetrics.buttonRadius),
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            inherit: false,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleGroupsPage(AdwThemeData theme) {
    return AdwPreferencesPage(
      maxWidth: 560,
      groupSpacing: 42.0,
      children: [
            AdwPreferencesGroup(
              title: const Text('TIME INTERVAL SELECTOR'),
              description: const Text(
                'Segmented single-choice toggle bar with animated active indicator.',
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Center(
                    child: AdwToggleGroup<String>(
                      selectedValue: _selectedToggleInterval,
                      onChanged: (val) =>
                          setState(() => _selectedToggleInterval = val),
                      items: const [
                        AdwToggleItem(value: 'Day', label: Text('Day')),
                        AdwToggleItem(value: 'Week', label: Text('Week')),
                        AdwToggleItem(value: 'Month', label: Text('Month')),
                        AdwToggleItem(value: 'Year', label: Text('Year')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            AdwPreferencesGroup(
              title: const Text('TEXT STYLING TOGGLE'),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Center(
                    child: AdwToggleGroup<int>(
                      selectedValue: _selectedAlignment,
                      onChanged: (val) =>
                          setState(() => _selectedAlignment = val),
                      items: const [
                        AdwToggleItem(
                          value: 0,
                          icon:
                              Icon(AdwIcons.format_text_direction_ltr_symbolic),
                          tooltip: 'Direction',
                        ),
                        AdwToggleItem(
                          value: 1,
                          icon: Icon(AdwIcons.format_text_bold_symbolic),
                          tooltip: 'Bold',
                        ),
                        AdwToggleItem(
                          value: 2,
                          icon: Icon(AdwIcons.format_text_italic_symbolic),
                          tooltip: 'Italic',
                        ),
                        AdwToggleItem(
                          value: 3,
                          icon: Icon(AdwIcons.format_text_underline_symbolic),
                          tooltip: 'Underline',
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
}
