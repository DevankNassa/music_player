import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/library_service.dart';
import 'services/media_notification_handler.dart';
import 'state/library_store.dart';
import 'state/queue_player.dart';
import 'theme/organic.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Caprasimo', 'Figtree']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/OFL-$font.txt'));
    }
  });
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
  final libraryStore = LibraryStore();
  // iOS has no shared music folder: load the app's own Documents folder
  // (visible in the Files app).
  if (Platform.isIOS) {
    final documents = await getApplicationDocumentsDirectory();
    unawaited(libraryStore.addFolder(documents.path));
  }
  // Folders picked in earlier sessions, e.g. a Syncthing folder.
  for (final folder in await LibraryService.restoreFolders()) {
    unawaited(libraryStore.addFolder(folder));
  }
  AppLifecycleListener(onResume: libraryStore.rescanFolders);
  runApp(InstantPlaylistApp(queuePlayer: queuePlayer, libraryStore: libraryStore));
}

class InstantPlaylistApp extends StatelessWidget {
  final QueuePlayer? queuePlayer;
  final LibraryStore? libraryStore;

  const InstantPlaylistApp({super.key, this.queuePlayer, this.libraryStore});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (libraryStore != null)
          ChangeNotifierProvider.value(value: libraryStore!)
        else
          ChangeNotifierProvider(create: (_) => LibraryStore()),
        if (queuePlayer != null)
          ChangeNotifierProvider.value(value: queuePlayer!)
        else
          ChangeNotifierProvider(create: (_) => QueuePlayer()),
      ],
      child: MaterialApp(
        title: 'Instant Playlist',
        // The Organic design system only defines a light palette.
        theme: organicTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
