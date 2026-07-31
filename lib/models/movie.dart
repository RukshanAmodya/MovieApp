class Movie {
  final String id;
  final String title;
  final String coverUrl;
  final String streamUrl;

  const Movie({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.streamUrl,
  });

  factory Movie.fromMap(String id, dynamic map) {
    if (map is! Map) {
      return Movie(
        id: id,
        title: 'Unknown Title',
        coverUrl: '',
        streamUrl: '',
      );
    }

    final rawCover =
        map['cover_url']?.toString() ?? map['coverUrl']?.toString() ?? '';
    final rawStream =
        map['stream_url']?.toString() ?? map['streamUrl']?.toString() ?? '';

    return Movie(
      id: id,
      title: map['title']?.toString().trim() ?? 'Unknown Title',
      coverUrl: rawCover.trim(),
      streamUrl: rawStream.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'cover_url': coverUrl,
      'stream_url': streamUrl,
    };
  }
}
