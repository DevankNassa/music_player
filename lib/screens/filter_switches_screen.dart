import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/filter_switch.dart';
import '../models/song.dart';
import '../state/filtering.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';
import '../theme/organic.dart';
import '../widgets/now_playing_bar.dart';

const _switchCount = 6;

/// The Mix tab: the six filter switches as a switchboard of three-position
/// faders (ONLY / ANY / NO), the active filters read back as a sentence, and
/// the matching songs.
class FilterSwitchesScreen extends StatefulWidget {
  const FilterSwitchesScreen({super.key});

  @override
  State<FilterSwitchesScreen> createState() => _FilterSwitchesScreenState();
}

class _FilterSwitchesScreenState extends State<FilterSwitchesScreen> {
  final List<FilterSwitch> _switches = List.generate(_switchCount, (_) => FilterSwitch());
  bool _resultsExpanded = false;

  /// Patches [tag] into the first free fader, or frees its fader if it's
  /// already patched.
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
        const SnackBar(content: Text('All 6 faders are in use. Long-press one to free it.')),
      );
      return;
    }
    setState(() => _switches[emptyIndex].tag = tag);
  }

  void _setPosition(FilterSwitch sw, SwitchPosition position) =>
      setState(() => sw.position = position);

  /// Tapping a tag in the sentence steps it any → only → never → any.
  void _cycle(FilterSwitch sw) {
    _setPosition(sw, switch (sw.position) {
      SwitchPosition.neutral => SwitchPosition.require,
      SwitchPosition.require => SwitchPosition.exclude,
      SwitchPosition.exclude => SwitchPosition.neutral,
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryStore = context.watch<LibraryStore>();
    final queuePlayer = context.watch<QueuePlayer>();
    final matches = applyFilters(libraryStore.songs, _switches);
    final allTags = libraryStore.allTags.toList()..sort();
    final unassigned = allTags.where((t) => !_switches.any((s) => s.tag == t)).toList();
    final slotsLeft = _switches.where((s) => s.tag == null).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: queuePlayer.currentSong == null ? 24 : NowPlayingBar.dockClearance + 12,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: Text('Mix', style: Organic.headingStyle(30)),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
            decoration: BoxDecoration(
              color: Organic.surface,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                for (final sw in _switches)
                  Expanded(
                    child: _Fader(
                      sw: sw,
                      onChanged: (position) => _setPosition(sw, position),
                      onClear: () => _toggleTag(sw.tag!),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: _MixSentence(switches: _switches, onCycle: _cycle),
          ),
          _ResultsCard(
            matches: matches,
            queuePlayer: queuePlayer,
            expanded: _resultsExpanded,
            onToggle: () => setState(() => _resultsExpanded = !_resultsExpanded),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: Text(
              allTags.isEmpty
                  ? 'No tags yet. Tag some songs in the Tag tab first.'
                  : 'Patch a tag into a free fader · $slotsLeft of $_switchCount free'
                        '${slotsLeft < _switchCount ? ' · long-press a fader to free it' : ''}',
              style: const TextStyle(fontSize: 12, color: Organic.neutral700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in unassigned)
                  Material(
                    color: Colors.transparent,
                    shape: const StadiumBorder(side: BorderSide(color: Organic.accent)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _toggleTag(tag),
                      hoverColor: Organic.accent100,
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            '+ $tag',
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 0.24,
                              color: Organic.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One vertical three-position fader. Tap the top, middle or bottom third
/// (or drag the knob) to pick ONLY / ANY / NO. Empty faders are dimmed and
/// inert; long-press a patched one to free it.
class _Fader extends StatelessWidget {
  final FilterSwitch sw;
  final ValueChanged<SwitchPosition> onChanged;
  final VoidCallback onClear;

  const _Fader({required this.sw, required this.onChanged, required this.onClear});

  static const _trackHeight = 120.0;
  static const _knobSize = 36.0;

  static SwitchPosition _positionAt(double dy) {
    if (dy < _trackHeight / 3) return SwitchPosition.require;
    if (dy < _trackHeight * 2 / 3) return SwitchPosition.neutral;
    return SwitchPosition.exclude;
  }

  @override
  Widget build(BuildContext context) {
    final tag = sw.tag;
    final hasTag = tag != null;
    final (knobTop, knobColor, knobText, spoken) = switch (sw.position) {
      _ when !hasTag => (42.0, Organic.neutral300, '', 'empty'),
      SwitchPosition.require => (3.0, Organic.accent2_600, 'ONLY', 'only'),
      SwitchPosition.neutral => (42.0, Organic.neutral500, 'ANY', 'any'),
      SwitchPosition.exclude => (81.0, Organic.accent, 'NO', 'never'),
    };

    return Semantics(
      label: hasTag ? 'Fader for $tag: $spoken' : 'Empty fader',
      child: Opacity(
        opacity: hasTag ? 1 : 0.4,
        child: IgnorePointer(
          ignoring: !hasTag,
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => onChanged(_positionAt(d.localPosition.dy)),
                onVerticalDragUpdate: (d) {
                  final next = _positionAt(d.localPosition.dy);
                  if (next != sw.position) onChanged(next);
                },
                onLongPress: hasTag ? onClear : null,
                child: Container(
                  width: 42,
                  height: _trackHeight,
                  decoration: BoxDecoration(
                    color: Organic.neutral200,
                    borderRadius: BorderRadius.circular(999),
                    // Approximates the mock's inset shadow with a darker rim.
                    border: Border.all(color: const Color(0x142E2B25)),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.ease,
                        left: 2,
                        top: knobTop - 1,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: _knobSize,
                          height: _knobSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: knobColor,
                            shape: BoxShape.circle,
                            boxShadow: Organic.shadowMd,
                          ),
                          child: Text(
                            knobText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Organic.neutral100,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tag ?? 'empty',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Play songs tagged [chill] but never [explicit]." Each tag is a chip
/// that cycles its fader when tapped.
class _MixSentence extends StatelessWidget {
  final List<FilterSwitch> switches;
  final ValueChanged<FilterSwitch> onCycle;

  const _MixSentence({required this.switches, required this.onCycle});

  @override
  Widget build(BuildContext context) {
    final required = switches.where((s) => s.tag != null && s.position == SwitchPosition.require);
    final excluded = switches.where((s) => s.tag != null && s.position == SwitchPosition.exclude);
    final style = Organic.headingStyle(21, height: 1.65);
    const muted = TextStyle(color: Organic.neutral500);

    InlineSpan chip(FilterSwitch sw, {required bool excluded}) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: excluded ? Organic.accent : Organic.accent2_600,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onCycle(sw),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  sw.tag!,
                  style: Organic.headingStyle(17, color: Organic.neutral100, height: 1).copyWith(
                    decoration: excluded ? TextDecoration.lineThrough : null,
                    decorationColor: Organic.neutral100,
                    decorationThickness: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'Play songs tagged '),
          if (required.isEmpty) const TextSpan(text: 'anything', style: muted),
          for (final sw in required) chip(sw, excluded: false),
          const TextSpan(text: ' but never '),
          if (excluded.isEmpty) const TextSpan(text: 'nothing', style: muted),
          for (final sw in excluded) chip(sw, excluded: true),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  final List<Song> matches;
  final QueuePlayer queuePlayer;
  final bool expanded;
  final VoidCallback onToggle;

  const _ResultsCard({
    required this.matches,
    required this.queuePlayer,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(color: Organic.surface, borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggle,
                    child: Row(
                      children: [
                        Text(
                          '${matches.length}',
                          style: Organic.headingStyle(30, height: 1, color: Organic.accent700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${matches.length == 1 ? 'song' : 'songs'} match',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(Icons.expand_more_rounded, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: matches.isEmpty ? null : () => queuePlayer.setQueue(matches),
                  child: const Text('Play all'),
                ),
              ],
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 10, 8),
              child: matches.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No songs match this combination.',
                        style: TextStyle(fontSize: 13, color: Organic.neutral700),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (var i = 0; i < matches.length; i++) _matchRow(matches[i], i)],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _matchRow(Song song, int index) {
    final isCurrent = queuePlayer.currentSong?.filePath == song.filePath;
    return InkWell(
      onTap: () {
        if (isCurrent) {
          queuePlayer.togglePlayPause();
        } else {
          queuePlayer.setQueue(matches, startIndex: index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Organic.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isCurrent ? Organic.accent700 : Organic.text,
              ),
            ),
            if (song.tags.isNotEmpty)
              Text(
                song.tags.join(', '),
                style: const TextStyle(fontSize: 12, color: Organic.neutral700),
              ),
          ],
        ),
      ),
    );
  }
}
