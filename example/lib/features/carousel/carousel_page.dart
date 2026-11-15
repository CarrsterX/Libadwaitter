import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

enum _CarouselIndicatorStyle { dots, lines }

class CarouselPage extends StatefulWidget {
  const CarouselPage({super.key});

  @override
  State<CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  final AdwCarouselController _carouselController = AdwCarouselController();
  final GlobalKey _carouselKey = GlobalKey();
  Axis _orientation = Axis.horizontal;
  _CarouselIndicatorStyle _indicatorStyle = _CarouselIndicatorStyle.dots;
  bool _allowScrollWheel = true;
  bool _allowLongSwipes = false;

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  Widget _buildIndicator() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: _indicatorStyle == _CarouselIndicatorStyle.dots
          ? AdwCarouselIndicatorDots(
              key: const ValueKey('dots'),
              controller: _carouselController,
              orientation: _orientation,
            )
          : AdwCarouselIndicatorLines(
              key: const ValueKey('lines'),
              controller: _carouselController,
              orientation: _orientation,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carousel = AdwCarousel(
      key: _carouselKey,
      controller: _carouselController,
      scrollDirection: _orientation,
      allowScrollWheel: _allowScrollWheel,
      allowLongSwipes: _allowLongSwipes,
      showNavigationButtons: false,
      children: [
        const AdwStatusPage(
          icon: DemoWidgetIcon(DemoIconType.carousel, size: 128),
          title: Text('Carousel'),
          description: Text('A widget for paginated scrolling'),
        ),
        _CarouselSettingsPage(
          orientation: _orientation,
          indicatorStyle: _indicatorStyle,
          allowScrollWheel: _allowScrollWheel,
          allowLongSwipes: _allowLongSwipes,
          onOrientationChanged: (value) => setState(() => _orientation = value),
          onIndicatorStyleChanged: (value) =>
              setState(() => _indicatorStyle = value),
          onAllowScrollWheelChanged: (value) =>
              setState(() => _allowScrollWheel = value),
          onAllowLongSwipesChanged: (value) =>
              setState(() => _allowLongSwipes = value),
        ),
        AdwStatusPage(
          title: const Text('Another Page'),
          child: Center(
            child: AdwButton.suggested(
              isPill: true,
              onPressed: () {
                final duration =
                    AdwCurves.resolve(context, AdwCurves.normalDuration);
                _carouselController.animateToPage(0, duration: duration);
              },
              child: const Text('Return to the First Page'),
            ),
          ),
        ),
      ],
    );

    final indicator = Padding(
      padding: const EdgeInsets.all(6.0),
      child: _buildIndicator(),
    );

    // Match native GtkSizeGroup symmetry: keep carousel centered while placing
    // the indicator at the bottom (horizontal) or right (vertical).
    const double indicatorThickness = 32.0;

    if (_orientation == Axis.horizontal) {
      return Column(
        children: [
          const SizedBox(height: indicatorThickness),
          Expanded(child: carousel),
          SizedBox(
            height: indicatorThickness,
            child: Center(child: indicator),
          ),
        ],
      );
    }

    return Row(
      children: [
        const SizedBox(width: indicatorThickness),
        Expanded(child: carousel),
        SizedBox(
          width: indicatorThickness,
          child: Center(child: indicator),
        ),
      ],
    );
  }
}

class _CarouselSettingsPage extends StatelessWidget {
  final Axis orientation;
  final _CarouselIndicatorStyle indicatorStyle;
  final bool allowScrollWheel;
  final bool allowLongSwipes;
  final ValueChanged<Axis> onOrientationChanged;
  final ValueChanged<_CarouselIndicatorStyle> onIndicatorStyleChanged;
  final ValueChanged<bool> onAllowScrollWheelChanged;
  final ValueChanged<bool> onAllowLongSwipesChanged;

  const _CarouselSettingsPage({
    required this.orientation,
    required this.indicatorStyle,
    required this.allowScrollWheel,
    required this.allowLongSwipes,
    required this.onOrientationChanged,
    required this.onIndicatorStyleChanged,
    required this.onAllowScrollWheelChanged,
    required this.onAllowLongSwipesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AdwClamp(
          maximumSize: 400,
          child: AdwPreferencesGroup(
            children: [
              AdwComboRow<Axis>(
                title: const Text('Orientation'),
                items: Axis.values,
                selectedItem: orientation,
                itemTitleBuilder: (axis) =>
                    axis == Axis.horizontal ? 'Horizontal' : 'Vertical',
                onSelected: onOrientationChanged,
              ),
              AdwComboRow<_CarouselIndicatorStyle>(
                title: const Text('Page Indicators'),
                items: _CarouselIndicatorStyle.values,
                selectedItem: indicatorStyle,
                itemTitleBuilder: (style) =>
                    style == _CarouselIndicatorStyle.dots ? 'Dots' : 'Lines',
                onSelected: onIndicatorStyleChanged,
              ),
              AdwSwitchRow(
                title: const Text('Scroll Wheel'),
                value: allowScrollWheel,
                onChanged: onAllowScrollWheelChanged,
              ),
              AdwSwitchRow(
                title: const Text('Long Swipes'),
                value: allowLongSwipes,
                onChanged: onAllowLongSwipesChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
