import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/library_service.dart';
import 'services/media_notification_handler.dart';
import 'state/library_store.dart';
import 'state/queue_player.dart';
import 'state/tag_pad_settings.dart';
import 'state/theme_settings.dart';
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
  // just_audio has no Linux/Windows player of its own; media_kit (libmpv)
  // fills in there.
  JustAudioMediaKit.ensureInitialized();
  // A music app's audio session: other apps' navigation prompts and
  // notification sounds duck it, calls pause it, and just_audio resumes or
  // unducks once they're done.
  await (await AudioSession.instance).configure(const AudioSessionConfiguration.music());
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
    unawaited(libraryStore.addFolder(documents.path, builtIn: true));
  }
  // Folders picked in earlier sessions, e.g. a Syncthing folder.
  for (final folder in await LibraryService.restoreFolders()) {
    unawaited(libraryStore.addFolder(folder));
  }
  AppLifecycleListener(onResume: libraryStore.rescanFolders);
  final tagPadSettings = TagPadSettings();
  await tagPadSettings.load();
  final themeSettings = ThemeSettings();
  await themeSettings.load();
  runApp(
    InstantPlaylistApp(
      queuePlayer: queuePlayer,
      libraryStore: libraryStore,
      tagPadSettings: tagPadSettings,
      themeSettings: themeSettings,
    ),
  );
}

class InstantPlaylistApp extends StatelessWidget {
  final QueuePlayer? queuePlayer;
  final LibraryStore? libraryStore;
  final TagPadSettings? tagPadSettings;
  final ThemeSettings? themeSettings;

  const InstantPlaylistApp({
    super.key,
    this.queuePlayer,
    this.libraryStore,
    this.tagPadSettings,
    this.themeSettings,
  });

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
        if (tagPadSettings != null)
          ChangeNotifierProvider.value(value: tagPadSettings!)
        else
          ChangeNotifierProvider(create: (_) => TagPadSettings()),
        if (themeSettings != null)
          ChangeNotifierProvider.value(value: themeSettings!)
        else
          ChangeNotifierProvider(create: (_) => ThemeSettings()),
      ],
      child: Consumer<ThemeSettings>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Instant Playlist',
          theme: organicTheme(Brightness.light),
          darkTheme: organicTheme(Brightness.dark),
          themeMode: theme.mode,
          // Switching theme dissolves from one palette to the other.
          themeAnimationDuration: const Duration(milliseconds: 320),
          themeAnimationCurve: Curves.easeInOut,
          // Status and navigation bar icons follow the theme on every route.
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: organicOverlayStyle(Organic.of(context)),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
