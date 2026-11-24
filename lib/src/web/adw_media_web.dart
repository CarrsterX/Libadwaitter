import 'dart:js_interop';
import 'dart:js_interop_unsafe';

typedef WebMediaCommandCallback = void Function(
  String command, {
  int? positionUs,
  int? offsetUs,
});

@JS('window')
external JSObject get _window;

@JS('navigator')
external JSObject get _navigator;

JSFunction? get _audioCtor {
  if (!_window.has('Audio')) return null;
  final raw = _window['Audio'];
  if (raw.isUndefinedOrNull) return null;
  return raw as JSFunction;
}

// Tiny silent 0.1s PCM WAV (8 kHz, 8-bit mono) so Chromium/Brave activates
// the browser Media Session & OS media controls even for simulated playback.
const String _kSilentWavDataUri =
    'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';

JSObject? _silentAudio;

JSObject? _ensureSilentAudio() {
  if (_silentAudio != null) return _silentAudio;
  final ctor = _audioCtor;
  if (ctor == null) return null;
  try {
    final audio = ctor.callAsConstructor<JSObject>(_kSilentWavDataUri.toJS);
    audio['loop'] = true.toJS;
    audio['volume'] = 0.01.toJS;
    _silentAudio = audio;
    return audio;
  } catch (_) {
    return null;
  }
}

JSFunction? get _mediaMetadataCtor {
  if (!_window.has('MediaMetadata')) return null;
  final raw = _window['MediaMetadata'];
  if (raw.isUndefinedOrNull) return null;
  return raw as JSFunction;
}

JSObject? get _mediaSession {
  if (!_navigator.has('mediaSession')) return null;
  final ms = _navigator['mediaSession'];
  return ms.isUndefinedOrNull ? null : ms as JSObject;
}

void webMediaRegisterHandlers(WebMediaCommandCallback onCommand) {
  final ms = _mediaSession;
  if (ms == null) return;

  void setHandler(String action, JSFunction fn) {
    try {
      ms.callMethod<JSAny?>('setActionHandler'.toJS, action.toJS, fn);
    } catch (_) {}
  }

  setHandler('play', (() => onCommand('play')).toJS);
  setHandler('pause', (() => onCommand('pause')).toJS);
  setHandler('stop', (() => onCommand('stop')).toJS);
  setHandler('nexttrack', (() => onCommand('next')).toJS);
  setHandler('previoustrack', (() => onCommand('previous')).toJS);
  setHandler(
    'seekbackward',
    ((JSObject? details) {
      double offsetSec = 10.0;
      if (details != null && details.has('seekOffset')) {
        final raw = details['seekOffset'];
        if (!raw.isUndefinedOrNull) {
          final parsed = (raw as JSNumber).toDartDouble;
          if (parsed > 0) offsetSec = parsed;
        }
      }
      onCommand('seek', offsetUs: -(offsetSec * 1000000).round());
    }).toJS,
  );
  setHandler(
    'seekforward',
    ((JSObject? details) {
      double offsetSec = 10.0;
      if (details != null && details.has('seekOffset')) {
        final raw = details['seekOffset'];
        if (!raw.isUndefinedOrNull) {
          final parsed = (raw as JSNumber).toDartDouble;
          if (parsed > 0) offsetSec = parsed;
        }
      }
      onCommand('seek', offsetUs: (offsetSec * 1000000).round());
    }).toJS,
  );
  setHandler(
    'seekto',
    ((JSObject? details) {
      if (details != null && details.has('seekTime')) {
        final raw = details['seekTime'];
        if (!raw.isUndefinedOrNull) {
          final seekTime = (raw as JSNumber).toDartDouble;
          onCommand('setPosition', positionUs: (seekTime * 1000000).round());
        }
      }
    }).toJS,
  );
}

double _lastDurationSec = 0.0;
double _lastRate = 1.0;

void _syncPositionState(Duration position) {
  final ms = _mediaSession;
  if (ms == null || _lastDurationSec <= 0 || !ms.has('setPositionState')) {
    return;
  }
  try {
    final posSec =
        (position.inMicroseconds / 1000000.0).clamp(0.0, _lastDurationSec);
    final state = JSObject();
    state['duration'] = _lastDurationSec.toJS;
    state['playbackRate'] = (_lastRate > 0 ? _lastRate : 1.0).toJS;
    state['position'] = posSec.toJS;
    ms.callMethod<JSAny?>('setPositionState'.toJS, state);
  } catch (_) {}
}

void webMediaSetMetadata({
  required String title,
  String? artist,
  String? album,
  String? artUrl,
  Duration? duration,
}) {
  if (duration != null && duration.inMicroseconds > 0) {
    _lastDurationSec = duration.inMicroseconds / 1000000.0;
  }
  final ms = _mediaSession;
  final ctor = _mediaMetadataCtor;
  if (ms == null || ctor == null) return;
  try {
    final init = JSObject();
    init['title'] = title.toJS;
    if (artist != null) init['artist'] = artist.toJS;
    if (album != null) init['album'] = album.toJS;
    if (artUrl != null && artUrl.isNotEmpty) {
      final art = JSObject();
      art['src'] = artUrl.toJS;
      init['artwork'] = <JSObject>[art].toJS;
    }
    ms['metadata'] = ctor.callAsConstructor<JSObject>(init);
  } catch (_) {}
}

void webMediaSetPlaybackState({
  required String status,
  Duration position = Duration.zero,
  double rate = 1.0,
}) {
  _lastRate = rate;
  final ms = _mediaSession;
  if (ms == null) return;
  try {
    final audio = _ensureSilentAudio();
    if (status == 'playing') {
      audio?.callMethod<JSAny?>('play'.toJS);
    } else {
      audio?.callMethod<JSAny?>('pause'.toJS);
    }
    final webState = switch (status) {
      'playing' => 'playing',
      'paused' => 'paused',
      _ => 'none',
    };
    ms['playbackState'] = webState.toJS;
    _syncPositionState(position);
  } catch (_) {}
}

void webMediaSetPosition(Duration position) {
  _syncPositionState(position);
}

void webMediaDispose() {
  try {
    _silentAudio?.callMethod<JSAny?>('pause'.toJS);
  } catch (_) {}
  final ms = _mediaSession;
  if (ms == null) return;
  try {
    ms['metadata'] = null;
    ms['playbackState'] = 'none'.toJS;
  } catch (_) {}
}
