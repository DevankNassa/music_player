import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    try {
      final picked = await LibraryService.pickSongs();
      if (!mounted) return;
      context.read<LibraryStore>().addSongs(picked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't add songs: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addFolder() async {
    if (!await LibraryService.ensureAudioPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio permission is needed to scan a folder. Enable it in system settings.'),
        ),
      );
      return;
    }
    final String? folder;
    try {
      folder = await LibraryService.pickFolder();
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't open that folder: ${e.message}")),
      );
      return;
    }
    if (folder == null || !mounted) return;
    setState(() => _loading = true);
    await context.read<LibraryStore>().addFolder(folder);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _showAddSheet() async {
    // iOS hands back individually picked songs as throwaway copies, so tags
    // wouldn't reach the originals; a picked folder is tagged in place.
    if (Platform.isIOS) return _addFolder();
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Add a folder'),
              subtitle: const Text('New files added to it later are picked up automatically'),
              onTap: () => Navigator.of(context).pop(_AddChoice.folder),
            ),
            ListTile(
              leading: const Icon(Icons.audio_file),
              title: const Text('Add individual songs'),
              onTap: () => Navigator.of(context).pop(_AddChoice.files),
            ),
          ],
        ),
      ),
    );
    if (choice == _AddChoice.folder) {
      await _addFolder();
    } else if (choice == _AddChoice.files) {
      await _addSongs();
    }
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
                  : Text(
                      Platform.isIOS
                          ? 'No songs yet. Tap + to choose your music\n'
                              'folder, e.g. your Syncthing folder.'
                          : 'No songs yet. Tap + to add some.',
                      textAlign: TextAlign.center,
                    ),
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
        onPressed: _showAddSheet,
        tooltip: 'Add songs',
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum _AddChoice { folder, files }
