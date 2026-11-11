import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../services/library_service.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';
import '../theme/organic.dart';
import '../widgets/folder_actions.dart';
import '../widgets/now_playing_bar.dart';
import '../widgets/organic.dart';
import 'settings_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _loading = false;
  bool _searching = false;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _closeSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = false;
      _query.clear();
    });
  }

  /// Songs whose title, artist or any tag contains the query.
  static List<Song> _matching(List<Song> songs, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return songs;
    bool has(String? text) => text != null && text.toLowerCase().contains(q);
    return songs.where((s) => has(s.title) || has(s.artist) || s.tags.any(has)).toList();
  }

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
    final folder = await pickFolderWithFeedback(context);
    if (folder == null || !mounted) return;
    setState(() => _loading = true);
    await context.read<LibraryStore>().addFolder(folder);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _showAddSheet() async {
    // iOS and Android hand back individually picked songs as throwaway
    // copies, so tags wouldn't reach the originals; a picked folder is
    // tagged in place.
    if (Platform.isIOS || Platform.isAndroid) return _addFolder();
    final c = Organic.of(context);
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
            child: _AddOption(
              icon: Icons.folder_open_rounded,
              background: c.accent2_200,
              foreground: c.accent2_800,
              title: 'Add a folder',
              subtitle: 'New files added to it later are picked up automatically',
            ),
          ),
          const SizedBox(height: 4),
          SheetRow(
            padding: const EdgeInsets.all(12),
            onTap: () => Navigator.of(context).pop(_AddChoice.files),
            child: _AddOption(
              icon: Icons.music_note_rounded,
              background: c.accent200,
              foreground: c.accent800,
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
    final c = Organic.of(context);
    final libraryStore = context.watch<LibraryStore>();
    final library = libraryStore.songs;
    final tagCount = libraryStore.allTags.length;
    final queuePlayer = context.watch<QueuePlayer>();
    final songs = _searching ? _matching(library, _query.text) : library;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Songs, artists or tags',
                        prefixIcon: Icon(Icons.search_rounded, color: c.neutral700),
                        filled: true,
                        fillColor: c.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(onPressed: _closeSearch, child: const Text('Cancel')),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 14, 6),
              child: Row(
                children: [
                  Expanded(child: Text('Library', style: Organic.headingStyle(30))),
                  IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () => setState(() => _searching = true),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(onPressed: _showAddSheet, child: const Text('+ Add')),
                ],
              ),
            ),
          if (library.isNotEmpty && !_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${songsText(library.length)} · ${tagCount == 1 ? '1 tag' : '$tagCount tags'}',
                      style: TextStyle(fontSize: 13, color: c.neutral700),
                    ),
                  ),
                  PillButton(
                    label: 'Shuffle',
                    icon: Icons.shuffle_rounded,
                    color: c.surface,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      queuePlayer.setQueue([...library]..shuffle());
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: library.isEmpty
                ? Center(
                    child: _loading
                        ? const CircularProgressIndicator()
                        : EmptyState(
                            title: 'Your library is empty',
                            text: Platform.isIOS || Platform.isAndroid
                                ? 'No songs yet. Tap + Add to choose your music\n'
                                      'folder, e.g. your Syncthing folder.'
                                : 'No songs yet. Tap + Add to add some.',
                          ),
                  )
                : songs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(26, 28, 26, 0),
                    child: Text(
                      'No songs, artists or tags match "${_query.text.trim()}".',
                      style: TextStyle(fontSize: 14, color: c.neutral700),
                    ),
                  )
                : ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                        song: song,
                        isCurrent: isCurrent,
                        playing: isCurrent && queuePlayer.isPlaying,
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

/// Song row: a round play/pause button, the title, then the artist and the
/// song's tags as sage chips. The current song gets a warm highlight and an
/// accent button.
class _SongRow extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool playing;
  final VoidCallback onTap;

  const _SongRow({
    required this.song,
    required this.isCurrent,
    required this.playing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    final tags = song.tags.toList()..sort();
    return Material(
      color: isCurrent ? c.accent100 : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: c.neutral200,
        highlightColor: c.neutral200,
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrent ? c.accent : c.neutral200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 22,
                  color: isCurrent ? c.bg : c.text,
                  semanticLabel: playing ? 'Pause' : 'Play',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    if (song.artist != null || tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (song.artist != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Text(
                                song.artist!,
                                style: TextStyle(fontSize: 12, color: c.neutral700),
                              ),
                            ),
                          for (final tag in tags) _TagChip(tag),
                        ],
                      ),
                    ],
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

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip(this.tag);

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(color: c.accent2_100, borderRadius: BorderRadius.circular(999)),
      child: Text(tag, style: TextStyle(fontSize: 11, letterSpacing: 0.2, color: c.accent2_800)),
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
    final c = Organic.of(context);
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
                Text(subtitle!, style: TextStyle(fontSize: 12, color: c.neutral700)),
            ],
          ),
        ),
      ],
    );
  }
}

enum _AddChoice { folder, files }
