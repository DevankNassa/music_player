import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around a single [AudioPlayer] so the rest of the app only
/// has to deal with "what's playing" rather than the player's full API.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentPath;

  AudioPlayerService() {
    // The default (release) mode makes iOS tear down its player right after
    // a song ends, which can wipe out the next song if it starts too soon.
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<void> get onComplete => _player.onPlayerComplete;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;
  String? get currentPath => _currentPath;
  bool get isPlaying => _player.state == PlayerState.playing;

  Future<void> seek(Duration position) => _player.seek(position);

  Future<Duration?> getDuration() => _player.getDuration();

  /// Call from an [onComplete] listener before starting the next song. On
  /// iOS the native player rewinds the finished song after reporting
  /// completion; starting a new one before that lands leaves it silent.
  Future<void> settleAfterComplete() async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    await _player.onSeekComplete.first.timeout(const Duration(seconds: 1), onTimeout: () {});
  }

  Future<void> play(String filePath) async {
    _currentPath = filePath;
    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.resume();

  Future<void> togglePlay(String filePath) async {
    if (_currentPath == filePath) {
      isPlaying ? await pause() : await resume();
    } else {
      await play(filePath);
    }
  }

  void dispose() {
    _player.dispose();
  }
}
