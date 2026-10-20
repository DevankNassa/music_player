import 'package:flutter_test/flutter_test.dart';

import 'package:insta_playlist/main.dart';

void main() {
  testWidgets('App launches to the library screen', (WidgetTester tester) async {
    await tester.pumpWidget(const InstaPlaylistApp());

    expect(find.text('Insta-Playlist'), findsOneWidget);
    expect(find.text('No songs yet. Tap + to add some.'), findsOneWidget);
  });
}
