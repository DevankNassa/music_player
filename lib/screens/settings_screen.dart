import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../state/library_store.dart';
import '../state/tag_pad_settings.dart';
import '../state/theme_settings.dart';
import '../theme/organic.dart';
import '../widgets/folder_actions.dart';
import '../widgets/organic.dart';
import 'pinned_tags_screen.dart';

String songsText(int n) => '$n ${n == 1 ? 'song' : 'songs'}';

/// Settings, opened from the gear in the Library header: light or dark
/// appearance, the watched music folders and how the Tag pad orders tags.
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
    final c = Organic.of(context);
    final libraryStore = context.watch<LibraryStore>();
    final tagPad = context.watch<TagPadSettings>();
    final folders = libraryStore.watchedFolders;
    final pinned = tagPad.pinned;

    return SettingsPage(
      title: 'Settings',
      children: [
        const SectionHeader('Appearance'),
        const _ThemePicker(),
        SectionHeader(
          'Music folders',
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          note: '${folders.length} watched',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
          child: Text(
            'New files in these folders are added to your library automatically.',
            style: TextStyle(fontSize: 13, color: c.neutral700),
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
                hoverColor: c.accent100,
                highlightColor: c.accent100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      DashedOutline(
                        radius: 20,
                        color: c.accent400,
                        strokeWidth: 2,
                        child: SizedBox.square(
                          dimension: 40,
                          child: Icon(Icons.add_rounded, size: 22, color: c.accent700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add folders',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: c.accent700,
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
              color: c.accent100,
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
                      _RowIcon(
                        icon: Icons.push_pin_outlined,
                        background: c.accent200,
                        foreground: c.accent800,
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
                              style: TextStyle(fontSize: 12, color: c.neutral700),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: c.neutral700),
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
    final c = Organic.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, onRemove == null ? 12 : 6, 10),
      child: Row(
        children: [
          _RowIcon(
            icon: Icons.folder_rounded,
            background: c.accent2_200,
            foreground: c.accent2_800,
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
                    color: detail == null ? c.accent700 : c.neutral700,
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
    final c = Organic.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
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

/// Three small previews of the app (follow the system, light, dark); tapping
/// one switches theme straight away.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeSettings>();
    Widget option(ThemeMode mode, String label, List<OrganicColors> palettes) => Expanded(
      child: _ThemeOption(
        label: label,
        palettes: palettes,
        selected: theme.mode == mode,
        onTap: () {
          HapticFeedback.selectionClick();
          theme.setMode(mode);
        },
      ),
    );
    return Row(
      children: [
        option(ThemeMode.system, 'System', const [OrganicColors.light, OrganicColors.dark]),
        const SizedBox(width: 10),
        option(ThemeMode.light, 'Light', const [OrganicColors.light]),
        const SizedBox(width: 10),
        option(ThemeMode.dark, 'Dark', const [OrganicColors.dark]),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;

  /// One palette, or two for "System", drawn as side-by-side halves.
  final List<OrganicColors> palettes;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.palettes,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      excludeSemantics: true,
      child: PressScale(
        scale: 0.96,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
            decoration: BoxDecoration(
              color: selected ? c.accent100 : c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: selected ? c.accent : Colors.transparent, width: 2),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 78,
                    child: Row(children: [for (final p in palettes) Expanded(child: _MiniApp(p))]),
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      Icon(Icons.check_circle_rounded, size: 15, color: c.accent700),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? c.accent700 : c.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A thumbnail of the app in palette [p]: a heading, two song rows and the
/// dark mini-player with its accent play button.
class _MiniApp extends StatelessWidget {
  final OrganicColors p;

  const _MiniApp(this.p);

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, Color color, {double height = 5}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
    );
    return ColoredBox(
      color: p.bg,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 10, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                bar(26, p.text, height: 6),
                const SizedBox(height: 8),
                bar(40, p.surface, height: 8),
                const SizedBox(height: 5),
                bar(32, p.accent2_400, height: 8),
                const SizedBox(height: 9),
                Container(
                  width: 46,
                  height: 16,
                  padding: const EdgeInsets.all(3),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: p.cardEdge),
                  ),
                  child: Container(
                    width: 10,
                    decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
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
