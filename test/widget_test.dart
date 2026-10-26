import 'package:flutter_test/flutter_test.dart';

import 'package:insta_playlist/main.dart';

void main() {
  testWidgets('App launches to the library tab', (WidgetTester tester) async {
    await tester.pumpWidget(const InstaPlaylistApp());

    expect(find.text('+ Add'), findsOneWidget);
    expect(find.text('No songs yet. Tap + Add to add some.'), findsOneWidget);
  });

  testWidgets('Tab bar switches to the other tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const InstaPlaylistApp());

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
}
