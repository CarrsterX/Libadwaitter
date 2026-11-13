import 'package:flutter/painting.dart';

/// Official typographic scale adhering to GNOME HIG and GTK4 Libadwaita specifications.
///
/// Follows upstream Libadwaita typography tokens and CSS classes:
/// - GitLab source: `https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/...`
/// - CSS classes: `.large-title`, `.title-1`, `.title-2`, `.title-3`, `.title-4`,
///   `.heading`, `.body`, `.caption`, `.caption-heading`, `.monospace`.
///
/// Uses the bundled variable font [AdwaitaSans] (`assets/fonts/AdwaitaSans-Regular.ttf`)
/// supporting continuous optical sizes (`opsz` 14..32) and weights (`wght` 100..900),
/// with fallback to native Linux desktop fonts (`Adwaita Sans`, `Cantarell`, `Inter`).
class AdwTypography {
  static const String sansFamily = 'AdwaitaSans';
  static const String monoFamily = 'AdwaitaMono';
  static const String packageName = 'libadwaitter';

  static const List<String> fallbackSans = <String>[
    'Adwaita Sans',
    'Cantarell',
    'Inter',
    'system-ui',
    'sans-serif',
  ];

  static const List<String> fallbackMono = <String>[
    'Adwaita Mono',
    'Source Code Pro',
    'monospace',
  ];

  /// Display text for assistants, greeters, or empty splash screens (`.large-title`).
  ///
  /// Upstream GTK4: `font-size: 24pt` (32px), `font-weight: 300` (Light).
  final TextStyle largeTitle;

  /// Display title for status pages and primary headers (`.title-1`).
  ///
  /// Upstream GTK4: `font-size: 181%` (27px), `font-weight: 800` (ExtraBold).
  final TextStyle title1;

  /// Prominent title for dialog message headings and compact pages (`.title-2`).
  ///
  /// Upstream GTK4: `font-size: 136%` (20px), `font-weight: 800` (ExtraBold).
  final TextStyle title2;

  /// Secondary heading for alert dialogs and medium cards (`.title-3`).
  ///
  /// Upstream GTK4: `font-size: 136%` (20px), `font-weight: 700` (Bold).
  final TextStyle title3;

  /// Sub-section heading within page bodies (`.title-4`).
  ///
  /// Upstream GTK4: `font-size: 118%` (17.5px), `font-weight: 700` (Bold).
  final TextStyle title4;

  /// Standard UI heading for window titles, group headers, and button titles (`.heading`).
  ///
  /// Upstream GTK4: `font-size: 100%` (15px), `font-weight: 700` (Bold), primary color.
  final TextStyle heading;

  /// Default text for interface controls, row labels, and general reading (`.body`).
  ///
  /// Upstream GTK4: `font-size: 100%` (15px / 11pt), `font-weight: 400`, `line-height: 140%`.
  final TextStyle body;

  /// Small explanatory text for row subtitles, window subtitles, and captions (`.caption`).
  ///
  /// Upstream GTK4: `font-size: 82%` (12px), `font-weight: 400`, secondary color.
  final TextStyle caption;

  /// Emphasized small text for column headers and table headers (`.caption-heading`).
  ///
  /// Upstream GTK4: `font-size: 82%` (12px), `font-weight: 700` (Bold).
  final TextStyle captionHeading;

  /// Semantic subtitle style for action rows and window headers (12px secondary text).
  final TextStyle subtitle;

  /// Uppercase section header style for navigation sidebars and group labels.
  ///
  /// Upstream GTK4: `font-size: 11px`, `font-weight: 700`, `letter-spacing: 0.5`.
  final TextStyle sectionTitle;

  /// Monospaced text for code blocks, logs, and terminals (`.monospace`).
  ///
  /// Upstream GTK4: `font-size: 10pt` (13px), `font-family: AdwaitaMono`.
  final TextStyle code;

  const AdwTypography({
    required this.largeTitle,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.title4,
    required this.heading,
    required this.body,
    required this.caption,
    required this.captionHeading,
    required this.subtitle,
    required this.sectionTitle,
    required this.code,
  });

  /// Factory constructing the full Libadwaita typographic scale bound to semantic colors.
  factory AdwTypography.fromColors({
    required Color foreground,
    required Color secondaryForeground,
  }) {
    TextStyle makeSans({
      required double fontSize,
      required FontWeight fontWeight,
      required Color color,
      double? height,
      double? letterSpacing,
    }) {
      return TextStyle(
        fontFamily: sansFamily,
        package: packageName,
        fontFamilyFallback: fallbackSans,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontVariations: <FontVariation>[
          FontVariation('wght', fontWeight.value.toDouble()),
        ],
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    TextStyle makeMono({
      required double fontSize,
      required FontWeight fontWeight,
      required Color color,
    }) {
      return TextStyle(
        fontFamily: monoFamily,
        package: packageName,
        fontFamilyFallback: fallbackMono,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontVariations: <FontVariation>[
          FontVariation('wght', fontWeight.value.toDouble()),
        ],
        color: color,
      );
    }

    return AdwTypography(
      // .large-title: 24pt (32px), weight 300 (Light)
      largeTitle: makeSans(
        fontSize: 32.0,
        fontWeight: FontWeight.w300,
        color: foreground,
        letterSpacing: -0.5,
      ),

      // .title-1: 181% (27px), weight 800 (ExtraBold)
      title1: makeSans(
        fontSize: 27.0,
        fontWeight: FontWeight.w800,
        color: foreground,
        letterSpacing: -0.3,
      ),

      // .title-2: 136% (20px), weight 800 (ExtraBold)
      title2: makeSans(
        fontSize: 20.0,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),

      // .title-3: 136% (20px), weight 700 (Bold)
      title3: makeSans(
        fontSize: 20.0,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),

      // .title-4: 118% (17.5px), weight 700 (Bold)
      title4: makeSans(
        fontSize: 17.5,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),

      // .heading: 100% (15px), weight 700 (Bold), primary foreground
      heading: makeSans(
        fontSize: 15.0,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),

      // .body: 100% (15px), weight 400, line-height 140%
      body: makeSans(
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        color: foreground,
        height: 1.4,
      ),

      // .caption: 82% (12px), weight 400, secondary foreground, line-height 140%
      caption: makeSans(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: secondaryForeground,
        height: 1.4,
      ),

      // .caption-heading: 82% (12px), weight 700 (Bold), primary foreground
      captionHeading: makeSans(
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),

      // subtitle: semantic alias for secondary text accompanying titles (12px)
      subtitle: makeSans(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: secondaryForeground,
        height: 1.4,
      ),

      // sectionTitle: GNOME navigation sidebar section header (.navigation-sidebar > .header > .heading)
      sectionTitle: makeSans(
        fontSize: 15.0,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),

      // .monospace: 10pt (13px), AdwaitaMono
      code: makeMono(
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        color: foreground,
      ),
    );
  }

  /// Creates a copy of this typography scale with selective overrides.
  AdwTypography copyWith({
    TextStyle? largeTitle,
    TextStyle? title1,
    TextStyle? title2,
    TextStyle? title3,
    TextStyle? title4,
    TextStyle? heading,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? captionHeading,
    TextStyle? subtitle,
    TextStyle? sectionTitle,
    TextStyle? code,
  }) {
    return AdwTypography(
      largeTitle: largeTitle ?? this.largeTitle,
      title1: title1 ?? this.title1,
      title2: title2 ?? this.title2,
      title3: title3 ?? this.title3,
      title4: title4 ?? this.title4,
      heading: heading ?? this.heading,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      captionHeading: captionHeading ?? this.captionHeading,
      subtitle: subtitle ?? this.subtitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      code: code ?? this.code,
    );
  }
}
