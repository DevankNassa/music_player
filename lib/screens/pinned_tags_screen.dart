import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/library_store.dart';
import '../state/tag_pad_settings.dart';
import '../theme/organic.dart';
import '../widgets/organic.dart';
import 'settings_screen.dart';

/// Settings → Tag pad → Pinned tags: pin up to 12 tags in a chosen order,
/// pick how the rest are sorted, and delete a tag from every song.
class PinnedTagsScreen extends StatelessWidget {
  const PinnedTagsScreen({super.key});

  Future<void> _delete(BuildContext context, String tag) async {
    final libraryStore = context.read<LibraryStore>();
    final tagPad = context.read<TagPadSettings>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showOrganicConfirm(
      context: context,
      title: 'Delete "$tag"?',
      body:
          'It will be removed from ${songsText(libraryStore.songCountWithTag(tag))} and from '
          "the Tag pad and Mix. The songs stay in your library. This can't be undone.",
      action: 'Delete tag',
    );
    if (!confirmed) return;
    tagPad.unpin(tag);
    final failed = await libraryStore.deleteTag(tag);
    if (failed > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't remove \"$tag\" from ${songsText(failed)}.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    final libraryStore = context.watch<LibraryStore>();
    final tagPad = context.watch<TagPadSettings>();
    final arranged = tagPad.arrange(libraryStore.allTags, libraryStore.songCountWithTag);
    final pinned = arranged.pinned;

    return SettingsPage(
      title: 'Pinned tags',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'These appear first on the Tag pad, in this order.',
            style: TextStyle(fontSize: 13, color: c.neutral700),
          ),
        ),
        SectionHeader('Pinned', note: '${pinned.length} of ${TagPadSettings.maxPinned}'),
        SettingsCard(
          children: [
            if (pinned.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'No pinned tags. The Tag pad shows all tags in the order below.',
                  style: TextStyle(fontSize: 14, color: c.neutral700),
                ),
              ),
            for (final (i, tag) in pinned.indexed)
              _TagRow(
                number: i + 1,
                name: tag,
                count: libraryStore.songCountWithTag(tag),
                actions: [
                  IconButton(
                    tooltip: 'Move up',
                    icon: const Icon(Icons.arrow_upward_rounded),
                    onPressed: i == 0
                        ? null
                        : () => tagPad.move(
                            tagPad.pinned.indexOf(tag),
                            tagPad.pinned.indexOf(pinned[i - 1]),
                          ),
                  ),
                  IconButton(
                    tooltip: 'Move down',
                    icon: const Icon(Icons.arrow_downward_rounded),
                    onPressed: i == pinned.length - 1
                        ? null
                        : () => tagPad.move(
                            tagPad.pinned.indexOf(tag),
                            tagPad.pinned.indexOf(pinned[i + 1]),
                          ),
                  ),
                  IconButton(
                    tooltip: 'Unpin',
                    icon: const Icon(Icons.push_pin_rounded),
                    onPressed: () => tagPad.unpin(tag),
                  ),
                  _DeleteButton(onPressed: () => _delete(context, tag)),
                ],
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
          child: Row(
            children: [
              Expanded(child: Text('Then the rest', style: Organic.headingStyle(20))),
              _SortToggle(sort: tagPad.sort, onChanged: tagPad.setSort),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final tag in arranged.rest)
              _TagRow(
                name: tag,
                count: libraryStore.songCountWithTag(tag),
                actions: [
                  TextButton(
                    onPressed: tagPad.isFull ? null : () => tagPad.pin(tag),
                    child: const Text('Pin'),
                  ),
                  _DeleteButton(onPressed: () => _delete(context, tag)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  final int? number;
  final String name;
  final int count;
  final List<Widget> actions;

  const _TagRow({this.number, required this.name, required this.count, required this.actions});

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      child: Row(
        children: [
          if (number != null)
            SizedBox(
              width: 26,
              child: Text('$number', style: Organic.headingStyle(18, color: c.accent700)),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: number != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Text(songsText(count), style: TextStyle(fontSize: 12, color: c.neutral700)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    return IconButton(
      tooltip: 'Delete tag from all songs',
      color: c.accent700,
      icon: const Icon(Icons.delete_outline_rounded),
      onPressed: onPressed,
    );
  }
}

/// A–Z / Most used pill toggle; the chosen side is dark.
class _SortToggle extends StatelessWidget {
  final TagSort sort;
  final ValueChanged<TagSort> onChanged;

  const _SortToggle({required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    Widget option(TagSort value, String label) {
      final selected = sort == value;
      return Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? c.neutral900 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onChanged(value),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? c.neutral100 : c.text,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(TagSort.alphabetical, 'A–Z'),
          const SizedBox(width: 2),
          option(TagSort.mostUsed, 'Most used'),
        ],
      ),
    );
  }
}
