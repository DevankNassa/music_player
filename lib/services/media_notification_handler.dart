import 'package:audio_service/audio_service.dart';

import '../state/queue_player.dart';

/// Mirrors [QueuePlayer] into the system media session, which gives the
/// app a media controls notification (and lock-screen / headset-button
/// controls) and keeps playback alive in the background on Android.
/// Commands from the notification are forwarded straight back to the
/// [QueuePlayer], so it stays the single source of truth.
class MediaNotificationHandler extends BaseAudioHandler with SeekHandler {
  final QueuePlayer _queuePlayer;

  String? _lastPath;
  bool? _lastPlaying;
  Duration? _lastDuration;

  MediaNotificationHandler(this._queuePlayer) {
    _queuePlayer.addListener(_sync);
    _sync();
  }

  /// QueuePlayer notifies on every position tick; only push to the media
  /// session when something the notification shows actually changed. The
  /// system extrapolates the position between updates on its own.
  void _sync() {
    final song = _queuePlayer.currentSong;
    final playing = _queuePlayer.isPlaying;
    final duration = _queuePlayer.duration;

    if (song?.filePath != _lastPath || duration != _lastDuration) {
      mediaItem.add(song == null
          ? null
          : MediaItem(
              id: song.filePath,
              title: song.title,
              artist: song.artist,
              duration: duration == Duration.zero ? null : duration,
            ));
    }

    if (song?.filePath != _lastPath ||
        playing != _lastPlaying ||
        duration != _lastDuration) {
      _broadcastState();
    }

    _lastPath = song?.filePath;
    _lastPlaying = playing;
    _lastDuration = duration;
  }

  void _broadcastState() {
    final playing = _queuePlayer.isPlaying;
    final hasSong = _queuePlayer.currentSong != null;
    // Previous/next are always shown, even at the ends of the queue:
    // Android's media panel drops the slot entirely when an action is
    // missing, so the buttons would appear and disappear between songs.
    final controls = [
      MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
    ];
    playbackState.add(PlaybackState(
      controls: controls,
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: List.generate(controls.length, (i) => i),
      processingState: hasSong ? AudioProcessingState.ready : AudioProcessingState.idle,
      playing: playing,
      updatePosition: _queuePlayer.position,
    ));
  }

  @override
  Future<void> play() => _queuePlayer.play();

  @override
  Future<void> pause() => _queuePlayer.pause();

  @override
  Future<void> skipToNext() => _queuePlayer.next();

  /// Standard player behaviour: restart the current song if it's a few
  /// seconds in (or there's nothing before it), otherwise go back one.
  @override
  Future<void> skipToPrevious() async {
    if (!_queuePlayer.hasPrevious || _queuePlayer.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
    } else {
      await _queuePlayer.previous();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _queuePlayer.seek(position);
    // Position jumps aren't one of the changes _sync watches for.
    playbackState.add(playbackState.value.copyWith(updatePosition: position));
  }

  @override
  Future<void> stop() async {
    await _queuePlayer.pause();
    await super.stop();
  }
}
