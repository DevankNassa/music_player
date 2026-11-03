import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../services/audio_player_service.dart';

/// Plays through a list of songs in order, auto-advancing when one
/// finishes. Shared across screens so playback survives switching tabs,
/// and so Quick Tag Mode / the filter screen's "play results" both reuse
/// the same sequencing logic instead of each rolling their own.
class QueuePlayer extends ChangeNotifier {
  final AudioPlayerService _player = AudioPlayerService();
  List<Song> _queue = [];
  int _index = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _playToken = 0;

  QueuePlayer() {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.onComplete.listen((_) => _onSongComplete());
    _player.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _player.durationStream.listen((d) {
      _duration = d;
      notifyListeners();
    });
  }

  Song? get currentSong => _queue.isEmpty ? null : _queue[_index];
  bool get isPlaying => _player.isPlaying;
  bool get hasNext => _queue.isNotEmpty && _index < _queue.length - 1;
  bool get hasPrevious => _queue.isNotEmpty && _index > 0;
  Duration get position => _position;
  Duration get duration => _duration;
  int get queueIndex => _index;
  int get queueLength => _queue.length;

  /// How far through the current song, 0..1 (0 until the duration is known).
  double get progress {
    if (_duration <= Duration.zero) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setQueue(List<Song> queue, {int startIndex = 0}) async {
    if (queue.isEmpty) return;
    _queue = queue;
    _index = startIndex.clamp(0, queue.length - 1);
    await _playCurrent();
  }

  Future<void> togglePlayPause() async {
    final song = currentSong;
    if (song == null) return;
    await _player.togglePlay(song.filePath);
  }

  Future<void> play() async {
    if (currentSong == null || isPlaying) return;
    await _player.resume();
  }

  Future<void> pause() => _player.pause();

  Future<void> next() async {
    if (!hasNext) return;
    _index++;
    await _playCurrent();
  }

  Future<void> previous() async {
    if (!hasPrevious) return;
    _index--;
    await _playCurrent();
  }

  Future<void> _onSongComplete() async {
    final token = _playToken;
    await _player.settleAfterComplete();
    // The user may have skipped while we waited; don't advance twice.
    if (token != _playToken) return;
    await next();
  }

  Future<void> _playCurrent() async {
    final song = currentSong;
    if (song == null) return;
    final token = ++_playToken;
    _position = Duration.zero;
    _duration = Duration.zero;
    await _player.play(song.filePath);
    notifyListeners();
    if (_duration == Duration.zero) _fillDuration(token);
  }

  /// iOS only reports a duration once the file's length is known, which for
  /// some files is after playback starts and never gets re-sent. Ask for it
  /// directly until it shows up.
  Future<void> _fillDuration(int token) async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (token != _playToken || _duration > Duration.zero) return;
      final d = await _player.getDuration();
      if (token != _playToken) return;
      if (d != null && d > Duration.zero) {
        _duration = d;
        notifyListeners();
        return;
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
