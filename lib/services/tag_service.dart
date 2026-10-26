import 'package:audiotags/audiotags.dart';

/// Reads/writes Instant Playlist tags using the song file's own metadata.
///
/// Tags are stored in the standard "genre" field (ID3 TCON / equivalent),
/// semicolon-separated, since that's the metadata field closest in meaning
/// to a free-form label and is supported across formats by [AudioTags].
class TagService {
  static const _separator = ';';

  static Future<Tag?> readRawTag(String filePath) => AudioTags.read(filePath);

  static Set<String> extractTags(Tag? tag) {
    final genre = tag?.genre;
    if (genre == null || genre.trim().isEmpty) return <String>{};
    return genre
        .split(_separator)
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet();
  }

  static Future<void> writeTags(String filePath, Set<String> tags) async {
    final existing = await AudioTags.read(filePath);
    final updated = Tag(
      title: existing?.title,
      trackArtist: existing?.trackArtist,
      album: existing?.album,
      albumArtist: existing?.albumArtist,
      year: existing?.year,
      genre: tags.join(_separator),
      trackNumber: existing?.trackNumber,
      trackTotal: existing?.trackTotal,
      discNumber: existing?.discNumber,
      discTotal: existing?.discTotal,
      lyrics: existing?.lyrics,
      pictures: existing?.pictures ?? const [],
      bpm: existing?.bpm,
    );
    await AudioTags.write(filePath, updated);
  }
}
