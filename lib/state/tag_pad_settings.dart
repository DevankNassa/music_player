import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum TagSort { alphabetical, mostUsed }

/// How the Tag pad orders tags: up to [maxPinned] pinned tags first in the
/// user's order, then the rest by [sort]. Kept in a JSON file in the app
/// support directory, like the desktop folder list.
class TagPadSettings extends ChangeNotifier {
  static const maxPinned = 12;

  final List<String> _pinned = [];
  TagSort _sort = TagSort.alphabetical;

  List<String> get pinned => List.unmodifiable(_pinned);
  TagSort get sort => _sort;
  bool get isFull => _pinned.length >= maxPinned;

  /// Pinned tags still in [allTags] in their pinned order, then the rest
  /// sorted by [sort]. [songCount] gives how many songs have a tag.
  ({List<String> pinned, List<String> rest}) arrange(
    Set<String> allTags,
    int Function(String tag) songCount,
  ) {
    final pinned = _pinned.where(allTags.contains).toList();
    final rest = allTags.where((t) => !_pinned.contains(t)).toList()..sort();
    if (_sort == TagSort.mostUsed) {
      // Ties fall back to A–Z.
      rest.sort((a, b) {
        final byCount = songCount(b).compareTo(songCount(a));
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    }
    return (pinned: pinned, rest: rest);
  }

  void pin(String tag) {
    if (isFull || _pinned.contains(tag)) return;
    _pinned.add(tag);
    _changed();
  }

  void unpin(String tag) {
    if (_pinned.remove(tag)) _changed();
  }

  void move(int from, int to) {
    if (from == to) return;
    _pinned.insert(to, _pinned.removeAt(from));
    _changed();
  }

  void setSort(TagSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  static Future<File> _file() async =>
      File(p.join((await getApplicationSupportDirectory()).path, 'tag_pad.json'));

  Future<void> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _pinned
        ..clear()
        ..addAll(List<String>.from(json['pinned'] as List? ?? []).take(maxPinned));
      _sort = json['sort'] == 'mostUsed' ? TagSort.mostUsed : TagSort.alphabetical;
      notifyListeners();
    } catch (_) {
      // A corrupt file just means starting from the defaults.
    }
  }

  Future<void> _save() async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'pinned': _pinned, 'sort': _sort.name}));
    } catch (_) {}
  }
}
