import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdwStatusPage(
      icon: AdwEmblem(size: 128, strokeWidth: 0.85),
      title: Text('Welcome to Adwaitter Demo'),
      description:
          Text('This is a tour of the features the library has to offer'),
    );
  }
}

