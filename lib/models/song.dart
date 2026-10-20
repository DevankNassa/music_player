class Song {
  final String filePath;
  final String title;
  final String? artist;
  final Set<String> tags;

  Song({
    required this.filePath,
    required this.title,
    this.artist,
    Set<String>? tags,
  }) : tags = tags ?? <String>{};

  Song copyWith({Set<String>? tags}) {
    return Song(
      filePath: filePath,
      title: title,
      artist: artist,
      tags: tags ?? this.tags,
    );
  }
}
