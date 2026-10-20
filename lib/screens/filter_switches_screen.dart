import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/filter_switch.dart';
import '../models/song.dart';
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
  bool _resultsExpanded = false;

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

  Widget _buildSwitchRow(BuildContext context, int i, ColorScheme scheme) {
    final sw = _switches[i];
    final tint = _tintFor(sw.position, scheme);

    final tagInfo = Row(
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
      ],
    );

    final segmentedButton = IgnorePointer(
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
          onSelectionChanged: (selection) => setState(() => sw.position = selection.first),
        ),
      ),
    );

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
        // The two-pane layout (wide/landscape viewports) can leave each
        // switch row with little horizontal room, so stack instead of
        // overflowing when it's too narrow to fit side by side.
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tagInfo,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: segmentedButton),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: tagInfo),
                const SizedBox(width: 12),
                segmentedButton,
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _configWidgets(BuildContext context, List<String> allTags, ColorScheme scheme) {
    return [
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Select tags'),
          subtitle: const Text('Tap a tag to assign it to a switch'),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
          ],
        ),
      ),
      const Divider(),
      for (var i = 0; i < _switchCount; i++) _buildSwitchRow(context, i, scheme),
    ];
  }

  List<Widget> _resultsWidgets(
    BuildContext context,
    List<Song> matches,
    QueuePlayer queuePlayer, {
    required bool collapsible,
  }) {
    final expanded = !collapsible || _resultsExpanded;
    return [
      InkWell(
        onTap: collapsible ? () => setState(() => _resultsExpanded = !_resultsExpanded) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              if (collapsible) ...[
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  '${matches.length} song${matches.length == 1 ? '' : 's'} match',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: matches.isEmpty ? null : () => queuePlayer.setQueue(matches),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play all'),
              ),
            ],
          ),
        ),
      ),
      if (expanded)
        if (matches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No songs match this combination.'),
          )
        else
          for (var index = 0; index < matches.length; index++)
            Builder(builder: (context) {
              final song = matches[index];
              final isCurrent = queuePlayer.currentSong?.filePath == song.filePath;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
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
            }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final libraryStore = context.watch<LibraryStore>();
    final queuePlayer = context.watch<QueuePlayer>();
    final matches = applyFilters(libraryStore.songs, _switches);
    final allTags = libraryStore.allTags.toList()..sort();
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // On a wide/landscape viewport the 6 switches alone can fill the
        // height, burying the results below the fold. Side-by-side columns
        // keep the playlist visible without scrolling past them first.
        final isWide = constraints.maxWidth > constraints.maxHeight;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  children: _configWidgets(context, allTags, scheme),
                ),
              ),
              VerticalDivider(width: 1, color: scheme.outlineVariant),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  children: _resultsWidgets(context, matches, queuePlayer, collapsible: false),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            ..._configWidgets(context, allTags, scheme),
            const Divider(height: 1),
            ..._resultsWidgets(context, matches, queuePlayer, collapsible: true),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
