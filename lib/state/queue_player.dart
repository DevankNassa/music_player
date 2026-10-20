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

  QueuePlayer() {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.onComplete.listen((_) => next());
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

  Future<void> _playCurrent() async {
    final song = currentSong;
    if (song == null) return;
    _position = Duration.zero;
    _duration = Duration.zero;
    await _player.play(song.filePath);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
