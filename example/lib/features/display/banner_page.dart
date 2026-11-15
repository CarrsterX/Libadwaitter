import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class BannerPage extends StatefulWidget {
  const BannerPage({super.key});

  @override
  State<BannerPage> createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> {
  bool _bannerRevealed = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdwBanner(
          revealed: _bannerRevealed,
          title: const Text(
              'No Internet Connection. Some features may be unavailable.'),
          buttonLabel: 'Retry',
          onButtonPressed: () {
            AdwToastOverlay.of(context).addToast(
              const AdwToast(title: Text('Retrying network connection...')),
            );
          },
        ),
        Expanded(
          child: Center(
            child: AdwButton(
              onPressed: () =>
                  setState(() => _bannerRevealed = !_bannerRevealed),
              child: Text(_bannerRevealed ? 'Hide Banner' : 'Show Banner'),
            ),
          ),
        ),
      ],
    );
  }
}

