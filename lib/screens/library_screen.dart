import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/library_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final List<Song> _songs = [];
  final AudioPlayerService _player = AudioPlayerService();
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _addSongs() async {
    setState(() => _loading = true);
    final picked = await LibraryService.pickSongs();
    setState(() {
      _songs.addAll(picked);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insta-Playlist')),
      body: _songs.isEmpty
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('No songs yet. Tap + to add some.'),
            )
          : StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                return ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    final isCurrent = _player.currentPath == song.filePath;
                    return ListTile(
                      leading: Icon(
                        isCurrent && isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                      ),
                      title: Text(song.title),
                      subtitle: Text(
                        [
                          if (song.artist != null) song.artist!,
                          if (song.tags.isNotEmpty) song.tags.join(', '),
                        ].join(' · '),
                      ),
                      onTap: () => _player.togglePlay(song.filePath),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSongs,
        tooltip: 'Add songs',
        child: const Icon(Icons.add),
      ),
    );
  }
}
