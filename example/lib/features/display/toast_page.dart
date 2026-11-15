import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class ToastPage extends StatelessWidget {
  const ToastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdwButton.suggested(
            isPill: true,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            onPressed: () {
              AdwToastOverlay.of(context).addToast(
                AdwToast(
                  title: const Text('File downloaded to ~/Downloads'),
                  action: AdwButton.suggested(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    onPressed: () {},
                    child: const Text('Undo'),
                  ),
                ),
              );
            },
            child: const Text('Show Toast Notification'),
          ),
          const SizedBox(height: 12),
          AdwButton(
            isPill: true,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            onPressed: () {
              AdwToastOverlay.of(context).addToast(
                const AdwToast(
                  title: Text('Preferences saved successfully'),
                ),
              );
            },
            child: const Text('Show Simple Toast'),
          ),
        ],
      ),
    );
  }
}

