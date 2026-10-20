import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../models/song.dart';
import 'tag_service.dart';

class LibraryService {
  /// Opens the system file picker for audio files and returns a [Song] for
  /// each one picked, with metadata (title/artist/tags) read from the file.
  static Future<List<Song>> pickSongs() async {
    final files = await FilePicker.pickFiles(type: FileType.audio);

    final songs = <Song>[];
    for (final file in files) {
      final path = file.path;
      if (path == null) continue;
      songs.add(await _loadSong(path));
    }
    return songs;
  }

  static Future<Song> _loadSong(String filePath) async {
    final tag = await TagService.readRawTag(filePath);
    final fileName = p.basenameWithoutExtension(filePath);
    return Song(
      filePath: filePath,
      title: (tag?.title?.trim().isNotEmpty ?? false) ? tag!.title! : fileName,
      artist: tag?.trackArtist,
      tags: TagService.extractTags(tag),
    );
  }
}
