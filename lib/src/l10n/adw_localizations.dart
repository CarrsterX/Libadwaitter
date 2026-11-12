import 'package:flutter/widgets.dart';

/// Localized strings for Libadwaitter components (default: English).
class AdwLocalizations {
  final Locale locale;

  const AdwLocalizations(this.locale);

  static const AdwLocalizations _defaultInstance = AdwLocalizations(Locale('en'));

  static AdwLocalizations of(BuildContext context) {
    return Localizations.of<AdwLocalizations>(context, AdwLocalizations) ?? _defaultInstance;
  }

  // Window Controls Tooltips
  String get closeButtonTooltip => 'Close';
  String get minimizeButtonTooltip => 'Minimize';
  String get maximizeButtonTooltip => 'Maximize';
  String get restoreButtonTooltip => 'Restore';

  // Common Dialog Actions
  String get cancelLabel => 'Cancel';
  String get okLabel => 'OK';
  String get closeLabel => 'Close';
  String get resetLabel => 'Reset';

  // About Dialog
  String get aboutDialogTitle => 'About';
  String get versionLabel => 'Version';
  String get creditsLabel => 'Credits';
  String get licenseLabel => 'License';
  String get websiteLabel => 'Website';

  // Search and Entry
  String get searchPlaceholder => 'Search';
  String get clearTextTooltip => 'Clear text';
}

/// Localization delegate for [AdwLocalizations].
class AdwLocalizationsDelegate extends LocalizationsDelegate<AdwLocalizations> {
  const AdwLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AdwLocalizations> load(Locale locale) {
    return Future.value(AdwLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AdwLocalizations> old) => false;
}

