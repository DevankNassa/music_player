import '../models/filter_switch.dart';
import '../models/song.dart';

/// A song is eligible only if it has every Require tag and none of the
/// Exclude tags; Neutral switches impose no constraint. See SPEC.md
/// "Feature: Tag Filter Switches".
List<Song> applyFilters(List<Song> songs, List<FilterSwitch> switches) {
  final requireTags = switches
      .where((s) => s.position == SwitchPosition.require)
      .map((s) => s.tag)
      .whereType<String>()
      .where((t) => t.isNotEmpty)
      .toSet();
  final excludeTags = switches
      .where((s) => s.position == SwitchPosition.exclude)
      .map((s) => s.tag)
      .whereType<String>()
      .where((t) => t.isNotEmpty)
      .toSet();

  return songs.where((song) {
    if (!requireTags.every(song.tags.contains)) return false;
    if (excludeTags.any(song.tags.contains)) return false;
    return true;
  }).toList();
}
