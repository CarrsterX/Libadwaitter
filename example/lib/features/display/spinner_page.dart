import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class SpinnerPage extends StatelessWidget {
  const SpinnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    return AdwStatusPage(
      icon: const AdwSpinner(size: 64),
      title: Text(
        'Spinner',
        style: theme.typography.title2,
      ),
      description: const Text('A modern spinner widget'),
    );
  }
}
