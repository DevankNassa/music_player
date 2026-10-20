import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insta_playlist/main.dart';

void main() {
  testWidgets('App launches to the library tab', (WidgetTester tester) async {
    await tester.pumpWidget(const InstaPlaylistApp());

    expect(find.widgetWithText(AppBar, 'Library'), findsOneWidget);
    expect(find.text('No songs yet. Tap + to add some.'), findsOneWidget);
  });

  testWidgets('Bottom nav switches to the other tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const InstaPlaylistApp());
    final navBar = find.byType(NavigationBar);

    await tester.tap(find.descendant(of: navBar, matching: find.text('Quick Tag')));
    await tester.pumpAndSettle();
    expect(find.text('Add songs in the Library tab first.'), findsOneWidget);

    await tester.tap(find.descendant(of: navBar, matching: find.text('Filters')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('0 songs match'),
      find.byType(Scrollable),
      const Offset(0, -300),
    );
    expect(find.text('0 songs match'), findsOneWidget);
  });
}
