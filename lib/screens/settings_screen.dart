import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../state/library_store.dart';
import '../state/tag_pad_settings.dart';
import '../theme/organic.dart';
import '../widgets/folder_actions.dart';
import '../widgets/organic.dart';
import 'pinned_tags_screen.dart';

String songsText(int n) => '$n ${n == 1 ? 'song' : 'songs'}';

/// Settings, opened from the gear in the Library header: the watched music
/// folders and how the Tag pad orders tags.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Set<String> _scanning = {};

  Future<void> _addFolder() async {
    final libraryStore = context.read<LibraryStore>();
    final folder = await pickFolderWithFeedback(context);
    if (folder == null || !mounted) return;
    setState(() => _scanning.add(folder));
    await libraryStore.addFolder(folder);
    if (mounted) setState(() => _scanning.remove(folder));
  }

  Future<void> _removeFolder(String folder) async {
    final libraryStore = context.read<LibraryStore>();
    final confirmed = await showOrganicConfirm(
      context: context,
      title: 'Remove this folder?',
      body:
          '${_folderName(folder)}\n\nIts ${songsText(libraryStore.songCountIn(folder))} leave '
          'your library and stop updating. Their tags are kept, so they come back tagged '
          "if you add the folder again. Files on your phone aren't deleted.",
      action: 'Remove',
    );
    if (confirmed) await libraryStore.removeFolder(folder);
  }

  String _folderName(String folder) {
    if (folder == context.read<LibraryStore>().builtInFolder) {
      return Platform.isIOS ? 'Instant Playlist (Files app)' : 'App folder';
    }
    return p.basename(folder);
  }

  @override
  Widget build(BuildContext context) {
    final libraryStore = context.watch<LibraryStore>();
    final tagPad = context.watch<TagPadSettings>();
    final folders = libraryStore.watchedFolders;
    final pinned = tagPad.pinned;

    return SettingsPage(
      title: 'Settings',
      children: [
        SectionHeader('Music folders', note: '${folders.length} watched'),
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 2, 8, 0),
          child: Text(
            'New files in these folders are added to your library automatically.',
            style: TextStyle(fontSize: 13, color: Organic.neutral700),
          ),
        ),
        SettingsCard(
          children: [
            for (final folder in folders)
              _FolderRow(
                name: _folderName(folder),
                detail: _scanning.contains(folder)
                    ? null
                    : songsText(libraryStore.songCountIn(folder)),
                onRemove: folder == libraryStore.builtInFolder ? null : () => _removeFolder(folder),
              ),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _addFolder,
                hoverColor: Organic.accent100,
                highlightColor: Organic.accent100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      DashedOutline(
                        radius: 20,
                        color: Organic.accent400,
                        strokeWidth: 2,
                        child: const SizedBox.square(
                          dimension: 40,
                          child: Icon(Icons.add_rounded, size: 22, color: Organic.accent700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Add folders',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Organic.accent700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SectionHeader('Tag pad', padding: EdgeInsets.fromLTRB(8, 12, 8, 0)),
        SettingsCard(
          children: [
            Material(
              color: Organic.accent100,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => const PinnedTagsScreen())),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const _RowIcon(
                        icon: Icons.push_pin_outlined,
                        background: Organic.accent200,
                        foreground: Organic.accent800,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pinned tags',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            Text(
                              pinned.isEmpty
                                  ? 'None · all tags sorted '
                                        '${tagPad.sort == TagSort.mostUsed ? 'by use' : 'A–Z'}'
                                  : '${pinned.length} pinned · ${pinned.take(3).join(', ')}'
                                        '${pinned.length > 3 ? '…' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Organic.neutral700),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Organic.neutral700),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FolderRow extends StatelessWidget {
  final String name;

  /// Song count, or null while the folder is still being scanned.
  final String? detail;
  final VoidCallback? onRemove;

  const _FolderRow({required this.name, required this.detail, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, onRemove == null ? 12 : 6, 10),
      child: Row(
        children: [
          const _RowIcon(
            icon: Icons.folder_rounded,
            background: Organic.accent2_200,
            foreground: Organic.accent2_800,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(
                  detail ?? 'Scanning…',
                  style: TextStyle(
                    fontSize: 12,
                    color: detail == null ? Organic.accent700 : Organic.neutral700,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove folder',
              icon: const Icon(Icons.close_rounded),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;

  const _RowIcon({required this.icon, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: foreground),
    );
  }
}

/// A pushed settings page: back button, big heading, scrolling content.
class SettingsPage extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsPage({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 14, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(title, style: Organic.headingStyle(30))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    children: [
                      for (final (i, child) in children.indexed) ...[
                        if (i > 0) const SizedBox(height: 12),
                        child,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Surface-coloured rounded group of rows.
class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Organic.surface, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: 2),
            child,
          ],
        ],
      ),
    );
  }
}
