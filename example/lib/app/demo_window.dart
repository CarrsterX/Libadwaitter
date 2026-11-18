import 'package:libadwaitter/libadwaitter.dart';
import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../demo_icons.dart';
import '../features/appearance/appearance_page.dart';
import '../features/appearance/demo_colors_dialog.dart';
import '../features/bottom_sheet/bottom_sheet_page.dart';
import '../features/boxed_lists/boxed_lists_page.dart';
import '../features/buttons/buttons_page.dart';
import '../features/carousel/carousel_page.dart';
import '../features/dialogs/dialogs_pages.dart';
import '../features/display/avatar_page.dart';
import '../features/display/banner_page.dart';
import '../features/display/spinner_page.dart';
import '../features/display/toast_page.dart';
import '../features/layout/clamp_page.dart';
import '../features/layout/multi_layout_view_page.dart';
import '../features/layout/wrap_box_page.dart';
import '../features/miscellaneous/animations_page.dart';
import '../features/miscellaneous/style_classes_page.dart';
import '../features/navigation_view/navigation_view_page.dart';
import '../features/preferences/demo_preferences_dialog.dart';
import '../features/split_views/split_views_page.dart';
import '../features/tab_view/tab_view_page.dart';
import '../features/toggle_groups/toggle_groups_page.dart';
import '../features/view_switcher/view_switcher_page.dart';
import '../features/welcome/welcome_page.dart';
import 'demo_page.dart';
import 'adwaitter_logo.dart';

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
  final GlobalKey _menuButtonKey = GlobalKey();
  bool _searchFocused = false;

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

  void _openSidebarSearch() {
    setState(() {
      if (!_searchBarVisible) {
        _searchBarVisible = true;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchBarVisible) {
          _searchFocusNode.requestFocus();
        }
      });
    });
  }

  void _closeWindowOrQuit(BuildContext windowContext) {
    final controller = AdwWindowScope.maybeOf(windowContext)?.controller;
    if (controller != null) {
      controller.close();
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return AdwWindow(
      showShadow: true,
      showBorder: true,
      delegateSafeAreaToChild: true,
      child: Builder(
        builder: (windowContext) => CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.f10):
                () => _showMainMenu(windowContext),
            const SingleActivator(LogicalKeyboardKey.comma, control: true):
                () => showAdwDemoPreferencesDialog(windowContext),
            const SingleActivator(
              LogicalKeyboardKey.slash,
              control: true,
              shift: true,
            ): () => _showShortcutsDialog(windowContext),
            const SingleActivator(
              LogicalKeyboardKey.question,
              control: true,
            ): () => _showShortcutsDialog(windowContext),
            const SingleActivator(
              LogicalKeyboardKey.question,
              control: true,
              shift: true,
            ): () => _showShortcutsDialog(windowContext),
            const SingleActivator(LogicalKeyboardKey.slash, control: true):
                () => _showShortcutsDialog(windowContext),
            const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                _openSidebarSearch,
            if (_searchBarVisible)
              const SingleActivator(LogicalKeyboardKey.escape):
                  _toggleSidebarSearch,
            const SingleActivator(LogicalKeyboardKey.keyW, control: true): () =>
                _closeWindowOrQuit(windowContext),
            const SingleActivator(LogicalKeyboardKey.keyQ, control: true): () =>
                _closeWindowOrQuit(windowContext),
          },
          child: Focus(
            autofocus: true,
            child: AdwNavigationSplitView(
              sidebarWidth: 270.0,
              breakpoint: 600.0,
              sidebar: _buildSidebar(theme),
              content: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  void _showMainMenu(BuildContext dialogContext) {
    final RenderBox? buttonBox =
        _menuButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null || !buttonBox.hasSize) return;

    final Rect anchorRect =
        buttonBox.localToGlobal(Offset.zero) & buttonBox.size;

    showAdwPopover(
      context: dialogContext,
      anchorRect: anchorRect,
      owner: _menuButtonKey,
      parentAnchor: AdwPopoverAnchor.bottom,
      childAnchor: AdwPopoverAnchor.top,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(
        minWidth: 240,
        maxWidth: 260,
        maxHeight: 340,
      ),
      builder: (popoverContext, handle) {
        final theme = AdwTheme.of(popoverContext);
        final shortcutStyle = theme.typography.body.copyWith(
          color: theme.colors.secondaryForeground,
          fontSize: 13.5,
        );

        return AdwPopoverSurface(
          arrowSide: AdwPopoverArrowSide.top,
          child: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdwPopoverMenuItem(
                  label: 'Inspector',
                  onTap: () {
                    handle.dismiss();
                    _showToast('Resize or use Flutter DevTools to inspect');
                  },
                ),
                AdwPopoverMenuItem(
                  label: 'Adaptive Preview',
                  onTap: () {
                    handle.dismiss();
                    _showToast('Resize the window to preview adaptive layouts');
                  },
                ),
                const AdwPopoverDivider(),
                AdwPopoverMenuItem(
                  label: 'Colors',
                  onTap: () {
                    handle.dismiss();
                    showDemoColorsDialog(
                      context: dialogContext,
                      currentThemeMode: widget.currentThemeMode,
                      currentAccent: widget.currentAccent,
                      onThemeModeChanged: widget.onThemeModeChanged,
                      onAccentChanged: widget.onAccentChanged,
                    );
                  },
                ),
                AdwPopoverMenuItem(
                  label: 'Preferences',
                  trailing: Text('Ctrl+,', style: shortcutStyle),
                  onTap: () {
                    handle.dismiss();
                    showAdwDemoPreferencesDialog(dialogContext);
                  },
                ),
                AdwPopoverMenuItem(
                  label: 'Keyboard Shortcuts',
                  trailing: Text('Ctrl+?', style: shortcutStyle),
                  onTap: () {
                    handle.dismiss();
                    _showShortcutsDialog(dialogContext);
                  },
                ),
                AdwPopoverMenuItem(
                  label: 'About Adwaitter Demo',
                  onTap: () {
                    handle.dismiss();
                    _showAboutAppDialog(dialogContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showToast(String title) {
    AdwToastOverlay.maybeOf(context)?.addToast(
      AdwToast(title: Text(title)),
    );
  }

  void _showShortcutsDialog(BuildContext dialogContext) {
    showAdwShortcutsDialog(
      context: dialogContext,
      sections: const [
        AdwShortcutsSection(
          title: 'General',
          items: [
            AdwShortcutsItem(
              title: 'Open Menu',
              accelerator: 'F10',
            ),
            AdwShortcutsItem(
              title: 'Preferences',
              accelerator: '<Control>comma',
            ),
            AdwShortcutsItem(
              title: 'Keyboard Shortcuts',
              accelerator: '<Control>question',
            ),
            AdwShortcutsItem(
              title: 'Close Current Window',
              accelerator: '<Control>W',
            ),
            AdwShortcutsItem(
              title: 'Quit',
              accelerator: '<Control>Q',
            ),
          ],
        ),
        AdwShortcutsSection(
          title: 'Tab View',
          items: [
            AdwShortcutsItem(
              title: 'New Tab',
              accelerator: '<Control>T',
            ),
            AdwShortcutsItem(
              title: 'New Window',
              accelerator: '<Control>N',
            ),
            AdwShortcutsItem(
              title: 'Close Tab',
              accelerator: '<Control>W',
            ),
          ],
        ),
        AdwShortcutsSection(
          items: [
            AdwShortcutsItem(
              title: 'Previous Tab',
              accelerator: '<Shift><Ctrl>Tab <Ctrl>Page_Up',
            ),
            AdwShortcutsItem(
              title: 'Next Tab',
              accelerator: '<Ctrl>Tab <Ctrl>Page_Down',
            ),
            AdwShortcutsItem(
              title: 'First Tab',
              accelerator: '<Ctrl>Home',
            ),
            AdwShortcutsItem(
              title: 'Last Tab',
              accelerator: '<Ctrl>End',
            ),
          ],
        ),
        AdwShortcutsSection(
          items: [
            AdwShortcutsItem(
              title: 'Move Tab Left',
              accelerator: '<Shift><Ctrl>Page_Up',
              direction: TextDirection.ltr,
            ),
            AdwShortcutsItem(
              title: 'Move Tab Right',
              accelerator: '<Shift><Ctrl>Page_Down',
              direction: TextDirection.ltr,
            ),
            AdwShortcutsItem(
              title: 'Move Tab Right',
              accelerator: '<Shift><Ctrl>Page_Up',
              direction: TextDirection.rtl,
            ),
            AdwShortcutsItem(
              title: 'Move Tab Left',
              accelerator: '<Shift><Ctrl>Page_Down',
              direction: TextDirection.rtl,
            ),
          ],
        ),
        AdwShortcutsSection(
          items: [
            AdwShortcutsItem(
              title: 'Switch to Tab 1–9',
              accelerator: '<Alt>1...9',
            ),
            AdwShortcutsItem(
              title: 'Switch to Tab 10',
              accelerator: '<Alt>0',
            ),
          ],
        ),
      ],
    );
  }

  void _showAboutAppDialog(BuildContext dialogContext) {
    showAdwAboutDialog(
      context: dialogContext,
      applicationIcon: const AdwaitterAppLogo(size: 140),
      applicationName: 'Adwaitter Demo',
      developerName: 'Claudio Carrasco',
      version: '1.0.0-alpha',
      comments: 'Tour of the features in Adwaitter.',
      website: 'https://github.com/CarrsterX/Libadwaitter',
      issueUrl: 'https://github.com/CarrsterX/Libadwaitter/issues',
      copyright: '© 2026 Claudio Carrasco',
      license: 'GNU Lesser General Public License v2.1',
      developers: const ['Claudio Carrasco'],
      artists: const ['GNOME Design Team'],
      acknowledgements: const [
        AdwAboutAcknowledgement(
          title: 'Special thanks to',
          people: ['Flutter Team', 'Dart Team'],
        ),
      ],
      otherAppsTitle: 'Inspired by',
      onOpenUrl: (url) => AdwPortal.openUri(url),
      otherApps: const [
        AdwAboutOtherApp(
          appId: 'dev.flutter.Flutter',
          name: 'Flutter',
          summary: 'Build apps for any screen',
          icon: FlutterLogo(size: 32),
          url: 'https://flutter.dev',
        ),
        AdwAboutOtherApp(
          appId: 'org.gnome.Adwaita1.Demo',
          name: 'Libadwaita',
          summary: 'Building blocks for modern GNOME apps',
          icon: LibadwaitaAppLogo(size: 32),
          url: 'https://gnome.pages.gitlab.gnome.org/libadwaita/',
        ),
      ],
    );
  }

  Widget _buildSidebar(AdwThemeData theme) {
    final topBar = Column(
      mainAxisSize: MainAxisSize.min,
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
              showWindowControls: true,
              showStartWindowControls: true,
              showEndWindowControls: isCollapsed,
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
                key: _menuButtonKey,
                width: 34,
                height: 34,
                padding: EdgeInsets.zero,
                onPressed: () => _showMainMenu(sidebarContext),
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
                          borderRadius:
                              BorderRadius.circular(AdwMetrics.buttonRadius),
                          border: Border.all(
                            color: _searchFocused
                                ? theme.colors.accentColor
                                    .withValues(alpha: 0.75)
                                : theme.colors.borderColor,
                            width: _searchFocused ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Find pages',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.typography.body.copyWith(
                                            height: 1.0,
                                            leadingDistribution:
                                                TextLeadingDistribution.even,
                                            color: theme
                                                .colors.secondaryForeground
                                                .withValues(alpha: 0.75),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: EditableText(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      style: theme.typography.body.copyWith(
                                        height: 1.0,
                                        leadingDistribution:
                                            TextLeadingDistribution.even,
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
      ],
    );

    return AdwToolbarView(
      bottomSafeArea: false,
      topBar: topBar,
      content: Builder(
        builder: (sidebarContext) {
              final isCollapsed =
                  AdwNavigationSplitViewScope.maybeOf(sidebarContext)
                          ?.isCollapsed ??
                      false;
              final double bottomSafeInset =
                  MediaQuery.maybePaddingOf(sidebarContext)?.bottom ?? 0.0;
              if (_searchFilter.isNotEmpty && !_hasSidebarResults()) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AdwIcons.edit_find_symbolic,
                          size: 96,
                          color: theme.colors.windowForeground
                              .withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Results Found',
                          style: theme.typography.title2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Try a different search',
                          style: theme.typography.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: isCollapsed
                    ? EdgeInsets.fromLTRB(12, 24, 12, bottomSafeInset)
                    : EdgeInsets.fromLTRB(0, 8, 0, 4 + bottomSafeInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isCollapsed)
                      AdwPreferencesGroup(
                        margin: const EdgeInsets.only(bottom: 28),
                        children: [
                          _buildSidebarItem(
                            page: DemoPage.welcome,
                            iconWidget:
                                const AdwaitterSymbolicLogo(size: 16),
                            title: 'Welcome',
                            isCollapsed: true,
                          ),
                        ],
                      )
                    else
                      _buildSidebarItem(
                        page: DemoPage.welcome,
                        iconWidget:
                            const AdwaitterSymbolicLogo(size: 16),
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
                      isCollapsed: isCollapsed,
                    ),
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
                      isCollapsed: isCollapsed,
                    ),
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
                          iconWidget: const DemoWidgetIcon(
                              DemoIconType.avatar,
                              size: 16),
                          title: 'Avatar',
                          isCollapsed: isCollapsed,
                        ),
                      ],
                      isCollapsed: isCollapsed,
                    ),
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
                      isCollapsed: isCollapsed,
                    ),
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
                      isCollapsed: isCollapsed,
                    ),
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
                      isCollapsed: isCollapsed,
                    ),
                  ],
                ),
              );
            },
      ),
    );
  }

  bool _hasSidebarResults() {
    const titles = [
      'welcome',
      'navigation view',
      'split views',
      'view switcher',
      'tab view',
      'bottom sheet',
      'styles',
      'boxed lists',
      'buttons',
      'toggles',
      'toggle groups',
      'sliders & spinners',
      'avatar',
      'dialogs',
      'toasts',
      'carousel',
      'clamp',
      'banner',
      'animations',
    ];
    return titles.any((t) => t.contains(_searchFilter));
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
          return AdwActionRow(
            minHeight: AdwMetrics.rowMinHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
      return AdwPreferencesGroup(
        margin: const EdgeInsets.only(bottom: 28),
        title: Text(title),
        children: visibleItems,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
          child: Text(
            title,
            style: theme.typography.sectionTitle,
          ),
        ),
        ...visibleItems,
      ],
    );
  }

  bool _isScrollablePage(DemoPage page) {
    return switch (page) {
      DemoPage.boxedLists ||
      DemoPage.toggleGroups ||
      DemoPage.buttons ||
      DemoPage.banner ||
      DemoPage.avatar ||
      DemoPage.appearance =>
        true,
      _ => false,
    };
  }

  Widget _buildContent() {
    if (_selectedPage == DemoPage.bottomSheet) {
      return const BottomSheetPage();
    }

    return AdwToolbarView(
      bottomSafeArea: !_isScrollablePage(_selectedPage),
      topBar: Builder(
        builder: (contentContext) {
          final isCollapsed =
              AdwNavigationSplitViewScope.maybeOf(contentContext)
                      ?.isCollapsed ??
                  false;
          return AdwHeaderBar(
            isFlat: true,
            showWindowControls: true,
            showStartWindowControls: isCollapsed,
            showEndWindowControls: true,
          );
        },
      ),
      content: KeyedSubtree(
        key: ValueKey(_selectedPage),
        child: _buildPageBody(),
      ),
    );
  }

  Widget _buildPageBody() {
    return switch (_selectedPage) {
      DemoPage.welcome => const WelcomePage(),
      DemoPage.navigationView => const NavigationViewPage(),
      DemoPage.splitViews => const SplitViewsPage(),
      DemoPage.viewSwitcher => const ViewSwitcherPage(),
      DemoPage.tabView => const TabViewPage(),
      DemoPage.bottomSheet => const BottomSheetPage(),
      DemoPage.carousel => const CarouselPage(),
      DemoPage.boxedLists => const BoxedListsPage(),
      DemoPage.toggleGroups => const ToggleGroupsPage(),
      DemoPage.buttons => const ButtonsPage(),
      DemoPage.banner => const BannerPage(),
      DemoPage.toasts => const ToastPage(),
      DemoPage.alertDialog => const AlertDialogPage(),
      DemoPage.aboutDialog => const AboutDialogPage(),
      DemoPage.appearance => AppearancePage(
          currentThemeMode: widget.currentThemeMode,
          currentAccent: widget.currentAccent,
          onThemeModeChanged: widget.onThemeModeChanged,
          onAccentChanged: widget.onAccentChanged,
        ),
      DemoPage.spinner => const SpinnerPage(),
      DemoPage.avatar => const AvatarPage(),
      DemoPage.clamp => const ClampPage(),
      DemoPage.wrapBox => const WrapBoxPage(),
      DemoPage.multiLayoutView => const MultiLayoutViewPage(),
      DemoPage.styleClasses => const StyleClassesPage(),
      DemoPage.animations => const AnimationsPage(),
    };
  }
}
