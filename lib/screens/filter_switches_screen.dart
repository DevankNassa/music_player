import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/filter_switch.dart';
import '../state/filtering.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';

const _switchCount = 6;

Color? _tintFor(SwitchPosition position, ColorScheme scheme) {
  switch (position) {
    case SwitchPosition.require:
      return Colors.green.withValues(alpha: scheme.brightness == Brightness.dark ? 0.35 : 0.2);
    case SwitchPosition.exclude:
      return Colors.red.withValues(alpha: scheme.brightness == Brightness.dark ? 0.35 : 0.18);
    case SwitchPosition.neutral:
      return null;
  }
}

class FilterSwitchesScreen extends StatefulWidget {
  const FilterSwitchesScreen({super.key});

  @override
  State<FilterSwitchesScreen> createState() => _FilterSwitchesScreenState();
}

class _FilterSwitchesScreenState extends State<FilterSwitchesScreen> {
  final List<FilterSwitch> _switches = List.generate(_switchCount, (_) => FilterSwitch());

  void _toggleTag(String tag) {
    final assignedIndex = _switches.indexWhere((s) => s.tag == tag);
    if (assignedIndex != -1) {
      setState(() {
        _switches[assignedIndex].tag = null;
        _switches[assignedIndex].position = SwitchPosition.neutral;
      });
      return;
    }
    final emptyIndex = _switches.indexWhere((s) => s.tag == null);
    if (emptyIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All 6 switches are already assigned. Clear one first.')),
      );
      return;
    }
    setState(() => _switches[emptyIndex].tag = tag);
  }

  @override
  Widget build(BuildContext context) {
    final libraryStore = context.watch<LibraryStore>();
    final queuePlayer = context.watch<QueuePlayer>();
    final matches = applyFilters(libraryStore.songs, _switches);
    final allTags = libraryStore.allTags.toList()..sort();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Tap a tag to assign it to a switch', style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: allTags.isEmpty
              ? const Text('No tags yet — tag some songs in Quick Tag mode first.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allTags.map((tag) {
                    final assignedIndex = _switches.indexWhere((s) => s.tag == tag);
                    final isAssigned = assignedIndex != -1;
                    final tint =
                        isAssigned ? _tintFor(_switches[assignedIndex].position, scheme) : null;
                    return FilterChip(
                      label: Text(isAssigned ? '$tag · #${assignedIndex + 1}' : tag),
                      selected: isAssigned,
                      selectedColor: tint,
                      onSelected: (_) => _toggleTag(tag),
                    );
                  }).toList(),
                ),
        ),
        const Divider(height: 24),
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _switchCount,
            itemBuilder: (context, i) {
              final sw = _switches[i];
              final tint = _tintFor(sw.position, scheme);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text('${i + 1}', style: Theme.of(context).textTheme.labelLarge),
                      ),
                      Expanded(
                        child: sw.tag == null
                            ? Text(
                                'No tag selected',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              )
                            : Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      sw.tag!,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                  IconButton(
                                    iconSize: 18,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _toggleTag(sw.tag!),
                                  ),
                                ],
                              ),
                      ),
                      IgnorePointer(
                        ignoring: sw.tag == null,
                        child: Opacity(
                          opacity: sw.tag == null ? 0.4 : 1,
                          child: SegmentedButton<SwitchPosition>(
                            segments: const [
                              ButtonSegment(
                                value: SwitchPosition.exclude,
                                icon: Icon(Icons.block),
                                tooltip: 'Exclude: no songs with this tag',
                              ),
                              ButtonSegment(
                                value: SwitchPosition.neutral,
                                icon: Icon(Icons.remove),
                                tooltip: "Neutral: doesn't matter",
                              ),
                              ButtonSegment(
                                value: SwitchPosition.require,
                                icon: Icon(Icons.check),
                                tooltip: 'Require: only songs with this tag',
                              ),
                            ],
                            selected: {sw.position},
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(selectedBackgroundColor: tint),
                            onSelectionChanged: (selection) =>
                                setState(() => sw.position = selection.first),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${matches.length} song${matches.length == 1 ? '' : 's'} match',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: matches.isEmpty ? null : () => queuePlayer.setQueue(matches),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play all'),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: matches.isEmpty
              ? const Center(child: Text('No songs match this combination.'))
              : ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final song = matches[index];
                    final isCurrent = queuePlayer.currentSong?.filePath == song.filePath;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isCurrent && queuePlayer.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_outline,
                      ),
                      title: Text(song.title),
                      subtitle: song.tags.isEmpty ? null : Text(song.tags.join(', ')),
                      onTap: () {
                        if (isCurrent) {
                          queuePlayer.togglePlayPause();
                        } else {
                          queuePlayer.setQueue(matches, startIndex: index);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
