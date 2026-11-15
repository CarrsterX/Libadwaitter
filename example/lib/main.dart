import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import 'app/demo_window.dart';

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
