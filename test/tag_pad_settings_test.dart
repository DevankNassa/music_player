import 'package:flutter_test/flutter_test.dart';
import 'package:insta_playlist/state/tag_pad_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tags = {'chill', 'gym', 'rain', 'drive'};
  final counts = {'chill': 2, 'gym': 5, 'rain': 2, 'drive': 1};

  test('pinned tags come first in pinned order, the rest A–Z', () {
    final settings = TagPadSettings()
      ..pin('rain')
      ..pin('chill');
    final arranged = settings.arrange(tags, (t) => counts[t]!);
    expect(arranged.pinned, ['rain', 'chill']);
    expect(arranged.rest, ['drive', 'gym']);
  });

  test('most used sorts by song count, ties A–Z', () {
    final settings = TagPadSettings()..setSort(TagSort.mostUsed);
    final arranged = settings.arrange(tags, (t) => counts[t]!);
    expect(arranged.rest, ['gym', 'chill', 'rain', 'drive']);
  });

  test('move reorders and pins cap at 12', () {
    final settings = TagPadSettings();
    for (var i = 0; i < 14; i++) {
      settings.pin('t$i');
    }
    expect(settings.pinned.length, TagPadSettings.maxPinned);
    settings.move(0, 2);
    expect(settings.pinned.take(3), ['t1', 't2', 't0']);
  });
}
