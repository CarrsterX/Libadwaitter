import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'web/adw_media_web_stub.dart'
    if (dart.library.js_interop) 'web/adw_media_web.dart' as web_media;

/// Playback state published to the system media controller (MPRIS2 on Linux,
/// `MediaSession` on Android).
///
/// {@category Media & System Tray}
enum AdwPlaybackStatus {
  /// Media playback is stopped.
  stopped,

  /// Media is actively playing.
  playing,

  /// Media playback is paused.
  paused,
}

/// Loop / repeat mode published to the system media controller (MPRIS2 `LoopStatus`).
///
/// {@category Media & System Tray}
enum AdwLoopMode {
  /// No repeat.
  none,

  /// Repeat the current track.
  track,

  /// Repeat the entire playlist.
  playlist,
}

/// Media track metadata published to the system media controller.
///
/// {@category Media & System Tray}
class AdwMediaMetadata {
  /// Creates a track metadata snapshot for [AdwMediaSession].
  const AdwMediaMetadata({
    required this.title,
    this.artist,
    this.album,
    this.artUrl,
    this.duration,
    this.trackId,
  });

  /// Track display title.
  final String title;

  /// Optional artist name.
  final String? artist;

  /// Optional album name.
  final String? album;

  /// Optional artwork URI (`file://` or `https://`).
  final String? artUrl;

  /// Optional total track duration.
  final Duration? duration;

  /// Optional unique track identifier.
  final String? trackId;

  /// Serializes this metadata to a platform-channel map.
  Map<String, dynamic> toMap() => {
        'title': title,
        if (artist != null) 'artist': artist,
        if (album != null) 'album': album,
        if (artUrl != null) 'artUrl': artUrl,
        if (duration != null) 'durationUs': duration!.inMicroseconds,
        if (trackId != null) 'trackId': trackId,
      };
}

/// Command types emitted by the system media controls (GNOME Shell, lock
/// screen, hardware media keys, Android media shade / Bluetooth controls).
///
/// {@category Media & System Tray}
enum AdwMediaCommandType {
  /// Start or resume playback.
  play,

  /// Pause playback.
  pause,

  /// Toggle between playing and paused.
  playPause,

  /// Stop playback.
  stop,

  /// Skip to the next track.
  next,

  /// Skip to the previous track.
  previous,

  /// Seek by a relative [AdwMediaCommand.offset].
  seek,

  /// Jump to an absolute [AdwMediaCommand.position].
  setPosition,

  /// Change the repeat mode to [AdwMediaCommand.loopMode].
  setLoopMode,

  /// Toggle shuffle state to [AdwMediaCommand.shuffle].
  setShuffle,

  /// Bring the application window to the foreground.
  raise,

  /// Request application exit.
  quit,
}

/// Command received from the system media controller via [AdwMediaSession.commands].
///
/// {@category Media & System Tray}
class AdwMediaCommand {
  /// Creates a media control command payload.
  const AdwMediaCommand({
    required this.type,
    this.offset,
    this.position,
    this.loopMode,
    this.shuffle,
  });

  /// The kind of media action requested by the system.
  final AdwMediaCommandType type;

  /// Relative seek offset for [AdwMediaCommandType.seek].
  final Duration? offset;

  /// Absolute target position for [AdwMediaCommandType.setPosition].
  final Duration? position;

  /// Target loop mode for [AdwMediaCommandType.setLoopMode].
  final AdwLoopMode? loopMode;

  /// Target shuffle state for [AdwMediaCommandType.setShuffle].
  final bool? shuffle;
}

/// System media player integration bridge (`libadwaitter/media`).
///
/// ```dart
/// await AdwMediaSession.setMetadata(
///   const AdwMediaMetadata(title: 'Track 1', artist: 'Artist'),
/// );
/// await AdwMediaSession.setPlaybackStatus(AdwPlaybackStatus.playing);
/// ```
///
/// {@category Media & System Tray}
///
/// - **Linux:** Exposes an `org.mpris.MediaPlayer2` D-Bus service so GNOME
///   Shell, lock-screen controls, and hardware media keys control your player.
/// - **Android:** Registers a native `android.media.session.MediaSession` and
///   system media notification with transport controls.
class AdwMediaSession {
  AdwMediaSession._();

  static const MethodChannel _defaultChannel =
      MethodChannel('libadwaitter/media');

  static MethodChannel _channel = _defaultChannel;
  static bool _handlerRegistered = false;
  static final StreamController<AdwMediaCommand> _commandController =
      StreamController<AdwMediaCommand>.broadcast();

  static bool get _isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.android;

  /// Stream of media transport commands initiated by the operating system.
  static Stream<AdwMediaCommand> get commands {
    _ensureHandlerRegistered();
    return _commandController.stream;
  }

  static void _ensureHandlerRegistered() {
    if (_handlerRegistered) return;
    _handlerRegistered = true;
    if (kIsWeb) {
      web_media.webMediaRegisterHandlers(
        (command, {int? positionUs, int? offsetUs}) {
          _dispatchCommand(command, positionUs: positionUs, offsetUs: offsetUs);
        },
      );
      return;
    }
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static void _dispatchCommand(
    String name, {
    int? offsetUs,
    int? positionUs,
    String? loopStr,
    bool? shuffle,
  }) {
    final type = switch (name) {
      'play' => AdwMediaCommandType.play,
      'pause' => AdwMediaCommandType.pause,
      'playPause' => AdwMediaCommandType.playPause,
      'stop' => AdwMediaCommandType.stop,
      'next' => AdwMediaCommandType.next,
      'previous' => AdwMediaCommandType.previous,
      'seek' => AdwMediaCommandType.seek,
      'setPosition' => AdwMediaCommandType.setPosition,
      'setLoopMode' => AdwMediaCommandType.setLoopMode,
      'setShuffle' => AdwMediaCommandType.setShuffle,
      'raise' => AdwMediaCommandType.raise,
      'quit' => AdwMediaCommandType.quit,
      _ => null,
    };
    if (type == null) return;
    final loopMode = switch (loopStr) {
      'none' => AdwLoopMode.none,
      'track' => AdwLoopMode.track,
      'playlist' => AdwLoopMode.playlist,
      _ => null,
    };
    _commandController.add(
      AdwMediaCommand(
        type: type,
        offset: offsetUs != null ? Duration(microseconds: offsetUs) : null,
        position:
            positionUs != null ? Duration(microseconds: positionUs) : null,
        loopMode: loopMode,
        shuffle: shuffle,
      ),
    );
  }

  static Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onMediaCommand') return;
    final args = call.arguments;
    if (args is! Map) return;
    final name = args['command'] as String?;
    if (name == null) return;
    _dispatchCommand(
      name,
      offsetUs: (args['offsetUs'] as num?)?.toInt(),
      positionUs: (args['positionUs'] as num?)?.toInt(),
      loopStr: args['loopMode'] as String?,
      shuffle: args['shuffle'] as bool?,
    );
  }

  /// Publishes current track metadata to the system media controller.
  static Future<void> setMetadata(AdwMediaMetadata metadata) async {
    if (!_isSupported) return;
    _ensureHandlerRegistered();
    if (kIsWeb) {
      web_media.webMediaSetMetadata(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        artUrl: metadata.artUrl,
        duration: metadata.duration,
      );
      return;
    }
    try {
      await _channel.invokeMethod<void>('setMetadata', metadata.toMap());
    } on MissingPluginException {
      // Runner does not register libadwaitter/media.
    }
  }

  /// Publishes playback status, position, and available transport capabilities.
  static Future<void> setPlaybackState({
    required AdwPlaybackStatus status,
    Duration position = Duration.zero,
    double rate = 1.0,
    AdwLoopMode loopMode = AdwLoopMode.none,
    bool shuffle = false,
    bool canGoNext = true,
    bool canGoPrevious = true,
    bool canPlay = true,
    bool canPause = true,
    bool canSeek = true,
  }) async {
    if (!_isSupported) return;
    _ensureHandlerRegistered();
    if (kIsWeb) {
      web_media.webMediaSetPlaybackState(
        status: status.name,
        position: position,
        rate: rate,
      );
      return;
    }
    try {
      await _channel.invokeMethod<void>('setPlaybackState', {
        'status': status.name,
        'positionUs': position.inMicroseconds,
        'rate': rate,
        'loopMode': loopMode.name,
        'shuffle': shuffle,
        'canGoNext': canGoNext,
        'canGoPrevious': canGoPrevious,
        'canPlay': canPlay,
        'canPause': canPause,
        'canSeek': canSeek,
      });
    } on MissingPluginException {
      // Runner does not register libadwaitter/media.
    }
  }

  /// Notifies the system controller that playback jumped to [position].
  static Future<void> setPosition(Duration position) async {
    if (!_isSupported) return;
    _ensureHandlerRegistered();
    if (kIsWeb) {
      web_media.webMediaSetPosition(position);
      return;
    }
    try {
      await _channel.invokeMethod<void>('setPosition', {
        'positionUs': position.inMicroseconds,
      });
    } on MissingPluginException {
      // Runner does not register libadwaitter/media.
    }
  }

  /// Unregisters the system media session (releases the MPRIS2 bus name on
  /// Linux and removes the media notification/session on Android).
  static Future<void> dispose() async {
    if (!_isSupported) return;
    if (kIsWeb) {
      web_media.webMediaDispose();
      return;
    }
    try {
      await _channel.invokeMethod<void>('dispose');
    } on MissingPluginException {
      // Runner does not register libadwaitter/media.
    }
  }

  @visibleForTesting
  static void setChannelForTesting(MethodChannel channel) {
    _channel = channel;
    _handlerRegistered = false;
  }

  @visibleForTesting
  static void resetChannelForTesting() {
    _channel = _defaultChannel;
    _handlerRegistered = false;
  }
}
