import 'package:firebase_database/firebase_database.dart';
import '../models/movie.dart';

class MovieService {
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;
  MovieService._internal();

  final DatabaseReference _moviesRef =
      FirebaseDatabase.instance.ref('movies');

  /// Returns a live stream of all movies from Firebase Realtime DB.
  Stream<List<Movie>> moviesStream() {
    return _moviesRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Movie>[];

      final Map<dynamic, dynamic> moviesMap = data as Map<dynamic, dynamic>;
      final movies = moviesMap.entries
          .map((e) => Movie.fromMap(
                e.key.toString(),
                e.value as Map<dynamic, dynamic>,
              ))
          .toList();

      // Sort alphabetically by title
      movies.sort((a, b) => a.title.compareTo(b.title));
      return movies;
    });
  }

  /// Fetch movies once (no live updates).
  Future<List<Movie>> fetchMoviesOnce() async {
    final snapshot = await _moviesRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final Map<dynamic, dynamic> moviesMap =
        snapshot.value as Map<dynamic, dynamic>;
    final movies = moviesMap.entries
        .map((e) => Movie.fromMap(
              e.key.toString(),
              e.value as Map<dynamic, dynamic>,
            ))
        .toList();
    movies.sort((a, b) => a.title.compareTo(b.title));
    return movies;
  }
}
