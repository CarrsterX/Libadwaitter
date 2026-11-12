import 'package:flutter/widgets.dart';

/// Official GNOME Libadwaita 1.10+ color palette tokens.
///
/// Extracted directly from official upstream Libadwaita CSS definitions on GNOME GitLab:
/// https://gitlab.gnome.org/GNOME/libadwaita
abstract final class AdwColors {
  // --- Blues ---
  static const Color blue1 = Color(0xFF99C1F1);
  static const Color blue2 = Color(0xFF62A0EA);
  static const Color blue3 = Color(0xFF3584E4); // Default accent color
  static const Color blue4 = Color(0xFF1C71D8);
  static const Color blue5 = Color(0xFF1A5FB4);

  // --- Greens ---
  static const Color green1 = Color(0xFF8FF0A4);
  static const Color green2 = Color(0xFF57E389);
  static const Color green3 = Color(0xFF33D17A);
  static const Color green4 = Color(0xFF2EC27E);
  static const Color green5 = Color(0xFF26A269);

  // --- Yellows ---
  static const Color yellow1 = Color(0xFFF9F06B);
  static const Color yellow2 = Color(0xFFF8E45C);
  static const Color yellow3 = Color(0xFFF6D32D);
  static const Color yellow4 = Color(0xFFF5C211);
  static const Color yellow5 = Color(0xFFE5A50A);

  // --- Oranges ---
  static const Color orange1 = Color(0xFFFFBE6F);
  static const Color orange2 = Color(0xFFFFA348);
  static const Color orange3 = Color(0xFFFF7800);
  static const Color orange4 = Color(0xFFE66100);
  static const Color orange5 = Color(0xFFC64600);

  // --- Reds / Destructive ---
  static const Color red1 = Color(0xFFF66151);
  static const Color red2 = Color(0xFFED333B);
  static const Color red3 = Color(0xFFE01B24); // Destructive light
  static const Color red4 = Color(0xFFC01C28); // Destructive dark
  static const Color red5 = Color(0xFFA51D2D);

  // --- Purples ---
  static const Color purple1 = Color(0xFFDC8ADD);
  static const Color purple2 = Color(0xFFC061CB);
  static const Color purple3 = Color(0xFF9141AC);
  static const Color purple4 = Color(0xFF813D9C);
  static const Color purple5 = Color(0xFF613583);

  // --- Browns ---
  static const Color brown1 = Color(0xFFCDAB8F);
  static const Color brown2 = Color(0xFFB5835A);
  static const Color brown3 = Color(0xFF986A44);
  static const Color brown4 = Color(0xFF865E3C);
  static const Color brown5 = Color(0xFF63452C);

  // --- Light Scale ---
  static const Color light1 = Color(0xFFFFFFFF);
  static const Color light2 = Color(0xFFF6F5F4);
  static const Color light3 = Color(0xFFDEDDDA);
  static const Color light4 = Color(0xFFC0BFBC);
  static const Color light5 = Color(0xFF9A9996);

  // --- Dark Scale ---
  static const Color dark1 = Color(0xFF77767B);
  static const Color dark2 = Color(0xFF5E5C64);
  static const Color dark3 = Color(0xFF3D3846);
  static const Color dark4 = Color(0xFF241F31);
  static const Color dark5 = Color(0xFF000000);

  // --- Official GNOME 47+ Accent Colors ---
  static const Color accentBlue = Color(0xFF3584E4);
  static const Color accentTeal = Color(0xFF2190A4);
  static const Color accentGreen = Color(0xFF3A944A);
  static const Color accentYellow = Color(0xFFE5A50A);
  static const Color accentOrange = Color(0xFFE66100);
  static const Color accentRed = Color(0xFFE01B24);
  static const Color accentPink = Color(0xFFD56199);
  static const Color accentPurple = Color(0xFF9141AC);
  static const Color accentSlate = Color(0xFF636779);
}

/// The 9 official accent colors introduced in GNOME 47 and Libadwaita.
enum AdwAccentColor {
  blue(AdwColors.accentBlue, 'Blue'),
  teal(AdwColors.accentTeal, 'Teal'),
  green(AdwColors.accentGreen, 'Green'),
  yellow(AdwColors.accentYellow, 'Yellow'),
  orange(AdwColors.accentOrange, 'Orange'),
  red(AdwColors.accentRed, 'Red'),
  pink(AdwColors.accentPink, 'Pink'),
  purple(AdwColors.accentPurple, 'Purple'),
  slate(AdwColors.accentSlate, 'Slate');

  final Color color;
  final String label;

  const AdwAccentColor(this.color, this.label);
}

