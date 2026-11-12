/// Metric constants, dimensions, and curvature radii based on GNOME HIG and Libadwaita.
abstract final class AdwMetrics {
  // --- Border Radii ---
  /// Standard corner radius for buttons and text inputs (6px).
  static const double buttonRadius = 6.0;

  /// Standard corner radius for text entries (6px).
  static const double entryRadius = 6.0;

  /// Standard corner radius for grouped preference cards and containers (12px).
  static const double cardRadius = 12.0;

  /// Standard corner radius for top-level floating windows (15px, `--window-radius` in Libadwaita 1.6+).
  static const double windowRadius = 15.0;

  /// Standard corner radius for modal dialogs (14px).
  static const double dialogRadius = 14.0;

  /// Standard corner radius for floating toast overlays (12px).
  static const double toastRadius = 12.0;

  /// Capsule/pill corner radius for full circular capping (999px).
  static const double pillRadius = 999.0;

  // --- Paddings & Spacings ---
  static const double spacingTiny = 3.0;
  static const double spacingSmall = 6.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 18.0;
  static const double spacingExtraLarge = 24.0;

  /// Recommended vertical spacing between consecutive preference groups.
  static const double preferencesGroupSpacing = 18.0;

  /// Standard maximum width for preference pages and centered form layouts (640px).
  static const double preferencesPageMaxWidth = 640.0;

  // --- Component Dimensions ---
  /// Standard height of a Libadwaita header bar (46px).
  static const double headerBarHeight = 46.0;

  /// Standard minimum height of a preference action row (48px).
  static const double rowMinHeight = 48.0;

  /// Standard minimum height of interactive push buttons (34px).
  static const double buttonMinHeight = 34.0;

  /// Track width of a standard switch control (46px).
  static const double switchWidth = 46.0;

  /// Track height of a standard switch control (26px).
  static const double switchHeight = 26.0;

  /// Standard small symbolic icon size (16px).
  static const double iconSizeSmall = 16.0;

  /// Standard medium symbolic icon size for headers and rows (20px).
  static const double iconSizeMedium = 20.0;

  /// Standard large symbolic icon size (24px).
  static const double iconSizeLarge = 24.0;
}

