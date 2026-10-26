import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/library_service.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';
import '../theme/organic.dart';
import '../widgets/now_playing_bar.dart';
import '../widgets/organic.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't add songs: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addFolder() async {
    if (!await LibraryService.ensureAudioPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Audio permission is needed to scan a folder. Enable it in system settings.',
          ),
        ),
      );
      return;
    }
    final String? folder;
    try {
      folder = await LibraryService.pickFolder();
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't open that folder: ${e.message}")));
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
    final choice = await showOrganicSheet<_AddChoice>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetRow(
            filled: true,
            padding: const EdgeInsets.all(12),
            onTap: () => Navigator.of(context).pop(_AddChoice.folder),
            child: const _AddOption(
              icon: Icons.folder_open_rounded,
              background: Organic.accent2_200,
              foreground: Organic.accent2_800,
              title: 'Add a folder',
              subtitle: 'New files added to it later are picked up automatically',
            ),
          ),
          const SizedBox(height: 4),
          SheetRow(
            padding: const EdgeInsets.all(12),
            onTap: () => Navigator.of(context).pop(_AddChoice.files),
            child: const _AddOption(
              icon: Icons.music_note_rounded,
              background: Organic.accent200,
              foreground: Organic.accent800,
              title: 'Add individual songs',
            ),
          ),
        ],
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

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
            child: Row(
              children: [
                Expanded(child: Text('Library', style: Organic.headingStyle(30))),
                FilledButton(onPressed: _showAddSheet, child: const Text('+ Add')),
              ],
            ),
          ),
          Expanded(
            child: songs.isEmpty
                ? Center(
                    child: _loading
                        ? const CircularProgressIndicator()
                        : Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              Platform.isIOS
                                  ? 'No songs yet. Tap + Add to choose your music\n'
                                        'folder, e.g. your Syncthing folder.'
                                  : 'No songs yet. Tap + Add to add some.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Organic.neutral700),
                            ),
                          ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      0,
                      14,
                      queuePlayer.currentSong == null ? 16 : NowPlayingBar.dockClearance,
                    ),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isCurrent = queuePlayer.currentSong?.filePath == song.filePath;
                      return _SongRow(
                        number: index + 1,
                        song: song.title,
                        subtitle: [
                          if (song.artist != null) song.artist!,
                          if (song.tags.isNotEmpty) song.tags.join(', '),
                        ].join(' · '),
                        isCurrent: isCurrent,
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
          ),
        ],
      ),
    );
  }
}

/// Numbered song row; the playing song gets a warm highlight and an accent
/// number.
class _SongRow extends StatelessWidget {
  final int number;
  final String song;
  final String subtitle;
  final bool isCurrent;
  final VoidCallback onTap;

  const _SongRow({
    required this.number,
    required this.song,
    required this.subtitle,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent ? Organic.accent100 : Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: Organic.neutral200,
        highlightColor: Organic.neutral200,
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$number',
                  textAlign: TextAlign.right,
                  style: Organic.headingStyle(
                    20,
                    color: isCurrent ? Organic.accent : Organic.neutral500,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Organic.neutral700),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String? subtitle;

  const _AddOption({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: foreground),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: Organic.neutral700)),
            ],
          ),
        ),
      ],
    );
  }
}

enum _AddChoice { folder, files }
