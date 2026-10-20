import 'package:flutter/material.dart';

import 'screens/library_screen.dart';

void main() {
  runApp(const InstaPlaylistApp());
}

class InstaPlaylistApp extends StatelessWidget {
  const InstaPlaylistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insta-Playlist',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const LibraryScreen(),
    );
  }
}
