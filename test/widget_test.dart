import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insta_playlist/main.dart';
import 'package:insta_playlist/models/song.dart';
import 'package:insta_playlist/state/library_store.dart';
import 'package:insta_playlist/state/tag_pad_settings.dart';
import 'package:insta_playlist/state/theme_settings.dart';
import 'package:insta_playlist/theme/organic.dart';

void main() {
  testWidgets('App launches to the library tab', (WidgetTester tester) async {
    await tester.pumpWidget(const InstantPlaylistApp());

    expect(find.text('+ Add'), findsOneWidget);
    expect(find.text('No songs yet. Tap + Add to add some.'), findsOneWidget);
  });

  testWidgets('Tab bar switches to the other tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const InstantPlaylistApp());

    await tester.tap(find.text('Player'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing playing. Add songs in the Library tab.'), findsOneWidget);

    await tester.tap(find.text('Tag'));
    await tester.pumpAndSettle();
    expect(find.text('Add songs in the Library tab first.'), findsOneWidget);

    await tester.tap(find.text('Mix'));
    await tester.pumpAndSettle();
    expect(find.text('songs match'), findsOneWidget);
    expect(find.text('No tags yet. Tag some songs in the Tag tab first.'), findsOneWidget);
  });

  libraryTests();
}

LibraryStore _libraryWithSongs() => LibraryStore()
  ..addSongs([
    Song(filePath: '/music/a.mp3', title: 'Holocene', artist: 'Bon Iver', tags: {'chill', 'rain'}),
    Song(filePath: '/music/b.mp3', title: 'Midnight City', artist: 'M83', tags: {'drive', 'gym'}),
    Song(filePath: '/music/c.mp3', title: 'A song with a rather long title that should ellipsize'),
  ]);

void libraryTests() {
  testWidgets('Library search filters by title, artist or tag', (WidgetTester tester) async {
    await tester.pumpWidget(InstantPlaylistApp(libraryStore: _libraryWithSongs()));
    expect(find.text('Holocene'), findsOneWidget);
    expect(find.text('rain'), findsOneWidget);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'gym');
    await tester.pump();
    expect(find.text('Midnight City'), findsOneWidget);
    expect(find.text('Holocene'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No songs, artists or tags match "zzz".'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Holocene'), findsOneWidget);
  });

  testWidgets('Settings and Pinned tags render; pin, sort and delete prompt work', (
    WidgetTester tester,
  ) async {
    final tagPad = TagPadSettings();
    await tester.pumpWidget(
      InstantPlaylistApp(libraryStore: _libraryWithSongs(), tagPadSettings: tagPad),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Music folders'), findsOneWidget);
    expect(find.text('None · all tags sorted A–Z'), findsOneWidget);

    await tester.tap(find.text('Pinned tags'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 12'), findsOneWidget);
    await tester.tap(find.text('Pin').at(3)); // rain
    await tester.pumpAndSettle();
    expect(tagPad.pinned, ['rain']);
    expect(find.text('1 of 12'), findsOneWidget);

    await tester.tap(find.text('Most used'));
    await tester.pumpAndSettle();
    expect(tagPad.sort, TagSort.mostUsed);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete "rain"?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tagPad.pinned, ['rain']);
  });

  testWidgets('Settings switches between the light and dark themes', (WidgetTester tester) async {
    final theme = ThemeSettings();
    await tester.pumpWidget(InstantPlaylistApp(themeSettings: theme));
    OrganicColors palette() => Organic.of(tester.element(find.text('Appearance')));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(theme.mode, ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(theme.mode, ThemeMode.dark);
    expect(palette().bg, OrganicColors.dark.bg);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(theme.mode, ThemeMode.light);
    expect(palette().bg, OrganicColors.light.bg);
  });
}
