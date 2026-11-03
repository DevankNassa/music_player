import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

/// Where the playing queue came from. Only a Mix queue follows the faders.
enum QueueSource { library, mix }

/// Plays through a list of songs in order. Shared across screens so
/// playback survives switching tabs, and so the Library, Quick Tag Mode and
/// the Mix tab all reuse the same sequencing.
///
/// The whole queue is handed to just_audio as one playlist, so the native
/// player moves on to the next song by itself, even with the screen locked,
/// instead of waiting for the app to react to the end of each song.
class QueuePlayer extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer(maxSkipsOnError: 3);
  QueueSource? _source;

  /// Playlist edits are applied one at a time, in order.
  Future<void> _edits = Future.value();

  QueuePlayer() {
    _player.playerStateStream.listen((_) => notifyListeners(), onError: (_) {});
    _player.currentIndexStream.listen((_) => notifyListeners());
    _player.sequenceStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) => notifyListeners());
  }

  List<IndexedAudioSource> get _sequence => _player.sequence;

  Song? get currentSong {
    final index = _player.currentIndex;
    if (index == null || index >= _sequence.length) return null;
    return _sequence[index].tag as Song?;
  }

  /// The songs queued, in play order.
  List<Song> get queue => [for (final s in _sequence) s.tag as Song];

  QueueSource? get source => _source;
  bool get isPlaying => _player.playing && _player.processingState != ProcessingState.completed;
  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  int get queueIndex => _player.currentIndex ?? 0;
  int get queueLength => _sequence.length;

  /// How far through the current song, 0..1 (0 until the duration is known).
  double get progress {
    final d = duration;
    if (d <= Duration.zero) return 0;
    return (position.inMilliseconds / d.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setQueue(
    List<Song> queue, {
    int startIndex = 0,
    QueueSource source = QueueSource.library,
  }) async {
    if (queue.isEmpty) return;
    _source = source;
    await _edit(() async {
      await _player.setAudioSources([
        for (final song in queue) _sourceFor(song),
      ], initialIndex: startIndex.clamp(0, queue.length - 1));
    });
    _start();
  }

  /// Follows the Mix tab's results while a Mix queue plays. If the playing
  /// song is still in [matches], the queue becomes [matches] around it; if
  /// not, it finishes and [matches] plays from the top. Either way the
  /// playing song isn't interrupted.
  Future<void> updateMixQueue(List<Song> matches) => _edit(() async {
    final index = _player.currentIndex;
    final current = currentSong;
    if (_source != QueueSource.mix || index == null || current == null) return;

    final at = matches.indexWhere((s) => s.filePath == current.filePath);
    final before = at == -1 ? <Song>[] : matches.sublist(0, at);
    final after = at == -1 ? matches : matches.sublist(at + 1);

    final queued = [for (final s in queue) s.filePath];
    final wanted = [...before, current, ...after].map((s) => s.filePath).toList();
    if (listEquals(queued, wanted)) return;

    // Clear everything around the playing song, then rebuild both sides.
    if (index + 1 < _sequence.length) {
      await _player.removeAudioSourceRange(index + 1, _sequence.length);
    }
    if (index > 0) await _player.removeAudioSourceRange(0, index);
    if (before.isNotEmpty) await _player.insertAudioSources(0, before.map(_sourceFor).toList());
    if (after.isNotEmpty) await _player.addAudioSources(after.map(_sourceFor).toList());
  });

  Future<void> togglePlayPause() async {
    if (currentSong == null) return;
    isPlaying ? await pause() : await play();
  }

  Future<void> play() async {
    if (currentSong == null || isPlaying) return;
    // At the end of the queue, play the last song again from the start.
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero, index: _player.currentIndex);
    }
    _start();
  }

  Future<void> pause() => _player.pause();

  Future<void> next() async {
    if (hasNext) await _player.seekToNext();
  }

  Future<void> previous() async {
    if (hasPrevious) await _player.seekToPrevious();
  }

  /// just_audio's play() only completes once playback stops, so it's never
  /// awaited.
  void _start() => unawaited(_player.play().catchError((Object _) {}));

  Future<void> _edit(Future<void> Function() edit) {
    final result = _edits.then((_) => edit());
    _edits = result.catchError((Object _) {});
    return result.catchError((Object _) {});
  }

  static AudioSource _sourceFor(Song song) => AudioSource.file(song.filePath, tag: song);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
