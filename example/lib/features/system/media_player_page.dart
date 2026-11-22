import 'dart:async';

import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class MediaPlayerPage extends StatefulWidget {
  const MediaPlayerPage({super.key});

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  static const List<
      ({String title, String artist, String album, Duration duration})> _tracks =
      [
    (
      title: 'Aurora Borealis',
      artist: 'GNOME Soundscape',
      album: 'Adwaita Sessions',
      duration: Duration(minutes: 3, seconds: 42),
    ),
    (
      title: 'Wayland Drift',
      artist: 'Libadwaitter Ensemble',
      album: 'Adwaita Sessions',
      duration: Duration(minutes: 4, seconds: 15),
    ),
    (
      title: 'Symbolic Echoes',
      artist: 'Desktop Collective',
      album: 'Open Standards',
      duration: Duration(minutes: 2, seconds: 58),
    ),
  ];

  int _trackIndex = 0;
  AdwPlaybackStatus _status = AdwPlaybackStatus.paused;
  AdwLoopMode _loopMode = AdwLoopMode.none;
  bool _shuffle = false;
  Duration _position = const Duration(seconds: 42);
  Timer? _ticker;
  StreamSubscription<AdwMediaCommand>? _commandSub;
  final List<String> _commandLog = <String>[];

  ({String title, String artist, String album, Duration duration}) get _current =>
      _tracks[_trackIndex];

  bool get _isPlaying => _status == AdwPlaybackStatus.playing;

  @override
  void initState() {
    super.initState();
    _commandSub = AdwMediaSession.commands.listen(_handleSystemCommand);
    _syncSystemSession(includeMetadata: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _commandSub?.cancel();
    AdwMediaSession.dispose();
    super.dispose();
  }

  void _startOrStopTicker() {
    _ticker?.cancel();
    if (_isPlaying) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _position += const Duration(seconds: 1);
          if (_position >= _current.duration) {
            _trackIndex = (_trackIndex + 1) % _tracks.length;
            _position = Duration.zero;
            _syncSystemSession(includeMetadata: true);
          }
        });
      });
    }
  }

  Future<void> _syncSystemSession({bool includeMetadata = false}) async {
    if (includeMetadata) {
      await AdwMediaSession.setMetadata(
        AdwMediaMetadata(
          title: _current.title,
          artist: _current.artist,
          album: _current.album,
          duration: _current.duration,
          trackId: '/org/libadwaitter/track/$_trackIndex',
        ),
      );
    }
    await AdwMediaSession.setPlaybackState(
      status: _status,
      position: _position,
      loopMode: _loopMode,
      shuffle: _shuffle,
      canGoNext: true,
      canGoPrevious: true,
      canPlay: true,
      canPause: true,
      canSeek: true,
    );
  }

  void _logCommand(String description) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _commandLog.insert(0, '[$ts] $description');
      if (_commandLog.length > 10) {
        _commandLog.removeLast();
      }
    });
  }

  void _handleSystemCommand(AdwMediaCommand command) {
    if (!mounted) return;
    switch (command.type) {
      case AdwMediaCommandType.play:
        _setPlaying(true);
        _logCommand('System → Play');
      case AdwMediaCommandType.pause:
        _setPlaying(false);
        _logCommand('System → Pause');
      case AdwMediaCommandType.playPause:
        _togglePlayPause();
        _logCommand('System → PlayPause');
      case AdwMediaCommandType.stop:
        setState(() {
          _status = AdwPlaybackStatus.stopped;
          _position = Duration.zero;
        });
        _startOrStopTicker();
        _syncSystemSession();
        _logCommand('System → Stop');
      case AdwMediaCommandType.next:
        _nextTrack();
        _logCommand('System → Next');
      case AdwMediaCommandType.previous:
        _previousTrack();
        _logCommand('System → Previous');
      case AdwMediaCommandType.seek:
        final delta = command.offset ?? Duration.zero;
        _seekTo(_position + delta);
        _logCommand('System → Seek (${delta.inSeconds}s)');
      case AdwMediaCommandType.setPosition:
        if (command.position != null) {
          _seekTo(command.position!);
          _logCommand(
              'System → SetPosition (${_formatDuration(command.position!)})');
        }
      case AdwMediaCommandType.setLoopMode:
        if (command.loopMode != null) {
          setState(() => _loopMode = command.loopMode!);
          _syncSystemSession();
          _logCommand('System → Loop (${command.loopMode!.name})');
        }
      case AdwMediaCommandType.setShuffle:
        if (command.shuffle != null) {
          setState(() => _shuffle = command.shuffle!);
          _syncSystemSession();
          _logCommand('System → Shuffle (${command.shuffle! ? 'On' : 'Off'})');
        }
      case AdwMediaCommandType.raise:
        _logCommand('System → Raise Window');
      case AdwMediaCommandType.quit:
        _logCommand('System → Quit');
    }
  }

  void _setPlaying(bool playing) {
    setState(() {
      _status = playing ? AdwPlaybackStatus.playing : AdwPlaybackStatus.paused;
    });
    _startOrStopTicker();
    _syncSystemSession();
  }

  void _togglePlayPause() => _setPlaying(!_isPlaying);

  void _previousTrack() {
    setState(() {
      _trackIndex = (_trackIndex - 1 + _tracks.length) % _tracks.length;
      _position = Duration.zero;
    });
    _syncSystemSession(includeMetadata: true);
  }

  void _nextTrack() {
    setState(() {
      _trackIndex = (_trackIndex + 1) % _tracks.length;
      _position = Duration.zero;
    });
    _syncSystemSession(includeMetadata: true);
  }

  void _toggleShuffle() {
    setState(() => _shuffle = !_shuffle);
    _syncSystemSession();
  }

  void _cycleLoopMode() {
    setState(() {
      _loopMode = switch (_loopMode) {
        AdwLoopMode.none => AdwLoopMode.playlist,
        AdwLoopMode.playlist => AdwLoopMode.track,
        AdwLoopMode.track => AdwLoopMode.none,
      };
    });
    _syncSystemSession();
  }

  void _seekTo(Duration target) {
    final clampedMs =
        target.inMilliseconds.clamp(0, _current.duration.inMilliseconds);
    setState(() {
      _position = Duration(milliseconds: clampedMs);
    });
    AdwMediaSession.setPosition(_position);
    _syncSystemSession();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final totalMs = _current.duration.inMilliseconds;
    final progress =
        totalMs > 0 ? (_position.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;

    return AdwPreferencesPage(
      children: [
        const AdwStatusPage(
          icon: Icon(AdwIcons.audio_x_generic_symbolic, size: 64),
          title: Text('Media Player'),
          description: Text(
            'Publishes playback metadata and receives system controls via MPRIS2 on Linux (GNOME Shell / media keys) and MediaSession on Android.',
          ),
        ),
        const SizedBox(height: 16),
        AdwCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colors.accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AdwIcons.audio_x_generic_symbolic,
                      size: 28,
                      color: theme.colors.accentColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_current.title, style: theme.typography.title3),
                        const SizedBox(height: 2),
                        Text(
                          '${_current.artist} — ${_current.album}',
                          style: theme.typography.body.copyWith(
                            color: theme.colors.windowForeground
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AdwSlider(
                value: progress,
                onChanged: (v) {
                  _seekTo(Duration(milliseconds: (totalMs * v).round()));
                },
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.windowForeground
                          .withValues(alpha: 0.65),
                    ),
                  ),
                  Text(
                    _formatDuration(_current.duration),
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.windowForeground
                          .withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AdwButton.flat(
                    borderRadius: BorderRadius.circular(999),
                    padding: const EdgeInsets.all(10),
                    onPressed: _toggleShuffle,
                    child: Icon(
                      AdwIcons.media_playlist_shuffle_symbolic,
                      size: 18,
                      color: _shuffle
                          ? theme.colors.accentColor
                          : theme.colors.windowForeground
                              .withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AdwButton.flat(
                    borderRadius: BorderRadius.circular(999),
                    padding: const EdgeInsets.all(10),
                    onPressed: _previousTrack,
                    child: const Icon(
                      AdwIcons.media_skip_backward_symbolic,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  AdwButton.suggested(
                    borderRadius: BorderRadius.circular(999),
                    padding: const EdgeInsets.all(14),
                    onPressed: _togglePlayPause,
                    child: Icon(
                      _isPlaying
                          ? AdwIcons.media_playback_pause_symbolic
                          : AdwIcons.media_playback_start_symbolic,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  AdwButton.flat(
                    borderRadius: BorderRadius.circular(999),
                    padding: const EdgeInsets.all(10),
                    onPressed: _nextTrack,
                    child: const Icon(
                      AdwIcons.media_skip_forward_symbolic,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AdwButton.flat(
                    borderRadius: BorderRadius.circular(999),
                    padding: const EdgeInsets.all(10),
                    onPressed: _cycleLoopMode,
                    child: Icon(
                      _loopMode == AdwLoopMode.track
                          ? AdwIcons.media_playlist_repeat_song_symbolic
                          : AdwIcons.media_playlist_repeat_symbolic,
                      size: 18,
                      color: _loopMode != AdwLoopMode.none
                          ? theme.colors.accentColor
                          : theme.colors.windowForeground
                              .withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdwPreferencesGroup(
          title: const Text('System Media Bridge'),
          children: [
            AdwActionRow(
              title: const Text('Playback Status'),
              subtitle: Text(
                switch (_status) {
                  AdwPlaybackStatus.playing => 'Playing',
                  AdwPlaybackStatus.paused => 'Paused',
                  AdwPlaybackStatus.stopped => 'Stopped',
                },
              ),
            ),
            AdwActionRow(
              title: const Text('Active Track'),
              subtitle: Text('${_current.title} — ${_current.artist}'),
            ),
            AdwActionRow(
              title: const Text('Loop / Shuffle'),
              subtitle: Text(
                'Loop: ${_loopMode.name}  •  Shuffle: ${_shuffle ? 'On' : 'Off'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdwPreferencesGroup(
          title: const Text('Received System Commands'),
          description: const Text(
            'Use GNOME Shell media controls, hardware keys, or Android media shade to control playback.',
          ),
          headerSuffix: _commandLog.isNotEmpty
              ? AdwButton.flat(
                  onPressed: () => setState(_commandLog.clear),
                  child: const Text('Clear'),
                )
              : null,
          children: _commandLog.isEmpty
              ? [
                  AdwActionRow(
                    title: Text(
                      'No system commands received yet',
                      style: theme.typography.body.copyWith(
                        color: theme.colors.windowForeground
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ]
              : _commandLog
                  .map((entry) => AdwActionRow(title: Text(entry)))
                  .toList(growable: false),
        ),
      ],
    );
  }
}
