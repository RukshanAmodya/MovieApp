class Movie {
  final String id;
  final String title;
  final String coverUrl;
  final String streamUrl;
  final String slug;

  const Movie({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.streamUrl,
    required this.slug,
  });

  factory Movie.fromMap(String id, Map<dynamic, dynamic> map) {
    return Movie(
      id: id,
      title: map['title']?.toString() ?? 'Unknown Title',
      coverUrl: map['cover_url']?.toString() ?? '',
      streamUrl: map['stream_url']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'cover_url': coverUrl,
      'stream_url': streamUrl,
      'slug': slug,
    };
  }
}
