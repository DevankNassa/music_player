import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/media_notification_handler.dart';
import 'state/library_store.dart';
import 'state/queue_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final queuePlayer = QueuePlayer();
  // audio_service has no Linux/Windows implementation; there playback just
  // runs without a system media notification.
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await AudioService.init(
      builder: () => MediaNotificationHandler(queuePlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.devanknassa.insta_playlist.playback',
        androidNotificationChannelName: 'Playback',
        androidNotificationOngoing: true,
      ),
    );
  }
  runApp(InstaPlaylistApp(queuePlayer: queuePlayer));
}

class InstaPlaylistApp extends StatelessWidget {
  final QueuePlayer? queuePlayer;

  const InstaPlaylistApp({super.key, this.queuePlayer});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryStore()),
        if (queuePlayer != null)
          ChangeNotifierProvider.value(value: queuePlayer!)
        else
          ChangeNotifierProvider(create: (_) => QueuePlayer()),
      ],
      child: MaterialApp(
        title: 'Insta-Playlist',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
