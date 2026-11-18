import 'dart:math' as math;

import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

/// All 35 easing functions from Libadwaita's `AdwEasing` (`adw-easing.h`).
enum AdwEasing {
  linear('Linear'),
  easeInQuad('Ease-in (Quadratic)'),
  easeOutQuad('Ease-out (Quadratic)'),
  easeInOutQuad('Ease-in-out (Quadratic)'),
  easeInCubic('Ease-in (Cubic)'),
  easeOutCubic('Ease-out (Cubic)'),
  easeInOutCubic('Ease-in-out (Cubic)'),
  easeInQuart('Ease-in (Quartic)'),
  easeOutQuart('Ease-out (Quartic)'),
  easeInOutQuart('Ease-in-out (Quartic)'),
  easeInQuint('Ease-in (Quintic)'),
  easeOutQuint('Ease-out (Quintic)'),
  easeInOutQuint('Ease-in-out (Quintic)'),
  easeInSine('Ease-in (Sine)'),
  easeOutSine('Ease-out (Sine)'),
  easeInOutSine('Ease-in-out (Sine)'),
  easeInExpo('Ease-in (Exponential)'),
  easeOutExpo('Ease-out (Exponential)'),
  easeInOutExpo('Ease-in-out (Exponential)'),
  easeInCirc('Ease-in (Circular)'),
  easeOutCirc('Ease-out (Circular)'),
  easeInOutCirc('Ease-in-out (Circular)'),
  easeInElastic('Ease-in (Elastic)'),
  easeOutElastic('Ease-out (Elastic)'),
  easeInOutElastic('Ease-in-out (Elastic)'),
  easeInBack('Ease-in (Back)'),
  easeOutBack('Ease-out (Back)'),
  easeInOutBack('Ease-in-out (Back)'),
  easeInBounce('Ease-in (Bounce)'),
  easeOutBounce('Ease-out (Bounce)'),
  easeInOutBounce('Ease-in-out (Bounce)'),
  ease('Ease'),
  easeIn('Ease-in'),
  easeOut('Ease-out'),
  easeInOut('Ease-in-out');

  final String label;
  const AdwEasing(this.label);

  /// Evaluates this easing function at [value] in `[0, 1]`, matching `adw_easing_ease`.
  double transform(double value) {
    switch (this) {
      case AdwEasing.linear:
        return value;
      case AdwEasing.easeInQuad:
        return value * value;
      case AdwEasing.easeOutQuad:
        return -1.0 * value * (value - 2.0);
      case AdwEasing.easeInOutQuad:
        var p = value * 2.0;
        if (p < 1.0) return 0.5 * p * p;
        p -= 1.0;
        return -0.5 * (p * (p - 2.0) - 1.0);
      case AdwEasing.easeInCubic:
        return value * value * value;
      case AdwEasing.easeOutCubic:
        final p = value - 1.0;
        return p * p * p + 1.0;
      case AdwEasing.easeInOutCubic:
        var p = value * 2.0;
        if (p < 1.0) return 0.5 * p * p * p;
        p -= 2.0;
        return 0.5 * (p * p * p + 2.0);
      case AdwEasing.easeInQuart:
        return value * value * value * value;
      case AdwEasing.easeOutQuart:
        final p = value - 1.0;
        return -1.0 * (p * p * p * p - 1.0);
      case AdwEasing.easeInOutQuart:
        var p = value * 2.0;
        if (p < 1.0) return 0.5 * p * p * p * p;
        p -= 2.0;
        return -0.5 * (p * p * p * p - 2.0);
      case AdwEasing.easeInQuint:
        return value * value * value * value * value;
      case AdwEasing.easeOutQuint:
        final p = value - 1.0;
        return p * p * p * p * p + 1.0;
      case AdwEasing.easeInOutQuint:
        var p = value * 2.0;
        if (p < 1.0) return 0.5 * p * p * p * p * p;
        p -= 2.0;
        return 0.5 * (p * p * p * p * p + 2.0);
      case AdwEasing.easeInSine:
        return -1.0 * math.cos(value * (math.pi / 2.0)) + 1.0;
      case AdwEasing.easeOutSine:
        return math.sin(value * (math.pi / 2.0));
      case AdwEasing.easeInOutSine:
        return -0.5 * (math.cos(math.pi * value) - 1.0);
      case AdwEasing.easeInExpo:
        return value <= 1e-12 ? 0.0 : math.pow(2.0, 10.0 * (value - 1.0)).toDouble();
      case AdwEasing.easeOutExpo:
        return (1.0 - value).abs() <= 1e-12
            ? 1.0
            : -math.pow(2.0, -10.0 * value).toDouble() + 1.0;
      case AdwEasing.easeInOutExpo:
        if (value <= 1e-12) return 0.0;
        if ((1.0 - value).abs() <= 1e-12) return 1.0;
        var p = value * 2.0;
        if (p < 1.0) return 0.5 * math.pow(2.0, 10.0 * (p - 1.0)).toDouble();
        p -= 1.0;
        return 0.5 * (-math.pow(2.0, -10.0 * p).toDouble() + 2.0);
      case AdwEasing.easeInCirc:
        return -1.0 * (math.sqrt(math.max(0.0, 1.0 - value * value)) - 1.0);
      case AdwEasing.easeOutCirc:
        final p = value - 1.0;
        return math.sqrt(math.max(0.0, 1.0 - p * p));
      case AdwEasing.easeInOutCirc:
        var p = value * 2.0;
        if (p < 1.0) {
          return -0.5 * (math.sqrt(math.max(0.0, 1.0 - p * p)) - 1.0);
        }
        p -= 2.0;
        return 0.5 * (math.sqrt(math.max(0.0, 1.0 - p * p)) + 1.0);
      case AdwEasing.easeInElastic:
        const p = 0.3;
        const s = p / 4.0;
        var q = value;
        if ((q - 1.0).abs() <= 1e-12) return 1.0;
        q -= 1.0;
        return -(math.pow(2.0, 10.0 * q) *
                math.sin((q - s) * (2.0 * math.pi) / p))
            .toDouble();
      case AdwEasing.easeOutElastic:
        const p = 0.3;
        const s = p / 4.0;
        final q = value;
        if ((q - 1.0).abs() <= 1e-12) return 1.0;
        return (math.pow(2.0, -10.0 * q) *
                    math.sin((q - s) * (2.0 * math.pi) / p) +
                1.0)
            .toDouble();
      case AdwEasing.easeInOutElastic:
        const p = 0.3 * 1.5;
        const s = p / 4.0;
        var q = value * 2.0;
        if ((q - 2.0).abs() <= 1e-12) return 1.0;
        if (q < 1.0) {
          q -= 1.0;
          return -0.5 *
              (math.pow(2.0, 10.0 * q) *
                      math.sin((q - s) * (2.0 * math.pi) / p))
                  .toDouble();
        }
        q -= 1.0;
        return (math.pow(2.0, -10.0 * q) *
                    math.sin((q - s) * (2.0 * math.pi) / p) *
                    0.5 +
                1.0)
            .toDouble();
      case AdwEasing.easeInBack:
        return value * value * ((1.70158 + 1.0) * value - 1.70158);
      case AdwEasing.easeOutBack:
        final p = value - 1.0;
        return p * p * ((1.70158 + 1.0) * p + 1.70158) + 1.0;
      case AdwEasing.easeInOutBack:
        var p = value * 2.0;
        const s = 1.70158 * 1.525;
        if (p < 1.0) {
          return 0.5 * (p * p * ((s + 1.0) * p - s));
        }
        p -= 2.0;
        return 0.5 * (p * p * ((s + 1.0) * p + s) + 2.0);
      case AdwEasing.easeInBounce:
        return _easeInBounce(value);
      case AdwEasing.easeOutBounce:
        return _easeOutBounce(value);
      case AdwEasing.easeInOutBounce:
        if (value < 0.5) {
          return _easeInBounce(value * 2.0) * 0.5;
        }
        return _easeOutBounce(value * 2.0 - 1.0) * 0.5 + 0.5;
      case AdwEasing.ease:
        return _cubicBezier(value, 0.25, 0.1, 0.25, 1.0);
      case AdwEasing.easeIn:
        return _cubicBezier(value, 0.42, 0.0, 1.0, 1.0);
      case AdwEasing.easeOut:
        return _cubicBezier(value, 0.0, 0.0, 0.58, 1.0);
      case AdwEasing.easeInOut:
        return _cubicBezier(value, 0.42, 0.0, 0.58, 1.0);
    }
  }

  static double _easeOutBounce(double p) {
    if (p < (1.0 / 2.75)) {
      return 7.5625 * p * p;
    } else if (p < (2.0 / 2.75)) {
      final q = p - (1.5 / 2.75);
      return 7.5625 * q * q + 0.75;
    } else if (p < (2.5 / 2.75)) {
      final q = p - (2.25 / 2.75);
      return 7.5625 * q * q + 0.9375;
    } else {
      final q = p - (2.625 / 2.75);
      return 7.5625 * q * q + 0.984375;
    }
  }

  static double _easeInBounce(double t) {
    return 1.0 - _easeOutBounce(1.0 - t);
  }

  static double _xForT(double t, double x1, double x2) {
    final omt = 1.0 - t;
    return 3.0 * omt * omt * t * x1 + 3.0 * omt * t * t * x2 + t * t * t;
  }

  static double _yForT(double t, double y1, double y2) {
    final omt = 1.0 - t;
    return 3.0 * omt * omt * t * y1 + 3.0 * omt * t * t * y2 + t * t * t;
  }

  static double _cubicBezier(
    double x,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    if (x <= 1e-12) return 0.0;
    if ((1.0 - x).abs() <= 1e-12) return 1.0;
    var minT = 0.0;
    var maxT = 1.0;
    for (var i = 0; i < 30; i++) {
      final guessT = (minT + maxT) * 0.5;
      final guessX = _xForT(guessT, x1, x2);
      if (x < guessX) {
        maxT = guessT;
      } else {
        minT = guessT;
      }
    }
    return _yForT((minT + maxT) * 0.5, y1, y2);
  }
}

enum _AnimMode { timed, spring }

enum _AnimState { idle, playing, paused, finished }

class AnimationsPage extends StatefulWidget {
  const AnimationsPage({super.key});

  @override
  State<AnimationsPage> createState() => _AnimationsPageState();
}

class _AnimationsPageState extends State<AnimationsPage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _lastTick;
  double _elapsedMs = 0.0;

  _AnimMode _mode = _AnimMode.timed;
  _AnimState _state = _AnimState.idle;

  // Timed animation parameters (`adw-demo-page-animations.ui` & `.c`)
  AdwEasing _easing = AdwEasing.easeInOutCubic;
  double _durationMs = 500.0;
  double _repeatCount = 1.0;
  bool _reverse = false;
  bool _alternate = false;

  // Spring animation parameters (`adw-demo-page-animations.ui` & `.c`)
  double _initialVelocity = 0.0;
  double _damping = 10.0;
  double _mass = 1.0;
  double _stiffness = 100.0;
  double _epsilon = 0.001;
  bool _springClamp = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_state != _AnimState.playing) return;
    final dtMs = _lastTick == null
        ? 0.0
        : (elapsed - _lastTick!).inMicroseconds / 1000.0;
    _lastTick = elapsed;

    final nextElapsed = _elapsedMs + dtMs;
    final estDuration = _estimatedDurationMs();

    if (estDuration.isFinite && nextElapsed >= estDuration) {
      _ticker.stop();
      _lastTick = null;
      setState(() {
        _elapsedMs = estDuration;
        _state = _AnimState.finished;
      });
    } else {
      setState(() {
        _elapsedMs = nextElapsed;
      });
    }
  }

  double _estimatedDurationMs() {
    if (_mode == _AnimMode.timed) {
      final count = _repeatCount.round();
      if (count <= 0) return double.infinity;
      return _durationMs * count;
    }
    return _calculateSpringDurationMs();
  }

  double _currentProgress() {
    if (_state == _AnimState.idle) {
      return 0.0;
    }
    if (_state == _AnimState.finished) {
      if (_mode == _AnimMode.timed) {
        final count = _repeatCount.round();
        final rev =
            _alternate ? (count % 2 == 1 ? !_reverse : _reverse) : _reverse;
        return _alternate == rev ? 1.0 : 0.0;
      }
      return 1.0;
    }
    if (_mode == _AnimMode.timed) {
      return _calculateTimedValue(_elapsedMs);
    }
    return _calculateSpringValue(_elapsedMs);
  }

  double _calculateTimedValue(double tMs) {
    if (_durationMs <= 0) return 1.0;
    final totalIter = tMs / _durationMs;
    final iteration = totalIter.floor();
    var progress = totalIter - iteration;

    var rev = false;
    if (_alternate) {
      rev = (iteration % 2) != 0;
    }
    if (_reverse) {
      rev = !rev;
    }

    final est = _estimatedDurationMs();
    if (est.isFinite && tMs >= est) {
      return _alternate == rev ? 1.0 : 0.0;
    }

    if (rev) {
      progress = 1.0 - progress;
    }

    return _easing.transform(progress);
  }

  // Exact port of `oscillate` from `adw-spring-animation.c` (`value_from = 0`, `value_to = 1`).
  double _oscillateSpring(double timeMs) {
    final b = _damping;
    final m = _mass <= 0.0 ? 0.001 : _mass;
    final k = _stiffness;
    final v0 = _initialVelocity;

    final t = timeMs / 1000.0;
    final beta = b / (2.0 * m);
    final omega0 = math.sqrt(k / m);
    const x0 = -1.0; // value_from (0) - value_to (1)
    final envelope = math.exp(-beta * t);

    if ((beta - omega0).abs() <= 1.19209290e-7) {
      return 1.0 + envelope * (x0 + (beta * x0 + v0) * t);
    }

    if (beta < omega0) {
      final omega1 = math.sqrt((omega0 * omega0) - (beta * beta));
      return 1.0 +
          envelope *
              (x0 * math.cos(omega1 * t) +
                  ((beta * x0 + v0) / omega1) * math.sin(omega1 * t));
    }

    final omega2 = math.sqrt((beta * beta) - (omega0 * omega0));
    final coshVal = 0.5 * (math.exp(omega2 * t) + math.exp(-omega2 * t));
    final sinhVal = 0.5 * (math.exp(omega2 * t) - math.exp(-omega2 * t));
    return 1.0 +
        envelope * (x0 * coshVal + ((beta * x0 + v0) / omega2) * sinhVal);
  }

  double _getFirstZeroMs() {
    var i = 1;
    var y = _oscillateSpring(i.toDouble());
    while (1.0 - y > _epsilon) {
      if (i > 20000) return 0.0;
      i++;
      y = _oscillateSpring(i.toDouble());
    }
    return i.toDouble();
  }

  double _calculateSpringDurationMs() {
    final m = _mass <= 0.0 ? 0.001 : _mass;
    final beta = _damping / (2.0 * m);
    if (beta <= 1e-12) return double.infinity;

    if (_springClamp) {
      return _getFirstZeroMs();
    }

    final omega0 = math.sqrt(_stiffness / m);
    var x0 = -math.log(_epsilon) / beta;

    if ((beta - omega0).abs() <= 1.19209290e-7 || beta < omega0) {
      return x0 * 1000.0;
    }

    const delta = 0.001;
    var y0 = _oscillateSpring(x0 * 1000.0);
    var slope = (_oscillateSpring((x0 + delta) * 1000.0) - y0) / delta;
    if (slope.abs() <= 1e-12) return x0 * 1000.0;
    var x1 = (1.0 - y0 + slope * x0) / slope;
    var y1 = _oscillateSpring(x1 * 1000.0);

    var i = 0;
    while ((1.0 - y1).abs() > _epsilon) {
      if (i > 1000) return 0.0;
      x0 = x1;
      y0 = y1;
      slope = (_oscillateSpring((x0 + delta) * 1000.0) - y0) / delta;
      if (slope.abs() <= 1e-12) break;
      x1 = (1.0 - y0 + slope * x0) / slope;
      y1 = _oscillateSpring(x1 * 1000.0);
      i++;
    }
    return x1 * 1000.0;
  }

  double _calculateSpringValue(double tMs) {
    final est = _calculateSpringDurationMs();
    if (est.isFinite && tMs >= est) return 1.0;
    final val = _oscillateSpring(tMs);
    return _springClamp ? val.clamp(0.0, 1.0) : val;
  }

  void _resetAnimation() {
    _ticker.stop();
    _lastTick = null;
    setState(() {
      _elapsedMs = 0.0;
      _state = _AnimState.idle;
    });
  }

  void _playPauseAnimation() {
    if (_state == _AnimState.playing) {
      _ticker.stop();
      _lastTick = null;
      setState(() {
        _state = _AnimState.paused;
      });
    } else if (_state == _AnimState.paused) {
      _lastTick = null;
      setState(() {
        _state = _AnimState.playing;
      });
      _ticker.start();
    } else {
      _lastTick = null;
      setState(() {
        _elapsedMs = 0.0;
        _state = _AnimState.playing;
      });
      _ticker.start();
    }
  }

  void _skipAnimation() {
    _ticker.stop();
    _lastTick = null;
    setState(() {
      final est = _estimatedDurationMs();
      _elapsedMs = est.isFinite ? est : _durationMs;
      _state = _AnimState.finished;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final progress = _currentProgress();
    final isPlaying = _state == _AnimState.playing;
    final canReset = _state != _AnimState.idle;
    final canSkip = _state != _AnimState.finished;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated green ball inside 400px AdwClamp (`timed_animation_sample`)
            AdwClamp(
              maximumSize: 400.0,
              tighteningThreshold: 300.0,
              minimumMargin: 0.0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final trackWidth = constraints.maxWidth;
                    const ballSize = 30.0;
                    final offset = (trackWidth - ballSize) * (progress - 0.5);

                    return SizedBox(
                      width: trackWidth,
                      height: ballSize,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(offset, 0.0),
                          child: Container(
                            width: ballSize,
                            height: ballSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AdwColors.green2,
                                  AdwColors.green5,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Title & Description (`.timed-animation-page > box > label.title`)
            Text(
              'Animations',
              style: theme.typography.title1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12.0),
            Text(
              'Simple transitions',
              style: theme.typography.body,
              textAlign: TextAlign.center,
            ),

            // Playback controls (`timed_animation_button_box`, forced LTR)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdwButton(
                      style: AdwButtonStyle.flat,
                      isCircular: true,
                      width: 34.0,
                      height: 34.0,
                      onPressed: canReset ? _resetAnimation : null,
                      child: const Icon(
                        AdwIcons.media_skip_backward_symbolic,
                        size: 16.0,
                      ),
                    ),
                    const SizedBox(width: 18.0),
                    AdwButton(
                      style: AdwButtonStyle.suggested,
                      isCircular: true,
                      width: 48.0,
                      height: 48.0,
                      onPressed: _playPauseAnimation,
                      child: Icon(
                        isPlaying
                            ? AdwIcons.media_playback_pause_symbolic
                            : AdwIcons.media_playback_start_symbolic,
                        size: 16.0,
                      ),
                    ),
                    const SizedBox(width: 18.0),
                    AdwButton(
                      style: AdwButtonStyle.flat,
                      isCircular: true,
                      width: 34.0,
                      height: 34.0,
                      onPressed: canSkip ? _skipAnimation : null,
                      child: const Icon(
                        AdwIcons.media_skip_forward_symbolic,
                        size: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // `AdwInlineViewSwitcher` (`width-request: 250`, `margin-bottom: 32`)
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: SizedBox(
                width: 250.0,
                child: AdwToggleGroup<_AnimMode>(
                  homogeneous: true,
                  selectedValue: _mode,
                  onChanged: (nextMode) {
                    if (_mode == nextMode) return;
                    _mode = nextMode;
                    _resetAnimation();
                  },
                  items: [
                    AdwToggleItem.withLabel(
                      value: _AnimMode.timed,
                      label: const Text('Timed'),
                    ),
                    AdwToggleItem.withLabel(
                      value: _AnimMode.spring,
                      label: const Text('Spring'),
                    ),
                  ],
                ),
              ),
            ),

            // `animation_preferences_stack` inside 400px `AdwClamp`
            AdwClamp(
              maximumSize: 400.0,
              tighteningThreshold: 300.0,
              minimumMargin: 0.0,
              child: AnimatedSize(
                duration: AdwCurves.normalDuration,
                curve: AdwCurves.standard,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                child: AnimatedSwitcher(
                  duration: AdwCurves.normalDuration,
                  switchInCurve: AdwCurves.standard,
                  switchOutCurve: AdwCurves.standard,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        for (final prev in previousChildren)
                          Positioned(
                            top: 0.0,
                            left: 0.0,
                            right: 0.0,
                            child: prev,
                          ),
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: _mode == _AnimMode.timed
                      ? _buildTimedGroup()
                      : _buildSpringGroup(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimedGroup() {
    return AdwPreferencesGroup(
      key: const ValueKey('Timed'),
      children: [
        AdwComboRow<AdwEasing>(
          title: const Text('Easing'),
          items: AdwEasing.values,
          selectedItem: _easing,
          itemTitleBuilder: (e) => e.label,
          onSelected: (e) => setState(() => _easing = e),
        ),
        AdwSpinRow(
          title: const Text('Duration'),
          value: _durationMs,
          min: 100.0,
          max: 4000.0,
          step: 50.0,
          onChanged: (v) => setState(() => _durationMs = v),
        ),
        AdwSpinRow(
          title: const Text('Repeat Count'),
          value: _repeatCount,
          min: 0.0,
          max: 10.0,
          step: 1.0,
          onChanged: (v) => setState(() => _repeatCount = v),
        ),
        AdwSwitchRow(
          title: const Text('Reverse'),
          value: _reverse,
          onChanged: (v) => setState(() => _reverse = v),
        ),
        AdwSwitchRow(
          title: const Text('Alternate'),
          value: _alternate,
          onChanged: (v) => setState(() => _alternate = v),
        ),
      ],
    );
  }

  Widget _buildSpringGroup() {
    return AdwPreferencesGroup(
      key: const ValueKey('Spring'),
      children: [
        AdwSpinRow(
          title: const Text('Initial Velocity'),
          value: _initialVelocity,
          min: -1000.0,
          max: 1000.0,
          step: 1.0,
          onChanged: (v) => setState(() => _initialVelocity = v),
        ),
        AdwSpinRow(
          title: const Text('Damping'),
          value: _damping,
          min: 0.0,
          max: 1000.0,
          step: 1.0,
          onChanged: (v) => setState(() => _damping = v),
        ),
        AdwSpinRow(
          title: const Text('Mass'),
          value: _mass,
          min: 0.0,
          max: 100.0,
          step: 1.0,
          onChanged: (v) => setState(() => _mass = v),
        ),
        AdwSpinRow(
          title: const Text('Stiffness'),
          value: _stiffness,
          min: 0.0,
          max: 1000.0,
          step: 1.0,
          onChanged: (v) => setState(() => _stiffness = v),
        ),
        AdwSpinRow(
          title: const Text('Epsilon'),
          value: _epsilon,
          min: 0.0001,
          max: 0.01,
          step: 0.001,
          decimalDigits: 5,
          onChanged: (v) => setState(() => _epsilon = v),
        ),
        AdwSwitchRow(
          title: const Text('Clamp'),
          value: _springClamp,
          onChanged: (v) => setState(() => _springClamp = v),
        ),
      ],
    );
  }
}
