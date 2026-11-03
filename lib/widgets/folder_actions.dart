import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/library_service.dart';

/// Folder picking shared by the Library's "+ Add" and Settings' "Add
/// folders".

/// Opens the folder picker and returns the picked folder, or null if the
/// user canceled. Permission and access problems are shown as a snackbar.
Future<String?> pickFolderWithFeedback(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!await LibraryService.ensureAudioPermission()) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Audio permission is needed to scan a folder. Enable it in system settings.'),
      ),
    );
    return null;
  }
  try {
    return await LibraryService.pickFolder();
  } on PlatformException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text("Couldn't open that folder: ${e.message}")));
    return null;
  }
}
