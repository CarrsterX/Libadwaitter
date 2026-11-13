import 'package:flutter/widgets.dart';

import 'adw_colors.dart';
import 'adw_typography.dart';

/// Theme appearance mode for Libadwaitter.
///
/// Provides decoupled theme brightness management independent of Material's `ThemeMode`.
enum AdwThemeMode {
  /// Follows the host operating system dark/light preference.
  system,

  /// Enforces Libadwaita light stylesheet.
  light,

  /// Enforces Libadwaita dark stylesheet.
  dark,
}

/// Semantic color scheme defining GNOME Libadwaita tokens.
class AdwColorScheme {
  final bool isDark;
  final Color windowBackground;
  final Color windowForeground;
  final Color secondaryForeground;
  final Color viewBackground;
  final Color viewForeground;
  final Color cardBackground;
  final Color cardForeground;
  final Color headerBarBackground;
  final Color headerBarForeground;
  final Color dialogBackground;
  final Color dialogForeground;
  final Color popoverBackground;
  final Color popoverForeground;
  final Color borderColor;
  final Color dividerColor;
  final Color accentColor;
  final Color accentForeground;
  final Color destructiveColor;
  final Color destructiveForeground;
  final Color successColor;
  final Color warningColor;
  final Color hoverColor;
  final Color activeColor;
  final Color sidebarBackground;
  final Color sidebarBorder;

  /// Ergonomic alias for [windowForeground].
  Color get foreground => windowForeground;

  /// Ergonomic alias for [hoverColor].
  Color get hoverBackground => hoverColor;

  /// Background color for standard push buttons and segmented controls.
  Color get buttonBackground => isDark
      ? const Color(0x1FDDDDDD)
      : const Color(0x0F000000);

  /// Background color for selected items in a navigation sidebar (`.navigation-sidebar row:selected`).
  ///
  /// Evaluates to exact `#424246` in dark mode over [sidebarBackground] (`#2E2E32`).
  Color get sidebarSelectedBackground => isDark
      ? const Color(0x19FFFFFF)
      : const Color(0x14000000);

  /// Backdrop sidebar background color (`@define-color sidebar_backdrop_color`)
  /// used when the parent window is unfocused.
  Color get sidebarBackdropBackground => isDark
      ? const Color(0xFF28282C)
      : const Color(0xFFF3F3F5);

  /// Outer hairline border around floating CSD windows (`window.csd`).
  Color get windowOutline => isDark
      ? const Color(0x80000000)
      : const Color(0x26000000);

  /// Subtle 1px inner edge highlight on floating CSD windows (`~8%` white in dark mode).
  Color get windowInnerBorder => isDark
      ? const Color(0x14FFFFFF)
      : const Color(0x80FFFFFF);

  const AdwColorScheme({
    required this.isDark,
    required this.windowBackground,
    required this.windowForeground,
    required this.secondaryForeground,
    required this.viewBackground,
    required this.viewForeground,
    required this.cardBackground,
    required this.cardForeground,
    required this.headerBarBackground,
    required this.headerBarForeground,
    required this.dialogBackground,
    required this.dialogForeground,
    required this.popoverBackground,
    required this.popoverForeground,
    required this.borderColor,
    required this.dividerColor,
    required this.accentColor,
    required this.accentForeground,
    required this.destructiveColor,
    required this.destructiveForeground,
    required this.successColor,
    required this.warningColor,
    required this.hoverColor,
    required this.activeColor,
    required this.sidebarBackground,
    required this.sidebarBorder,
  });

  /// Official Libadwaita Light Color Scheme.
  factory AdwColorScheme.light({AdwAccentColor accent = AdwAccentColor.blue}) {
    return AdwColorScheme(
      isDark: false,
      windowBackground: const Color(0xFFFAFAFB),
      windowForeground: const Color(0xCC000006),
      secondaryForeground: const Color(0x8A000006),
      viewBackground: const Color(0xFFFFFFFF),
      viewForeground: const Color(0xCC000006),
      cardBackground: const Color(0xFFFFFFFF),
      cardForeground: const Color(0xCC000006),
      headerBarBackground: const Color(0xFFFFFFFF),
      headerBarForeground: const Color(0xCC000006),
      dialogBackground: const Color(0xFFFFFFFF),
      dialogForeground: const Color(0xCC000006),
      popoverBackground: const Color(0xFFFFFFFF),
      popoverForeground: const Color(0xCC000006),
      borderColor: const Color(0x26000000), // ~15% opacity
      dividerColor: const Color(0x1A000000), // ~10% opacity
      accentColor: accent.color,
      accentForeground: const Color(0xFFFFFFFF),
      destructiveColor: AdwColors.red3,
      destructiveForeground: const Color(0xFFFFFFFF),
      successColor: AdwColors.green4,
      warningColor: AdwColors.yellow5,
      hoverColor: const Color(0x0F000000), // ~6%
      activeColor: const Color(0x1F000000), // ~12%
      sidebarBackground: const Color(0xFFEBEBED),
      sidebarBorder: const Color(0x1A000000),
    );
  }

  /// Official Libadwaita Dark Color Scheme.
  factory AdwColorScheme.dark({AdwAccentColor accent = AdwAccentColor.blue}) {
    return AdwColorScheme(
      isDark: true,
      windowBackground: const Color(0xFF222226),
      windowForeground: const Color(0xFFFFFFFF),
      secondaryForeground: const Color(0xB3FFFFFF),
      viewBackground: const Color(0xFF1D1D20),
      viewForeground: const Color(0xFFFFFFFF),
      cardBackground: const Color(0xFF333337),
      cardForeground: const Color(0xFFFFFFFF),
      headerBarBackground: const Color(0xFF2E2E32),
      headerBarForeground: const Color(0xFFFFFFFF),
      dialogBackground: const Color(0xFF36363A),
      dialogForeground: const Color(0xFFFFFFFF),
      popoverBackground: const Color(0xFF36363A),
      popoverForeground: const Color(0xFFFFFFFF),
      borderColor: const Color(0x26FFFFFF), // ~15% opacity
      dividerColor: const Color(0x1AFFFFFF), // ~10% opacity
      accentColor: accent.color,
      accentForeground: const Color(0xFFFFFFFF),
      destructiveColor: AdwColors.red4,
      destructiveForeground: const Color(0xFFFFFFFF),
      successColor: AdwColors.green5,
      warningColor: const Color(0xFFCD9309),
      hoverColor: const Color(0x0FFFFFFF), // ~6%
      activeColor: const Color(0x1FFFFFFF), // ~12%
      sidebarBackground: const Color(0xFF2E2E32),
      sidebarBorder: const Color(0x26FFFFFF),
    );
  }
}

/// Libadwaita theme data container (colors, typography, global layout settings).
class AdwThemeData {
  final AdwColorScheme colors;
  final AdwTypography typography;

  const AdwThemeData({
    required this.colors,
    required this.typography,
  });

  factory AdwThemeData.light({AdwAccentColor accent = AdwAccentColor.blue}) {
    final colors = AdwColorScheme.light(accent: accent);
    final typography = AdwTypography.fromColors(
      foreground: colors.windowForeground,
      secondaryForeground: colors.secondaryForeground,
    );
    return AdwThemeData(colors: colors, typography: typography);
  }

  factory AdwThemeData.dark({AdwAccentColor accent = AdwAccentColor.blue}) {
    final colors = AdwColorScheme.dark(accent: accent);
    final typography = AdwTypography.fromColors(
      foreground: colors.windowForeground,
      secondaryForeground: colors.secondaryForeground,
    );
    return AdwThemeData(colors: colors, typography: typography);
  }

  /// Returns a copy of this theme data with a mutated [accent] color.
  AdwThemeData withAccent(AdwAccentColor accent) {
    if (colors.isDark) {
      return AdwThemeData.dark(accent: accent);
    } else {
      return AdwThemeData.light(accent: accent);
    }
  }
}

/// Inherited widget for propagating and accessing [AdwThemeData] in the widget tree.
class AdwTheme extends InheritedTheme {
  final AdwThemeData data;

  const AdwTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// Retrieves the current [AdwThemeData] from the closest ancestor, asserting if none exists.
  static AdwThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<AdwTheme>();
    assert(
      theme != null,
      'No AdwTheme found in context. Ensure your app is wrapped with AdwApplication or AdwTheme.',
    );
    return theme!.data;
  }

  /// Safely retrieves the current [AdwThemeData] or null if absent.
  static AdwThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdwTheme>()?.data;
  }

  @override
  bool updateShouldNotify(covariant AdwTheme oldWidget) {
    return data != oldWidget.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return AdwTheme(data: data, child: child);
  }
}

