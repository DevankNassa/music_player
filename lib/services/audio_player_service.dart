import 'package:just_audio/just_audio.dart';

/// Thin wrapper around a single [AudioPlayer] so the UI only has to deal
/// with "what's playing" rather than the player's full API.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentPath;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  String? get currentPath => _currentPath;

  Future<void> togglePlay(String filePath) async {
    if (_currentPath == filePath) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    _currentPath = filePath;
    await _player.setFilePath(filePath);
    await _player.play();
  }

  void dispose() {
    _player.dispose();
  }
}
