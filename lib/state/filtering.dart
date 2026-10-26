import '../models/filter_switch.dart';
import '../models/song.dart';

/// A song is eligible only if it has every Require tag, at least one of the
/// Any tags (when any are set), and none of the Exclude tags. See SPEC.md
/// "Feature: Tag Filter Switches".
List<Song> applyFilters(List<Song> songs, List<FilterSwitch> switches) {
  Set<String> tagsAt(SwitchPosition position) => switches
      .where((s) => s.position == position)
      .map((s) => s.tag)
      .whereType<String>()
      .where((t) => t.isNotEmpty)
      .toSet();

  final requireTags = tagsAt(SwitchPosition.require);
  final anyTags = tagsAt(SwitchPosition.neutral);
  final excludeTags = tagsAt(SwitchPosition.exclude);

  return songs.where((song) {
    if (!requireTags.every(song.tags.contains)) return false;
    if (anyTags.isNotEmpty && !anyTags.any(song.tags.contains)) return false;
    if (excludeTags.any(song.tags.contains)) return false;
    return true;
  }).toList();
}
