import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/library_service.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _loading = false;

  Future<void> _addSongs() async {
    setState(() => _loading = true);
    final picked = await LibraryService.pickSongs();
    if (!mounted) return;
    context.read<LibraryStore>().addSongs(picked);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<LibraryStore>().songs;
    final queuePlayer = context.watch<QueuePlayer>();

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: songs.isEmpty
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('No songs yet. Tap + to add some.'),
            )
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isCurrent = queuePlayer.currentSong?.filePath == song.filePath;
                return ListTile(
                  leading: Icon(
                    isCurrent && queuePlayer.isPlaying
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
                  onTap: () {
                    if (isCurrent) {
                      queuePlayer.togglePlayPause();
                    } else {
                      queuePlayer.setQueue(songs, startIndex: index);
                    }
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
