import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class PendingPage extends StatelessWidget {
  final String title;

  const PendingPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      title: Text(title),
      description: const Text('Pending review against native demo'),
    );
  }
}

