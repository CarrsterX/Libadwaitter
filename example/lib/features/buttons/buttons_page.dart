import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class ButtonsPage extends StatelessWidget {
  const ButtonsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}

